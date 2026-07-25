---
phase: 01-shell-foundation-theme
plan: 03
subsystem: infra
tags: [quickshell, startup, services, shapes, hard-errors]

requires:
  - phase: 01-01
    provides: Wholesale ii quickshell tree and PanelLoader architecture
  - phase: 01-02
    provides: Theme generation path and colors.json
provides:
  - Quickshell launches with Configuration Loaded (no hard crash)
  - IllogicalImpulseFamily bar renders on connected monitors (Variants over Quickshell.screens)
  - Service singletons initialize (MaterialThemeLoader, GlobalFocusGrab, Translation, etc.)
  - Vendored rounded-polygon shapes module under modules/common/widgets/shapes/
affects: [phase-2-core-bar-modules]

tech-stack:
  added: [end-4/rounded-polygon-qmljs shapes module vendored, optional syntax-highlighting package]
  patterns: [fix hard startup only; leave non-fatal warnings; multi-monitor Bar via Variants]

key-files:
  created:
    - .config/quickshell/modules/common/widgets/shapes/ (vendored submodule contents)
  modified:
    - .config/quickshell/modules/ii/sidebarLeft/aiChat/MessageCodeBlock.qml
    - arch/quickshell.sh

key-decisions:
  - "Vendor shapes submodule files into the tree (not nested git submodule) so copy is self-contained"
  - "Degrade AI code blocks to plain monospace when org.kde.syntaxhighlighting is missing rather than blocking shell load"
  - "Full arch/quickshell.sh package install still requires local sudo; verified launch with existing quickshell + generated colors.json"

patterns-established:
  - "Hard-error fixes only at startup; non-fatal FileView missing-state warnings left alone"
  - "dots-hyprland submodules must be initialized before wholesale copy is complete"

requirements-completed: [FWK-05]

coverage:
  - id: D1
    description: "quickshell launches without crash (Configuration Loaded)"
    requirement: FWK-05
    verification:
      - kind: other
        ref: "timeout 4 quickshell → exit 124 + 'Configuration Loaded'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Visible bar layer on every connected monitor (DP-1; HDMI-A-2 not connected this session)"
    requirement: FWK-05
    verification:
      - kind: other
        ref: "hyprctl layers shows quickshell:bar on DP-1; Bar.qml Variants over Quickshell.screens"
        status: pass
    human_judgment: true
    rationale: "Visual bar adequacy and multi-monitor when HDMI attached need human glance; automation confirmed layer presence on currently connected monitor"
  - id: D3
    description: "Service singletons initialize (MaterialThemeLoader path + GlobalFocusGrab/Translation debug)"
    requirement: FWK-05
    verification:
      - kind: other
        ref: "log: GlobalFocusGrab Initialized; Translation Language changed; MaterialThemeLoader active (warn only on m3primaryDim)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-21
status: complete
---

# Phase 1 Plan 03: Integration and Service Singleton Verification Summary

**Quickshell launches successfully with IllogicalImpulseFamily bar and service singletons after fixing empty shapes submodule and hard syntax-highlighting import**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-07-21T11:42:00Z
- **Completed:** 2026-07-21T11:55:00Z
- **Tasks:** 1/1
- **Files modified:** shapes tree + MessageCodeBlock.qml + arch/quickshell.sh

## Accomplishments

- Initialized and vendored `rounded-polygon-qmljs` shapes content (was an empty git submodule after 01-01 copy)
- Softened MessageCodeBlock so missing `org.kde.syntaxhighlighting` no longer blocks shell load
- Confirmed `Configuration Loaded`, `quickshell:bar` layer on DP-1, and service singleton init (GlobalFocusGrab, Translation, MaterialThemeLoader)

## Task Commits

1. **Task 1: Execute and Fix Hard Startup Errors** - `ec7c514` (feat)

**Plan metadata:** (this SUMMARY commit)

## Files Created/Modified

- `.config/quickshell/modules/common/widgets/shapes/**` — ShapeCanvas, material-shapes.js, geometry/shapes helpers
- `.config/quickshell/modules/ii/sidebarLeft/aiChat/MessageCodeBlock.qml` — optional syntax highlighting
- `arch/quickshell.sh` — add `syntax-highlighting` package for future full AI code highlighting

## Decisions Made

- Only fixed hard load failures; left non-fatal warnings (missing config/state files, bluez, notification server already registered by swaync, m3primaryDim property mismatch)
- Did not remove AI/Booru/SongRec services; only made MessageCodeBlock not hard-depend on KDE syntax highlighting
- Did not modify `../dots-hyprland/` source (submodule init was in that repo for copy source only; vendored into our tree)

## Deviations from Plan

### Auto-fixed Issues

**1. [Hard startup] Empty shapes submodule**
- **Found during:** Task 1
- **Issue:** `modules/common/widgets/shapes` was an uninitialized git submodule; MaterialShape failed with module not installed
- **Fix:** `git submodule update --init` in dots-hyprland source, rsync contents (exclude `.git`) into our tree
- **Files modified:** `.config/quickshell/modules/common/widgets/shapes/**`
- **Verification:** Next error moved past MaterialShape

**2. [Hard startup] org.kde.syntaxhighlighting not installed**
- **Found during:** Task 1
- **Issue:** MessageCodeBlock import blocked entire IllogicalImpulseFamily load; could not `yay`/`pacman` install without sudo
- **Fix:** Remove hard import; plain monospace code blocks; add package to PACKAGES for later provision
- **Files modified:** MessageCodeBlock.qml, arch/quickshell.sh
- **Verification:** `Configuration Loaded`; process stays up under timeout

**3. [Environment] Full arch/quickshell.sh not run end-to-end**
- **Found during:** Task 1
- **Issue:** `install_packages` / `setup_i2c` need sudo password
- **Fix:** Used existing quickshell binary, existing symlink `~/.config/quickshell` → repo, and colors.json from 01-02
- **Verification:** Launch succeeded with that subset

## Issues Encountered

- Only monitor DP-1 was connected (HDMI-A-2 not present). Bar.qml uses `Variants` over `Quickshell.screens`, so additional monitors get bars when attached.
- Soft warnings remain: missing `~/.config/illogical-impulse/config.json`, `m3primaryDim` property, notification server owned by swaync, bluez D-Bus. Not hard crashes.

## Self-Check: PASSED

- [x] `timeout 4 quickshell` → Configuration Loaded (exit 124 = still running)
- [x] `hyprctl layers` shows `quickshell:bar` on DP-1
- [x] Service singletons log init without hard crash
- [x] Directory structure FWK-05: modules/, services/, scripts/, defaults/, assets/, panelFamilies present
