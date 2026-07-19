import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerToolSafetyConcern } from "../agent-concerns/concerns/tool-safety";

export default function toolSafetyExtension(pi: ExtensionAPI): void {
  registerToolSafetyConcern(pi);
}
