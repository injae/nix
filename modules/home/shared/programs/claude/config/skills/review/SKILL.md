---
name: review
description: >
  사시코(Sashiko) 스타일 멀티-스테이지 코드 리뷰 스킬.
  아키텍처 → 보안 → 리소스 → 동시성 순으로 서브에이전트가 순차 리뷰하고,
  메인 에이전트가 최종 리포트로 취합한다.
triggers:
  - "리뷰"
  - "코드 리뷰"
  - "PR 리뷰"
  - "리뷰해줘"
  - "review this"
  - "코드 검토"
  - "sashiko review"
  - "review"
  - "diff 리뷰"
  - "패치 리뷰"
version: 1.0.0
---

# Sashiko Review Skill

사시코 방식 4단계 멀티-에이전트 리뷰. 각 단계가 같은 코드를 독립 관점으로 검토하고, 마지막에 통합 보고서로 합친다.

---

## 사용 시점

- 코드 diff / patch 리뷰 요청
- PR 내용 텍스트 리뷰
- 파일/함수 단위 코드 검토
- "버그 없는지", "보안 문제 있는지" 확인 요청

---

## 리뷰 파이프라인

순서 고정. 앞 단계 결과를 다음 단계 입력으로 사용.

```text
입력 → Stage 1(아키텍처) → Stage 2(보안) → Stage 3(리소스) → Stage 4(동시성) → 최종 리포트
```

---

## 실행 절차

1. **입력 파악**
   - 코드/diff/파일 경로 확인.
   - 가능하면 파일 전체 읽기보다 tree-sitter, LSP/MCP 도구 우선.
   - Emacs 환경이면 `emacs-dev`의 File analysis 흐름 따름.

2. **언어 감지**
   - 우선 확장자 기준: `.go` / `.py` / `.ts` `.tsx` `.js` `.jsx` / `.rs`.
   - 확장자 불명확 시 구문(import, 키워드, 타입 선언)으로 판별.

3. **언어 레퍼런스 로드**
   - 해당 파일 있으면 Read로 로드.
   - ${Lang} -> `references/lang/${lang}.md` (예: `references/lang/go.md`)
   - Go → `references/lang/go.md`
   - Python → `references/lang/python.md`
   - TypeScript / JavaScript → `references/lang/typescript.md`
   - Rust → `references/lang/rust.md`

4. **Stage 순차 실행**
   - 각 Stage 실행 시 공통 프롬프트 + 언어 파일의 해당 Stage 섹션을 함께 적용.

5. **결과 취합**
   - 메인 리뷰어가 `references/final-report.md` 형식으로 최종 리포트 출력.

Stage 프롬프트 경로:
- Stage 1: `references/01-architecture.md`
- Stage 2: `references/02-security.md`
- Stage 3: `references/03-resource.md`
- Stage 4: `references/04-concurrency.md`
- 최종 취합: `references/final-report.md`

---

## Severity 기준

| Level    | 의미                          | 처리 방침             |
|----------|-------------------------------|-----------------------|
| CRITICAL | 즉시 수정 필요, 병합 블로커   | 무조건 수정 후 재검토 |
| HIGH     | 심각 버그/취약점, 병합 전 수정 권장 | 병합 전 수정      |
| MEDIUM   | 개선 권장, 기술부채 누적 위험 | 이슈 트래킹           |
| LOW      | 스타일/마이너 제안            | 선택 반영             |
| INFO     | 참고/긍정 관찰                | 참고                  |

---

## 핵심 원칙

- **증거 기반**: 모든 지적에 코드 라인 + 근거 포함.
- **언어 불가지론**: Go/Python/TS/Rust 관용 패턴 반영.
- **위양성 허용**: 놓친 버그가 더 위험. 의심되면 언급.
- **YAGNI**: 없는 기능 제안 금지. 현재 코드 문제만 리뷰.
- **수정안 포함**: CRITICAL/HIGH는 가능한 수정 스니펫 제공.
