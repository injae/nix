---
name: python-development
description: "Use whenever writing, reviewing, or refactoring Python code. Applies PEP 8/PEP 20 based patterns and anti-patterns, and checks for correctness, maintainability, performance, and security. Automatically triggered when opening a Python file, implementing a Python function, or discussing Python code quality issues."
---

# Python Development Skill

## Official References

- PEP 8 (Style Guide): https://peps.python.org/pep-0008/
- PEP 20 (The Zen of Python): https://peps.python.org/pep-0020/
- PEP 257 (Docstring Conventions): https://peps.python.org/pep-0257/
- Python Anti-Patterns Book: https://docs.quantifiedcode.com/python-anti-patterns/
- python-patterns (collection of good patterns): https://github.com/faif/python-patterns
- Real Python Anti-Patterns: https://realpython.com/the-most-diabolical-python-antipattern/

---

## Patterns (What To Do)

### Pythonic Code
- `if x is None:` / `if x is not None:` — use `is` for None comparisons (PEP 8)
- Boolean comparisons: `if flag:` not `if flag == True:`
- Use `set` for membership lookups in sequences (`in` on a list is O(n), set is O(1))
- List comprehensions: use only when concise and readable
- Manage resources with `with` statements (files, DB connections, etc.)

### Type Hints / Type Safety
- Annotate function signatures with type hints (`def fn(x: int) -> str:`)
- Use `Optional[X]` or `X | None` (Python 3.10+)
- Run static type checks with `mypy` or `pyright`

### Error Handling
- Catch specific exceptions (`except ValueError:` not `except:`)
- Never `except Exception as e: pass` — at minimum, log it
- Preserve exception chains: `raise NewError(...) from original_error`
- Design custom exceptions with a meaningful class hierarchy

### Code Structure
- Functions should have a single responsibility; aim for 20 lines or fewer
- Extract complex nested logic into helper functions
- Isolate data transformation logic into small pure functions
- Minimize global mutable state

### Naming (PEP 8)
- Variables/functions: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_CASE`
- Internal use: `_private` prefix
- Never use `l`, `O`, or `I` as single-character variable names

### Testing
- Write tests using `pytest`
- Test file names: `test_*.py` or `*_test.py`
- Recommended structure: Given/When/Then

---

## Anti-Patterns (What Not To Do)

### Correctness
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `except:` (bare) | Swallows all exceptions, including SystemExit | `except Exception as e:` |
| Mutable default argument `def fn(x=[])` | State is shared across function calls | `def fn(x=None): x = x or []` |
| Using `==` to compare to `None` | Confuses equality with identity | `is None` / `is not None` |
| Using `assert` for input validation | Disabled by the `-O` flag | Explicit `if` + `raise` |
| Consuming an iterator multiple times | Yields empty results on second consumption | Convert to `list()` first |

### Maintainability
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| God Class / God Function | Hard to change and impossible to test | Follow the single responsibility principle |
| Hardcoded magic numbers `if x > 42:` | Meaning is unclear | Define constants: `MAX_RETRY = 42` |
| Deep nesting (`if/if/if/if`) | Hurts readability | Early return / helper functions |
| Long `import *` lists | Pollutes the namespace | Explicit imports |
| Comments explaining bad code | Code should be self-documenting | Clarify the code itself |

### Performance
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `in` lookup on a `list` | O(n) time complexity | Convert to `set` first |
| String `+` concatenation in a loop | Creates a new object every iteration | `"".join(parts)` |
| Unnecessary list comprehension → list | Wastes memory | Use a generator expression |
| Recomputing a function call inside a loop | Unnecessary repeated work | Compute once outside the loop |
| `pandas` row-by-row `iterrows()` | Extremely slow | Vectorized operations or `apply` |

### Security
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| Using `eval()` / `exec()` | Risk of arbitrary code execution | Safe parsing libraries |
| Building SQL strings with string formatting | SQL Injection | Parameterized queries |
| Deserializing external data with `pickle` | Risk of arbitrary code execution | JSON or a safe format |
| Hardcoding secrets in code | Risk of leaking credentials | Environment variables / secrets manager |

---

## Checklist (For Code Review)

- [ ] Are None comparisons done with `is` / `is not`?
- [ ] Are exceptions caught specifically?
- [ ] Are mutable objects avoided as function default values?
- [ ] Are type hints added?
- [ ] Are resources managed with `with` statements?
- [ ] Is `set` used instead of `list` for lookups?
- [ ] Is there no `eval()`/`exec()`?
- [ ] Does SQL use parameterized queries?
- [ ] Are there no `mypy` / `pyright` errors?
- [ ] Is there test coverage?