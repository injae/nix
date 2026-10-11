export const ACTIVE_BUFFER_EXPR = String.raw`(let* ((buf (seq-find (lambda (b) (let ((n (buffer-name b))) (and (buffer-file-name b) (not (string-prefix-p " " n)) (not (string-match-p "\\*claude-code" n))))) (buffer-list)))) (when buf (format "%s\t%s" (buffer-name buf) (buffer-file-name buf))))`

const PRINTED_STRING = /^"(.*)"$/s

export const activeBufferContext = (stdout: string): string | undefined => {
  const printed = PRINTED_STRING.exec(stdout.trim())?.[1]
  if (printed === undefined) return undefined
  const raw = printed.replaceAll('\\t', '\t').replaceAll('\\n', '\n')
  const tab = raw.indexOf('\t')
  const name = tab === -1 ? raw : raw.slice(0, tab)
  const path = tab === -1 ? '' : raw.slice(tab + 1)
  if (name === '') return undefined
  return path === '' ? `Active Emacs buffer: ${name}` : `Active Emacs buffer: ${name}\nFile path: ${path}`
}

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
