#!/usr/bin/env bash
# SessionStart hook: inject mandatory skill evaluation instructions once at session start.

cat <<'EOF'
INSTRUCTION: MANDATORY SKILL ACTIVATION SEQUENCE

Step 1 - EVALUATE (must appear in your next response):
For each relevant skill in <available_skills>, state: [skill-name] - YES/NO - [reason]

Step 2 - ACTIVATE (immediately after Step 1):
IF any skills are YES and not yet loaded in this session -> load each relevant SKILL.md via read or /skill:name now
IF any YES skill is already loaded and unchanged -> do NOT reload; state "already loaded" and proceed
IF no skills are YES -> state "No skills needed" and proceed

Step 3 - IMPLEMENT:
Only after Step 2 is complete, proceed with implementation.

CRITICAL: Do not skip activation. Evaluation without activation is invalid.
EOF
