import { describe, expect, test } from 'claude-code/testing'
import type { On, SessionMessage } from 'claude-code'
import {
  BEGIN_WORK_UNIT_TOOL,
  GROUPING_DIRECTIVE,
  PRESERVE_DIRECTIVE,
  compactInstructions,
  keptStart,
  markedUnitStart,
  parseBoundary,
} from '../hooks/units'

const prompt = (text: string): SessionMessage => ({ role: 'user', text, toolUses: [] })

const reply = (text: string, tool?: string): SessionMessage => ({
  role: 'assistant',
  text,
  toolUses: tool === undefined ? [] : [{ tool_use_id: `id-${text}`, tool, input: { title: text } }],
})

const toolResult = (text: string): SessionMessage => ({
  role: 'user',
  text: '',
  toolUses: [],
  toolResults: [{ tool_use_id: `id-${text}`, text: 'ok', isError: false }],
})

const unit = (title: string): SessionMessage[] => [
  prompt(`do ${title}`),
  reply(title, BEGIN_WORK_UNIT_TOOL),
  toolResult(title),
  reply(`${title} done`),
]

const CONVERSATION = [...unit('a'), ...unit('b'), ...unit('c')]

describe('markedUnitStart', () => {
  test('starts at the prompt before the last begin_work_unit call', () => {
    expect(markedUnitStart(CONVERSATION)).toBe(8)
  })

  test('skips tool results when looking back for the prompt', () => {
    const messages = [prompt('x'), reply('read', 'Read'), toolResult('read'), reply('c', BEGIN_WORK_UNIT_TOOL)]

    expect(markedUnitStart(messages)).toBe(0)
  })

  test('answers undefined without a marker', () => {
    expect(markedUnitStart([prompt('x'), reply('y')])).toBeUndefined()
  })
})

describe('keptStart', () => {
  test('keeps the current unit when it is at most half the conversation', () => {
    expect(keptStart(8, 12)).toBe(8)
    expect(keptStart(6, 12)).toBe(6)
  })

  test('summarizes everything when the unit is the whole conversation, too big, or unknown', () => {
    expect(keptStart(0, 12)).toBeUndefined()
    expect(keptStart(5, 12)).toBeUndefined()
    expect(keptStart(undefined, 12)).toBeUndefined()
  })
})

test('parseBoundary accepts only a listed prompt index', () => {
  expect(parseBoundary('8', [0, 4, 8])).toBe(8)
  expect(parseBoundary('The current unit starts at [4].', [0, 4, 8])).toBe(4)
  expect(parseBoundary('5', [0, 4, 8])).toBeUndefined()
  expect(parseBoundary('none', [0, 4, 8])).toBeUndefined()
})

test('compactInstructions keeps the person’s words first', () => {
  expect(compactInstructions('keep the plan')).toBe(
    `keep the plan\n\n${GROUPING_DIRECTIVE}\n\n${PRESERVE_DIRECTIVE}`,
  )
  expect(compactInstructions(undefined)).toBe(`${GROUPING_DIRECTIVE}\n\n${PRESERVE_DIRECTIVE}`)
})

const SUMMARY: SessionMessage = { role: 'user', text: 'summary', toolUses: [] }

const recordSummarized = (on: On): SessionMessage[][] => {
  const summarized: SessionMessage[][] = []
  on('session.compact', ($, e) => {
    summarized.push([...e.messages])
    return { messages: [SUMMARY] }
  })
  return summarized
}

describe('session.compact', () => {
  test('summarizes finished units and keeps the current one verbatim', async ($, on) => {
    on('session.cwd', () => ({ value: '/proj' }))
    const summarized = recordSummarized(on)

    const result = await $.session.compact({ trigger: 'manual', messages: CONVERSATION })

    expect(summarized).toEqual([CONVERSATION.slice(0, 8)])
    expect(result.messages).toEqual([SUMMARY, ...CONVERSATION.slice(8)])
  })

  test('asks haiku for the boundary when no unit was marked', async ($, on) => {
    const unmarked = [prompt('a'), reply('a'), prompt('b'), reply('b'), prompt('c'), reply('c')]
    on('session.cwd', () => ({ value: '/proj' }))
    const asked: string[] = []
    on('model.complete', ($, e) => {
      asked.push(e.model)
      return { value: { isAnswered: true, text: '4', usage: USAGE } }
    })
    const summarized = recordSummarized(on)

    const result = await $.session.compact({ trigger: 'manual', messages: unmarked })

    expect(asked).toEqual(['haiku'])
    expect(summarized).toEqual([unmarked.slice(0, 4)])
    expect(result.messages).toEqual([SUMMARY, ...unmarked.slice(4)])
  })

  test('summarizes everything when haiku cannot tell', async ($, on) => {
    const unmarked = [prompt('a'), reply('a'), prompt('b'), reply('b')]
    on('session.cwd', () => ({ value: '/proj' }))
    on('model.complete', () => ({ value: { isAnswered: false, reason: 'empty-reply', usage: USAGE } }))
    const summarized = recordSummarized(on)

    const result = await $.session.compact({ trigger: 'manual', messages: unmarked })

    expect(summarized).toEqual([unmarked])
    expect(result.messages).toEqual([SUMMARY])
  })

  test('passes the grouping and preserve directives to the summarizer', async ($, on) => {
    on('session.cwd', () => ({ value: '/proj' }))
    const instructions: (string | undefined)[] = []
    on('session.compact', ($, e) => {
      instructions.push(e.instructions)
      return { messages: [SUMMARY] }
    })

    await $.session.compact({ trigger: 'manual', messages: CONVERSATION, instructions: 'keep the plan' })

    expect(instructions).toEqual([compactInstructions('keep the plan')])
  })

  test('declines precompute so the real compaction sees the current unit', async ($, on) => {
    const summarized = recordSummarized(on)

    const result = await $.session.compact({ trigger: 'precompute', messages: CONVERSATION })

    expect(summarized).toHaveLength(0)
    expect(result.skip).toBeDefined()
  })

  test("leaves a subagent's compaction alone", async ($, on) => {
    const summarized = recordSummarized(on)

    await $.session.compact({ trigger: 'auto', agentId: 'a1', messages: CONVERSATION })

    expect(summarized).toEqual([CONVERSATION])
  })
})

test('begin_work_unit answers with its title', async ($, on) => {
  on('tool.call', { tool: BEGIN_WORK_UNIT_TOOL }, () => ({ deny: 'reached the bottom' }))
  on('ui.status', () => ({ value: undefined }))

  const outcome = await $.tool.call({ tool: BEGIN_WORK_UNIT_TOOL, title: 'compact grouping' })

  expect(outcome.result).toBe('work unit: compact grouping')
})

const USAGE = { input_tokens: 1, output_tokens: 1, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 }
