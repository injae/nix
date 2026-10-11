import type { EngineInterface, ProcessRunResult, Register } from 'claude-code'

const ENVRC = '.envrc'
const RC_NOT_LOADED = 'RC not loaded'

export const isEnvrc = (path: string): boolean => path === ENVRC || path.endsWith(`/${ENVRC}`)

export const parentDir = (path: string): string => path.slice(0, path.lastIndexOf('/')) || '/'

const direnv = async (
  $: EngineInterface,
  command: 'status' | 'reload',
  cwd: string,
): Promise<ProcessRunResult | undefined> => {
  try {
    return await $.process.run(['direnv', command], { cwd })
  } catch {
    return undefined
  }
}

export const register: Register = on => {
  on('classic.SessionStart', async ($, e, next) => {
    const result = await next(e)
    const envrc = `${e.cwd}/${ENVRC}`
    if (!(await $.fs.exists(envrc))) return result
    const status = await direnv($, 'status', e.cwd)
    if (status?.stdout.includes(RC_NOT_LOADED)) await direnv($, 'reload', e.cwd)
    return { ...result, watchPaths: [...(result.watchPaths ?? []), envrc] }
  })

  on('classic.CwdChanged', async ($, e, next) => {
    const result = await next(e)
    if (await $.fs.exists(`${e.new_cwd}/${ENVRC}`)) await direnv($, 'reload', e.new_cwd)
    return result
  })

  on('classic.FileChanged', async ($, e, next) => {
    const result = await next(e)
    if (e.event !== 'unlink' && isEnvrc(e.file_path)) await direnv($, 'reload', parentDir(e.file_path))
    return result
  })
}
