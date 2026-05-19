# Rust 언어 특화 체크리스트

공통 Stage 체크리스트에 아래 항목을 추가한다.

---

## Stage 2 — 보안

- `rand::random()` / `rand::thread_rng()`을 보안 목적 난수 생성에 사용하는가? (`rand::rngs::OsRng` 또는 `getrandom` 권장)
- `unsafe` 블록에서 포인터 역참조 시 유효성 검증이 없는가?
- FFI 경계에서 외부 데이터를 검증 없이 사용하는가?
- `serde`로 역직렬화 시 입력 크기 제한이 없는가?

---

## Stage 3 — 리소스 관리

**메모리**
- `Rc<RefCell<T>>`의 순환 참조가 발생할 수 있는가? (`Weak` 참조 활용 여부)
- `Arc<T>` 참조 카운트가 예상보다 오래 유지되어 메모리를 점유하는가?
- `Box::leak()`으로 의도적으로 누수시킨 메모리가 문서화되어 있는가?

**파일 & I/O**
- `File`, `BufReader`, `BufWriter`가 RAII(`Drop`)로 자동 닫히는 것을 신뢰하는가? (명시적 `flush()` 누락 여부 확인)
- `BufWriter`를 `drop()` 전에 `flush()`하지 않아 데이터가 손실될 수 있는가?

**비동기 (tokio / async-std)**
- 태스크 핸들(`JoinHandle`)이 `await`되지 않고 버려지는가? (결과 및 패닉 무시)

---

## Stage 4 — 동시성 & 성능

**레이스 컨디션**
- `unsafe` 코드에서 `Send` / `Sync` 트레잇을 수동으로 구현할 때 안전성 증명이 있는가?
- `Mutex<T>` 대신 `RefCell<T>`을 멀티스레드 환경에서 사용하는가?

**데드락**
- `Mutex::lock()`이 중첩되어 같은 스레드에서 두 번 잠기는가? (재진입 불가)
- 여러 `Mutex`를 항상 동일한 순서로 획득하는가?
- `RwLock` 읽기 락 보유 중 쓰기 락을 획득하려 하는가?

**비동기 (tokio)**
- `tokio::spawn`된 태스크 안에서 `std::thread::sleep()` 등 블로킹 함수를 호출하는가? (`tokio::time::sleep` 권장)
- CPU-bound 작업을 `tokio::task::spawn_blocking()` 없이 async 태스크에서 실행하는가?
- `tokio::select!`에서 취소 안전하지 않은 Future를 사용하는가?

**성능**
- `String` 연결을 루프에서 `+` 또는 `push_str`로 반복하는가? (`String::with_capacity` 사전 할당 고려)
- `clone()`이 hot path에서 불필요하게 호출되는가?
- `Vec`에 대용량 데이터를 push할 때 `with_capacity`로 사전 할당하는가?
- 반복자 체인에 불필요한 중간 컬렉션(`.collect()`)이 있는가?
