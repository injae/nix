import type { Plugin } from "@opencode-ai/plugin"

export const ForcedEval: Plugin = async () => {
  return {
    "chat.params": async (_input, output) => {
      const injection = `
## Per-response skill evaluation (MANDATORY)

On EVERY user message, BEFORE doing anything else:

1. Scan <available_skills> — evaluate each against the current task
2. State for each skill: [name] - YES/NO - [reason]
3. If any match → use Skill() tool to load them NOW
4. If none → confirm "No skills needed" and proceed
5. Only THEN start implementation

CRITICAL: The skill-eval tool is visible. Do not skip this step.

## Tool-use rule (MANDATORY)

When making ANY code or file change:
- ALWAYS use tools (read → edit/write) to apply the change directly
- NEVER just describe the change in text and stop
- If you described a change in text, you have NOT finished — call the tool next`

      if (!output.system) {
        output.system = injection
      } else {
        output.system = injection + "\n\n" + output.system
      }
    },
  }
}

export default ForcedEval
