---
status: resolved
gap_id: G-01-1
phase: 01-shell-foundation-theme
created: 2026-07-21T12:25:00Z
updated: 2026-07-21T12:50:00Z
resolved_by: 01-04-PLAN.md
---

# Debug: Bar visible but icons missing / text overlapping / design inconsistent

## Status

**Resolved by plan 01-04** (executed 2026-07-21). Human retest of visual quality still required via `/gsd-verify-work 1`.

## Symptoms

- Bar layer loads (`Configuration Loaded`, bar visible)
- User: "lots of image missing, text overlapping, design is not consistent"
- Logs (pre-fix):
  - `Cannot assign to non-existent property "m3primaryDim"`
  - `Unable to assign [undefined] to double` @ `BarContent.qml:134`
  - `Could not load icon "image-missing"` (repeated)
  - `TypeError: Cannot read property 'enable' of undefined` @ `NotificationPopup.qml:17`
  - `Invalid dispatcher` for `hl.dsp.focus({workspace = 2})`

## Root Cause

**Primary:** Runtime font dependencies for the wholesale ii shell were never provisioned (Material Symbols Rounded, Google Sans Flex, etc.).

**Contributing:** undefined `widgetPadding`, `forceMonitor` Config skew, plugin-only `hl.dsp.focus`, missing Appearance m3*Dim props.

## Fix Applied (01-04)

| Item | Fix |
|------|-----|
| Fonts | User-local Material Symbols + Config/live config → Noto Sans / JetBrainsMono Nerd Font; scripts install package |
| Padding | `Workspaces.widgetPadding: 0` |
| Dispatch | Stock `workspace N` / `workspace r±1` |
| Notifications | `forceMonitor` → `monitor` |
| Theme | Appearance m3*Dim + palette keys |

Post-fix smoke: gap-related warnings absent; `Configuration Loaded`.
