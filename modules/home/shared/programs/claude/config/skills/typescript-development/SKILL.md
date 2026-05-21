---
name: typescript-development
description: "Must be used when writing, reviewing, or refactoring TypeScript code. Applies type-safety patterns and anti-patterns based on strict mode. Automatically triggers when opening TypeScript files, designing types, or discussing generics/type narrowing."
---

# TypeScript Development Skill

## Official References

- TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/intro.html
- TypeScript Do's and Don'ts: https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html
- TypeScript tsconfig reference: https://www.typescriptlang.org/tsconfig
- Total TypeScript (Matt Pocock): https://www.totaltypescript.com/articles
- TypeScript Tips: https://www.totaltypescript.com/tips
- refactoring.guru TypeScript patterns: https://refactoring.guru/design-patterns/typescript

---

## Patterns (Do's)

### Type Design
- Enable `strict: true` in tsconfig — especially `strictNullChecks` and `noImplicitAny`
- Recommend `noUncheckedIndexedAccess: true` — for safe array/object index access
- Use lowercase primitive types: `string`, `number`, `boolean` (uppercase `String`, `Number` are forbidden)
- Express state with union types: `type Status = "pending" | "done" | "error"`
- Prefer `type` over `interface` by default (intersection types are more flexible than extends)
- Model state with Discriminated Unions

### Type Narrowing
- Use type guard functions for explicit narrowing: `function isUser(x: unknown): x is User`
- Narrow naturally with `in` operator, `typeof`, and `instanceof`
- Minimize `as` type assertions — when necessary, document the reason in a comment
- Never bypass the type system with `as any`

### Generics
- Use generics only to eliminate type repetition (avoid over-generalization)
- Constrain generics with `extends`: `<T extends object>`
- Leverage utility types: `Partial<T>`, `Required<T>`, `Pick<T,K>`, `Omit<T,K>`, `ReturnType<F>`

### Function / API Design
- Annotate function return types explicitly (clarifies intent in complex logic)
- Prefer union parameters + type guards over overloading
- Use `unknown` then narrow (instead of `any`)
- Express immutability with `readonly` arrays/objects

### null / undefined Handling
- Actively use optional chaining `?.` and nullish coalescing `??`
- Perform explicit null checks before use (minimize non-null assertion `!`)

---

## Anti-Patterns (Don'ts)

### Type System Abuse
| Anti-Pattern | Reason | Correct Alternative |
|---|---|---|
| Using `any` | Completely disables type checking | `unknown` + type narrowing |
| `as any` | Bypasses the type system | Proper type definition or type guard |
| Uppercase `Number`, `String`, `Boolean` | Boxed object types, practically useless | `number`, `string`, `boolean` |
| `Object` type | Less precise than `{}` or `object` | `Record<string, unknown>` or a specific type |
| `Function` type | Ignores parameter/return types | Explicit signature `(x: T) => U` |
| Overusing type assertions `as SomeType` | Can lead to runtime errors | Type guard or proper type design |

### Structural Design
| Anti-Pattern | Reason | Correct Alternative |
|---|---|---|
| Using `enum` | Generates JS runtime code, not tree-shakeable | `as const` + union type |
| Empty interface `interface Foo {}` | Expresses nothing | `type Foo = Record<string, unknown>` |
| Abusing declaration merging | Unpredictable type extension | Explicit extension |
| Overusing classes (when unnecessary in JS) | Excessive complexity | Simple objects + functions |
| Overusing `!` non-null assertion | Runtime null errors | Explicit null checks |

### null / undefined
| Anti-Pattern | Reason | Correct Alternative |
|---|---|---|
| `== null` (loose comparison) | Intent is unclear | `=== null` or `=== undefined` |
| Mixing null and undefined | Confusing | Stick to one (`undefined` recommended) |
| Direct array index access `arr[0].name` | Ignores possibility of undefined | `noUncheckedIndexedAccess` + check |

### Performance / Build
| Anti-Pattern | Reason | Correct Alternative |
|---|---|---|
| Excessively deep nested generics | Slows compilation, hard to read | Split into intermediate type aliases |
| `tsconfig` `strict: false` | Disables most type safety | `strict: true` |
| Not using `import type` in `.d.ts` | Unnecessary runtime dependency | `import type` |

---

## Checklist (For Code Review)

- [ ] Is `strict: true` configured?
- [ ] Is there no `any`? (replaced with `unknown` + narrowing?)
- [ ] Are `as` assertions minimized?
- [ ] Are primitive types lowercase (`string`, `number`)?
- [ ] Is `as const` union used instead of `enum`?
- [ ] Is `undefined` handled when accessing array/object indices?
- [ ] Are return types explicitly annotated?
- [ ] Does `tsc --noEmit` pass with no errors?