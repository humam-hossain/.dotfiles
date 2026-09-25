---
phase: 41-end-to-end-verification-repository-integrity
plan: "01"
subsystem: testing
tags:
  - integration
  - verification
  - symlinks
  - power-profiles
  - media-controls
  - quickshell
requires: []
provides:
  - scripts/phase41-interactions-assert.sh
affects:
  - scripts/phase41-interactions-assert.sh
tech-stack:
  added: []
  patterns:
    - two-tier testing (hard static AST / soft live IPC)
    - atomic signal trap rollback (trap cleanup EXIT INT TERM)
    - headless Node.js coordinate simulation
key-files:
  created:
    - scripts/phase41-interactions-assert.sh
  modified: []
key-decisions:
  - "D-01: Modular harness architecture with --section, --quick, and sub-harness orchestration"
  - "D-04: Two-tier gating with hard AST fails and soft live desktop skips"
  - "D-07: Atomic power profile state rollback to INITIAL_PROFILE via signal traps"
requirements:
  - INTG-01
  - INTG-02
duration: "7 min"
completed: "2026-09-25T11:40:30Z"
coverage:
  - deliverable: "Milestone v0.8 Integration Harness Scaffold & Prerequisite Gating"
    verification:
      kind: "command"
      ref: "./scripts/phase41-interactions-assert.sh --syntax"
      status: "pass"
    human_judgment: false
  - deliverable: "Section 1 Restow Leaf Symlink and Submodule Cleanliness Assertions"
    verification:
      kind: "command"
      ref: "./scripts/phase41-interactions-assert.sh --section 1"
      status: "pass"
    human_judgment: false
  - deliverable: "Section 2 Power Profiles Daemon Verification & Atomic State Rollback"
    verification:
      kind: "command"
      ref: "./scripts/phase41-interactions-assert.sh --section 2"
      status: "pass"
    human_judgment: false
  - deliverable: "Section 3 Media Popup Anchoring AST & Headless Coordinate Clamping Simulation"
    verification:
      kind: "command"
      ref: "./scripts/phase41-interactions-assert.sh --section 3"
      status: "pass"
    human_judgment: false
---

# Phase 41 Plan 01: Milestone v0.8 Integration Engine Scaffold & Foundation Summary

Scaffolded the Milestone v0.8 Integration & Verification Engine (`scripts/phase41-interactions-assert.sh`) with root EUID gating, CLI argument parsing (`--section`, `--quick`, `--syntax`, `--live-notify`), prerequisite binary checks across 9 tools, Section 1 (Restow Symlink Isolation & Tree Topology), Section 2 (Power Profiles Daemon & Safe Rollback), and Section 3 (Dynamic Media Popup Positioning & Clamping).

## Key Accomplishments

1. **Test Runner Foundation & Prerequisite Gating (INTG-02, D-01, D-03, D-05, T-41-01):**
   - Implemented non-root EUID check failing closed.
   - Built CLI argument parser supporting `--section <1-6>`, `--quick`/`--standalone`, `--syntax`/`-c`, and `--live-notify`/`-l`.
   - Verified 9 prerequisite binaries (`bash`, `jq`, `node`, `lua`, `luac`, `powerprofilesctl`, `wpctl`, `qs`, `git`) available on `$PATH`.
   - Wired working-tree porcelain baseline snapshots to `/tmp` via randomized `mktemp` and signal cleanup.

2. **Section 1: Restow Symlink Isolation & Tree Topology (INTG-01, D-02, D-09, T-41-01):**
   - Verified `vendor/dots-hyprland` submodule has 0 uncommitted modifications.
   - Validated all 11 restow QML overlays exist and resolve as valid leaf symlinks into `$HOME/.config/quickshell/ii/` pointing to the canonical repository sources.
   - Enforced directory folding prevention across all 11 parent directories in the live quickshell hierarchy.

3. **Section 2: Power Profiles Daemon & Safe Rollback (POWER-01..03, D-02, D-07, T-41-01):**
   - Verified `power-profiles-daemon` package installed via pacman and manifested in `arch/pkglist-native.txt`.
   - Confirmed zero local QML overrides for upstream `PowerProfilesToggle.qml` or `AndroidPowerProfileToggle.qml`.
   - Verified active `power-profiles-daemon.service`, captured initial profile (`balanced`), cycled through `power-saver`, `balanced`, and `performance`, and executed atomic signal-trapped rollback to initial state.

4. **Section 3: Dynamic Media Popup Positioning & Clamping (MEDIA-01..02, D-02):**
   - Validated `MediaControls.qml` AST tokens (`GlobalStates.mediaPillScreen`, `GlobalStates.mediaPillCenterX`, `Math.round`, `hyprlandGapsOut`, `Math.max`, `Math.min`).
   - Verified `GlobalStates.qml` property declarations (`mediaPillCenterX`, `mediaPillCenterY`, `mediaPillScreen`).
   - Evaluated coordinate clamping logic in headless Node.js VM across 3 scenarios: standard center (760), right edge clamp (1510), and fallback center (760).
   - Validated live Wayland monitor queries via `hyprctl` and active Quickshell `-c ii` profile process.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- `scripts/phase41-interactions-assert.sh` exists on disk and is executable.
- `git log` confirms commits for Task 1 tracer (`8ecbbac`), Task 2 Section 1 (`2de3987`), and Task 3 Sections 2 & 3 (`7ee67dd`).
- Verification suite passes cleanly:
  * `./scripts/phase41-interactions-assert.sh --syntax`: FAIL=0 FINDINGS=0
  * `./scripts/phase41-interactions-assert.sh --section 1`: FAIL=0 FINDINGS=0
  * `./scripts/phase41-interactions-assert.sh --section 2`: FAIL=0 FINDINGS=0
  * `./scripts/phase41-interactions-assert.sh --section 3`: FAIL=0 FINDINGS=0
