---
phase: 20
slug: hypr-custom-overlays-and-startup-restore
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-14"
validated: "2026-09-16"
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None. Custom bash assert scripts under `scripts/` (`scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`), adhering to `set -euo pipefail`, four-prefix `[PASS]/[FAIL]/[FINDING]/[INFO]`, and trap cleanup |
| **Config file** | none — by design |
| **Quick run command** | `./arch/dots-hyprland.sh verify --strict` |
| **Full suite command** | `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` |
| **Estimated runtime** | ~1 second for quick run; ~3-5 seconds for full assert suite |

---

## Sampling Rate

- **After every task commit:** Run `./arch/dots-hyprland.sh verify --strict`
- **After every plan wave:** Run `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`
- **Before `/gsd:verify-work`:** Full suite green (`FAIL=0`)
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01 T1 | 20-01 | 1 | SAFE-01 | T-20-01 | Scratch fixture verifies timestamped backup creation, `stow -n --no-folding` dry-run, and unmanaged stub pruning safely | integration | `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 1` | ✅ exists | ✅ green |
| 20-01 T2 | 20-01 | 1 | SAFE-01 | T-20-02 | Non-destructive drill fixture proves one-line undo (`stow -D` + restore) and re-stow preserves file integrity | drill | `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 2` | ✅ exists | ✅ green |
| 20-02 T1 | 20-02 | 2 | HYPR-03 | T-20-03 | `custom/variables.lua` configures terminal, browser, etc.; `git diff --exit-code vendor/dots-hyprland` clean | integration | `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 3` | ✅ exists | ✅ green |
| 20-02 T2 | 20-02 | 2 | START-01 | T-20-04 | `custom/execs.lua` registers Polkit agent, workspace pins (Chrome, kitty+tmux, btop, discord), and session service | integration | `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 4` | ✅ exists | ✅ green |
| 20-02 T3 | 20-02 | 2 | D-04 | — | GTK-3.0 and xsettingsd cursor theme set to `Bibata-Modern-Classic 24` | integration | `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 5` | ✅ exists | ✅ green |
| 20-03 T1 | 20-03 | 3 | HYPR-02 | T-20-05 | `custom/keybinds.lua` issues `hl.unbind` for 8 upstream collisions; `hyprctl binds -j` has no duplicates; descriptions format `"Category: Label"` | unit | `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 6` | ✅ exists | ✅ green |
| 20-04 T1 | 20-04 | 4 | HYPR-01 | T-20-06 | All 6 files in `~/.config/hypr/custom/` resolve into `stow/hypr/`; no ancestor symlinks; `verify --strict` exits 0 | integration | `./arch/dots-hyprland.sh verify --strict` | ✅ exists | ✅ green |
| 20-04 T2 | 20-04 | 4 | SAFE-01 | T-20-07 | Live escape-route rehearsal performed on live system; restore confirmed and re-stowed; verify exits 0 | drill | `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` | ✅ exists | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` — assertion harness covering HYPR-01, HYPR-02, HYPR-03, START-01, SAFE-01

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Classification |
|----------|-------------|------------|-------------------|----------------|
| Autostart & Window Placement | START-01 | Fresh graphical login required to observe compositor startup execution and workspace assignment | Log out of Hyprland, log back in; verify Chrome on ws 1, kitty+tmux on ws 1, btop on special:btop, discord on special:social | Non-blocking inspection / manual sampling (automated config and socket checks proven in Section 4) (D-06) |
| Polkit Authentication Prompt | START-01 | Requires GUI authentication action to trigger KDE polkit dialog | Trigger action requiring root privileges (e.g. `pkexec true` in terminal) and confirm KDE auth dialog appears | Non-blocking inspection / manual sampling (D-06) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-09-16
