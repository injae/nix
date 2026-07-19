# Go Migration

## Fetch & Locate

```bash
go get <module>@latest
# Files land at:
$(go env GOMODCACHE)/<module>@<version>/
```

## Read API from Cache

Use `file-outline` + `symbol-source` on cached files — same MCP tools as project files.
Never use `cat` or WebFetch GitHub raw URLs to research API changes.

## Compatibility Check

```bash
# Inspect new package's own dependencies
cat $(go env GOMODCACHE)/<module>@<version>/go.mod

# Discover if a companion package has a new major module
go list -m -versions <companion-module>
go list -m -versions <companion-module>/v5
```

If a companion package's go.mod still references the old major version, search:
`WebSearch "<companion-package> v5 support"` before concluding it's incompatible.

## Compile-Driven Iteration

After updating imports:

```bash
go build ./...
```

Fix errors top-down. Do not try to anticipate every API change before building —
the compiler surfaces all breakage at once and is faster than manual research.
