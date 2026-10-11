import { describe, expect, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On, SessionMessage } from 'claude-code'
import { BEGIN_WORK_UNIT_TOOL, UNITS_PANE, unitRows } from '../hooks/units'

const SURFACES = ['terminal', 'desktop'] as const
const PANE_PROPS = {
  title: 'Work units',
  isFocused: false,
  bodyColumns: 60,
  placement: 'inline' as const,
  scroll: { offset: 0, bodyRows: 20 },
  view: {},
}

const prompt = (text: string): SessionMessage => ({ role: 'user', text, toolUses: [] })
const marker = (title: string): SessionMessage => ({
  role: 'assistant',
  text: '',
  toolUses: [{ tool_use_id: `id-${title}`, tool: BEGIN_WORK_UNIT_TOOL, input: { title } }],
})
const reply = (text: string): SessionMessage => ({ role: 'assistant', text, toolUses: [] })

const conversation = (...titles: string[]): SessionMessage[] =>
  titles.flatMap(title => [prompt(`do ${title}`), marker(title), reply(`${title} done`)])

const recordStatuses = (on: On): (string | undefined)[] => {
  const statuses: (string | undefined)[] = []
  on('ui.status', ($, e) => {
    statuses.push(e.text)
    return { value: undefined }
  })
  return statuses
}

const beginUnits = async ($: Engine, ...titles: string[]): Promise<void> => {
  for (const title of titles) await $.tool.call({ tool: BEGIN_WORK_UNIT_TOOL, title })
}

describe('status line', () => {
  test('shows the current unit when one begins', async ($, on) => {
    const statuses = recordStatuses(on)

    await beginUnits($, 'a', 'b')

    expect(statuses).toEqual(['▸ a', '▸ b'])
  })

  test('shows the current unit again after a reload', async ($, on) => {
    const statuses = recordStatuses(on)
    on('tool.register', ($, e) => ({ value: { tool: `mcp__work-units__${e.name}` } }))
    on('command.register', ($, e) => ({ value: { command: e.name } }))
    on('session.start', ($, e) => ({ cwd: e.cwd }))
    await beginUnits($, 'a')

    await $.session.start({ cwd: '/proj', surface: 'terminal', isInteractive: true })

    expect(statuses).toEqual(['▸ a', '▸ a'])
  })
})

test('/units opens the pane', async ($, on) => {
  const opened: string[] = []
  on('ui.open', ($, e) => {
    opened.push(e.id)
    return { value: { isPlaced: true } }
  })

  const result = await $.command.run({
    command: 'units',
    args: '',
    origin: { kind: 'composer' },
    presentation: { isFullscreen: true, columns: 160 },
  })

  expect(opened).toEqual([UNITS_PANE])
  expect(result.text).toBeDefined()
})

describe('units pane', () => {
  const mountPane = ($: Engine, surface: (typeof SURFACES)[number]) =>
    $.ui.mount({ plugin: 'work-units', surface, component: 'Pane', requestId: UNITS_PANE, props: PANE_PROPS })

  test('marks what the next compaction keeps', async ($, on) => {
    recordStatuses(on)
    on('session.messages', () => ({ value: conversation('a', 'b', 'c') }))
    await beginUnits($, 'a', 'b', 'c')

    for (const surface of SURFACES) {
      const pane = await mountPane($, surface)
      expect(await pane.find({ type: 'Text', text: /· a +다음 compact 때 요약/ })).toBeDefined()
      expect(await pane.find({ type: 'Text', text: /▸ c +원문 유지/ })).toBeDefined()
      await pane.unmount()
    }
  })

  test('says so before any unit begins', async ($, on) => {
    on('session.messages', () => ({ value: [] }))

    const pane = await mountPane($, 'terminal')

    expect(await pane.find({ type: 'Text', text: '아직 작업 단위 없음' })).toBeDefined()
  })

  test('marks units folded by a compaction as summarized', async ($, on) => {
    const messages = conversation('a', 'b', 'c')
    const compacted = [prompt('summary'), reply('ok'), prompt('more'), reply('ok'), ...messages.slice(6)]
    recordStatuses(on)
    on('session.cwd', () => ({ value: '/proj' }))
    on('session.compact', () => ({ messages: [prompt('summary')] }))
    on('session.messages', () => ({ value: compacted }))
    await beginUnits($, 'a', 'b', 'c')

    await $.session.compact({ trigger: 'manual', messages })

    const pane = await mountPane($, 'terminal')
    expect(await pane.find({ type: 'Text', text: /✓ a +요약됨/ })).toBeDefined()
    expect(await pane.find({ type: 'Text', text: /▸ c +원문 유지/ })).toBeDefined()
  })
})

describe('unitRows', () => {
  const units = [
    { title: 'a', isSummarized: true },
    { title: 'b', isSummarized: false },
    { title: 'c', isSummarized: false },
  ]

  test('keeps only the current unit verbatim when the boundary holds', () => {
    expect(unitRows(units, true)).toEqual([
      { mark: '✓', title: 'a', label: '요약됨' },
      { mark: '·', title: 'b', label: '다음 compact 때 요약' },
      { mark: '▸', title: 'c', label: '원문 유지' },
    ])
  })

  test('summarizes the current unit too when the boundary does not hold', () => {
    expect(unitRows(units, false).at(-1)).toEqual({ mark: '▸', title: 'c', label: '다음 compact 때 요약' })
  })
})

test('tool.describe keeps begin_work_unit out of ToolSearch', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description, isDeferred: true }))

  const described = await $.tool.describe({
    tool: BEGIN_WORK_UNIT_TOOL,
    description: 'marks a unit',
    isDeferred: true,
    provider: { plugin: 'work-units', tier: 'user' },
  })

  expect(described.isDeferred).toBe(false)
})
