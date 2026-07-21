---
status: code_fixed
gap_id: G-02-7a
phase: 02-core-bar-modules
created: 2026-07-22
updated: 2026-07-21T18:35:06Z
---

# Debug: ActiveWindow wastes bar space

## Symptoms
- User: ActiveWindow (“window”) takes too much space; no need; want it removed

## Investigation
1. `BarContent.qml` leftSectionRowLayout: `LeftSidebarButton → ActiveWindow → Workspaces → Resources`
2. ActiveWindow has `Layout.fillWidth: true` — expands and steals horizontal space from workspaces
3. CONTEXT D-15/D-17 intentionally kept ActiveWindow for Phase 2

## Root cause
ActiveWindow is present and **fillWidth** per D-15/D-17. UAT feedback overrides that decision: remove ActiveWindow from the left region to free space.

## Fix direction
- Remove `ActiveWindow { ... }` block from left section (do not leave a zero-width stub)
- Left becomes: LeftSidebarButton → Workspaces → Resources
- Record decision override in plan notes / CONTEXT when executing (UAT supersedes D-17 for ActiveWindow only)

## Resolution

status: code_fixed (2026-07-21T18:35:06Z)
Code shipped via gap-closure plans 02-06..02-08. Awaiting human re-UAT via /gsd-verify-work 2.
