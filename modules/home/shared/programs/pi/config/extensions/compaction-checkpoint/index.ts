import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerCheckpointConcern } from "../agent-concerns/concerns/checkpoint";

export default function compactionCheckpointExtension(pi: ExtensionAPI): void {
  registerCheckpointConcern(pi);
}
