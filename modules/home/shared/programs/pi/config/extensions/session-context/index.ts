import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerSessionContextConcern } from "../agent-concerns/concerns/session-context";

export default function sessionContextExtension(pi: ExtensionAPI): void {
  registerSessionContextConcern(pi);
}
