import type { SessionMessage } from 'claude-code'
import type { WorkUnit } from '../types'

export const BEGIN_WORK_UNIT = 'begin_work_unit'
export const BEGIN_WORK_UNIT_TOOL = 'mcp__work-units__begin_work_unit'

export const BEGIN_WORK_UNIT_DESCRIPTION =
  'Marks the start of a new unit of work. Call it once, before any other tool, whenever you begin ' +
  'a new user request or switch to a distinct task. Compaction later summarizes finished units by ' +
  'their titles and keeps the current unit verbatim.'

export const GROUPING_DIRECTIVE =
  'Organize the summary by unit of work, each headed by its begin_work_unit title (or a short name ' +
  'you give it), oldest first: goal, decisions and their reasons, files changed, status, open items.'

export const PRESERVE_DIRECTIVE =
  'Preserve the MANDATORY SKILL ACTIVATION SEQUENCE directive verbatim in the summary. ' +
  'Do not remove, summarize, or weaken it.'

const BOUNDARY_PROMPTS = 50
const EXCERPT_CHARS = 200

export const compactInstructions = (instructions: string | undefined): string =>
  [instructions, GROUPING_DIRECTIVE, PRESERVE_DIRECTIVE].filter(Boolean).join('\n\n')

const isPrompt = (message: SessionMessage): boolean =>
  message.role === 'user' && !message.toolResults?.length

export const isUnitMarker = (message: SessionMessage): boolean =>
  message.role === 'assistant' && message.toolUses.some(use => use.tool === BEGIN_WORK_UNIT_TOOL)

export const markedUnitStart = (messages: readonly SessionMessage[]): number | undefined => {
  const marker = messages.findLastIndex(isUnitMarker)
  if (marker === -1) return undefined
  const prompt = messages.slice(0, marker).findLastIndex(isPrompt)
  return prompt === -1 ? marker : prompt
}

export const keptStart = (start: number | undefined, total: number): number | undefined =>
  start === undefined || start === 0 || total - start > total / 2 ? undefined : start

export const promptIndexes = (messages: readonly SessionMessage[]): number[] =>
  messages.flatMap((message, index) => (isPrompt(message) ? [index] : [])).slice(-BOUNDARY_PROMPTS)

const excerpt = (text: string): string => text.replace(/\s+/g, ' ').trim().slice(0, EXCERPT_CHARS)

export const boundaryQuestion = (messages: readonly SessionMessage[], indexes: readonly number[]): string =>
  [
    "Below are the user's prompts from a coding session, oldest first, each with its index.",
    'Reply with only the index of the prompt where the current unit of work began: the latest task, ' +
      'still in progress, together with the follow-ups and approvals that belong to it.',
    '',
    ...indexes.map(index => `[${index}] ${excerpt(messages[index]?.text ?? '')}`),
  ].join('\n')

export const parseBoundary = (reply: string, indexes: readonly number[]): number | undefined => {
  const index = Number(/\d+/.exec(reply)?.[0])
  return indexes.includes(index) ? index : undefined
}

export const UNITS_PANE = 'units'

export type UnitRow = { mark: '✓' | '·' | '▸'; title: string; label: string }

const SUMMARIZED = '요약됨'
const SUMMARIZED_NEXT = '다음 compact 때 요약'
const KEPT_VERBATIM = '원문 유지'

export const unitRows = (units: readonly WorkUnit[], keepsCurrent: boolean): UnitRow[] =>
  units.map((unit, index): UnitRow => {
    if (unit.isSummarized) return { mark: '✓', title: unit.title, label: SUMMARIZED }
    const isCurrent = index === units.length - 1
    if (!isCurrent) return { mark: '·', title: unit.title, label: SUMMARIZED_NEXT }
    return { mark: '▸', title: unit.title, label: keepsCurrent ? KEPT_VERBATIM : SUMMARIZED_NEXT }
  })

export const afterCompaction = (units: readonly WorkUnit[], keepsCurrent: boolean): WorkUnit[] =>
  units.map((unit, index) =>
    keepsCurrent && index === units.length - 1 ? unit : { ...unit, isSummarized: true },
  )
