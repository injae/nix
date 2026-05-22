---
name: nix-system
description: "Invoke at session start when NIX_CONFIG_DIR is set or when both .envrc and flake.nix are present in the working directory. Applies Nix-managed configuration rules: never edit derived paths directly, locate sources under NIX_CONFIG_DIR, and prefix shell commands with direnv exec when a flake devshell is active."
user-invocable: true
---

# Nix System Configuration

Run these checks immediately:

```bash
echo "NIX_CONFIG_DIR=${NIX_CONFIG_DIR:-<not set>}"
test -f .envrc && test -f flake.nix && echo "direnv+flake detected" || echo "no direnv+flake"
```

**If `NIX_CONFIG_DIR` is set:** note the path. All edits to derived config files (`~/.claude/`, `~/.config/`, `/etc/`) must go to their source under `$NIX_CONFIG_DIR` instead.

**If `.envrc` + `flake.nix` both exist in CWD:** prefix every shell command with `direnv exec .` for the rest of this session.

---

## Nix-managed configuration rules

이 시스템의 설정 대부분은 Nix로 선언적으로 관리됩니다. **어떤 설정 파일을 수정하든**, 편집 전에 반드시 먼저 확인합니다:

1. **Nix 관리 여부 확인**: 대상 파일이 `~/.config/`, `~/.claude/`, `/etc/` 등 파생 경로에 있다면, 실제 소스는 `$NIX_CONFIG_DIR` 아래에 있을 가능성이 높습니다. 파생 경로를 직접 수정하지 않습니다.
2. **소스 경로 찾기**: `$NIX_CONFIG_DIR`에서 해당 설정의 원본 파일을 먼저 찾아 편집합니다.
3. **CLAUDE.md 참조**: Nix 관련 작업이라면 `$NIX_CONFIG_DIR/CLAUDE.md`를 읽고 해당 프로젝트 지침을 따릅니다.

주요 경로 매핑:

| 파생 경로 | Nix 소스 경로 |
|-----------|--------------|
| `~/.claude/` (CLAUDE.md, settings.json, skills, hooks) | `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/` |
| `~/.config/` | `$NIX_CONFIG_DIR` 내 해당 모듈 |
| `/etc/` | `$NIX_CONFIG_DIR` 내 시스템 모듈 |

**예외**: 파일이 명시적으로 Nix 비관리 대상(e.g. `.envrc`, 프로젝트 로컬 파일)이거나, `CLAUDE.local.md`처럼 의도적으로 파생 경로에만 존재하는 경우는 직접 편집합니다.

**Never run `just switch` yourself.** The user will run it manually — do not remind them, and do not mention it as a closing remark.

When creating a new file anywhere under `$NIX_CONFIG_DIR`, immediately run `git add <file>` afterward. Nix flakes only see files tracked by git, so untracked files are silently ignored.
