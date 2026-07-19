import { execFileSync } from "node:child_process";
import { inEmacs } from "./environment";

export type EmacsBuffer = { name: string; filePath?: string };

export function getActiveEmacsBuffer(): EmacsBuffer | null {
  if (!inEmacs()) return null;

  const expr = [
    "(let* ((buf (seq-find",
    '  (lambda (b)',
    '    (let ((n (buffer-name b)))',
    '      (and (buffer-file-name b)',
    '           (not (string-prefix-p \" \" n))',
    '           (not (string-match-p \"\\\\*claude-code\" n)))))',
    '  (buffer-list))))',
    ' (when buf',
    '   (format \"%s\\t%s\" (buffer-name buf) (buffer-file-name buf))))',
  ].join(" ");

  try {
    const raw = execFileSync("emacsclient", ["--eval", expr], {
      encoding: "utf8",
      timeout: 2000,
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();

    const match = raw.match(/^"([\s\S]*)"$/);
    if (!match) return null;

    const decoded = match[1].replace(/\\t/g, "\t").replace(/\\n/g, "\n");
    const [name, filePath] = decoded.split("\t", 2);
    if (!name) return null;

    return filePath ? { name, filePath } : { name };
  } catch {
    return null;
  }
}
