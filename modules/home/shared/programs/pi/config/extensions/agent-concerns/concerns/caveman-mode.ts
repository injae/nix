import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { INDEPENDENT_CAVEMAN_MODES, VALID_CAVEMAN_MODES } from "../constants";
import {
  cavemanPrompt,
  disableCaveman,
  getDefaultCavemanMode,
  readCavemanMode,
  writeCavemanMode,
} from "../caveman";

export function registerCavemanModeConcern(pi: ExtensionAPI): void {
  pi.on("session_start", async (_event, ctx) => {
    const defaultMode = getDefaultCavemanMode();
    if (defaultMode !== "off" && !readCavemanMode()) {
      writeCavemanMode(defaultMode);
    }

    if (ctx.hasUI) {
      ctx.ui.notify("Agent concerns extension loaded", "info");
    }
  });

  pi.on("input", async (event) => {
    if (event.source === "extension") return { action: "continue" as const };

    const prompt = event.text.trim().toLowerCase();
    const activate = /(activate|enable|turn on|start|talk like).*caveman|caveman.*(mode|activate|enable|turn on|start)/i;
    const deactivate = /(stop|disable|deactivate|turn off).*caveman|caveman.*(stop|disable|deactivate|turn off)|normal mode/i;

    if (activate.test(prompt) && !deactivate.test(prompt)) {
      const defaultMode = getDefaultCavemanMode();
      if (defaultMode !== "off") writeCavemanMode(defaultMode);
    }

    if (deactivate.test(prompt)) {
      disableCaveman();
    }

    return { action: "continue" as const };
  });

  pi.registerCommand("caveman", {
    description:
      "Toggle caveman response mode. Usage: /caveman [lite|full|ultra|wenyan-lite|wenyan|wenyan-full|wenyan-ultra|commit|review|compress|off]",
    handler: async (args, ctx) => {
      const requested = (args || "").trim().toLowerCase();
      const normalized = requested === "wenyan-full" ? "wenyan" : requested;
      const mode = normalized === "" ? getDefaultCavemanMode() : normalized === "stop" ? "off" : normalized;

      if (mode === "off" || mode === "disable") {
        disableCaveman();
        ctx.ui.notify("Caveman mode disabled", "info");
        return;
      }

      if (!VALID_CAVEMAN_MODES.has(mode) || mode === "off") {
        ctx.ui.notify(`Unknown caveman mode: ${requested || "(empty)"}`, "warning");
        return;
      }

      writeCavemanMode(mode);
      if (INDEPENDENT_CAVEMAN_MODES.has(mode)) {
        ctx.ui.notify(`Caveman mode enabled: ${mode} (skill-driven mode)`, "info");
        return;
      }

      ctx.ui.notify(`Caveman mode enabled: ${mode}`, "info");
    },
  });

  pi.on("before_agent_start", async (event) => {
    const cavemanMode = readCavemanMode();
    if (!cavemanMode || cavemanMode === "off") {
      return undefined;
    }

    return {
      systemPrompt: `${event.systemPrompt}\n\n${cavemanPrompt(cavemanMode)}`,
    };
  });
}
