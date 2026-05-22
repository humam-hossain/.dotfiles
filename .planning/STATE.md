---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: verifying
last_updated: "2026-05-22T00:00:00.000Z"
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 5
  completed_plans: 7
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-02)

**Core value:** One dotfiles repo gives a clean, modern, bug-resistant desktop and editor experience across Linux (and Windows for Neovim) without the setup fighting the user.
**Current focus:** Phase 15 — popup-panels

## Current Position

Phase: 14 (script-backed-widgets) — COMPLETE ✓
Plan: All 5 plans complete (incl. gap closure 14-04, 14-05)
Status: Phase 14 done — ready for Phase 15
Progress: 5/5 plans complete [██████████] 100%

## Performance Metrics

| Metric | Value |
|--------|-------|
| Phases complete | 2/5 |
| Plans complete | 0/? |
| Current phase | 14 |
| Milestone | v1.2 |
| Phase 14 P01 | 3 tasks | 12 files | Services + Colours + qmldir |
| Phase 14 P02 | 3 tasks | 11 files | Widgets + qmldir |
| Phase 14 P03 | 2 tasks | 2 files | BarContent + Volume OSD |
| Phase 14 P04 | 1 task | 6 files | ToolTip import fix (gap closure) |
| Phase 14 P05 | 4 tasks | 22 files | 9 UAT gap fixes (gap closure) |

## Accumulated Context

### Decisions

- Phase 13 Plan 01: Use no-version `services/qmldir` singleton registrations to match the existing `qs.theme` convention.
- Phase 13 Plan 01: Keep PipeWire, MPRIS, and Hyprland native APIs behind `qs.services` wrappers for downstream widgets.
- [Phase 13-native-api-widgets]: Pre-register all four Phase 13 widgets in widgets/qmldir so Plan 13-03 can add MusicWidget and TrayWidget without touching the manifest.
- [Phase 13-native-api-widgets]: Keep empty-vs-occupied workspace differentiation deferred per A4; all listed non-active workspaces render with Colours.textColor.
- [Phase 13-native-api-widgets]: Keep Hyprland dispatch and pavucontrol launch command surfaces static to satisfy T-13-HYP-02 and T-13-VOL-01.
- [Phase 14-script-backed-widgets]: Pre-register ALL 10 Phase 14 services in services/qmldir so Plan 14-02 (widgets) only needs to create .qml files — no shared file conflict on qmldir.
- [Phase 14-script-backed-widgets]: Pre-register ALL 10 Phase 14 widgets in widgets/qmldir so Plan 14-03 (BarContent wiring) only needs BarContent.qml — no shared file conflict.
- [Phase 14-script-backed-widgets]: All 10 service singletons follow the established `pragma Singleton + Timer + Process + StdioCollector` pattern from Phase 13.
- [Phase 14-script-backed-widgets]: All Process.command arrays use static literals only — no service property data flows into command arguments (threat model T-14-PROC-01 enforced).
- [Phase 14-script-backed-widgets]: Lock (CTRL-02) and Power (CTRL-03) explicitly dropped per user decision in discuss-phase.

### Roadmap Evolution

- v1.0 milestone completed and archived (2026-04-15)
- v1.1 milestone completed and archived (2026-04-25) — 6 phases, 15 plans, 8/8 requirements satisfied
- v1.2 milestone started (2026-05-02) — Waybar → Quickshell Migration
- v1.2 roadmap created (2026-05-02) — 5 phases (12-16), 31 requirements mapped

### Architecture Notes (v1.2)

Critical patterns established in ARCHITECTURE.md / research/SUMMARY.md:

- Use `PopupWindow` (not a second `PanelWindow`) for all popups
- Use `HyprlandFocusGrab` (not `grabFocus: true`) for popup dismiss
- Use `visible: false` (not `opacity: 0`) to fully remove popups from input tree
- Bind `PwObjectTracker` before reading any PipeWire `.audio` properties
- Wrap all script paths: `["bash", "-c", "$HOME/.config/waybar/scripts/..."]` — Process.command does not expand `~`
- Never instantiate `NotificationServer` — conflicts with swaync on org.freedesktop.Notifications D-Bus
- Set `WlrKeyboardFocus.None` on the bar PanelWindow unconditionally

### Pending Todos

None.

### Blockers/Concerns

None.

## Deferred Items

Carried forward from v1.1 audit (2026-04-25):

| Category | Item | Status |
|----------|------|--------|
| tech_debt | `attach.lua` dead code: `apply_neotree`, `setup_lsp_attach` | deferred |
| tech_debt | Windows `<leader>o` interactive verification — no Windows machine | deferred |
| tech_debt | README Validation Commands summary table missing `keymaps`/`formats` rows | deferred |
| tech_debt | `colortheme.lua:14` stale neo-tree comment | deferred |
| tech_debt | SUMMARY frontmatter `requirements-completed` missing in phases 8/10 | deferred |

## Session Continuity

Next action: `/gsd-discuss-phase 15` — Discuss Phase 15 before planning
