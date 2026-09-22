---
phase: 38-power-profiles-daemon-system-integration
plan: 01
subsystem: infra
tags: [power-profiles-daemon, upower, quickshell, dbus, arch-linux, systemd, bootstrap]

# Dependency graph
requires:
  - phase: 37-voice-pill-bar-layout-integration-dual-monitor-verification-and-strict-packaging
    provides: "Established assert harness patterns, headless Quickshell test runner, and strict verification invariants"
provides:
  - "Arch Linux power-profiles-daemon installation and systemd service activation"
  - "Authoritative package tracking in arch/pkglist-native.txt"
  - "Idempotent bootstrap.sh package checking and service enablement"
  - "Strict upstream zero-override Quickshell toggle parity"
  - "Automated 5-section test harness scripts/phase38-power-profiles-assert.sh"
affects: [quickshell, bootstrap, packaging, power-management]

# Actuals
actuals:
  tokens: 18500
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: [power-profiles-daemon]
  patterns: [idempotent-service-activation, headless-quickshell-upower-assertion, zero-override-upstream-parity]

key-files:
  created:
    - "scripts/phase38-power-profiles-assert.sh"
  modified:
    - "arch/pkglist-native.txt"
    - "bootstrap.sh"

key-decisions:
  - "D-01: Preserved strict upstream parity with zero local QML overrides in restow/quickshell/"
  - "D-04: Added power-profiles-daemon to arch/pkglist-native.txt strictly in LC_ALL=C alphabetical order between playerctl and python"
  - "D-05/D-06: Added idempotent package check and systemctl is-active guard in bootstrap.sh step_packages"
  - "D-07: Maintained zero runtime coupling in arch/dots-hyprland.sh verify --strict"

patterns-established:
  - "Idempotent package & service activation pre-checks in bootstrap.sh"
  - "Headless Quickshell UPower PowerProfiles QML test runner in assert harness"

requirements-completed:
  - POWER-01
  - POWER-02
  - POWER-03

# Coverage metadata
coverage:
  - id: D1
    description: "power-profiles-daemon is installed on Arch Linux and power-profiles-daemon.service is actively running and enabled"
    requirement: "POWER-01"
    verification:
      - kind: integration
        ref: "./scripts/phase38-power-profiles-assert.sh --section 1 && ./scripts/phase38-power-profiles-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Quickshell upstream quick-toggle PowerProfilesToggle.qml cycles Power Saver -> Balanced -> Performance via native Quickshell.Services.UPower with zero local QML overrides"
    requirement: "POWER-02"
    verification:
      - kind: e2e
        ref: "./scripts/phase38-power-profiles-assert.sh --section 3 && ./scripts/phase38-power-profiles-assert.sh --section 5"
        status: pass
    human_judgment: false
  - id: D3
    description: "Package manifest arch/pkglist-native.txt and bootstrap.sh updated with idempotent power-profiles-daemon check and activation"
    requirement: "POWER-03"
    verification:
      - kind: integration
        ref: "./scripts/phase38-power-profiles-assert.sh --section 1 && ./scripts/phase38-power-profiles-assert.sh --section 4"
        status: pass
    human_judgment: false
  - id: D4
    description: "Strict repository integrity verification via arch/dots-hyprland.sh verify --strict with 0 findings and zero git working tree churn"
    requirement: "POWER-03"
    verification:
      - kind: unit
        ref: "./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

# Metrics
duration: 9 min
completed: 2026-09-23
status: complete
---

# Phase 38 Plan 01: Power Profiles Daemon System Integration Summary

**Integrated power-profiles-daemon system service on Arch Linux, tracked in package manifests and idempotent bootstrap, verified live Quickshell UPower D-Bus binding with strict zero local QML overrides and clean repository integrity.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-22T23:59:00Z
- **Completed:** 2026-09-23T00:08:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Installed `power-profiles-daemon` 0.30-1 and enabled `power-profiles-daemon.service` on system level, verifying live D-Bus responsiveness on `net.hadess.PowerProfiles` and profile listing via `powerprofilesctl`.
- Updated authoritative package manifest `arch/pkglist-native.txt` with `power-profiles-daemon` in strict `LC_ALL=C` alphabetical order between `playerctl` and `python` with validated sorting.
- Hardened root `bootstrap.sh` in `step_packages` with idempotent package existence check, dry-run preview messaging, and pre-checked `systemctl is-active` service activation before sudo.
- Constructed executable 5-section assertion test harness at `scripts/phase38-power-profiles-assert.sh` verifying package installation, systemd/D-Bus state, zero-override upstream QML parity (D-01), bootstrap idempotency, headless Quickshell UPower binding, and strict repository cleanliness.
- Verified `./arch/dots-hyprland.sh verify --strict` exits 0 with 0 findings and zero git working-tree churn.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — Power Profiles Daemon installation, service activation, and D-Bus / Quickshell UPower end-to-end verification** - `f6d0234` (test)
2. **Task 2: Repository manifest tracking in pkglist-native.txt and idempotent bootstrap.sh integration** - `15e91b6` (feat)
3. **Task 3: Complete 5-section assertion test harness, zero-override invariant, and strict repository verification** - `cee30d3` (test)

## Files Created/Modified

- `scripts/phase38-power-profiles-assert.sh` - Automated 5-section assertion test harness validating the full power profiles stack and repository integrity.
- `arch/pkglist-native.txt` - Authoritative native Arch Linux package manifest containing `power-profiles-daemon` in alphabetical order.
- `bootstrap.sh` - Root bootstrap orchestrator with idempotent `power-profiles-daemon` check and activation in `step_packages`.

## Decisions Made

- **D-01 (Strict Upstream Parity):** Preserved upstream `dots-hyprland` power profiles implementation 100% as-is with zero local overrides in `restow/quickshell/`.
- **D-02 (Native 3-State Cycling):** Leveraged upstream `PowerProfilesToggle.qml` which natively communicates with `net.hadess.PowerProfiles` via `Quickshell.Services.UPower`.
- **D-04 (Package Tracking):** Positioned `power-profiles-daemon` strictly between `playerctl` and `python` in `arch/pkglist-native.txt`.
- **D-05/D-06 (Idempotent Bootstrap):** Added pre-checks with `pacman -Q` and `systemctl is-active --quiet` so subsequent `./bootstrap.sh` runs perform zero unnecessary operations.
- **D-07 (Repository Integrity):** Preserved strict focus of `arch/dots-hyprland.sh verify --strict` without introducing runtime daemon dependencies.

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates

- **sudo authentication for power-profiles-daemon installation and systemd enablement:** Handled via interactive checkpoint where the operator executed `sudo pacman -S --needed --noconfirm power-profiles-daemon && sudo systemctl enable --now power-profiles-daemon.service` in terminal, verified and resumed successfully.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 38 completed with all requirements verified.
- Power profile switching is operational system-wide and directly accessible in the Quickshell Right Sidebar quick toggles.

---
*Phase: 38-power-profiles-daemon-system-integration*
*Completed: 2026-09-23*
