---
phase: "28"
slug: "terminal-fuzzel-launcher-dynamic-palette"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-17"
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Standalone Bash Assert Harness (`scripts/phase28-terminal-fuzzel-assert.sh`) |
| **Config file** | `scripts/phase28-terminal-fuzzel-assert.sh` |
| **Quick run command** | `bash scripts/phase28-terminal-fuzzel-assert.sh --section 1` |
| **Full suite command** | `bash scripts/phase28-terminal-fuzzel-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase28-terminal-fuzzel-assert.sh --section <N>` matching the task domain
- **After every plan wave:** Run `bash scripts/phase28-terminal-fuzzel-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0`, 0 findings)
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 0 | INTG-01 | T-28-01 | Guard-paths contract & fail-closed harness scaffold | contract | `bash scripts/phase28-terminal-fuzzel-assert.sh --help` | ✅ exists | ✅ green |
| 28-01-02 | 01 | 1 | TERM-01 | T-28-01 | Template & config readiness (Matugen, fuzzel.ini, guard-paths, kittens) | unit | `bash scripts/phase28-terminal-fuzzel-assert.sh --section 1` | ✅ exists | ✅ green |
| 28-02-01 | 02 | 2 | TERM-01 | T-28-02 | Fuzzel theme syntax, colors section, hex validity, and dry-run | integration | `bash scripts/phase28-terminal-fuzzel-assert.sh --section 2` | ✅ exists | ✅ green |
| 28-02-02 | 02 | 2 | TERM-02 | T-28-02 | Kitty theme syntax, ANSI/grey overrides, opacity, and layout | integration | `bash scripts/phase28-terminal-fuzzel-assert.sh --section 3` | ✅ exists | ✅ green |
| 28-03-01 | 03 | 3 | TERM-01 | T-28-03 | Live reload drill via switchwall.sh --noswitch & dual-mode Kitty probe | integration | `bash scripts/phase28-terminal-fuzzel-assert.sh --section 4` | ✅ exists | ✅ green |
| 28-03-02 | 03 | 3 | INTG-02 | T-28-03 | Full 5-section suite pass & strict verification 0 findings | smoke / regression | `bash scripts/phase28-terminal-fuzzel-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ✅ exists | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/phase28-terminal-fuzzel-assert.sh` — Phase 28 assert harness scaffold with `--section <1-5>` dispatch and fail-closed reporting

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual aesthetic check of Kitty transparency & blur | TERM-02 | Subjective desktop readability against various wallpaper backdrops | Open Kitty terminal over light and dark wallpapers; verify 85% opacity provides legibility while showing subtle blur |
| Fuzzel overlay interactive appearance | TERM-01 | Interactive GUI overlay appearance | Trigger Fuzzel (Super+Space or app launcher); verify M3 colors match wallpaper accent and text is crisp |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated
