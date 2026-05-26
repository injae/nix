---
name: typescript-development
description: "Use for TypeScript write/review/refactor tasks. Enforce strict type-safety patterns and anti-patterns for type design, narrowing, generics, API design, and null handling."
---

# TypeScript Development Skill

## References
- TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/intro.html
- TypeScript Do's and Don'ts: https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html
- TSConfig reference: https://www.typescriptlang.org/tsconfig
- Total TypeScript articles: https://www.totaltypescript.com/articles
- Total TypeScript tips: https://www.totaltypescript.com/tips
- refactoring.guru TypeScript patterns: https://refactoring.guru/design-patterns/typescript

---

## Do

### Type Design
- Enable `strict: true` (`strictNullChecks`, `noImplicitAny`).
- Recommend `noUncheckedIndexedAccess: true`.
- Use lowercase primitives: `string`, `number`, `boolean` (not `String`, `Number`).
- Model states with unions (`"pending" | "done" | "error"`).
- Prefer `type` over `interface` by default (intersection flexibility).
- Use discriminated unions for state modeling.

### Type Narrowing
- Use explicit type guards: `x is User`.
- Narrow with `in`, `typeof`, `instanceof`.
- Minimize `as`; if needed, document reason.
- Never use `as any`.

### Generics
- Use generics to remove duplication, not for over-generalization.
- Constrain generics with `extends`.
- Use utility types: `Partial`, `Required`, `Pick`, `Omit`, `ReturnType`.

### Function / API Design
- Annotate return types explicitly for non-trivial logic.
- Prefer union params + type guards over overload sprawl.
- Prefer `unknown` + narrowing over `any`.
- Express immutability with `readonly`.

### Null / Undefined Handling
- Use `?.` and `??`.
- Add explicit null checks before use.
- Minimize non-null assertion `!`.

---

## Don’t

### Type System Abuse
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `any` | Disables type checking | `unknown` + narrowing |
| `as any` | Bypasses type system | Proper type or type guard |
| `Number`/`String`/`Boolean` | Boxed types | `number`/`string`/`boolean` |
| `Object` | Too imprecise | `Record<string, unknown>` or concrete type |
| `Function` | Ignores signature | Explicit function signature |
| Excessive `as SomeType` | Runtime risk | Type guard / better type design |

### Structural Design
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `enum` default usage | Emits runtime JS, poor tree-shaking | `as const` + union |
| Empty interface | No meaning | `type Foo = Record<string, unknown>` |
| Declaration merging abuse | Unpredictable extensions | Explicit extension |
| Unnecessary class-heavy design | Complexity | Objects + functions |
| Overusing `!` | Null runtime risk | Explicit null checks |

### Null / Undefined
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `== null` | Ambiguous intent | `=== null` or `=== undefined` |
| Mixing null + undefined | Inconsistent state model | Pick one (`undefined` recommended) |
| Unsafe index access (`arr[0].x`) | `undefined` risk | `noUncheckedIndexedAccess` + guard |

### Performance / Build
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| Deep nested generics | Slow compile, hard read | Split with intermediate type aliases |
| `strict: false` | Weak type safety | `strict: true` |
| Missing `import type` in `.d.ts` | Unneeded runtime deps | `import type` |

---

## Checklist (Code Review)
- [ ] `strict: true` enabled?
- [ ] No `any` (replaced by `unknown` + narrowing)?
- [ ] `as` assertions minimized?
- [ ] Primitive types lowercase?
- [ ] `as const` + union used instead of `enum` where possible?
- [ ] `undefined` handled for indexed access?
- [ ] Return types explicitly annotated?
- [ ] `tsc --noEmit` passes clean?
