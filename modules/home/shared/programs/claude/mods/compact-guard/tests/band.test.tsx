import { describe, expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On, SessionMessage, TurnCompleteInput } from 'claude-code'

const MESSAGES: SessionMessage[] = [{ role: 'user', text: 'hi', toolUses: [] }]
const TURN: TurnCompleteInput = { answer: 'done', durationMs: 1, isAborted: false, turnId: 't1', reason: 'answer' }
const SURFACES = ['terminal', 'desktop'] as const
const ENGINE_BAND = 'engine band'
const BAND_PROPS = {
  hasSurvey: false,
  isWorking: false,
  maxRows: 10,
  bodyColumns: 80,
  scroll: { offset: 0, bodyRows: 10 },
  view: {},
}

type World = { statuses: (string | undefined)[]; compactions: number; toasts: string[] }

let settle: () => Promise<void> = async () => {}

const world = (on: On, percents: number[]): World => {
  const state: World = { statuses: [], compactions: 0, toasts: [] }
  settle = mock.clock(on).settle
  on('session.usage', () => ({
    value: { startedAt: 0, context: { window: 200_000, percent: percents.shift() }, rateLimits: [] },
  }))
  on('ui.status', ($, e) => {
    state.statuses.push(e.text)
    return { value: undefined }
  })
  on('ui.toast', ($, e) => {
    state.toasts.push(e.text)
    return { value: undefined }
  })
  on('turn.complete', ($, e) => ({ text: e.answer }))
  on('session.compact', () => {
    state.compactions += 1
    return { messages: MESSAGES }
  })
  on('ui.render', { component: 'AbovePrompt' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>{ENGINE_BAND}</Text>
  })
  return state
}

const finishTurn = async ($: Engine, turn: TurnCompleteInput = TURN): Promise<void> => {
  await $.turn.complete(turn)
  await settle()
}

const mountBand = ($: Engine, surface: (typeof SURFACES)[number]) =>
  $.ui.mount({ plugin: 'compact-guard', surface, component: 'AbovePrompt', props: BAND_PROPS })

describe('status line', () => {
  test('shows the context fill after each main turn', async ($, on) => {
    const { statuses } = world(on, [42, 43])

    await finishTurn($)
    await finishTurn($, { ...TURN, agentId: 'a1' })

    expect(statuses).toEqual(['ctx 42%'])
  })
})

describe('warning band', () => {
  test('leaves the band to the engine below 70%', async ($, on) => {
    world(on, [69])
    await finishTurn($)

    for (const surface of SURFACES) {
      const band = await mountBand($, surface)
      expect(await band.find({ text: ENGINE_BAND })).toBeDefined()
      await band.unmount()
    }
  })

  test('warns from 70% with both actions', async ($, on) => {
    world(on, [72])
    await finishTurn($)

    for (const surface of SURFACES) {
      const band = await mountBand($, surface)
      expect(await band.find({ type: 'Text', text: 'ctx 72% · 75%에서 자동 compact' })).toBeDefined()
      expect(await band.findAll({ type: 'Button' })).toHaveLength(2)
      await band.unmount()
    }
  })

  test('compacts now and hides the band', async ($, on) => {
    const state = world(on, [72])
    await finishTurn($)
    const band = await mountBand($, 'terminal')

    await band.press({ key: 'compact-now' })

    expect(state.compactions).toBe(1)
    expect(await band.find({ text: ENGINE_BAND })).toBeDefined()
  })

  test('skips auto compact until the context falls below 70%', async ($, on) => {
    const state = world(on, [72, 80, 30, 80])
    await finishTurn($)
    const band = await mountBand($, 'terminal')

    await band.press({ key: 'skip' })
    await finishTurn($)
    expect(state.compactions).toBe(0)
    expect(await band.find({ text: ENGINE_BAND })).toBeDefined()

    await finishTurn($)
    await finishTurn($)
    expect(state.compactions).toBe(1)
  })

  test('hides the band after another plugin compacts', async ($, on) => {
    world(on, [72])
    await finishTurn($)

    await $.session.compact({ trigger: 'manual', messages: MESSAGES })

    const band = await mountBand($, 'terminal')
    expect(await band.find({ text: ENGINE_BAND })).toBeDefined()
  })
})
