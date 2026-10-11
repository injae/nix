import type { EngineInterface, Register } from 'claude-code'
import {
  EXPLORE_REMINDER,
  FLAKE_WITH_ENVRC,
  SKILL_ACTIVATION,
  SKILL_REMINDER,
  type SessionEnvironment,
  sessionStartContext,
  shellPlanReason,
  shellPlanTools,
} from './context'

const LOCAL_INSTRUCTIONS = '.claude/CLAUDE.local.md'

type WithContext = { additionalContext?: string[] }

const withContext = <R extends WithContext>(result: R, ...context: string[]): R => ({
  ...result,
  additionalContext: [...(result.additionalContext ?? []), ...context],
})

const readText = async ($: EngineInterface, path: string): Promise<string | undefined> => {
  if (!(await $.fs.exists(path))) return undefined
  const content = await $.fs.read(path)
  return typeof content === 'string' ? content : undefined
}

const nixReason = async ($: EngineInterface, cwd: string): Promise<string | undefined> => {
  const nixConfigDir = await $.env.get('NIX_CONFIG_DIR')
  if (nixConfigDir) return `NIX_CONFIG_DIR=${nixConfigDir}`
  const [hasFlake, hasEnvrc] = await Promise.all([
    $.fs.exists(`${cwd}/flake.nix`),
    $.fs.exists(`${cwd}/.envrc`),
  ])
  return hasFlake && hasEnvrc ? FLAKE_WITH_ENVRC : undefined
}

const localInstructions = async ($: EngineInterface): Promise<string | undefined> => {
  const home = await $.env.get('HOME')
  if (home === undefined) return undefined
  const content = (await readText($, `${home}/${LOCAL_INSTRUCTIONS}`))?.trim()
  return content || undefined
}

const readSessionEnvironment = async (
  $: EngineInterface,
  cwd: string,
): Promise<SessionEnvironment> => {
  const insideEmacs = await $.env.get('INSIDE_EMACS')
  const isEmacs = Boolean(insideEmacs) || (await $.env.get('TERM_PROGRAM')) === 'emacs'
  return {
    insideEmacs: isEmacs ? (insideEmacs ?? '') : undefined,
    nixReason: await nixReason($, cwd),
    localInstructions: await localInstructions($),
  }
}

export const register: Register = on => {
  on('classic.SessionStart', async ($, e, next) => {
    const result = await next(e)
    const context = sessionStartContext(await readSessionEnvironment($, e.cwd))
    return withContext(result, context, SKILL_ACTIVATION)
  })

  on('classic.UserPromptSubmit', async ($, e, next) =>
    withContext(await next(e), SKILL_REMINDER, EXPLORE_REMINDER),
  )

  on('classic.Stop', async ($, e, next) => {
    const result = await next(e)
    if (e.stop_hook_active || result.block !== undefined) return result
    const tools = shellPlanTools(e.last_assistant_message ?? '')
    return tools.length === 0 ? result : { ...result, block: shellPlanReason(tools) }
  })
}
