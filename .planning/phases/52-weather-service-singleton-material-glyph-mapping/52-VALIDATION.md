---
phase: "52"
slug: "weather-service-singleton-material-glyph-mapping"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-03"
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash assertion test harness (`scripts/phase52-weather-assert.sh`) + Node.js dictionary evaluator & Quickshell log inspector |
| **Config file** | `scripts/phase52-weather-assert.sh` |
| **Quick run command** | `./scripts/phase52-weather-assert.sh -s 1` |
| **Full suite command** | `./scripts/phase52-weather-assert.sh` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase52-weather-assert.sh -s 1` (or matching section)
- **After every plan wave:** Run `./scripts/phase52-weather-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | GLYPH-02, GLYPH-03 | T-52-01 | Material Symbols glyph map covers all 59 WWO condition codes with day/night branching and neutral fallback | unit | `./scripts/phase52-weather-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 52-01-02 | 01 | 1 | GLYPH-04 | T-52-01 | EPA AQI (1–6) and severe weather alert levels map to Material You tokens (`Appearance.m3colors.*`) | unit | `./scripts/phase52-weather-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 52-02-01 | 02 | 2 | GLYPH-01 | T-52-01, T-52-03 | `Weather.qml` consumes local cache via `FileView` with non-blocking updates and cold-boot safety | integration | `./scripts/phase52-weather-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 52-02-02 | 02 | 2 | GLYPH-01, INTG-02 | T-52-04 | Backward-compatible `Weather.data.*` facade preserves legacy desktop background widget contract | integration | `./scripts/phase52-weather-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 52-03-01 | 03 | 3 | INTG-02, INTG-04 | T-52-02 | Restow overlay symlinks deployed, vendor backup created, zero QML runtime errors or child curl processes | system | `./scripts/phase52-weather-assert.sh -s 1 && ./scripts/phase52-weather-assert.sh -s 5` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase52-weather-assert.sh` — automated multi-section assertion harness covering Sections 1–5

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual Wallpaper Palette Integration | GLYPH-04 | Requires visual inspection of dynamic Material You color contrast against background | Switch wallpaper via `switchwall.sh` and verify AQI badge and alert highlight adapt dynamically |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
