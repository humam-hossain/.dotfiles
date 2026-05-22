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

Phase: 14 (script-backed-widgets) — GAP CLOSURE IN PROGRESS ⚠
Plan: 5/7 plans complete (UAT revealed 9 gaps; 14-05 fix caused Qt.getenv regression)
Status: Phase 14 gap closure — 14-06 and 14-07 pending
Progress: 5/7 plans complete [████████░░] 71%

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
| Phase 14 P05 | 4 tasks | 22 files | 9 UAT gap fixes (gap closure) — regression introduced |
| Phase 14 P06 | 3 tasks | 6 files | Qt.getenv regression fix + CPU/Disk investigation (gap closure) |
| Phase 14 P07 | 2 tasks | 3 files | Network nmcli fix + Volume OSD wpctl polling (gap closure) |

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

### Lessons Learned (Phase 14 gap closure)

- **Qt.getenv does NOT exist in QS 0.2.1** — Two separate code reviews (14-REVIEW WR-03, 14-05-REVIEW WR-01) incorrectly recommended `Qt.getenv("HOME")` over `"$HOME"` shell expansion. The correct pattern is `["bash", "-c", "$HOME/.config/waybar/scripts/..."]` — Process.command passes through bash -c which expands $HOME correctly.
- **Pipewire API readonly bindings broken in QS 0.2.1** (issue #807) — Timer polling `Pipewire.defaultAudioSink.audio.volume` always returns stale/cached values. Workaround: poll via `wpctl get-volume @DEFAULT_AUDIO_SINK@` subprocess which queries the real Pipewire daemon.
- **DiskService pipe-delimited parsing bug**: `parts.length === 3` check but awk outputs only 2 pipe-delimited fields. Fix: use `parts.length >= 2`.
- **nmcli -t field delimiter conflict**: nmcli uses `:` as delimiter which clashes with colons in SSIDs. Fix: parse from end of line backward (lastIndexOf) instead of forward split.

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

Next action: `/gsd-execute-phase 14 --gaps-only` — Execute gap closure plans 14-06 and 14-07
After gap closure: Re-run UAT tests, then `/gsd-discuss-phase 15`
