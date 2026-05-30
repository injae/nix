---
name: migration
description: "Migrating a dependency to a new major version. Covers research protocol,
  compatibility checking, and ecosystem package discovery. Language-specific details
  in sub-files (go.md, etc.). Use whenever upgrading a library major version."
user-invocable: true
---

# Dependency Migration

## General Protocol

1. **Migration guide first** — WebSearch for official migration guide before anything else
2. **Download first** — fetch the new version locally before researching API changes
2. **Read locally** — read API from local cache, not WebFetch on GitHub URLs
   (unreliable: 404s, wrong branches, requires guessing file paths)
3. **Check manifest** — read go.mod / package.json / etc. of the new package to find
   compatible versions of companion/ecosystem packages
4. **Search for alternatives** — major versions often split companion packages into new
   modules; use WebSearch before assuming compatibility is broken
5. **Compile-driven iteration** — after updating imports, run build to surface remaining
   breakage rather than trying to anticipate every change upfront

## Pre-plan checklist

Present a plan only after ALL of these are verified:
- [ ] Official migration guide found and read
- [ ] New package fetched and API read from cache
- [ ] All ecosystem/companion packages checked for compatibility
- [ ] For each incompatible package: replacement found or decision made

Research resolvable unknowns before asking.

## Sub-skills

| Language | File | When to read |
|----------|------|--------------|
| Go | `go.md` | go.mod, `go get`, module cache |
