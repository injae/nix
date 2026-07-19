import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { LOCAL_CLAUDE_PATH } from "../constants";
import { readTextIfExists, detectNix, inEmacs } from "../environment";
import { getActiveEmacsBuffer } from "../emacs";

const SKILL_EVAL_INPUT_PREFIX = [
  "INSTRUCTION: MANDATORY SKILL ACTIVATION SEQUENCE",
  "",
  "Step 1 - EVALUATE (must appear in your next response):",
  "For each relevant skill in <available_skills>, state: [skill-name] - YES/NO - [reason]",
  "",
  "Step 2 - ACTIVATE (immediately after Step 1):",
  "IF any skills are YES and not yet loaded in this session -> load each relevant SKILL.md via read or /skill:name now",
  "IF any YES skill is already loaded and unchanged -> do NOT reload; state \"already loaded\" and proceed",
  "IF no skills are YES -> state \"No skills needed\" and proceed",
  "",
  "Step 3 - IMPLEMENT:",
  "Only after Step 2 is complete, proceed with implementation.",
  "",
  "CRITICAL: Do not skip activation. Evaluation without activation is invalid.",
].join("\n");

let skillEvalInjectedOnce = false;

export function registerSessionContextConcern(pi: ExtensionAPI): void {
  pi.on("input", async (event) => {
    if (event.source === "extension") return { action: "continue" as const };
    if (skillEvalInjectedOnce) return { action: "continue" as const };

    skillEvalInjectedOnce = true;
    return {
      action: "transform" as const,
      text: `${SKILL_EVAL_INPUT_PREFIX}\n\n[USER REQUEST]\n${event.text}`,
      images: event.images,
    };
  });

  pi.on("before_agent_start", async (event, ctx) => {
    const sections: string[] = [];

    if (inEmacs()) {
      sections.push([
        "## Emacs session detected",
        "Before responding, load and follow the emacs-dev skill.",
      ].join("\n"));
    }

    const nixReason = detectNix(ctx.cwd);
    if (nixReason) {
      sections.push([
        "## Nix environment detected",
        `${nixReason}`,
        "Before responding, load and follow the nix-system skill.",
      ].join("\n"));
    }

    const localClaude = readTextIfExists(LOCAL_CLAUDE_PATH);
    if (localClaude) {
      sections.push(`## ~/.claude/CLAUDE.local.md\n${localClaude}`);
    }

    const activeBuffer = getActiveEmacsBuffer();
    if (activeBuffer) {
      const lines = ["## Active Emacs buffer", `Buffer: ${activeBuffer.name}`];
      if (activeBuffer.filePath) lines.push(`File: ${activeBuffer.filePath}`);
      sections.push(lines.join("\n"));
    }

    sections.push([
      "## Skill evaluation discipline (strict)",
      "You MUST execute this order on every implementation task:",
      "1) Evaluate relevant skills explicitly (YES/NO + reason).",
      "2) Activate every YES skill once per session.",
      "   - If not loaded yet: load SKILL.md via read or /skill:name.",
      "   - If already loaded and unchanged: do not reload; explicitly state reuse.",
      "3) Implement only after step 2 completes.",
      "If none apply, explicitly state: No skills needed.",
    ].join("\n"));

    if (sections.length === 0) return undefined;

    return {
      systemPrompt: `${event.systemPrompt}\n\n${sections.join("\n\n")}`,
    };
  });
}
