---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 09
subsystem: config
tags: [stow, restow, config-redistribution, reader-scan, assert, fixtures]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 06
    provides: "removal of repo-root .config/ and redistribution of hyprland configs"
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 07
    provides: "capture fixture assertions"
provides:
  - "scripts/nvim-validate.sh — retargeted to stow/nvim/"
  - "scripts/nvim-audit-failures.sh — retargeted to stow/nvim/"
  - "arch/system_monitor.sh — retargeted to stow/system_monitor/"
  - ".planning/todos/backlog-legacy-config-readers.md — out-of-scope reader census"
  - "scripts/phase13-d19-assert.sh — repointed fixtures to stow/hypr/ and re-pinned wrapper base"
  - "scripts/phase14-verify.sh — repointed fixtures to stow/hypr/, restow/hypr/, and docs/archive/"
  - "scripts/phase18-capture-model-assert.sh — Section 6 repo-root config removal and reader scan"
affects: [18-10, 18-11]

# Actuals
actuals:
  tokens: 22000
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Retarget live tooling from legacy repo-root paths to stow/ packages"
    - "Closed-phase assert preservation: in-place fixture repoints with BALANCED numstat"
    - "Doubly-anchored regex scan policing both bare/cwd-relative and variable-anchored retired paths"
    - "Vacuity guards ensuring non-vacuous absence assertions over deleted paths"

key-files:
  created:
    - .planning/todos/backlog-legacy-config-readers.md
  modified:
    - scripts/nvim-validate.sh
    - scripts/nvim-audit-failures.sh
    - arch/system_monitor.sh
    - scripts/phase13-d19-assert.sh
    - scripts/phase14-verify.sh
    - scripts/phase18-capture-model-assert.sh

key-decisions:
  - "Retarget all 14 sites in scripts/nvim-validate.sh and 1 site in scripts/nvim-audit-failures.sh to stow/nvim/"
  - "Retarget MONITOR_SRC in arch/system_monitor.sh to stow/system_monitor/ while preserving live destination and fetcher paths"
  - "Log out-of-scope legacy readers in ubuntu/ and debian/ (30 files / 53 lines) to .planning/todos/backlog-legacy-config-readers.md"
  - "Repoint fixture paths in scripts/phase13-d19-assert.sh to stow/hypr/ with balanced numstat; both closed asserts run green"
  - "Repoint fixture paths in scripts/phase14-verify.sh to stow/hypr/, restow/hypr/, and docs/archive/ with balanced numstat"
  - "Add Section 6 to scripts/phase18-capture-model-assert.sh verifying .config absence, 12 destinations present, vacuity guards, and doubly-anchored scan excluding phase17 assert, wrapper delete guard, and self"

requirements-completed: [FIX-03]

coverage:
  - id: D1
    description: "live scripts retargeted to stow/ with zero surviving repo-root references"
    requirement: "FIX-03"
    verification:
      - kind: automated
        ref: "! grep -q -- 'REPO_ROOT/\\.config/' scripts/nvim-validate.sh scripts/nvim-audit-failures.sh arch/system_monitor.sh"
        status: pass
      human_judgment: false
  - id: D2
    description: "closed-phase asserts repointed in-place and run green"
    requirement: "FIX-03"
    verification:
      - kind: automated
        ref: "./scripts/phase13-d19-assert.sh && ./scripts/phase14-verify.sh (both exit 0)"
        status: pass
      human_judgment: false
  - id: D3
    description: "section 6 asserts .config absent, all 12 destinations exist, and no in-scope reader exists"
    requirement: "FIX-03"
    verification:
      - kind: automated
        ref: "./scripts/phase18-capture-model-assert.sh (Section 6 passes; 0 FAIL)"
        status: pass
      human_judgment: false

# Metrics
duration: 20 min
completed: 2026-09-14
status: complete
---

# Phase 18 Plan 09: Legacy Config Readers Retargeting and Section 6 Assert Summary

**Retargeted live scripts (`nvim-validate.sh`, `nvim-audit-failures.sh`, `system_monitor.sh`) to the `stow/` tree, repointed fixtures in closed-phase asserts (`phase13-d19-assert.sh` and `phase14-verify.sh`), logged the legacy readers backlog, and added Section 6 to `scripts/phase18-capture-model-assert.sh`.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-14T01:23:45Z
- **Completed:** 2026-09-14T01:28:30Z
- **Tasks:** 3
- **Files modified:** 7 (1 created, 6 modified)

## Accomplishments

1. **Retarget Live Readers & Log Backlog (Task 1):**
   - Retargeted all 14 occurrences in [scripts/nvim-validate.sh](file:///home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh) to `stow/nvim/.config/nvim`.
   - Retargeted `NVIM_CONFIG` in [scripts/nvim-audit-failures.sh](file:///home/pera/github_repo/.dotfiles/scripts/nvim-audit-failures.sh) to `stow/nvim/.config/nvim`.
   - Retargeted `MONITOR_SRC` in [arch/system_monitor.sh](file:///home/pera/github_repo/.dotfiles/arch/system_monitor.sh) to `stow/system_monitor/.config/system_monitor/ping`.
   - Created [.planning/todos/backlog-legacy-config-readers.md](file:///home/pera/github_repo/.dotfiles/.planning/todos/backlog-legacy-config-readers.md) recording the 30 files / 53 lines census across `ubuntu/` and `debian/`.

2. **Repoint Closed-Phase Asserts (Task 2):**
   - Repointed fixture paths in [scripts/phase13-d19-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase13-d19-assert.sh) to `stow/hypr/` and updated `WRAPPER_BASE` pin to `8497511` with balanced diff (10 lines added, 10 deleted).
   - Repointed `OVERLAY_GENERAL` to `stow/hypr/`, `REPO_HYPRCONF` to `docs/archive/`, `REPO_LAUNCHER` to `restow/hypr/`, and `BASELINE` to the archived v0.3 milestone path in [scripts/phase14-verify.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase14-verify.sh) with balanced diff (6 lines added, 6 deleted).
   - Both `./scripts/phase13-d19-assert.sh` and `./scripts/phase14-verify.sh` run completely green (`FAIL=0`).

3. **Assert Section 6 (Task 3):**
   - Added Section 6 to [scripts/phase18-capture-model-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase18-capture-model-assert.sh):
     - 6a: Asserts `.config/` is absent from filesystem and untracked in git.
     - 6b: Iterates over [docs/config-redistribution.md](file:///home/pera/github_repo/.dotfiles/docs/config-redistribution.md) destination column and asserts all 12 destinations exist on disk.
     - 6c: Vacuity guards over `arch/` and `scripts/`, followed by a doubly-anchored scan for bare/cwd-relative and `$REPO_ROOT`-relative paths for the 12 moved configurations, excluding `phase17-unblock-assert.sh`, `dots-hyprland.sh` delete guard, and `phase18-capture-model-assert.sh`.
     - Emits `[INFO]` pointing to the backlog document.

## Verification Results

- `test ! -e .config && [ -z "$(git ls-files -- .config/)" ]`: PASS
- `./scripts/phase13-d19-assert.sh`: PASS (`FAIL=0`)
- `./scripts/phase14-verify.sh`: PASS (`FAIL=0 FINDINGS=0`)
- `./scripts/phase18-capture-model-assert.sh`: PASS (`FAIL=0 FINDINGS=0`)
- `git status --porcelain`: Clean
