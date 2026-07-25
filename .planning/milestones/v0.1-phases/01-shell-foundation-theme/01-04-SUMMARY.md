---
phase: 01-shell-foundation-theme
plan: 04
subsystem: shell
tags: [quickshell, fonts, bar, gap-closure, material-symbols]

requires:
  - phase: 01-03
    provides: Working shell launch and bar layer
provides:
  - Material Symbols font available (user-local + package scripts)
  - Config font fallbacks to installed families
  - Workspaces.widgetPadding + stock Hyprland workspace dispatch
  - notifications.monitor key alignment
  - Appearance m3*Dim / palette key properties for theme reapply
affects: [phase-2-core-bar-modules, UAT re-verify]

tech-stack:
  added: [ttf-material-symbols-variable (provisioned), Material Symbols Rounded user fonts]
  patterns: [stock hyprland workspace dispatch; Config defaults match installed fonts]

key-files:
  created: []
  modified:
    - arch/fonts.sh
    - arch/quickshell.sh
    - .config/quickshell/modules/common/Config.qml
    - .config/quickshell/modules/common/Appearance.qml
    - .config/quickshell/modules/ii/bar/Workspaces.qml
    - .config/quickshell/modules/ii/notificationPopup/NotificationPopup.qml
    - .config/quickshell/modules/settings/InterfaceConfig.qml

key-decisions:
  - "User-local Material Symbols install when sudo unavailable; scripts still install system package"
  - "Font defaults → Noto Sans + JetBrainsMono Nerd Font (not Google Sans Flex)"
  - "Replace hl.dsp.focus with stock workspace dispatcher (no plugin dep)"
  - "Consumers use Config.notifications.monitor (not forceMonitor)"

requirements-completed: [FWK-01, THM-02]
gap_ids: [G-01-1]

coverage:
  - id: G1
    description: "Material Symbols Rounded available to fontconfig"
    requirement: FWK-01
    verification:
      - kind: other
        ref: "fc-list shows Material Symbols Rounded"
        status: pass
    human_judgment: true
    rationale: "Visual icon quality still needs human glance after restart"
  - id: G2
    description: "No m3primaryDim / forceMonitor / undefined padding / hl.dsp.focus errors on load"
    requirement: FWK-01
    verification:
      - kind: other
        ref: "timeout 4 quickshell — Configuration Loaded; no gap-related WARN lines"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-21
status: complete
---

# Phase 1 Plan 04: Gap Closure — Bar Visual Fonts and QML Defects

**Closed UAT gap G-01-1:** missing Material Symbols / wrong UI fonts, undefined workspace padding, invalid Hyprland dispatch, and notification monitor Config key skew.

## Performance

- **Duration:** ~20 min
- **Tasks:** 3/3
- **Gap:** G-01-1

## Accomplishments

1. **Fonts**
   - Added `ttf-material-symbols-variable` to `arch/fonts.sh` and `arch/quickshell.sh`
   - Installed Material Symbols (Rounded/Outlined/Sharp) under `~/.local/share/fonts/MaterialSymbols` (sudo unavailable for system package)
   - Config defaults + live `~/.config/illogical-impulse/config.json` fonts → Noto Sans / JetBrainsMono Nerd Font

2. **Workspaces / BarContent**
   - Added `property real widgetPadding: 0` on Workspaces
   - Replaced `hl.dsp.focus(...)` with stock `workspace N` / `workspace r±1`

3. **Notifications + theme tokens**
   - `forceMonitor` → `notifications.monitor` in NotificationPopup + InterfaceConfig
   - Declared `m3primaryDim`, `m3secondaryDim`, `m3tertiaryDim`, `m3errorDim`, and palette key colors on Appearance.m3colors

## Verification (automated)

```
fc-list : family | rg 'Material Symbols Rounded'  → present
timeout 4 quickshell → Configuration Loaded
No: m3primaryDim, forceMonitor, undefined double, hl.dsp.focus
```

Remaining non-gap warnings (out of scope): FreeDesktop `image-missing` for app icons, ToolbarTabBar empty tab, bluez DBus, translation file missing.

## Task Commits

(See git log for plan 01-04)

## Next

- Restart quickshell and re-run `/gsd-verify-work 1` for human visual confirmation
- Optional: `sudo pacman -S ttf-material-symbols-variable` for system-wide install
