import { describe, expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On, SessionMessage, TurnCompleteInput } from 'claude-code'

const MESSAGES: SessionMessage[] = [{ role: 'user', text: 'hi', toolUses: [] }]

const TURN: TurnCompleteInput = { answer: 'done', durationMs: 1, isAborted: false, turnId: 't1', reason: 'answer' }

describe('auto compact', () => {
  const runTurn = async (
    $: Engine,
    on: On,
    percent: number,
    turn: TurnCompleteInput,
  ): Promise<(string | undefined)[]> => {
    const clock = mock.clock(on)
    on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200_000, percent }, rateLimits: [] } }))
    on('ui.toast', () => ({ value: undefined }))
    on('ui.status', () => ({ value: undefined }))
    on('turn.complete', ($, e) => ({ text: e.answer }))
    const instructions: (string | undefined)[] = []
    on('session.compact', ($, e) => {
      instructions.push(e.instructions)
      return { messages: MESSAGES }
    })

    await $.turn.complete(turn)
    await clock.settle()
    return instructions
  }

  test('compacts after an answered turn at the threshold, leaving how to compact to other plugins', async ($, on) => {
    expect(await runTurn($, on, 75, TURN)).toEqual([undefined])
  })

  test('leaves the conversation below the threshold', async ($, on) => {
    expect(await runTurn($, on, 74, TURN)).toEqual([])
  })

  test('leaves an interrupted turn alone', async ($, on) => {
    expect(await runTurn($, on, 90, { ...TURN, isAborted: true, reason: 'aborted' })).toEqual([])
  })

  test("leaves a subagent's turn alone", async ($, on) => {
    expect(await runTurn($, on, 90, { ...TURN, agentId: 'a1' })).toEqual([])
  })
})
