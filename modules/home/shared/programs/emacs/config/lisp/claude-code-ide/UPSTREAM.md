# Upstream Sync Record

Upstream: https://github.com/manzaltu/claude-code-ide.el

## Last-synced base

- Commit: `1de17bb` ("Recommend ghostel backend in README")
- Date: 2026-07-31 (= 싱크 시점 upstream HEAD)
- 방식: 3-way merge. base=`56db02e`, theirs=`1de17bb`, ours=로컬.
  이전 base 기록은 `a9485f7`였으나 ghostel backend를 로컬에서 통째로 제거했었기 때문에
  실질 base는 그 부모 `56db02e`.

로컬은 git 추적 clone이 아닌 nix repo에 vendored됨.

## 이번 싱크에서 가져온 것 (2026-07-31)

- `a9485f7` ghostel backend support — **재도입**. 과거 vterm 한글 입력 문제로 제거했으나
  `ghostel-ime`로 해결되어 복원함.
- `cc50839` ghostel ESC → evil 라우팅 (`claude-code-ide-ghostel-evil-escape`)
- `e342254` 세션 시작 중 CLI 종료 시 오류 메시지 개선
- `1de17bb` README만 변경 — vendor 대상 아님

수동 해결한 충돌 3곳 (`claude-code-ide.el`):

1. 세션 시작 시 reflow advice 등록 — 로컬 opencode `window-size-change-functions` 훅 유지 +
   upstream의 resize-handler nil 가드(`when-let`) 채택. ghostel은 resize handler가 없어 nil 반환.
2. 세션 종료 시 동일 지점 — 위와 같은 방식.
3. process sentinel — upstream의 ghostel 네이티브 sentinel 체이닝
   (`claude-code-ide--ghostel-sentinel`) + 로컬의 `--backend-name` 기반 메시지 병합.

추가 수정: upstream ghostel 분기가 참조하는 `claude-cmd` → 로컬 변수명 `ai-cmd`로 정정
(`claude-code-ide--create-terminal-session`). 로컬은 claude/opencode/pi 백엔드를 지원하므로
명령 변수가 `ai-cmd`로 개명되어 있음.

## Divergence (2026-07-31 측정, vs 1de17bb)

- `claude-code-ide.el`: 588 diff 라인
- `claude-code-ide-tests.el`: 148, `-transient.el`: 113, `-mcp-handlers.el`: 203,
  `-emacs-tools.el`: 40, `-mcp-http-server.el`: 34, `-mcp-server.el`: 12
- upstream과 동일: `-mcp.el`, `-debug.el`, `-diagnostics.el`
- 로컬 전용: `claude-code-ide-emacs-tools-extra.el`, `extras/*`

## 동기화 시 주의

- fast-forward 불가 → **3-way merge**. base=`1de17bb`, theirs=upstream HEAD(신규), ours=로컬.
- 반드시 보존: `extras/`, `claude-code-ide-emacs-tools-extra.el`, 로컬 core 수정
  (opencode/pi 백엔드, MCP 확장, reflow/redraw 처리).
- upstream 코드가 `claude-cmd`를 쓰면 로컬 `ai-cmd`로 바꿔야 함.
- 병합 후 `emacs -Q --batch -f batch-byte-compile`로 검증. 기존 경고는
  `vterm-copy-mode` / `vterm--term` free variable 2건뿐 — 그 외 경고가 생기면 병합 오류.
- 다음 싱크 후 이 파일의 base commit/날짜/divergence 갱신할 것.
