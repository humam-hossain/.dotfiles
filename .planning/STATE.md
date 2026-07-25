---
gsd_state_version: 1.0
milestone: v0.1
milestone_name: Core Framework & Basic Bar
current_phase: 04
status: completed
stopped_at: Phase 04 complete — all 4 plans done; FWK-02/IPC-02 deferred
last_updated: "2026-07-25T05:44:54.733Z"
last_activity: 2026-07-25
last_activity_desc: Phase 04 complete
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 31
  completed_plans: 31
current_phase_name: ipc-keybinds-integration
---

# Project State

## Current Position

Phase: 04
Plan: Not started
Status: All phases complete
Last activity: 2026-07-25 — Phase 04 complete

Progress: [██████████] 100% milestone phases (4/4 complete; finishing touches deferred)

## Session

**Last session:** 2026-07-25T05:43:04Z
**Stopped at:** Phase 04 complete — all 4 plans done; FWK-02/IPC-02 deferred
**Resume file:** None
**Next command:** `/gsd-complete-milestone` or finishing-touch for FWK-02/IPC-02 when ready

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-21)

**Core value:** Reproduce every current Waybar module's functionality before cutover — while gaining a unified, themeable shell.  
**Current focus:** Phase 04 complete; FWK-02/IPC-02 deferred (04-DEFERRED.md)

## Accumulated Context

### Decisions (recent)

- Wholesale dots-hyprland `ii` tree as foundation (Phase 1)
- Material theme via `colors.json` + MaterialThemeLoader (seed #7aa2f7 vibrant dark)
- Font stack: Material Symbols + Noto Sans / JetBrainsMono Nerd Font fallbacks
- Stock Hyprland `workspace` dispatch (no `hl.dsp.focus` plugin)
- Dual-write Config.qml + `~/.config/illogical-impulse/config.json`
- Clock format `ddd yyyy-MM-dd hh:mm:ss AP` with secondPrecision true
- Tray full-color (`monochromeIcons: false`); pin policy invert + Fcitx
- Bar D-15 L→R layout; indicators D-19 mute→mic→xkb→BT→Network→notif
- Network icon-only on bar via `Network.materialSymbol`; SSID via right sidebar
- **UAT override:** remove ActiveWindow from left (G-02-7a space)
- **UAT override:** always-visible indicator strip (not hide-when-idle Revealers)
- **UAT fix:** StyledPopup.forceActive + ClockWidget onClicked for click-to-pin
- **UAT override:** `bar.workspaces.shown: 4` (G-02-14; overrides D-02 shown:10)
- **UAT fix:** left sidebar opens only via LeftSidebarButton; cornerOpen disabled (G-02-13)
- **Phase 3:** CPU→RAM→Disk rings; dual thresholds; no swap/popup on strip; mute/mic icon+%; 130% volume + auto-unmute; pavucontrol middle/right (D-01..D-26)
- **Phase 4 scope (D-01..D-03):** This pass = IPC-01 + IPC-03 verify/UAT only; IPC-02 keybind and FWK-02 exec-once deferred finishing touches
- **Phase 4 reload (research):** Quickshell 0.3.0 has no `qs reload` CLI — soft reload via file-watch content change (same PID); no custom reload IPC (D-07)
- **Phase 4 productization (D-13):** Assert/UAT stock surfaces; fix QML only if verification red

### Phase 4 planning artifacts (ready)

| Artifact | Path |
|----------|------|
| Context | `04-CONTEXT.md` (D-01..D-13 locked) |
| Research | `04-RESEARCH.md` (HIGH confidence; Open Questions RESOLVED) |
| Patterns | `04-PATTERNS.md` (5/5 analogs) |
| UI-SPEC | `04-UI-SPEC.md` (no visual redesign; visibility + silent reload contracts) |
| Validation | `04-VALIDATION.md` (draft Wave 0 strategy) |
| Plans | `04-01` .. `04-04` PLAN.md (3 waves) |

**Coverage gates (plan-phase):**

- Requirements FWK-02, IPC-01, IPC-02, IPC-03: 4/4 covered (FWK-02/IPC-02 as deferred via 04-04)
- CONTEXT decisions D-01..D-13: 13/13 covered
- Post-planning gap analysis: 17/17 covered
- Plan-checker: VERIFICATION PASSED (iteration 2 after fail-loud / mandatory soft-reload fixes)

### Wave layout

| Wave | Plans | Focus |
|------|-------|--------|
| 1 | 04-01 | Wave 0 assert harness + VALIDATION wire |
| 2 | 04-02, 04-04 | IPC-01 live UAT; deferred backlog packaging |
| 3 | 04-03 | IPC-03 soft-reload + tray UAT |

### Next

1. `/gsd-execute-phase 4` — execute Wave 1→3 plans (IPC verify + soft-reload UAT + deferred packaging)
2. Human checkpoints: multi-monitor bar hide/show (04-02); silent reload + tray (04-03)
3. After execute + verify: finishing-touch pass for FWK-02/IPC-02 when bar is solid

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 03 P01 | 1min | 2 tasks | 2 files |
| Phase 03 P03 | 5min | 2 tasks | 1 files |
| Phase 03 P04 | 2min | 2 tasks | 3 files |
| Phase 03 P02 | 2min | 2 tasks | 2 files |
| Phase 03 P07 | 3min | 2 tasks | 1 files |
| Phase 03 P05 | 2min | 2 tasks | 1 files |
| Phase 03 P06 | 2min | 2 tasks | 1 files |
| Phase 03 P08 | 8min | 2 tasks | 1 files |
| Phase 03 P09 | 1min | 3 tasks | 3 files |
| Phase 03 P10 | 1min | 2 tasks | 1 files |
| Phase 04 P01 | 3min | 2 tasks | 2 files |
| Phase 04 P02 | 15min | 2 tasks | 2 files |
| Phase 04 P03 | 20min | 2 tasks | 2 files |
| Phase 04 P04 | 5min | 2 tasks | 3 files |

## Decisions

- [Phase ?]: Phase 3 Wave 0: split interval dual-write keys updateInterval=1000/memoryUpdateInterval=3000/diskUpdateInterval=10000; maxAllowed>=130 floor
- [Phase ?]: Warning tier uses Appearance.colors.colPrimary (no colWarning token)
- [Phase ?]: errorThreshold default 100 keeps error tier off until parent sets lower
- [Phase ?]: TextMetrics binds to labelText or '100%' so layout matches content
- [Phase 4]: IPC + soft-reload verify only this pass; FWK-02/IPC-02 deferred (04-DEFERRED.md); stock bar IPC + file-watch soft reload; no hyprland.conf product edits
- [Phase ?]: Wave 0 phase04-ipc-reload-assert.py: stock bar IPC + content-change soft-reload same-PID; no product QML
