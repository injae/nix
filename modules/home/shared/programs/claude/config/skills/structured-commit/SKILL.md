---
name: structured-commit
description: "Analyze current changes, divide into logical commit units, and commit each unit with a conventional commit message. Use when the user wants to split changes into multiple organized commits, or asks for 'structured commit', 'multi-commit', or 'commit by unit'."
user-invocable: true
allowed-tools:
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(git status*)
  - Bash(git add*)
  - Bash(git restore --staged*)
  - mcp__emacs-tools__call-fn
  - mcp__emacs-tools__git-commit
---

# Structured Commit

현재 변경사항을 논리적 커밋 단위로 분류하고 각 단위를 순차적으로 커밋한다.

---

## Step 1 — 변경사항 수집

Run in parallel:
- `git status --short` — staged/unstaged 파일 목록
- `git diff HEAD` — 전체 diff 내용
- `git log --oneline -5` — 최근 커밋 스타일 참고

---

## Step 2 — 변경사항 있는지 확인

Answer YES or NO:
- **YES** if `git status --short` returned file changes
- **NO** if the output is empty

If NO → 변경사항이 없다고 알리고 종료.

---

## Step 3 — 커밋 단위 제안

diff를 분석해 논리적으로 묶을 수 있는 커밋 단위를 나눈다.

**그룹 기준:**
- 같은 기능/버그/모듈에 속하는 파일끼리 묶기
- 독립적으로 리뷰/롤백 가능한 단위로 분리
- 하나의 변경이 여러 파일에 걸쳐 있으면 같은 그룹

**출력 형식:**
```
Group 1: feat(claude): add structured-commit skill
  - modules/home/shared/programs/claude/config/skills/structured-commit/SKILL.md

Group 2: fix(emacs): update navigation tool fallbacks
  - modules/home/shared/programs/emacs/config/module/+nav.el
  - modules/home/shared/programs/emacs/config/module/+lsp.el
```

각 그룹에 Conventional Commit 메시지 포함:
- Format: `type(scope): message`
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`
- 한 줄, 영어, 소문자, 마침표 없음

사용자에게 그룹 확인 요청: "이 순서로 커밋할까요? 수정이 필요하면 알려주세요."

---

## Step 4 — 사용자 확인 대기

Answer YES or NO:
- **YES** if 사용자가 승인하거나 별도 수정 없이 진행 의사 표시
- **NO** if 사용자가 그룹 수정을 요청

If NO → 피드백 반영해 그룹 재구성 후 Step 3으로 돌아가 재확인.

---

## Step 5 — 그룹별 순차 커밋

각 그룹을 순서대로 처리한다. 그룹 간 순서는 중요하므로 병렬 실행하지 않는다.

**그룹마다:**

1. 해당 그룹 파일만 스테이징 (모든 파일을 하나의 `git add` 명령으로):
   ```
   git add <file1> <file2> ...
   ```

2. `git-commit` MCP 툴로 즉시 커밋:
   - `message`: 해당 그룹의 커밋 메시지

3. 커밋 성공 시 진행 상황 출력:
   ```
   ✓ Group 1/3: feat(claude): add structured-commit skill
   ```

**Gate check — 다음 그룹으로 넘어가기 전 확인:**
- `git-commit` 가 에러 없이 완료됐는가?
- NO → 에러 내용 보고 후 중단, 사용자에게 상황 알림

---

## Step 6 — 완료

모든 그룹 커밋 완료 후:
- 완료된 커밋 목록 요약 출력
- `call-fn` 으로 Magit status 열기: `name`: `magit-status`, `args`: `[]`