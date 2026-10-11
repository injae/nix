import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

export const AUTO_COMPACT_PERCENT = 75
export const WARN_PERCENT = 70

const percentAtom = atom({ plugin: 'compact-guard', key: 'percent' } as const, null)
const isSkippedAtom = atom({ plugin: 'compact-guard', key: 'isSkipped' } as const, false)

const compactNow = async ($: EngineInterface, percent: number): Promise<void> => {
  try {
    $.ui.toast(`context ${percent}%: compacting`)
    await $.session.compact()
    await update($, percentAtom, () => null)
  } catch {
    $.ui.toast('compact waits for the running turn; it retries after the next turn')
  }
}

const measure = async ($: EngineInterface): Promise<number | undefined> => {
  const { percent } = (await $.session.usage()).context
  if (percent === undefined) return undefined
  $.ui.status(`ctx ${percent}%`)
  await update($, percentAtom, () => percent)
  if (percent < WARN_PERCENT) await update($, isSkippedAtom, () => false)
  return percent
}

export const register: Register = on => {
  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId !== undefined || e.reason !== 'answer') return result
    const percent = await measure($)
    if (percent !== undefined && percent >= AUTO_COMPACT_PERCENT && !(await read($, isSkippedAtom))) {
      $.clock.after(0, () => void compactNow($, percent))
    }
    return result
  })

  on('session.compact', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId === undefined && e.trigger !== 'precompute' && result.messages !== undefined) {
      await update($, percentAtom, () => null)
    }
    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)
    const percent = await read($, percentAtom)
    if (percent === null || percent < WARN_PERCENT || (await read($, isSkippedAtom))) return next(e)

    const { Box, Button, Text } = $.ui.resolve(e)
    return (
      <Box>
        <Text color="warning">
          ctx {percent}% · {AUTO_COMPACT_PERCENT}%에서 자동 compact
        </Text>
        <Text> </Text>
        <Button key="compact-now" label="지금 compact" onPress={() => compactNow($, percent)} />
        <Button key="skip" label="건너뛰기" onPress={() => update($, isSkippedAtom, () => true)} />
      </Box>
    )
  })
}
