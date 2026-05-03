---
phase: 13
slug: native-api-widgets
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-03
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — manual visual UAT (no qmltest infrastructure introduced this phase) |
| **Config file** | none |
| **Quick run command** | `quickshell` (launch shell, observe widget rendering on the bar) |
| **Full suite command** | `quickshell` + manual interaction script (click workspace, scroll bar, change volume, play media, right-click tray) |
| **Estimated runtime** | ~30 seconds per UAT pass |

---

## Sampling Rate

- **After every task commit:** Reload `quickshell` (Ctrl+C and re-launch) and visually verify the affected widget renders without QML console errors
- **After every plan wave:** Run the full manual UAT script for the widgets touched in that wave
- **Before `/gsd-verify-work`:** Full UAT must pass with zero QML warnings/errors
- **Max feedback latency:** ~30 seconds (manual)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | WS-01 | — | reactive workspace list, no IPC polling | manual | `quickshell` + observe Hyprland workspace add/remove | N/A | ⬜ pending |
| TBD | TBD | TBD | WS-02 | — | active workspace = Mauve fill | manual | visual diff against ROADMAP success criteria | N/A | ⬜ pending |
| TBD | TBD | TBD | WS-03 | — | click activates, scroll cycles | manual | click each workspace pill; scroll wheel up/down on bar group | N/A | ⬜ pending |
| TBD | TBD | TBD | AUDIO-01 | — | reads default sink only, no privileged ops | manual | change volume via media keys, observe widget update; click → pavucontrol opens | N/A | ⬜ pending |
| TBD | TBD | TBD | AUDIO-03 | — | hidden when no MPRIS player | manual | close all media; verify widget invisible; open spotify/mpv; verify widget visible | N/A | ⬜ pending |
| TBD | TBD | TBD | TRAY-01 | — | SNI items render, right-click context menu | manual | observe nm-applet/blueman/etc. icons appear; right-click each | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs filled in after planner completes.*

---

## Wave 0 Requirements

- [ ] No new test infrastructure required — this phase relies on manual visual UAT (D-57)
- [ ] Confirm `quickshell` binary launches without errors after each commit (smoke test)

*Existing infrastructure: none. Phase 13 introduces no automated tests; QML lacks native unit-test framework integrated in this repo.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reactive workspace add/remove | WS-01 | QML reactivity is observable only at runtime via Quickshell.Hyprland live data | Open new workspace via `hyprctl dispatch workspace 5`; verify pill appears in widget within ~100ms |
| Active workspace highlight color | WS-02 | Catppuccin Mauve = `#cba6f7`; visual verification | Switch workspaces via Super+1..9; confirm only the active pill renders Mauve background |
| Workspace click activate | WS-03 | Mouse interaction with Hyprland IPC | Click each visible workspace pill; verify Hyprland switches to it |
| Workspace scroll cycle | WS-03 | Wheel event → HyprlandIpc.dispatch | Scroll wheel up over workspace group → next workspace; scroll down → previous |
| Volume reactive update | AUDIO-01 | PwObjectTracker live binding | Change volume via media keys / pavucontrol; verify widget percent updates in <500ms |
| Volume click → pavucontrol | AUDIO-01 | Process.startDetached | Click volume widget; verify pavucontrol window opens |
| Mute icon swap | AUDIO-01 | Conditional binding on `.audio.muted` | Toggle mute via media key; verify mute icon replaces volume icon (and 0% displays as muted per CONTEXT D-deviation) |
| Music widget hide when no player | AUDIO-03 | `visible: activePlayer !== null` | Close all media players; verify widget invisible (zero footprint, not just transparent) |
| Music widget show when player active | AUDIO-03 | reactive Mpris.players binding | Launch spotify/mpv/playerctl; verify widget appears with title+artist |
| Music click → playPause | AUDIO-03 | `togglePlaying()` (corrected from CONTEXT D-31) | Click music widget; verify playback toggles |
| Music truncation 30 chars | CONTEXT D-29 deviation | Visual verification of ellipsis | Play track with 50+ char title; verify truncation at 30 chars with ellipsis |
| SNI tray icons render | TRAY-01 | SystemTray.items live | Verify nm-applet, blueman, dropbox, etc. icons appear from system services |
| Tray right-click → context menu | TRAY-01 | QsMenuAnchor + QsMenuOpener | Right-click each tray icon; verify native context menu appears with proper actions |
| Multi-monitor: bar/widgets per screen | BAR-02 carryover | Variants over Quickshell.screens | Connect/disconnect external display (or simulate via hyprctl); verify widgets render on each screen |

---

## Validation Sign-Off

- [ ] All tasks have manual UAT instructions in this file (no `<automated>` tasks since no test infra)
- [ ] Sampling continuity: each commit triggers a quickshell reload smoke test
- [ ] Wave 0 covers all MISSING references (none — no test infra introduced)
- [ ] No watch-mode flags
- [ ] Feedback latency ~30s per UAT pass
- [ ] `nyquist_compliant: true` set in frontmatter after planner fills task IDs

**Approval:** pending
