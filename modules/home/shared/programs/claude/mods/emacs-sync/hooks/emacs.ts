export const fileChangedExpr = (path: string): string =>
  `(claude-code-ide-mcp-file-changed ${JSON.stringify(path)})`

const INLINE_EDIT_RULES: readonly (readonly [name: string, pattern: RegExp])[] = [
  ['heredoc fed to an interpreter', /\b(?:python3?|perl|ruby|node|osascript|bash|sh|zsh)\b[^|;&\n]*<<-?\s*["']?\w/],
  [
    'inline interpreter program (-c / -e)',
    /\b(?:python3?\s+(?:--?[\w-]+(?:=\S*)?\s+)*-c|(?:perl|ruby|node)\s+(?:--?[\w-]+(?:=\S*)?\s+)*-e)\b/,
  ],
  [
    'heredoc redirected into a file',
    />>?\s*\S+[^\n]*<<-?\s*["']?\w|<<-?\s*["']?\w[^\n]*>>?\s*\S|\btee\b[^\n]*<<-?\s*["']?\w/,
  ],
  ['in-place stream edit', /\bsed\b[^|;&\n]*\s-i(?:\b|\.)|\bawk\b[^\n]*-i\s*inplace/],
]

const INLINE_EDIT_GUIDANCE =
  'Write the program to a file with the Write tool and run that file, ' +
  'or make the edit with Edit / ast-rewrite. ' +
  'Reading heredocs that touch no file stay allowed.'

export const inlineEditDenial = (command: string): string | undefined => {
  const rule = INLINE_EDIT_RULES.find(([, pattern]) => pattern.test(command))
  return rule === undefined ? undefined : `Blocked: ${rule[0]}. ${INLINE_EDIT_GUIDANCE}`
}
