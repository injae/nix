import type { EngineInterface, Register } from 'claude-code'
import { fileChangedExpr, inlineEditDenial } from './emacs'

const EMACSCLIENT = 'emacsclient'
const FILE_CHANGED_TIMEOUT_MS = 5_000

const evalInEmacs = async (
  $: EngineInterface,
  expr: string,
  timeoutMs: number,
): Promise<string | undefined> => {
  try {
    const { exitCode, stdout } = await $.process.run([EMACSCLIENT, '--eval', expr], { timeoutMs })
    return exitCode === 0 ? stdout : undefined
  } catch {
    return undefined
  }
}

type ToolOutcome = { deny?: string; isError?: boolean }

const hasSucceeded = (outcome: ToolOutcome): boolean =>
  outcome.deny === undefined && outcome.isError !== true

export const register: Register = on => {
  on('tool.call', { tool: 'Bash' }, ($, e, next) => {
    const denial = inlineEditDenial(e.command)
    return denial === undefined ? next(e) : { deny: denial }
  })

  on('tool.call', { tool: ['Edit', 'Write'] }, async ($, e, next) => {
    const outcome = await next(e)
    if (hasSucceeded(outcome)) await evalInEmacs($, fileChangedExpr(e.file_path), FILE_CHANGED_TIMEOUT_MS)
    return outcome
  })

  on('tool.call', { tool: 'NotebookEdit' }, async ($, e, next) => {
    const outcome = await next(e)
    if (hasSucceeded(outcome)) await evalInEmacs($, fileChangedExpr(e.notebook_path), FILE_CHANGED_TIMEOUT_MS)
    return outcome
  })
}
