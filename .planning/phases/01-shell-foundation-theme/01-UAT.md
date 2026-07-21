---
status: diagnosed
phase: 01-shell-foundation-theme
source: [01-VERIFICATION.md]
started: 2026-07-21T11:56:17Z
updated: 2026-07-21T12:36:27Z
---

## Current Test

[testing complete]

## Tests

### 1. Bar visible and usable on all connected monitors
expected: Top bar from IllogicalImpulseFamily on each connected monitor (DP-1 and HDMI-A-2 if attached); not hidden / missing
result: issue
reported: "bar shows up but lots of image missing, text overlapping, design is not consistent"
severity: major

### 2. Material colors look applied
expected: Bar/background surfaces reflect generated dark vibrant Material palette (seed #7aa2f7), not only greyscale Appearance defaults
result: pass

## Summary

total: 2
passed: 1
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-01-1
  truth: "Top bar from IllogicalImpulseFamily on each connected monitor (DP-1 and HDMI-A-2 if attached); not hidden / missing"
  status: failed
  reason: "User reported: bar shows up but lots of image missing, text overlapping, design is not consistent. Logs also show: Cannot assign to non-existent property m3primaryDim; Unable to assign [undefined] to double (BarContent.qml); Could not load icon image-missing; Unable to assign [undefined] to QQuickItem* (ToolbarTabBar.qml); NotificationPopup enable of undefined; Invalid dispatcher hl.dsp.focus"
  severity: major
  test: 1
  root_cause: "Missing runtime fonts (Material Symbols Rounded, Google Sans Flex, Readex Pro, Space Grotesk; JetBrains family name mismatch) so MaterialSymbol glyphs and UI text metrics fail — primary cause of missing icons / overlapping text. Contributing: Workspaces.widgetPadding undefined (BarContent:134), Config notifications.forceMonitor vs .monitor key skew, hl.dsp.focus dispatcher with no Hyprland plugins, incomplete Appearance.m3colors *Dim props."
  artifacts:
    - path: "arch/fonts.sh"
      issue: "Does not install Material Symbols or ii UI fonts"
    - path: "arch/quickshell.sh"
      issue: "PACKAGES omit font deps required by shell chrome"
    - path: ".config/quickshell/modules/common/Config.qml"
      issue: "Default fonts unavailable; notifications.monitor not forceMonitor"
    - path: ".config/quickshell/modules/ii/bar/BarContent.qml"
      issue: "padding: workspacesWidget.widgetPadding is undefined"
    - path: ".config/quickshell/modules/ii/bar/Workspaces.qml"
      issue: "No widgetPadding; uses hl.dsp.focus without plugin"
    - path: ".config/quickshell/modules/ii/notificationPopup/NotificationPopup.qml"
      issue: "Reads forceMonitor which Config does not define"
    - path: ".config/quickshell/modules/common/Appearance.qml"
      issue: "Missing m3*Dim properties vs colors.json keys"
  missing:
    - "Install ttf-material-symbols-variable and wire into fonts/quickshell provisioning"
    - "Fallback Config.appearance.fonts to installed families (Noto Sans / JetBrainsMono Nerd Font)"
    - "Add Workspaces.widgetPadding or fix BarContent padding binding"
    - "Align forceMonitor/monitor Config key across consumers"
    - "Replace hl.dsp.focus with stock workspace dispatcher"
    - "Optionally declare m3primaryDim and other *Dim properties on Appearance.m3colors"
  debug_session: ".planning/debug/bar-visual-icons-layout.md"
