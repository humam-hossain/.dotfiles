---
status: code_fixed
gap_id: G-02-4
phase: 02-core-bar-modules
created: 2026-07-22
updated: 2026-07-21T18:35:06Z
---

# Debug: Clock click does nothing

## Symptoms
- Hover on bar clock: popup shows date, uptime, todos (correct content, not Google Calendar)
- Click on clock: no action

## Investigation
1. `ClockWidget.qml` MouseArea only sets `hoverEnabled` and hosts `ClockWidgetPopup { hoverTarget: mouseArea }` — **no `onClicked`**.
2. `StyledPopup.qml` activates solely via `active: hoverTarget && hoverTarget.containsMouse` — hover-only LazyLoader.
3. Live config has `bar.tooltips.clickToShow: false` (hover path). Even if `clickToShow` were true, ClockWidget disables hover but still has no click handler, so click-to-show is also unimplemented.

## Root cause
Clock popup is **hover-only**. There is no click path to open/toggle `ClockWidgetPopup`. UAT expected click open; implementation never wired click.

## Fix direction
- Extend `StyledPopup` with optional pin/toggle (`forceActive` or `pinned` OR’d into `active`)
- Wire `ClockWidget` MouseArea `onClicked` to toggle pin (and respect `clickToShow` if useful)
- Keep hover behavior when unpinned

## Resolution

status: code_fixed (2026-07-21T18:35:06Z)
Code shipped via gap-closure plans 02-06..02-08. Awaiting human re-UAT via /gsd-verify-work 2.
