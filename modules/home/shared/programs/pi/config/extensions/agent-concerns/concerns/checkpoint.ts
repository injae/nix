import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { buildCompactionSummary, saveCompactionCheckpoint } from "../checkpoint";

export function registerCheckpointConcern(pi: ExtensionAPI): void {
  pi.on("session_before_compact", async (event, ctx) => {
    const checkpoint = saveCompactionCheckpoint(ctx.cwd, "compact");

    return {
      compaction: {
        summary: buildCompactionSummary(checkpoint),
        firstKeptEntryId: event.preparation.firstKeptEntryId,
        tokensBefore: event.preparation.tokensBefore,
      },
    };
  });
}
