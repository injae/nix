# Python 언어 특화 체크리스트

공통 Stage 체크리스트에 아래 항목을 추가한다.

---

## Stage 2 — 보안

- `random.random()` / `random.randint()` 등을 보안 목적 난수 생성에 사용하는가? (`secrets` 모듈 권장)
- `pickle.loads()`로 신뢰할 수 없는 데이터를 역직렬화하는가? (임의 코드 실행 위험)
- `yaml.load()` 대신 `yaml.safe_load()`를 사용하는가?
- `eval()` / `exec()`에 외부 입력이 들어가는가?
- `subprocess`에 `shell=True`와 함께 비검증 입력이 사용되는가?

---

## Stage 3 — 리소스 관리

**메모리**
- 참조 순환이 발생할 수 있는가? (`weakref` 활용 여부)
- `__del__`에 의존하는 리소스 정리가 있는가? (GC 보장 없음)
- 대용량 데이터를 `list()`로 한 번에 로드하는가? (제너레이터/이터레이터 활용 가능한가?)

**파일 & I/O**
- `with open(...)` 컨텍스트 매니저를 사용하는가?
- 루프 안에서 파일을 열고 예외 발생 시 닫히지 않는 경우가 있는가?

**데이터베이스**
- 커서(cursor)가 `close()` 또는 컨텍스트 매니저로 닫히는가?
- 커넥션이 `finally` 블록 또는 컨텍스트 매니저로 반환되는가?

---

## Stage 4 — 동시성 & 성능

**레이스 컨디션**
- GIL로 보호되지 않는 연산이 있는가?
  - `multiprocessing`에서 공유 상태 (`Manager`, `Value`, `Array` 없이 접근)
  - `asyncio`에서 `await` 사이의 공유 상태 변경

**비동기 패턴 (asyncio)**
- CPU-bound 작업이 `async def` 함수 안에서 직접 실행되어 이벤트 루프를 블로킹하는가? (`loop.run_in_executor` 또는 `asyncio.to_thread` 권장)
- `asyncio.gather()` 내 태스크에서 발생한 예외가 처리되는가?
- `asyncio.create_task()`로 생성한 태스크가 참조를 유지하는가? (GC에 의한 태스크 취소 방지)
- 비동기 함수가 동기 컨텍스트에서 `await` 없이 호출되는가?

**성능**
- 루프에서 문자열을 `+`로 연결하는가? (`"".join()` 권장)
- `re.compile()` 없이 루프 안에서 `re.match()` / `re.search()`를 반복 호출하는가?
- 리스트 컴프리헨션 대신 불필요한 중간 리스트를 생성하는가?
