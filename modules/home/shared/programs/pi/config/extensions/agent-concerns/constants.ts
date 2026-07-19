import * as os from "node:os";
import * as path from "node:path";

export const HOME = os.homedir();
export const CLAUDE_DIR = path.join(HOME, ".claude");
export const PI_AGENT_DIR = path.join(HOME, ".pi", "agent");
export const LOCAL_CLAUDE_PATH = path.join(CLAUDE_DIR, "CLAUDE.local.md");
export const PI_CHECKPOINT_DIR = path.join(PI_AGENT_DIR, "checkpoints");
export const CAVEMAN_FLAG_PATH = path.join(CLAUDE_DIR, ".caveman-active");

export const INDEPENDENT_CAVEMAN_MODES = new Set(["commit", "review", "compress"]);

export const VALID_CAVEMAN_MODES = new Set([
  "off",
  "lite",
  "full",
  "ultra",
  "wenyan-lite",
  "wenyan",
  "wenyan-full",
  "wenyan-ultra",
  ...INDEPENDENT_CAVEMAN_MODES,
]);
