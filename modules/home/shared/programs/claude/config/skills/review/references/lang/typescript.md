# TypeScript / JavaScript 언어 특화 체크리스트

공통 Stage 체크리스트에 아래 항목을 추가한다.

---

## Stage 2 — 보안

- `Math.random()`을 보안 목적 난수 생성에 사용하는가? (`crypto.getRandomValues()` / `crypto.randomUUID()` 권장)
- `JSON.parse()`로 신뢰할 수 없는 외부 데이터를 에러 처리 없이 파싱하는가?
- `innerHTML` / `outerHTML`에 비이스케이프 사용자 입력이 삽입되는가? (XSS)
- `dangerouslySetInnerHTML`에 검증되지 않은 값이 들어가는가?
- `eval()` / `new Function()`에 외부 입력이 사용되는가?

---

## Stage 3 — 리소스 관리

**메모리**
- `addEventListener`로 등록한 이벤트 리스너가 컴포넌트/객체 해제 시 제거되는가? (`removeEventListener` 또는 `AbortController`)
- 클로저가 의도치 않게 DOM 노드나 대형 객체를 참조 유지하고 있는가?
- `setInterval` / `setTimeout`이 더 이상 필요하지 않을 때 `clearInterval` / `clearTimeout`으로 정리되는가?

**파일 & I/O (Node.js)**
- `fs.createReadStream()` / `fs.createWriteStream()`이 오류 발생 시 닫히는가?
- 스트림에 `error` 이벤트 핸들러가 등록되어 있는가?

---

## Stage 4 — 동시성 & 성능

**레이스 컨디션 (비동기)**
- 여러 `await` 사이에서 공유 상태가 변경될 수 있는가? (TOCTOU 패턴)
- 병렬로 실행되는 `Promise.all()` 내 태스크들이 같은 상태를 동시에 수정하는가?

**비동기 패턴**
- `Promise` rejection이 `.catch()` 또는 `try/catch`로 처리되지 않는가?
- `async/await` 함수에서 에러가 `try/catch` 없이 전파되는가?
- `Promise.all()` 대신 순차 `await`를 사용하여 불필요하게 직렬화되는가?
- CPU-bound 작업(암호화, 이미지 처리 등)이 메인 스레드를 블로킹하는가? (Web Worker / `worker_threads` 권장)
- `async` 함수가 동기 컨텍스트에서 `await` 없이 호출되어 반환된 Promise가 무시되는가?

**성능**
- 루프에서 문자열을 `+`로 연결하는가? (템플릿 리터럴 또는 배열 `join` 권장)
- `new RegExp()`가 루프 안에서 매번 생성되는가?
- 대용량 배열에 `Array.prototype.forEach` 대신 `for...of`를 고려했는가?
- React 컴포넌트에서 렌더마다 새 객체/함수가 생성되어 불필요한 리렌더링을 유발하는가? (`useMemo`, `useCallback` 적용 여부)
