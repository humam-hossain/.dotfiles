---
phase: 23-one-command-bootstrap
plan: 01
subsystem: bootstrap-orchestrator
tags: [bootstrap, state-machine, cli, logging, assert-harness]
key-files:
  created:
    - bootstrap.sh
    - scripts/phase23-bootstrap-assert.sh
  modified:
    - arch/dots-hyprland.sh
requirements: [BOOT-01, BOOT-02]
requirements_completed: [BOOT-01, BOOT-02]
status: complete
completed_at: 2026-09-15T11:45:00Z
---

# Plan 23-01: Foundational CLI Parser, Logging Engine, JSON State Machine, and Assert Harness Summary

Delivered the root orchestrator entry point (`./bootstrap.sh`), closed CLI flag parser, dual-stream transcript logging, resumable atomic JSON state engine, wrapper delegation in `arch/dots-hyprland.sh`, and automated assert harness scaffolding (`scripts/phase23-bootstrap-assert.sh`) with Section 1 and Section 3 passing cleanly.

## Key Changes

1. **Root Orchestrator (`./bootstrap.sh`)**:
   - Physical repository root resolution (`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`).
   - Non-root execution gate asserting `CURRENT_EUID != 0` (supporting `DOTFILES_MOCK_EUID` override for testing per D-06).
   - Platform gate asserting Arch Linux environment (`/etc/arch-release`, overridable via `DOTFILES_MOCK_ARCH_RELEASE`).
   - Dual-stream console and transcript logging (`$XDG_STATE_HOME/dotfiles/logs/bootstrap-<timestamp>.log`) retaining the 5 most recent logs and using duplicated file descriptors (`exec 3>&1 4>&2`) with clean flush traps.
   - Closed CLI flag parser handling `--dry-run`, `--from <step>`, `--only <step>`, `--reset`, `--snapshot`, `--no-pause`, and `-h|--help`, rejecting unknown flags with exit code 2.

2. **JSON State Machine Engine (`$XDG_STATE_HOME/dotfiles/bootstrap-state`)**:
   - Persists state schema v1 containing timestamps, stage number, active step, per-step statuses (`pending`, `running`, `complete`, `failed`), and `last_error`.
   - Atomic state updates via temporary files on the same filesystem.
   - `execute_step()` supporting `--from` and `--only` step filtering.
   - Idempotent re-run skipping for completed steps (`[SKIP] Step '<step>' already completed.`).
   - Failure trapping with fail-closed resume guidance: `[FAIL] Bootstrap failed during step '<step>' (exit code <rc>). [INFO] To resume bootstrap from this step after addressing the issue, run: ./bootstrap.sh --from <step>`.

3. **Wrapper Subcommand Routing (`arch/dots-hyprland.sh`)**:
   - Registered `bootstrap` in `ALLOWLIST`.
   - Documented `bootstrap` in usage block.
   - Forwarded via `exec "$REPO_ROOT/bootstrap.sh" "$@"` in `main()`, adding 0 new stow sites and strictly preserving `PAIR_COUNT == 18`.

4. **Assert Test Harness (`scripts/phase23-bootstrap-assert.sh`)**:
   - Scaffolding with trap cleanup, scratch directories, and git working-tree porcelain bracket.
   - Implemented Section 1: validates `--help` exit 0, unknown option exit 2, non-root gate exit 1, wrapper forwarding, and `PAIR_COUNT == 18`.
   - Implemented Section 3: validates state schema initialization, failure trapping and error recording, `--from` resumption, `--only` isolation, `--reset` reinitialization, and 100% idempotence on re-runs.

## Verification Results

- `scripts/phase23-bootstrap-assert.sh --section 1`: PASSED (5/5 checks passed, FAIL=0, FINDINGS=0).
- `scripts/phase23-bootstrap-assert.sh --section 3`: PASSED (7/7 checks passed, FAIL=0, FINDINGS=0).
- `grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l`: strictly 18.
- Working-tree porcelain bracket: unchanged.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
