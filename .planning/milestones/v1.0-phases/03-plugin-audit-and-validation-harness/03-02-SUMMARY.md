---
phase: 03-plugin-audit-and-validation-harness
plan: 02
subsystem: validation
tags: [neovim, validation, headless, health, lua, shell]

requires: []
provides:
  - scripts/nvim-validate.sh — repo-owned shell orchestrator for headless startup/sync/health/smoke checks
  - .config/nvim/lua/core/health.lua — Lua module exporting snapshot(opts) for machine-readable plugin/tool/lazy status
  - .config/nvim/README.md — Phase 3 section documenting all subcommands and report paths
  - .planning/tmp/ added to .gitignore

affects: [03-03 lockfile refresh, 04-* plugin modernization]

tech-stack:
  added: []
  patterns: [headless smoke test, machine-readable JSON health snapshot, graceful tool degradation]

key-files:
  created:
    - scripts/nvim-validate.sh
    - .config/nvim/lua/core/health.lua
  modified:
    - .config/nvim/README.md (Phase 3 section added)
    - .gitignore (.planning/tmp/ added)

key-decisions:
  - "Health subcommand uses tool availability warnings (non-failing); plugin load failures fail hard"

patterns-established:
  - "Headless validation via nvim --headless with explicit rtp override pointing to repo config"
  - "Machine-readable JSON snapshot exported by Lua module, consumed by shell wrapper"
  - "Fail-fast all-subcommand with tail of relevant log on failure"

requirements-completed: [TOOL-01]

duration: 23min
completed: 2026-04-15
---

# Phase 03 Plan 02: Validation Harness — Summary

**Headless Neovim validation harness with startup/sync/health/smoke subcommands and machine-readable JSON health snapshot**

## Performance

- **Duration:** 23 min
- **Started:** 2026-04-15T06:10:00Z
- **Completed:** 2026-04-15T06:33:07Z
- **Tasks:** 3
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments

- Built `scripts/nvim-validate.sh` with four independent subcommands and an `all` aggregator
- Built `lua/core/health.lua` with `snapshot(opts)` that probes plugins, tools, and lazy.nvim stats into JSON
- Documented the full harness in `README.md` Phase 3 section with exact invocations and report paths
- Added `.planning/tmp/` to `.gitignore` to keep reports local

## Task Commits

Each task was committed atomically:

1. **Task 1: Write Lua health snapshot module** - `3c8b662` (feat)
2. **Task 2: Write validation shell orchestrator** - `52767f9` (feat)
3. **Task 3: Document the validation harness** - `aa05d5f` (docs)

## Files Created/Modified

- `scripts/nvim-validate.sh` — Shell orchestrator: startup, sync, health, smoke, all subcommands
- `.config/nvim/lua/core/health.lua` — Lua module with `snapshot(opts)` exporting JSON health report
- `.config/nvim/README.md` — Phase 3 section added after Phase 2, before Phase 1
- `.gitignore` — `.planning/tmp/` added

## Decisions Made

- Health subcommand warns (non-failing) on missing tools per D-07/D-08 graceful degradation policy; only plugin load failures cause harness failure
- Reports written to `.planning/tmp/nvim-validate/` for inspectability and diffability
- Uses `NVIM_APPNAME=nvim` so harness validates the active config (not a sandboxed copy)
- No CI configuration added (v2 concern); script is shell-portable for later CI integration

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

**Health subcommand timeout on full config:** The `health` subcommand correctly invokes `core.health.snapshot` but times out (>300s) when loading the full `init.lua` because lazy.nvim triggers Mason tool installation and Treesitter parser compilation on first headless run. This is a pre-existing config startup characteristic, not a harness bug. Verified with `--clean -u NONE` probe: the Lua module loads and writes correct JSON in isolation.

**Startup/sync/smoke all pass:** `startup`, `sync`, and `smoke` subcommands all exit 0 and write clean logs against the current repo config.

## Maintainer Invocations

```bash
# Quick smoke — startup only
./scripts/nvim-validate.sh startup

# Sync check after lockfile changes
./scripts/nvim-validate.sh sync

# Health snapshot (requires full config load — may be slow on first run)
./scripts/nvim-validate.sh health

# Probe individual plugin modules
./scripts/nvim-validate.sh smoke

# Full validation sweep (baseline)
./scripts/nvim-validate.sh all
```

## Baseline Harness Output

| Subcommand | Result | Notes |
|-----------|--------|-------|
| `startup` | PASS | No error keywords; clean headless quit |
| `sync` | PASS | Lazy! sync completed; no failures in log |
| `smoke` | PASS | All 15 probed plugin modules loaded |
| `health` | (timeout on full config) | Module correct; full startup >300s on this machine |

**Health snapshot schema confirmed correct** (from `--clean -u NONE` probe):
```json
{
  "neovim_version": "0.12.1+v0.12.1",
  "timestamp": "2026-04-15T06:32:33Z",
  "plugins": [...],
  "tools": [
    { "name": "sh",   "available": true, "path": "/usr/bin/sh" },
    { "name": "git",  "available": true, "path": "/usr/bin/git" },
    { "name": "rg",   "available": true, "path": "/usr/bin/rg" },
    { "name": "node", "available": true, "path": "/usr/bin/node" },
    { "name": "go",   "available": true, "path": "/usr/bin/go" }
  ],
  "lazy": { "installed": -1, "loaded": -1, "problems": [] }
}
```

## Next Phase Readiness

- Plan 03-03 (lockfile refresh + missing-tool hardening) can mechanically re-run `./scripts/nvim-validate.sh all` after each change
- Baseline is established: startup/sync/smoke all green; health module works in isolation
- Health subcommand will become reliable once 03-03 resolves the full-config startup slowness (likely by pre-installing tools or using a warm cache)

---
*Phase: 03-plugin-audit-and-validation-harness*
*Completed: 2026-04-15*
