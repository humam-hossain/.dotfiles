---
phase: 12
slug: bar-skeleton-and-theme
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-02
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — no automated test framework (QML visual rendering + Wayland compositor) |
| **Config file** | none |
| **Quick run command** | `quickshell` (manual visual inspection) + `bash arch/quickshell.sh` (smoke test) |
| **Full suite command** | Visual checklist BAR-01 through BAR-06 |
| **Estimated runtime** | ~2 minutes (install script + visual inspection) |

---

## Sampling Rate

- **After every task commit:** `bash arch/quickshell.sh` exit-0 check (script tasks) OR `quickshell` launch — no startup error in stderr (QML tasks)
- **After every plan wave:** Full visual checklist BAR-01 through BAR-06
- **Before `/gsd-verify-work`:** All six requirements visually confirmed
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | BAR-01 | — | N/A | manual/visual | `quickshell` — verify bar docks top, tiling windows do not overlap | ✅ | ⬜ pending |
| 12-01-02 | 01 | 1 | BAR-03 | — | N/A | manual/visual | `quickshell` — verify "Left"/"Center"/"Right" placeholder labels in pills | ✅ | ⬜ pending |
| 12-01-03 | 01 | 1 | BAR-04 | — | N/A | manual/visual | `quickshell` + screenshot — color-pick bar bg (#000000), pill bg (#1e1e2e), text (#cdd6f4), font JetBrainsMono | ✅ | ⬜ pending |
| 12-01-04 | 01 | 1 | BAR-02 | — | N/A | manual/visual | Connect second monitor while quickshell running — verify bar appears on new screen | ✅ | ⬜ pending |
| 12-01-05 | 01 | 1 | BAR-06 | — | N/A | manual/visual | `quickshell` alongside Waybar — verify both bars visible simultaneously | ✅ | ⬜ pending |
| 12-02-01 | 02 | 1 | BAR-05 | T-sudo | sudo operations use standard Arch pacman pattern; i2c group is minimal privilege | smoke (CLI) | `bash arch/quickshell.sh` — exit 0, symlink ~/.config/quickshell exists, /etc/modules-load.d/i2c.conf contains i2c-dev | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — this phase has no automated test framework. All validation is visual/manual or CLI smoke tests against existing infrastructure. No test stubs to create before execution begins.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bar docks at top, exclusive zone prevents window overlap | BAR-01 | Wayland compositor layout — no programmatic query | `quickshell` → launch terminal → verify gap above window equals bar height |
| Second monitor hot-plug adds bar | BAR-02 | Requires physical hardware event | Connect second monitor while Quickshell running → verify bar appears on new screen within ~1s |
| Left/center/right pill sections with placeholder text | BAR-03 | QML visual rendering | `quickshell` → screenshot → verify three pills with "Left" "Center" "Right" labels |
| Catppuccin Mocha colors + JetBrainsMono Nerd Font | BAR-04 | Color accuracy is perceptual | `quickshell` → screenshot → color-pick: bar bg #000000, pill bg #1e1e2e, text #cdd6f4; verify font name in Qt font dialog or qml Text.font.family |
| Waybar coexists without breakage | BAR-06 | Runtime process interaction | Run `quickshell` while Waybar is already running → verify both bars visible, Waybar still functional |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
