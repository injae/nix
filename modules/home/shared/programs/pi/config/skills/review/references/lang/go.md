# Go Language Checklist

> For full Go patterns and anti-patterns, see the `go-development` skill. This file contains only review-specific checklist items (per-stage additions).

공통 Stage 체크리스트에 아래 항목을 추가한다.

---

## Stage 1 — 아키텍처

**임베드 섀도잉**
- 외부 구조체가 임베드된 구조체와 **동일한 이름의 필드**를 선언하고 있는가?
  - `p.Field` 접근이 임베드 타입의 동명 필드를 조용히 가려, 한쪽에 쓰고 다른 쪽에서 읽는 버그가 생긴다.
  - 해결: 이름 충돌을 피하거나, 임베드 대신 명시적 필드로 감싸고 접근자를 제공한다.

---

## Stage 2 — 보안

- `math/rand` 대신 `crypto/rand`를 보안 목적 난수 생성에 사용하는가?
- `encoding/gob`으로 신뢰할 수 없는 데이터를 역직렬화하는가?

---

## Stage 3 — 리소스 관리

**메모리**
- goroutine 누수: 종료 조건 없이 실행되는 goroutine이 있는가?
- 슬라이스가 무한 성장할 수 있는가? (append 루프 등)

**파일 & I/O**
- `defer f.Close()` 패턴이 사용되는가?
- 루프 안에서 defer를 쓰면 파일이 함수 종료 시까지 닫히지 않는 문제가 있는가?

**데이터베이스**
- `rows.Close()`가 누락되지 않았는가? (`defer rows.Close()` 권장)
- `db.QueryRow().Scan()` 에러 처리가 누락되지 않았는가?

**네트워크**
- `defer resp.Body.Close()`가 모든 경로에서 호출되는가?

**OS 리소스**
- `time.Ticker` / `time.Timer`가 사용 후 `Stop()`되는가?
- 자식 프로세스가 `cmd.Wait()`되는가? (좀비 프로세스 방지)

---

## Stage 4 — 동시성 & 성능

**레이스 컨디션**
- `go vet -race`가 잡을 만한 패턴이 있는가?
  - `sync.Map` 또는 mutex 없이 map을 goroutine 간 공유
  - 슬라이스/구조체 필드에 동시 접근
  - 클로저에서 루프 변수 캡처 문제 (Go 1.22 이전 패턴)

**데드락**
- 채널 연산이 서로 기다리는 구조인가? (unbuffered channel 교착)
- `RLock` 보유 중 `Lock`을 획득하려 하는가?

**락 세분성**
- 읽기 전용 작업에 `RWMutex` 대신 `Mutex`를 사용하는가?

**Goroutine 관리**
- `context.Context`가 goroutine 체인 전체에 전파되는가?
- `WaitGroup.Add()`가 goroutine 시작 전에 호출되는가? (Add/Done/Wait 순서)
- goroutine 내부 패닉이 `recover()`되는가?
- 채널이 닫히지 않아 수신자가 영구 블록될 수 있는가?

**원자성**
- `sync/atomic` 대신 일반 변수에 동시 접근이 있는가?
- 32비트 시스템에서 64비트 원자 연산의 정렬 문제가 있는가? (구조체 필드 배치)

**성능**
- `strings.Builder` 대신 루프에서 `+` 연산으로 문자열을 연결하는가?
- `regexp.Compile()`이 루프 안에서 매번 호출되는가?
- 리플렉션(`reflect` 패키지)이 hot path에서 사용되는가?
