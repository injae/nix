# Pi Config

Nix-managed Pi configuration. Source of truth for the files we sync into `~/.pi/agent/`.

## Files

- `AGENTS.md` — global Pi instructions
- `settings.json` — global Pi settings
- `extensions/session-context/` — before_agent_start 컨텍스트 주입
- `extensions/caveman-mode/` — caveman 모드 토글/프롬프트 주입
- `extensions/tool-safety/` — tool_call 보안 가드
- `extensions/compaction-checkpoint/` — compaction 시 체크포인트 저장
- `extensions/agent-concerns/` — 위 확장들이 공유하는 내부 모듈 (자동 로드 엔트리 없음)

## Claude → Pi mapping

- `CLAUDE.md` language/work-style rules → `AGENTS.md`
- `~/.claude/skills` discovery → `settings.json` `skills`
- `SessionStart` hook → `session_start` + `before_agent_start`
- `UserPromptSubmit` hook → `input` + `before_agent_start`
- `PreCompact` hook → `session_before_compact`
- Claude permission deny rules → `tool_call` blocking
- Caveman activation/tracking → `/caveman` command + per-turn prompt injection

## Notes

Pi does not expose a direct cancellable equivalent of Claude's `Stop` hook, so the old stop-time context guard is not ported 1:1.
