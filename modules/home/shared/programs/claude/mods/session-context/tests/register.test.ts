import { describe, expect, mock, test } from 'claude-code/testing'
import {
  EXPLORE_REMINDER,
  FLAKE_WITH_ENVRC,
  SKILL_ACTIVATION,
  SKILL_REMINDER,
  shellPlanTools,
} from '../hooks/context'

const HOME = '/home/me'
const LOCAL_MD = `${HOME}/.claude/CLAUDE.local.md`

describe('SessionStart', () => {
  test('injects emacs, nix and local instructions inside Emacs with NIX_CONFIG_DIR', async ($, on) => {
    mock.env(on, { INSIDE_EMACS: 'ghostel', NIX_CONFIG_DIR: '/nix-config', HOME })
    on('fs.exists', ($, e) => ({ value: e.path === LOCAL_MD }))
    on('fs.read', () => ({ value: '  local rule  \n' }))
    on('classic.SessionStart', () => ({}))

    const result = await $.classic.SessionStart({ source: 'startup' })
    const [context, activation] = result.additionalContext ?? []

    expect(context).toStartWith('Emacs detected (INSIDE_EMACS=ghostel).')
    expect(context).toContain('/emacs-dev')
    expect(context).toContain('Nix environment detected (NIX_CONFIG_DIR=/nix-config)')
    expect(context).toEndWith('CLAUDE.local.md:\nlocal rule')
    expect(activation).toBe(SKILL_ACTIVATION)
  })

  test('detects nix from flake.nix and .envrc when NIX_CONFIG_DIR is unset', async ($, on) => {
    mock.env(on, { HOME })
    on('fs.exists', ($, e) => ({ value: e.path === '/proj/flake.nix' || e.path === '/proj/.envrc' }))
    on('classic.SessionStart', () => ({}))

    const result = await $.classic.SessionStart({ source: 'startup', cwd: '/proj' })
    const [context] = result.additionalContext ?? []

    expect(context).not.toContain('Emacs detected')
    expect(context).toStartWith('MANDATORY SESSION START: You MUST invoke the /emacs-dev skill')
    expect(context).toContain(FLAKE_WITH_ENVRC)
    expect(context).not.toContain('CLAUDE.local.md')
  })

  test('skips nix directive and blank local instructions', async ($, on) => {
    mock.env(on, { TERM_PROGRAM: 'emacs', HOME })
    on('fs.exists', ($, e) => ({ value: e.path === LOCAL_MD }))
    on('fs.read', () => ({ value: '   \n' }))
    on('classic.SessionStart', () => ({}))

    const result = await $.classic.SessionStart({ source: 'startup', cwd: '/proj' })
    const [context] = result.additionalContext ?? []

    expect(context).toStartWith('Emacs detected (INSIDE_EMACS=).')
    expect(context).not.toContain('/nix-system')
    expect(context).not.toContain('CLAUDE.local.md')
  })
})

test('UserPromptSubmit adds the skill and explore reminders', async ($, on) => {
  on('classic.UserPromptSubmit', () => ({}))

  const result = await $.classic.UserPromptSubmit({ prompt: 'hi' })

  expect(result.additionalContext).toEqual([SKILL_REMINDER, EXPLORE_REMINDER])
})

describe('Stop', () => {
  const SHELL_PLAN = [
    '1. hooks/ — structure-tree — layout',
    '2. register.ts — Bash grep (fallback) — callers',
  ].join('\n')

  test('blocks a plan that names a shell tool', async ($, on) => {
    on('classic.Stop', () => ({}))

    const result = await $.classic.Stop({ stop_hook_active: false, last_assistant_message: SHELL_PLAN })

    expect(result.block).toContain('Exploration plan routes through the shell: Bash grep (fallback).')
  })

  test('passes when the stop hook already re-prompted', async ($, on) => {
    on('classic.Stop', () => ({}))

    const result = await $.classic.Stop({ stop_hook_active: true, last_assistant_message: SHELL_PLAN })

    expect(result.block).toBeUndefined()
  })
})

describe('shellPlanTools', () => {
  test('ignores shell words inside parentheses and non-plan lines', () => {
    const message = [
      'Plan:',
      '1. a.ts — file-outline (no cat) — symbols',
      '2. src — grep-block — usages',
      'run ls — later',
    ].join('\n')

    expect(shellPlanTools(message)).toEqual([])
  })

  test('returns each shell-routed tool trimmed', () => {
    const message = '1. a — cat — x\n2. b —  rg -n foo  — y'

    expect(shellPlanTools(message)).toEqual(['cat', 'rg -n foo'])
  })
})
