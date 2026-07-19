import * as path from "node:path";
import { HOME } from "./constants";

export function expandHome(inputPath: string): string {
  if (inputPath === "~") return HOME;
  if (inputPath.startsWith("~/")) return path.join(HOME, inputPath.slice(2));
  return inputPath;
}

export function resolveToolPath(inputPath: string, cwd: string): string {
  const expanded = expandHome(inputPath);
  return path.isAbsolute(expanded)
    ? path.normalize(expanded)
    : path.normalize(path.resolve(cwd, expanded));
}
