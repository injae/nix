import * as fs from "node:fs";
import * as path from "node:path";

export function readTextIfExists(filePath: string): string | null {
  try {
    if (!fs.existsSync(filePath)) return null;
    const content = fs.readFileSync(filePath, "utf8").trim();
    return content || null;
  } catch {
    return null;
  }
}

export function inEmacs(): boolean {
  return Boolean(process.env.INSIDE_EMACS) || process.env.TERM_PROGRAM === "emacs";
}

export function detectNix(cwd: string): string | null {
  if (process.env.NIX_CONFIG_DIR) {
    return `NIX_CONFIG_DIR=${process.env.NIX_CONFIG_DIR}`;
  }

  const hasFlake = fs.existsSync(path.join(cwd, "flake.nix"));
  const hasEnvrc = fs.existsSync(path.join(cwd, ".envrc"));
  if (hasFlake && hasEnvrc) {
    return "flake.nix + .envrc detected in cwd";
  }

  return null;
}
