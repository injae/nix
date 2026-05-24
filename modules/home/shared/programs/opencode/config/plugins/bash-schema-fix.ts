import type { Plugin } from "@opencode-ai/plugin"

export const BashSchemaFix: Plugin = async () => {
  return {
    "chat.params": async (_input, output) => {
      const injection = `
## Bash tool usage (MANDATORY)

When calling the bash tool, you MUST always include BOTH required fields:
- \`command\`: the shell command to run
- \`description\`: a short description of what the command does (required, cannot be omitted)

CORRECT:
  bash({ command: "pwd && ls -la", description: "Show current directory and list files" })

WRONG (will cause schema error):
  bash({ command: "pwd && ls -la" })

Never omit \`description\` — it is required by the tool schema.`

      if (!output.system) {
        output.system = injection
      } else {
        output.system = output.system + "\n\n" + injection
      }
    },
  }
}

export default BashSchemaFix
