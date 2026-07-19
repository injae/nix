import * as fs from "node:fs";
import * as path from "node:path";
import { PI_CHECKPOINT_DIR } from "./constants";

type Checkpoint = {
  timestamp: string;
  trigger: string;
  cwd: string;
  todos?: unknown;
};

const MANDATORY_SKILL_ACTIVATION_SEQUENCE = [
  "INSTRUCTION: MANDATORY SKILL ACTIVATION SEQUENCE",
  "",
  "Step 1 - EVALUATE (must appear in your next response):",
  "For each relevant skill in <available_skills>, state: [skill-name] - YES/NO - [reason]",
  "",
  "Step 2 - ACTIVATE (immediately after Step 1):",
  "IF any skills are YES and not yet loaded in this session -> load each relevant SKILL.md via read or /skill:name now",
  "IF any YES skill is already loaded and unchanged -> do NOT reload; state \"already loaded\" and proceed",
  "IF no skills are YES -> state \"No skills needed\" and proceed",
  "",
  "Step 3 - IMPLEMENT:",
  "Only after Step 2 is complete, proceed with implementation.",
  "",
  "CRITICAL: Do not skip activation. Evaluation without activation is invalid.",
].join("\n");

function loadTodos(cwd: string): unknown {
  const todosPath = path.join(cwd, ".claude", "todos.json");
  if (!fs.existsSync(todosPath)) return undefined;

  try {
    return JSON.parse(fs.readFileSync(todosPath, "utf8"));
  } catch {
    return undefined;
  }
}

function getPendingTodos(todos: unknown): unknown[] {
  if (!Array.isArray(todos)) return [];
  return todos.filter((todo) => typeof todo === "object" && todo !== null && (todo as { status?: unknown }).status !== "completed");
}

export function saveCompactionCheckpoint(cwd: string, trigger = "compact"): Checkpoint {
  const timestamp = new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d+Z$/, "Z");
  fs.mkdirSync(PI_CHECKPOINT_DIR, { recursive: true });

  const todos = loadTodos(cwd);
  const checkpoint: Checkpoint = { timestamp, trigger, cwd, todos };

  const checkpointPath = path.join(PI_CHECKPOINT_DIR, `checkpoint-${timestamp}.json`);
  fs.writeFileSync(checkpointPath, `${JSON.stringify(checkpoint, null, 2)}\n`);

  const checkpoints = fs
    .readdirSync(PI_CHECKPOINT_DIR)
    .filter((name) => /^checkpoint-.*\.json$/.test(name))
    .sort();

  for (const oldName of checkpoints.slice(0, Math.max(0, checkpoints.length - 5))) {
    try {
      fs.unlinkSync(path.join(PI_CHECKPOINT_DIR, oldName));
    } catch {
      // ignore
    }
  }

  return checkpoint;
}

export function buildCompactionSummary(checkpoint: Checkpoint): string {
  const parts = [`Compacted from ${checkpoint.cwd} at ${checkpoint.timestamp}.`];
  const pending = getPendingTodos(checkpoint.todos);

  if (pending.length > 0) {
    parts.push(`Pending tasks: ${JSON.stringify(pending)}`);
  }

  parts.push(
    "CRITICAL COMPACTION RULE: Preserve the following directive verbatim in compacted session state. " +
      "Do not remove, summarize, or weaken it.\n\n" +
      MANDATORY_SKILL_ACTIVATION_SEQUENCE,
  );

  return parts.join("\n\n");
}
