---
phase: 02-core-bar-modules
verified: "2026-07-21T18:33:16Z"
status: human_needed
score: 12/12 must-haves present in code
behavior_unverified: 4
behavior_unverified_items:
  - "G-02-4 clock click opens/pins ClockWidgetPopup (visual)"
  - "G-02-7a left bar without ActiveWindow has enough workspace room (visual)"
  - "G-02-7b/G-02-8 always-visible full indicator strip (visual)"
  - "Indicators pill click still toggles right sidebar (visual)"
next_action: "Re-run human UAT for gap fixes then mark phase complete"
next_command: "/gsd-verify-work 2"
---

# Phase 2: Core Bar Modules — Verification Report

**Phase Goal:** Implement the four most essential bar modules — workspaces, clock, system tray, and network — giving the bar its core day-to-day functionality.

**Verified:** 2026-07-21T18:33:16Z  
**Status:** human_needed (all code must-haves present; gap-closure re-UAT pending)  
**Verifier:** orchestrator-inline after gap plans 02-06..02-08

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Hyprland workspace indicators with stock click/wheel dispatch | ✓ VERIFIED | `Workspaces.qml` dispatches `workspace ${id}` and `workspace r±1`; no plugin focus |
| 2 | Left layout: sidebar → workspaces → resources (no ActiveWindow) | ✓ CODE | G-02-7a: ActiveWindow instantiation removed; comment marks UAT intent |
| 3 | Clock shows system time; format/seconds via live config | ✓ VERIFIED | `phase02-config-assert.py` exit 0; ClockWidget binds DateTime |
| 4 | Clock click pins popup; hover still works | ✓ CODE / ⚠ HUMAN | forceActive + onClicked present; visual click/pin needs re-UAT (G-02-4) |
| 5 | SysTray present on right after Media/Battery | ✓ VERIFIED | BarContent right order Media → Battery → SysTray → Indicators |
| 6 | Network icon-only on bar (materialSymbol); SSID via sidebar | ✓ VERIFIED | `Network.materialSymbol`; no SSID text in indicators |
| 7 | Always-visible D-19 indicator strip | ✓ CODE / ⚠ HUMAN | mute/mic/BT/Network/notif always mounted; order verified; visual re-UAT (G-02-7b/8) |
| 8 | Configuration Loaded smoke | ✓ VERIFIED | `timeout 4 quickshell` → Configuration Loaded |

**Score:** 12/12 code truths present; 4 need human visual confirmation after gap closure

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/phase02-config-assert.py` | Live config asserts | ✓ EXISTS + GREEN | exit 0 |
| `Config.qml` + live config.json | Dual-write defaults | ✓ GREEN | assert script |
| `BarContent.qml` | D-15 layout + D-19 strip | ✓ SUBSTANTIVE | post 02-07/02-08 |
| `StyledPopup.qml` | forceActive pin | ✓ SUBSTANTIVE | default false |
| `ClockWidget.qml` | onClicked toggle pin | ✓ SUBSTANTIVE | hoverTarget preserved |
| `Workspaces.qml` | stock dispatch | ✓ SUBSTANTIVE | workspace $ / r±1 |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| ClockWidget MouseArea | ClockWidgetPopup | onClicked → forceActive | ✓ WIRED |
| StyledPopup | PanelWindow | active: forceActive \|\| containsMouse | ✓ WIRED |
| leftSectionRowLayout | Workspaces | no ActiveWindow | ✓ WIRED |
| indicatorsRowLayout | mute/mic/xkb/BT/Network/notif | always-visible MaterialSymbols | ✓ WIRED |
| rightSidebarButton | GlobalStates.sidebarRightOpen | onPressed toggle | ✓ WIRED |
| Workspaces | Hyprland | workspace dispatch | ✓ WIRED |

## Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| BAR-01 Workspaces | ✓ CODE / ⚠ HUMAN | Click/wheel previously UAT-pass; ActiveWindow removal needs visual room check |
| BAR-02 Clock | ✓ CODE / ⚠ HUMAN | Click-to-open was UAT fail; code fixed — retest click pin |
| BAR-03 Tray | ✓ SATISFIED | Prior UAT pass; SysTray still present |
| BAR-04 Network/indicators | ✓ CODE / ⚠ HUMAN | Full strip code-fixed; retest visual strip + sidebar pill |

## Gap Closure Cross-Check

| Gap | Plan | Code status | Human retest |
|-----|------|-------------|--------------|
| G-02-4 | 02-06 | forceActive + onClicked | pending |
| G-02-7a | 02-07 | ActiveWindow removed | pending |
| G-02-7b | 02-08 | always-visible strip | pending |
| G-02-8 | 02-08 | D-19 order + spacing | pending |

## Plans Cross-Check

| Plan | SUMMARY | Commits | Spot-check |
|------|---------|---------|------------|
| 02-01 | ✓ | present | assert script |
| 02-02 | ✓ | present | config green |
| 02-03 | ✓ | present | left/center layout |
| 02-04 | ✓ | present | right LTR |
| 02-05 | ✓ | present | gates |
| 02-06 | ✓ | 3a852d3, 14eea6e, 5360a1c | forceActive/onClicked |
| 02-07 | ✓ | 113b10a, 1672e8c | no ActiveWindow {} |
| 02-08 | ✓ | 71022b9, 1672e8c | always-visible strip |

## Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| runtime | bluez DBus unavailable | info | Bluetooth shows bluetooth_disabled (intended always-visible path) |
| runtime | polkit agent already exists | info | Pre-existing multi-agent warning; non-blocking |

**Anti-patterns:** 0 blockers

## Human Verification

1. **Clock click opens/pins popup (G-02-4)**
   - expected: Click clock → popup with date/uptime/todos stays; second click unpins; hover still works when unpinned
   - how: Click center clock on bar; confirm not Google Calendar

2. **No ActiveWindow on left; workspaces usable (G-02-7a)**
   - expected: Left is sidebar → workspaces → resources; no window-title strip; workspaces click/wheel still work
   - how: Inspect left bar; click workspace

3. **Full indicator strip (G-02-7b / G-02-8)**
   - expected: mute, mic, Bluetooth, Network, notif always visible (xkb if multi-layout); no large empty gap after network
   - how: Inspect right indicators pill at idle

4. **Indicators pill still opens right sidebar**
   - expected: Click anywhere on indicators pill toggles right sidebar
   - how: Click pill

## Gaps

None requiring additional code plans. Remaining work is human re-UAT only for items above.

## Regression

- Phase 1 shell still loads (`shell.qml` present; Configuration Loaded)
- No automated unit suite beyond phase02-config-assert + smoke

---
*Phase: 02-core-bar-modules*  
*Verification after gap-closure wave 6*
