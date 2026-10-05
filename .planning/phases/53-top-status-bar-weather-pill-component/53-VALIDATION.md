---
phase: "53"
slug: "top-status-bar-weather-pill-component"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-05"
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertion harness + Node.js VM evaluator (`scripts/phase53-weather-assert.sh`) |
| **Config file** | `scripts/phase53-weather-assert.sh` |
| **Quick run command** | `./scripts/phase53-weather-assert.sh -s 1` |
| **Full suite command** | `./scripts/phase53-weather-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase53-weather-assert.sh -s <section>`
- **After every plan wave:** Run `./scripts/phase53-weather-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0 FINDINGS=0`)
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 1 | BAR-01 | — | Shadow upstream via personal overlay; non-destructive backup | integration | `test -f restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` | ❌ W0 | ⬜ pending |
| 53-01-02 | 01 | 1 | BAR-01 | — | Pristine vendor hygiene; zero git submodule churn | integration | `./arch/dots-hyprland.sh verify --strict` | ✅ | ⬜ pending |
| 53-01-03 | 01 | 1 | BAR-02 | — | Celsius integer formatting with unit, dimmed offline state | unit | `node -e '/* test temp format and fallback */'` | ❌ W0 | ⬜ pending |
| 53-01-04 | 01 | 1 | BAR-03 | — | Imminent rain badge reveal (>50%), alert precedence | unit | `node -e '/* test rain calculation and alert precedence */'` | ❌ W0 | ⬜ pending |
| 53-01-05 | 01 | 1 | BAR-04 | — | MouseArea click absorption, StyledPopup hover anchoring | integration | `grep -q "acceptedButtons: Qt.AllButtons" restow/.../WeatherBar.qml` | ❌ W0 | ⬜ pending |
| 53-02-01 | 02 | 2 | BAR-01..04 | ASVS L1 | Fails closed on root execution (EUID 0 check) | security | `./scripts/phase53-weather-assert.sh` | ❌ W0 | ⬜ pending |
| 53-02-02 | 02 | 2 | BAR-01..04 | — | All 5 sections green, 0 findings | smoke/e2e | `./scripts/phase53-weather-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase53-weather-assert.sh` — automated 5-section test harness covering BAR-01..BAR-04
- [ ] `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` — personal overlay component

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual rendering in status bar | BAR-01 | Real compositor Wayland display inspection | Inspect Wayland desktop session bar center zone to ensure pill renders cleanly without visual overlap. |
| Hover delay smoothness | BAR-04 | Human interactive cursor movement | Hover cursor over pill; verify 1000ms delay before popup appears and smooth exit transition. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
