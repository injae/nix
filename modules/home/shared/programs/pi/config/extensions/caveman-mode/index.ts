import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerCavemanModeConcern } from "../agent-concerns/concerns/caveman-mode";

export default function cavemanModeExtension(pi: ExtensionAPI): void {
  registerCavemanModeConcern(pi);
}
