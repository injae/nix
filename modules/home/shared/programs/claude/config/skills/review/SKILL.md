---
name: review
description: >
  사시코(Sashiko) 스타일의 멀티-스테이지 코드 리뷰 에이전트.
  아키텍처 → 보안 → 리소스 관리 → 동시성 순으로 전문 서브에이전트가
  순차 리뷰한 뒤, 메인 에이전트가 최종 리포트로 취합한다.
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

사시코(刺し子) 방식의 **4단계 멀티-에이전트 코드 리뷰** 스킬이다.
리눅스 커널 리뷰 시스템 Sashiko의 파이프라인을 Claude Code 환경으로 포팅한 것으로,
사람 리뷰어 팀이 각자 전문 영역을 맡아 같은 코드를 독립적으로 검토하는 구조를 에이전트로 구현한다.

---

## 언제 이 스킬을 사용하는가

- 코드 diff / git patch를 리뷰 요청할 때
- PR 내용을 텍스트로 붙여넣을 때
- 파일이나 함수 단위 코드 리뷰를 요청할 때
- "버그 없는지 봐줘", "보안 문제 있어?" 같은 요청

---

## 리뷰 파이프라인 (4단계)

단계는 반드시 **순서대로** 실행한다. 앞 단계 결과를 다음 단계의 입력으로 활용한다.

```
[입력: 코드/diff/PR]
         │
         ▼
  ┌─────────────────┐
  │ Stage 1         │  아키텍처 & 설계 검증
  │ Architect Agent │  설계 의도, 패턴, 인터페이스 적합성
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Stage 2         │  보안 감사
  │ Security Agent  │  인젝션, 권한, 입력검증, 시크릿 노출
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Stage 3         │  리소스 관리 분석
  │ Resource Agent  │  메모리 누수, 파일 핸들, 트랜잭션, 연결 풀
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Stage 4         │  동시성 & 성능 분석
  │ Concurrency     │  레이스 컨디션, 데드락, 락 순서, 병목
  │ Agent           │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Main Reviewer   │  최종 리포트 취합
  │ (Orchestrator)  │  severity 기준 정렬, 수정 제안 포함
  └─────────────────┘
```

---

## 실행 방법

1. **입력 파악**: 코드/diff/파일 경로를 확인한다.
2. **언어 감지**: 코드의 주 언어를 판별한다 (Go / Python / TypeScript / JavaScript / Rust / 기타).
3. **언어 파일 로드**: 아래 매핑에 해당하는 파일이 있으면 Read로 로드한다.
   - Go → `references/lang/go.md`
   - Python → `references/lang/python.md`
   - TypeScript / JavaScript → `references/lang/typescript.md`
   - Rust → `references/lang/rust.md`
4. **서브에이전트 순차 실행**: 각 Stage를 실행할 때 공통 프롬프트와 언어 파일의 해당 Stage 섹션을 **함께** 적용한다.
5. **결과 취합**: 메인 리뷰어가 `references/final-report.md` 형식으로 최종 리포트를 출력한다.

각 단계 프롬프트 위치:
- Stage 1: `references/01-architecture.md`
- Stage 2: `references/02-security.md`
- Stage 3: `references/03-resource.md`
- Stage 4: `references/04-concurrency.md`
- 최종 취합: `references/final-report.md`

---

## Severity 기준

| Level    | 의미                                 | 처리 방침              |
|----------|--------------------------------------|------------------------|
| CRITICAL | 즉시 수정 필요. 병합 블로커           | 무조건 수정 후 재검토  |
| HIGH     | 심각한 버그/취약점. 병합 전 수정 권장 | 병합 전 수정           |
| MEDIUM   | 개선 권장. 기술 부채 누적 위험        | 이슈로 트래킹          |
| LOW      | 스타일/마이너 제안                    | 선택적 반영            |
| INFO     | 참고 사항, 긍정적 관찰                | 참고                   |

---

## 핵심 원칙

- **증거 기반**: 모든 지적은 구체적인 코드 라인과 근거를 함께 제시한다.
- **언어 불가지론**: Go, Python, TypeScript, Rust 등 언어에 따라 관용 패턴을 반영한다.
- **위음성보다 위양성 허용**: 놓친 버그가 잘못된 경고보다 위험하다. 의심스러우면 언급한다.
- **YAGNI 적용**: 없는 기능을 추가하라고 제안하지 않는다. 있는 코드의 문제만 리뷰한다.
- **수정 제안 포함**: CRITICAL/HIGH는 가능한 한 수정 코드 스니펫을 함께 제시한다.
