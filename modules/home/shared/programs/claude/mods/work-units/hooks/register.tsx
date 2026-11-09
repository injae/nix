import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, SessionMessage } from 'claude-code'
import {
  BEGIN_WORK_UNIT,
  BEGIN_WORK_UNIT_DESCRIPTION,
  BEGIN_WORK_UNIT_TOOL,
  UNITS_PANE,
  afterCompaction,
  boundaryQuestion,
  compactInstructions,
  isUnitMarker,
  keptStart,
  markedUnitStart,
  parseBoundary,
  promptIndexes,
  unitRows,
} from './units'

const unitsAtom = atom({ plugin: 'work-units', key: 'units' } as const, [])
const BOUNDARY_MODEL = 'haiku'
const BOUNDARY_MAX_TOKENS = 16
const UNITS_COMMAND = 'units'
const PANE_TITLE = 'Work units'

const judgedUnitStart = async (
  $: EngineInterface,
  messages: readonly SessionMessage[],
): Promise<number | undefined> => {
  const indexes = promptIndexes(messages)
  if (indexes.length < 2) return undefined
  const reply = await $.model.complete({
    model: BOUNDARY_MODEL,
    prompt: boundaryQuestion(messages, indexes),
    maxTokens: BOUNDARY_MAX_TOKENS,
  })
  return reply.isAnswered ? parseBoundary(reply.text, indexes) : undefined
}

const currentUnitStart = async (
  $: EngineInterface,
  messages: readonly SessionMessage[],
): Promise<number | undefined> =>
  keptStart(markedUnitStart(messages) ?? (await judgedUnitStart($, messages)), messages.length)

const showCurrentUnit = ($: EngineInterface, title: string | undefined): void => {
  $.ui.status(title === undefined ? undefined : `▸ ${title}`)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: BEGIN_WORK_UNIT,
      description: BEGIN_WORK_UNIT_DESCRIPTION,
      inputSchema: {
        type: 'object',
        properties: { title: { type: 'string', description: 'Short name of the unit of work' } },
        required: ['title'],
      },
    })
    await $.command.register({ name: UNITS_COMMAND, description: 'Show the work units of this session' })
    showCurrentUnit($, (await read($, unitsAtom)).at(-1)?.title)
    return next(e)
  })

  on('tool.describe', { tool: BEGIN_WORK_UNIT_TOOL }, async ($, e, next) => ({
    ...(await next(e)),
    isDeferred: false,
  }))

  on('tool.call', { tool: BEGIN_WORK_UNIT_TOOL }, async ($, e) => {
    const title = String(e.title)
    await update($, unitsAtom, units => [...units, { title, isSummarized: false }])
    showCurrentUnit($, title)
    return { result: `work unit: ${title}` }
  })

  on('command.run', { command: UNITS_COMMAND }, async $ => {
    await $.ui.open({ id: UNITS_PANE, title: PANE_TITLE, closeOnEscape: true })
    return { text: 'Work units pane opened.' }
  })

  on('session.compact', async ($, e, next) => {
    if (e.agentId !== undefined) return next(e)
    if (e.trigger === 'precompute') return { skip: 'work-units compacts when the compaction runs' }
    const instructions = compactInstructions(e.instructions)
    const start = await currentUnitStart($, e.messages)
    const summarized = start === undefined ? e.messages : e.messages.slice(0, start)
    const result = await next({ ...e, instructions, messages: summarized })
    if (result.messages === undefined) return result
    const kept = start === undefined ? [] : e.messages.slice(start)
    await update($, unitsAtom, units => afterCompaction(units, kept.some(isUnitMarker)))
    return { ...result, messages: [...result.messages, ...kept] }
  })

  on('ui.render', { component: 'Pane', requestId: UNITS_PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const units = await read($, unitsAtom)
    if (units.length === 0) return <Text dimColor>아직 작업 단위 없음</Text>

    const messages = await $.session.messages()
    const keepsCurrent = keptStart(markedUnitStart(messages), messages.length) !== undefined
    const rows = unitRows(units, keepsCurrent)
    const width = Math.max(...rows.map(row => row.title.length))
    return (
      <Box flexDirection="column">
        <Text bold>작업 단위 ({units.length})</Text>
        {rows.map(row => (
          <Text dimColor={row.mark === '✓'}>{`${row.mark} ${row.title.padEnd(width)}  ${row.label}`}</Text>
        ))}
      </Box>
    )
  })
}
