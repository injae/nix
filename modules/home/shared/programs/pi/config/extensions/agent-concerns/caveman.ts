import * as fs from "node:fs";
import * as path from "node:path";
import { CAVEMAN_FLAG_PATH, HOME, INDEPENDENT_CAVEMAN_MODES, VALID_CAVEMAN_MODES } from "./constants";

function getCavemanConfigPath(): string {
  if (process.env.XDG_CONFIG_HOME) {
    return path.join(process.env.XDG_CONFIG_HOME, "caveman", "config.json");
  }

  return path.join(HOME, ".config", "caveman", "config.json");
}

export function getDefaultCavemanMode(): string {
  const envMode = process.env.CAVEMAN_DEFAULT_MODE?.toLowerCase();
  if (envMode && VALID_CAVEMAN_MODES.has(envMode)) {
    return envMode;
  }

  try {
    const raw = fs.readFileSync(getCavemanConfigPath(), "utf8");
    const parsed = JSON.parse(raw) as { defaultMode?: string };
    const configured = parsed.defaultMode?.toLowerCase();
    if (configured && VALID_CAVEMAN_MODES.has(configured)) {
      return configured;
    }
  } catch {
    // ignore
  }

  return "full";
}

export function readCavemanMode(): string | null {
  try {
    const stat = fs.lstatSync(CAVEMAN_FLAG_PATH);
    if (!stat.isFile() || stat.isSymbolicLink() || stat.size > 64) return null;

    const raw = fs.readFileSync(CAVEMAN_FLAG_PATH, "utf8").trim().toLowerCase();
    return VALID_CAVEMAN_MODES.has(raw) ? raw : null;
  } catch {
    return null;
  }
}

export function writeCavemanMode(mode: string): void {
  fs.mkdirSync(path.dirname(CAVEMAN_FLAG_PATH), { recursive: true });
  fs.writeFileSync(CAVEMAN_FLAG_PATH, `${mode}\n`, { mode: 0o600 });
}

export function disableCaveman(): void {
  try {
    fs.unlinkSync(CAVEMAN_FLAG_PATH);
  } catch {
    // ignore
  }
}

export function cavemanPrompt(mode: string): string {
  const label = mode === "wenyan" ? "wenyan-full" : mode;

  if (INDEPENDENT_CAVEMAN_MODES.has(mode)) {
    return [
      `## Caveman mode (${label})`,
      `Behavior delegated to /caveman-${mode} skill.`,
    ].join("\n");
  }

  return [
    `## Caveman mode (${label})`,
    "Use terse, high-density prose. Keep technical substance, lose filler.",
    "Drop articles, pleasantries, hedging, and repetition.",
    "Fragments are allowed when clarity is preserved.",
    "Keep code, exact error text, and security warnings fully normal and precise.",
    "If brevity risks confusion for dangerous or irreversible actions, switch to clear normal prose for that part.",
  ].join("\n");
}
