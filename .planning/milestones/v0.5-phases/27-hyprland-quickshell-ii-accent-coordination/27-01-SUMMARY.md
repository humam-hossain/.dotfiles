---
phase: 27-hyprland-quickshell-ii-accent-coordination
plan: "01"
subsystem: testing
tags: [hyprland, quickshell, material-you, guard-paths, testing, assert-harness]

requires:
  - phase: 26-qt-kde-apps-material-you-harmonization
    provides: Qt and KDE Material You assert harness patterns and guard-paths tab contract
provides:
  - Phase 27 test assert harness (scripts/phase27-accent-coordination-assert.sh) with 5-section architecture
  - Verified guard-paths.tsv exclusion for $XDG_CONFIG_HOME/hypr/hyprland/colors.lua
  - Automated verification of Matugen hyprland templates, live colors.lua existence, and upstream overlay purity
affects: [27-02, 27-03, 29-integration-verification]

actuals:
  tokens: 28000
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - Fail-closed sectioned bash assert harness with cleanup trap and git porcelain snapshot invariant
    - Upstream overlay purity assertion with zero border overrides in custom/general.lua

key-files:
  created:
    - scripts/phase27-accent-coordination-assert.sh
  modified: []

key-decisions:
  - "D-29: Scaffold 5-section fail-closed bash test harness (scripts/phase27-accent-coordination-assert.sh) adhering to dotfiles assert conventions"
  - "INTG-01: Verify $XDG_CONFIG_HOME/hypr/hyprland/colors.lua is strictly guarded in guard-paths.tsv with tab-separated generated_theme classification"
  - "D-01..D-03, D-08, SHELL-01: Verify vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua binds required border, background, and pinned rule tokens"
  - "D-04: Enforce upstream overlay purity in stow/hypr/.config/hypr/custom/general.lua with zero personal border overrides"

patterns-established:
  - "Phase 27 5-section assert harness architecture with --section <1-5> support and git status snapshot comparison"

requirements-completed: [SHELL-01, INTG-01]

coverage:
  - id: D-01..D-03, D-08
    description: "Matugen hyprland template token bindings for active/inactive borders, canvas background, and pinned window rules"
    requirement: SHELL-01
    verification:
      - kind: automated
        ref: "scripts/phase27-accent-coordination-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: INTG-01
    description: "guard-paths.tsv verifies $XDG_CONFIG_HOME/hypr/hyprland/colors.lua strictly guarded as generated_theme"
    requirement: INTG-01
    verification:
      - kind: automated
        ref: "scripts/phase27-accent-coordination-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D-04
    description: "stow/hypr/.config/hypr/custom/general.lua maintains upstream overlay purity with zero personal border overrides"
    requirement: SHELL-01
    verification:
      - kind: automated
        ref: "scripts/phase27-accent-coordination-assert.sh --section 1"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-09-17
status: complete
---

# Phase 27 Plan 01: Assert Harness Scaffolding & Section 1 Readiness Summary

**Scaffolded the 5-section Phase 27 assertion harness (`scripts/phase27-accent-coordination-assert.sh`), verified strict `guard-paths.tsv` data contract protection for `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua`, and verified Section 1 Matugen template token declarations and upstream overlay purity with zero failures.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-17T14:34:00+06:00
- **Completed:** 2026-09-17T14:35:00+06:00
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Scaffolded `scripts/phase27-accent-coordination-assert.sh` (mode 0755) with fail-closed structure, cleanup trap, `--section <1-5>` CLI parsing, and pre/post git porcelain snapshot checks (D-29).
- Verified Section 1: confirmed vendor Matugen hyprland template declares token bindings for `active_border` (outline_variant 77%), `inactive_border` (surface_container_low 33%), `background_color` (surface.dark FF%), and pinned window rule `border_color` (primary accent gradient) (D-01..D-03, D-08, SHELL-01).
- Confirmed live `~/.config/hypr/hyprland/colors.lua` exists, is non-empty, and has valid syntax.
- Confirmed `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` is registered in `guard-paths.tsv` with tab-separated `generated_theme` classification and `matugen` generator (INTG-01).
- Confirmed `stow/hypr/.config/hypr/custom/general.lua` preserves upstream overlay purity with zero personal border or color overrides (D-04).

## Task Commits

1. **Task 1 & Task 2: Scaffold Phase 27 accent coordination assertion harness and implement Section 1** - `ead8785` (`feat(27-01): scaffold phase 27 accent coordination assert harness and section 1`)

## Verification Output

```text
[INFO] --- Section 1: Template & Config Readiness (INTG-01, D-01..D-04, D-08) ---
[PASS] S1: Matugen hyprland colors template declares active, inactive, background, and pinned border tokens (D-01..D-03, D-08)
[PASS] S1: Live colors.lua exists and is non-empty (/home/pera/.config/hypr/hyprland/colors.lua)
[PASS] S1: guard-paths.tsv guards $XDG_CONFIG_HOME/hypr/hyprland/colors.lua (INTG-01)
[PASS] S1: colors.lua guard entry strictly tab-separated (INTG-01)
[PASS] S1: stow/hypr/.config/hypr/custom/general.lua maintains upstream overlay purity (zero border overrides) (D-04)
[PASS] Closing self-check: git status --porcelain unchanged across run (D-28)
=== done: FAIL=0 FINDINGS=0 ===
```
