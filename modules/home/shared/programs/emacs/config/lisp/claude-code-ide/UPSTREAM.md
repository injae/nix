# Upstream Sync Record

Upstream: https://github.com/manzaltu/claude-code-ide.el

## Last-synced base

- Commit: `a9485f7` ("Add ghostel backend support")
- Date: 2026-06-01 (= 조회 시점 upstream HEAD)
- 근거: 사용자 회상 — HEAD에서 싱크했고 **ghostel backend는 로컬에서 의도적으로 제거**함 (vterm 한글 커스텀과 양립 어려움). 즉 ghostel 부재 = predates 아니라 local 삭제.

로컬은 git 추적 clone이 아닌 nix repo에 vendored됨 → 정확한 base 미기록. base는 사용자 회상 기반.

## Divergence (2026-07-01 측정, vs a9485f7)

- `claude-code-ide.el`: ~656줄 로컬 수정 (ghostel 제거 포함)
- 기타 core: transient 113, tests 261, emacs-tools 40, mcp-server 12, mcp-http-server 34, mcp-handlers 14
- 로컬 전용: `claude-code-ide-emacs-tools-extra.el`, `extras/*` (8 파일)

## 동기화 시 주의

- fast-forward 불가 → **3-way merge**. base=a9485f7, theirs=upstream HEAD(신규), ours=로컬.
- 반드시 보존: `extras/`, `claude-code-ide-emacs-tools-extra.el`, 로컬 core 수정.
- **ghostel backend 재도입 금지** — vterm 한글 커스텀과 충돌해 의도적으로 제거함. upstream이 ghostel 확장하면 merge 시 제외.
- 다음 싱크 후 이 파일의 base commit/날짜/divergence 갱신할 것.
