---
name: python-development
description: "Use for Python writing/review/refactor tasks. Apply PEP 8/PEP 20 patterns and anti-patterns for correctness, maintainability, performance, and security. Auto-trigger on Python file work and Python code quality discussions."

---

# Python Development Skill

## Do

### Pythonic Code
- Compare None with identity: `is None` / `is not None`.
- Use truthy checks: `if flag:` (not `if flag == True:`).
- Use `set` for frequent membership checks (`list` O(n), `set` O(1)).
- Use list comprehensions only when concise/readable.
- Use `with` for resource management (files/DB/connections).

### Type Hints / Type Safety
- Add signature type hints: `def fn(x: int) -> str:`.
- Use `Optional[X]` or `X | None` (Python 3.10+).
- Run static/type checks with `ty` and `ruff`.

### Error Handling
- Catch specific exceptions (`except ValueError:`; avoid broad catch).
- Never use `except Exception as e: pass`; at minimum log.
- Preserve exception chains: `raise NewError(...) from original_error`.
- Design custom exceptions with meaningful hierarchy.

### Code Structure
- Keep single responsibility per function; target ~20 lines or less.
- Extract nested/complex logic into helper functions.
- Isolate data transforms into small pure functions.
- Minimize global mutable state.

### Naming (PEP 8)
- variables/functions: `snake_case`
- classes: `PascalCase`
- constants: `UPPER_CASE`
- internal: `_private`
- never use single-letter `l`, `O`, `I`.

### Testing
- Use `pytest`.
- Test file names: `test_*.py` or `*_test.py`.
- Prefer Given/When/Then structure.

---

## Don’t

### Correctness
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `except:` (bare) | Swallows all exceptions including `SystemExit` | `except Exception as e:` |
| Mutable default arg `def fn(x=[])` | State shared across calls | `def fn(x=None): x = x or []` |
| `== None` | Equality vs identity confusion | `is None` / `is not None` |
| `assert` for input validation | Disabled by `-O` | Explicit `if` + `raise` |
| Reusing consumed iterator | Second pass empty | Materialize with `list()` |

### Maintainability
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| God Class / God Function | Hard to change/test | Single responsibility |
| Magic numbers (`if x > 42`) | Meaning unclear | Named constants (`MAX_RETRY = 42`) |
| Deep nesting | Readability loss | Early return / helper functions |
| `import *` | Namespace pollution | Explicit imports |
| Comments explain bad code | Symptom of unclear code | Rewrite for clarity |

### Performance
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `in` lookup on list | O(n) lookup | Convert to `set` |
| String `+` in loop | New object every iteration | `"".join(parts)` |
| Unnecessary list materialization | Memory waste | Generator expression |
| Recompute function in loop | Repeated work | Compute once outside loop |
| `pandas.iterrows()` row-by-row | Very slow | Vectorized ops or `apply` |

### Security
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `eval()` / `exec()` | Arbitrary code execution risk | Safe parsing libraries |
| SQL string interpolation | SQL injection risk | Parameterized queries |
| `pickle` for untrusted input | Arbitrary code execution risk | JSON or safe format |
| Hardcoded secrets | Credential leakage risk | Env vars or secrets manager |

---

## Checklist (Code Review)
- [ ] None comparison uses `is` / `is not`?
- [ ] Exceptions are caught specifically?
- [ ] No mutable default args?
- [ ] Type hints added?
- [ ] Resources managed with `with`?
- [ ] Membership lookups use `set` where appropriate?
- [ ] No `eval()` / `exec()`?
- [ ] SQL is parameterized?
- [ ] No `ty` / `ruff` errors?
- [ ] Test coverage exists?
