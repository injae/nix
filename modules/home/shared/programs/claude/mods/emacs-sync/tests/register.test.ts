import { describe, expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import { activeBufferContext, fileChangedExpr, inlineEditDenial } from '../hooks/emacs'

const recordEmacsclient = (on: On, stdout: string): (readonly string[])[] => {
  const calls: (readonly string[])[] = []
  on('process.run', ($, e) => {
    calls.push(e.argv)
    return { value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  return calls
}

describe('UserPromptSubmit', () => {
  test('adds the active buffer inside Emacs', async ($, on) => {
    mock.env(on, { INSIDE_EMACS: 'ghostel' })
    const calls = recordEmacsclient(on, '"upkeep.rs\\t/game/upkeep.rs"\n')
    on('classic.UserPromptSubmit', () => ({}))

    const result = await $.classic.UserPromptSubmit({ prompt: 'hi' })

    expect(calls[0]?.slice(0, 2)).toEqual(['emacsclient', '--eval'])
    expect(result.additionalContext).toEqual(['Active Emacs buffer: upkeep.rs\nFile path: /game/upkeep.rs'])
  })

  test('asks nothing outside Emacs', async ($, on) => {
    mock.env(on, {})
    const calls = recordEmacsclient(on, '')
    on('classic.UserPromptSubmit', () => ({}))

    const result = await $.classic.UserPromptSubmit({ prompt: 'hi' })

    expect(calls).toHaveLength(0)
    expect(result.additionalContext).toBeUndefined()
  })
})

describe('tool.call', () => {
  test('refuses an in-place sed edit', async ($, on) => {
    on('tool.call', { tool: 'Bash' }, () => ({ deny: 'reached the tool' }))

    const outcome = await $.tool.call({ tool: 'Bash', command: "sed -i '' 's/a/b/' f.txt" })

    expect(outcome.deny ?? outcome.text).toContain('Blocked: in-place stream edit.')
  })

  test('tells Emacs about a written file', async ($, on) => {
    const calls = recordEmacsclient(on, 't')
    on('tool.call', { tool: 'Write' }, () => ({ result: { type: 'create', filePath: '/p/a.ts', content: 'x', structuredPatch: [], originalFile: null } }))

    await $.tool.call({ tool: 'Write', file_path: '/p/a.ts', content: 'x' })

    expect(calls).toEqual([['emacsclient', '--eval', '(claude-code-ide-mcp-file-changed "/p/a.ts")']])
  })

  test('leaves Emacs alone when the edit was refused', async ($, on) => {
    const calls = recordEmacsclient(on, 't')
    on('tool.call', { tool: 'Edit' }, () => ({ deny: 'no' }))

    await $.tool.call({ tool: 'Edit', file_path: '/p/a.ts', old_string: 'a', new_string: 'b' })

    expect(calls).toHaveLength(0)
  })
})

describe('activeBufferContext', () => {
  test('reads a raw tab and a buffer without a file path', () => {
    expect(activeBufferContext('"a.rs\t/x/a.rs"')).toBe('Active Emacs buffer: a.rs\nFile path: /x/a.rs')
    expect(activeBufferContext('"scratch"')).toBe('Active Emacs buffer: scratch')
  })

  test('ignores nil and unquoted output', () => {
    expect(activeBufferContext('nil')).toBeUndefined()
    expect(activeBufferContext('""')).toBeUndefined()
  })
})

test('fileChangedExpr quotes the path as a Lisp string', () => {
  expect(fileChangedExpr('/p/"q".ts')).toBe('(claude-code-ide-mcp-file-changed "/p/\\"q\\".ts")')
})

describe('inlineEditDenial', () => {
  const BLOCKED: readonly (readonly [command: string, rule: string])[] = [
    ["python3 - <<'EOF'\nprint(1)\nEOF", 'heredoc fed to an interpreter'],
    ['python3 -c "open(1)"', 'inline interpreter program (-c / -e)'],
    ['perl -w -e "x"', 'inline interpreter program (-c / -e)'],
    ['node --no-warnings -e "x"', 'inline interpreter program (-c / -e)'],
    ['node --max-old-space-size=4096 -e "x"', 'inline interpreter program (-c / -e)'],
    ['python3 --isolated -c "x"', 'inline interpreter program (-c / -e)'],
    ['cat > out.txt <<EOF\nx\nEOF', 'heredoc redirected into a file'],
    ['tee out.txt <<EOF\nx\nEOF', 'heredoc redirected into a file'],
    ['sed -i.bak s/a/b/ f', 'in-place stream edit'],
    ['awk -i inplace 1 f', 'in-place stream edit'],
  ]

  test('blocks each invisible edit form', () => {
    for (const [command, rule] of BLOCKED) {
      expect(inlineEditDenial(command), command).toStartWith(`Blocked: ${rule}.`)
    }
  })

  test('allows reads and plain commands', () => {
    for (const command of [
      'cat <<EOF\nhi\nEOF',
      'git status',
      'sed -n 1,5p f',
      'grep -i foo f',
      'python3 tool.py -c config.toml',
    ]) {
      expect(inlineEditDenial(command), command).toBeUndefined()
    }
  })
})
