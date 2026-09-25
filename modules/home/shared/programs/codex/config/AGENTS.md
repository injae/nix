# 전역 Codex 지시

## Nix 관리 설정

`~/.codex/AGENTS.md`를 수정할 때는 `$NIX_CONFIG_DIR/modules/home/shared/programs/codex/config/AGENTS.md`를 수정한다.
`~/.codex/config.toml`의 모델·샌드박스와 `emacs-tools`, `graft` MCP 설정은 `$NIX_CONFIG_DIR/modules/home/shared/programs/codex/config.nix`에서 관리한다.

## 언어

**모든 출력을 한글로 작성한다.** 코드 리뷰 결과, 진단, 요약, 설명 전부 해당.

다음은 원문 그대로 둔다:

- 파일 경로, 심볼명(함수·타입·변수), 코드 블록
- 컴파일러/테스트 출력, 에러 메시지 인용
- 심각도 태그(`[P1]`, `[P2]` 등)와 구조화 필드 키
