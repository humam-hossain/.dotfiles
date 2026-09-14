---
phase: "21"
slug: "ii-bar-config-capture"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-15"
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash Test Harness (`scripts/phase21-ii-bar-config-capture-assert.sh`) |
| **Config file** | None (self-contained executable assert script) |
| **Quick run command** | `./scripts/phase21-ii-bar-config-capture-assert.sh --section <1-7>` |
| **Full suite command** | `./scripts/phase21-ii-bar-config-capture-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase21-ii-bar-config-capture-assert.sh --section <N>`
- **After every plan wave:** Run `./scripts/phase21-ii-bar-config-capture-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green AND `./arch/dots-hyprland.sh verify --strict` exits 0 with `FAIL=0 FINDINGS=0`
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | BAR-01 | T-21-01 | Ingest validation (`jq empty`, 0-byte check), atomic copy, symlink refusal, dirty repo mirror skip | integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 21-01-02 | 01 | 1 | BAR-01 | T-21-02 | Scratch XDG drill: `switchwall.sh:147` `mv` destroys symlink & `capture` picks up plain file | integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 21-02-01 | 02 | 2 | CAP-06 | T-21-03 | Systemd user timer enabled, active, stowed, oneshot service journal verification | systemd integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 21-02-02 | 02 | 2 | CAP-06 | T-21-03 | Drift capture drill: hand-edited live file captured to unstaged git status within interval | live integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 5` | ❌ W0 | ⬜ pending |
| 21-03-01 | 03 | 3 | BAR-02 | — | Personal bar settings baseline check & defaults-reset recovery drill with `config.json.bak.<epoch>` | integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 6` | ❌ W0 | ⬜ pending |
| 21-03-02 | 03 | 3 | BAR-01 | — | Live wallpaper confirmation run with `55192173787_b8322b1190_o.jpg` & clean theme revert | live integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 21-03-03 | 03 | 3 | BAR-01, BAR-02, CAP-06 | — | Overall tree integrity via strict link-aware verification | system check | `./arch/dots-hyprland.sh verify --strict` | ✅ Exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase21-ii-bar-config-capture-assert.sh` — gating assert script for Phase 21
- [ ] `capture/ii/.config/illogical-impulse/config.json` — repository mirror of deliberate personal bar baseline
- [ ] `stow/systemd/.config/systemd/user/dotfiles-capture.service` — systemd user service unit
- [ ] `stow/systemd/.config/systemd/user/dotfiles-capture.timer` — systemd user timer unit

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Quickshell visual bar render reload | BAR-02 | Live Wayland visual rendering inspection | Verify top bar visual appearance, spark icon, Dhaka weather, workspace indicator after `qs -c ii` reload |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
