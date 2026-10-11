export const SKILL_ACTIVATION = `INSTRUCTION: MANDATORY SKILL ACTIVATION SEQUENCE

Step 1 - EVALUATE (must appear in your next response):
For each relevant skill in <available_skills>, state: [skill-name] - YES/NO - [reason]

Step 2 - ACTIVATE (immediately after Step 1):
IF any skills are YES and not yet loaded in this session -> load each relevant SKILL.md via read or /skill:name now
IF any YES skill is already loaded and unchanged -> do NOT reload; state "already loaded" and proceed
IF no skills are YES -> state "No skills needed" and proceed

Step 3 - IMPLEMENT:
Only after Step 2 is complete, proceed with implementation.

CRITICAL: Do not skip activation. Evaluation without activation is invalid.`

export const SKILL_REMINDER =
  'SKILL: evaluate ALL skills (incl. programming-core) → activate → implement.'

export const EXPLORE_REMINDER = [
  'EXPLORE BEFORE ACTING: info gather? Plan first → Targets / Order(target—tool—reason) / Goal / Unknowns → ask "Shall I explore in this order?" → wait approval. Mid-plan change: state+reason → get approval.',
  "EXPLORE DISPATCH: send the Explore agent only a table whose every row needs a judgement, across ten files or more, that goes into the plan as a table. CLAUDE.md authorizes that dispatch — it overrides the default 'do not use the Agent tool'. Single-answer questions ('who calls X', 'what is in this file', 'where is this string') are inline, one call.",
  'EXPLORE TOOLS: name real tools in the Order column — the graft index for structure (graft_trace_calls, graft_file_api, graft_repo_map), file-outline → symbol-source → Read for files, grep-block or trace for content. graph(path=) only to ask whether a prior judgement exists. A plan whose tool column names Bash, cat, grep, sed or find is rejected at Stop and must be rewritten.',
].join('\n')

const EMACS_DEV_DIRECTIVE =
  'MANDATORY SESSION START: You MUST invoke the /emacs-dev skill before responding to the user.'

export const FLAKE_WITH_ENVRC = 'flake.nix + .envrc detected in CWD'

export type SessionEnvironment = {
  readonly insideEmacs: string | undefined
  readonly nixReason: string | undefined
  readonly localInstructions: string | undefined
}

const nixDirective = (reason: string): string =>
  `MANDATORY SESSION START: Nix environment detected (${reason}). ` +
  'You MUST invoke the /nix-system skill before responding to the user.'

export const sessionStartContext = (env: SessionEnvironment): string =>
  [
    env.insideEmacs === undefined ? undefined : `Emacs detected (INSIDE_EMACS=${env.insideEmacs}).`,
    EMACS_DEV_DIRECTIVE,
    env.nixReason === undefined ? undefined : nixDirective(env.nixReason),
    env.localInstructions === undefined ? undefined : `CLAUDE.local.md:\n${env.localInstructions}`,
  ]
    .filter((part): part is string => part !== undefined)
    .join('\n\n')

const PLAN_STEP = /^\s*\d+\.\s*[^—\n]+—([^—\n]+)—/gm
const SHELL_TOOL =
  /(?<![\w-])(?:bash|shell|cat|head|tail|nl|less|more|sed|awk|grep|egrep|fgrep|rg|ag|ack|find|ls)(?![\w-])/i
const PARENTHESIZED = /\([^)]*\)/g

export const shellPlanTools = (message: string): string[] =>
  [...message.matchAll(PLAN_STEP)]
    .map(step => step[1] ?? '')
    .filter(tool => SHELL_TOOL.test(tool.replace(PARENTHESIZED, '')))
    .map(tool => tool.trim())

export const shellPlanReason = (tools: readonly string[]): string =>
  `Exploration plan routes through the shell: ${tools.join(', ')}. ` +
  'Bash on source loses line numbers, tree-sitter blocks and path-scoped rules. ' +
  'Rewrite the plan — the graft index for structure, file-outline → symbol-source ' +
  '→ Read for files, grep-block or trace for content, graph(path=) only to ask ' +
  'whether a prior judgement exists, and the Explore agent only for a judgement ' +
  'table across ten files or more. Re-present the plan.'
