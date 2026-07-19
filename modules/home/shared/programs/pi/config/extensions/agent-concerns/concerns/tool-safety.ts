import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { resolveToolPath } from "../path-utils";
import { confirmFileMutation, isDangerousBash, isSecretLikePath } from "../safety";

export function registerToolSafetyConcern(pi: ExtensionAPI): void {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "read" || event.toolName === "ctx_execute_file" || event.toolName === "ctx_index") {
      const inputPath = typeof event.input.path === "string" ? event.input.path : null;
      if (inputPath) {
        const resolved = resolveToolPath(inputPath, ctx.cwd);
        if (isSecretLikePath(resolved)) {
          return { block: true, reason: `Blocked access to sensitive path: ${inputPath}` };
        }
      }
    }

    const mutationDecision = await confirmFileMutation(
      event.toolName,
      event.input as Record<string, unknown>,
      ctx.cwd,
      ctx.hasUI,
      async (message, title) => ctx.ui.confirm(message, title),
    );
    if (mutationDecision) {
      return mutationDecision;
    }

    if (event.toolName === "bash") {
      const command = typeof event.input.command === "string" ? event.input.command : "";
      if (isDangerousBash(command)) {
        return { block: true, reason: "Blocked dangerous bash command" };
      }
    }

    return undefined;
  });
}
