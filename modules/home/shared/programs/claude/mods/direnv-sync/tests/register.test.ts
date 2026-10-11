import { describe, expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import { isEnvrc, parentDir } from '../hooks/register'

type DirenvCall = { argv: readonly string[]; cwd: string | undefined }

const recordDirenv = (on: On, statusOutput: string): DirenvCall[] => {
  const calls: DirenvCall[] = []
  on('process.run', ($, e) => {
    calls.push({ argv: e.argv, cwd: e.init?.cwd })
    const stdout = e.argv[1] === 'status' ? statusOutput : ''
    return { value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  return calls
}

const withEnvrcIn = (on: On, dir: string): void => {
  on('fs.exists', ($, e) => ({ value: e.path === `${dir}/.envrc` }))
}

describe('SessionStart', () => {
  test('reloads an unloaded .envrc and watches it', async ($, on) => {
    withEnvrcIn(on, '/proj')
    const calls = recordDirenv(on, 'Found RC path /proj/.envrc\nRC not loaded\n')
    on('classic.SessionStart', () => ({}))

    const result = await $.classic.SessionStart({ source: 'startup', cwd: '/proj' })

    expect(calls.map(call => call.argv[1])).toEqual(['status', 'reload'])
    expect(calls[1]?.cwd).toBe('/proj')
    expect(result.watchPaths).toEqual(['/proj/.envrc'])
  })

  test('leaves a loaded .envrc alone', async ($, on) => {
    withEnvrcIn(on, '/proj')
    const calls = recordDirenv(on, 'Found RC allowed true\nFound RC path /proj/.envrc\n')
    on('classic.SessionStart', () => ({}))

    await $.classic.SessionStart({ source: 'startup', cwd: '/proj' })

    expect(calls.map(call => call.argv[1])).toEqual(['status'])
  })

  test('does nothing without an .envrc', async ($, on) => {
    withEnvrcIn(on, '/elsewhere')
    const calls = recordDirenv(on, '')
    on('classic.SessionStart', () => ({}))

    const result = await $.classic.SessionStart({ source: 'startup', cwd: '/proj' })

    expect(calls).toHaveLength(0)
    expect(result.watchPaths).toBeUndefined()
  })
})

test('CwdChanged reloads in the new directory', async ($, on) => {
  withEnvrcIn(on, '/next')
  const calls = recordDirenv(on, '')
  on('classic.CwdChanged', () => ({}))

  await $.classic.CwdChanged({ old_cwd: '/proj', new_cwd: '/next' })

  expect(calls).toEqual([{ argv: ['direnv', 'reload'], cwd: '/next' }])
})

describe('FileChanged', () => {
  test('reloads beside a changed .envrc', async ($, on) => {
    const calls = recordDirenv(on, '')
    on('classic.FileChanged', () => ({}))

    await $.classic.FileChanged({ file_path: '/proj/sub/.envrc', event: 'change' })

    expect(calls).toEqual([{ argv: ['direnv', 'reload'], cwd: '/proj/sub' }])
  })

  test('ignores other files and a removed .envrc', async ($, on) => {
    const calls = recordDirenv(on, '')
    on('classic.FileChanged', () => ({}))

    await $.classic.FileChanged({ file_path: '/proj/.envrc.local', event: 'change' })
    await $.classic.FileChanged({ file_path: '/proj/.envrc', event: 'unlink' })

    expect(calls).toHaveLength(0)
  })
})

test('path helpers', () => {
  expect(isEnvrc('.envrc')).toBe(true)
  expect(isEnvrc('/a/b.envrc')).toBe(false)
  expect(parentDir('/a/.envrc')).toBe('/a')
  expect(parentDir('/.envrc')).toBe('/')
})
