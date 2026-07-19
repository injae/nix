import * as path from "node:path";
import { HOME } from "./constants";
import { resolveToolPath } from "./path-utils";

export function isSecretLikePath(targetPath: string): boolean {
  const normalized = path.normalize(targetPath);
  const lower = normalized.toLowerCase();
  const base = path.basename(lower);

  if (/^\.env(\..+)?$/.test(base)) return true;
  if (/\.(key|pem|p12|p8|pfx)$/.test(base)) return true;
  if (lower.includes(`${path.sep}.gcp${path.sep}`)) return true;
  if (lower.includes(`${path.sep}.azure${path.sep}`)) return true;
  if (lower.includes(`${path.sep}.ssh${path.sep}`)) return true;
  if (lower.includes(`${path.sep}secrets${path.sep}`)) return true;
  if (lower === path.join(HOME, ".aws", "credentials").toLowerCase()) return true;
  if (lower.startsWith(path.join(HOME, ".config", "sops").toLowerCase() + path.sep)) return true;
  if (lower.startsWith(path.join(HOME, ".config", "sops-nix").toLowerCase() + path.sep)) return true;

  return false;
}

export function isDangerousBash(command: string): boolean {
  return /\brm\s+-rf\s+\/(?:\s|$|['"`])/.test(command) || /\brm\s+-r\s+\/(?:\s|$|['"`])/.test(command);
}

export async function confirmFileMutation(
  toolName: string,
  input: Record<string, unknown>,
  cwd: string,
  hasUI: boolean,
  confirm: (message: string, title?: string) => Promise<boolean>,
): Promise<{ block: true; reason: string } | undefined> {
  if (toolName !== "edit" && toolName !== "write") {
    return undefined;
  }

  const inputPath = typeof input.path === "string" ? input.path : null;
  const resolvedPath = inputPath ? resolveToolPath(inputPath, cwd) : "(unknown path)";

  if (!hasUI) {
    return { block: true, reason: `${toolName} blocked: explicit approval required for file modifications` };
  }

  const detailLines = [`Tool: ${toolName}`, `Path: ${resolvedPath}`];

  if (toolName === "edit") {
    const edits = Array.isArray(input.edits) ? input.edits.length : 0;
    detailLines.push(`Edit blocks: ${edits}`);
  }

  if (toolName === "write") {
    const content = typeof input.content === "string" ? input.content : "";
    detailLines.push(`Content bytes: ${Buffer.byteLength(content, "utf8")}`);
  }

  const approved = await confirm(detailLines.join("\n"), "Allow file modification?");
  if (approved) {
    return undefined;
  }

  return { block: true, reason: `${toolName} cancelled by user` };
}
