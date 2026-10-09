---
phase: "54"
slug: "multi-modal-popup-inspector-interactive-graphs"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-10-10"
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash Assert Harness (`scripts/phase54-weather-assert.sh`) |
| **Config file** | `scripts/phase54-weather-assert.sh` |
| **Quick run command** | `./scripts/phase54-weather-assert.sh --quick` |
| **Full suite command** | `./scripts/phase54-weather-assert.sh` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase54-weather-assert.sh --quick`
- **After every plan wave:** Run `./scripts/phase54-weather-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0 FINDINGS=0`) and `./arch/dots-hyprland.sh verify --strict` green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-01-01 | 01 | 1 | POPUP-01 | T-54-04 | Non-root exec, mock fixtures, zero vendor churn | automated | `./scripts/phase54-weather-assert.sh --syntax && ./scripts/phase54-weather-assert.sh -s 5` | ❌ W0 | ⬜ pending |
| 54-01-02 | 01 | 1 | POPUP-01 | T-54-02 | Base card M3 surface & StyledPopup boundary clamping | automated | `./scripts/phase54-weather-assert.sh -s 1` | ❌ W0 | ⬜ pending |
| 54-02-01 | 02 | 2 | POPUP-02 | T-54-01 | Hero card safe fallback for null/stale & debounced reload | automated | `./scripts/phase54-weather-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 54-02-02 | 02 | 2 | POPUP-07 | T-54-01 | Severe alert banner, drawer & safe severity tint | automated | `./scripts/phase54-weather-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 54-03-01 | 03 | 3 | GRAPH-01, GRAPH-02 | T-54-02 | Monotone Bezier spline bounds check & 24h rain bar normalization | automated | `./scripts/phase54-weather-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 54-03-02 | 03 | 3 | GRAPH-03, GRAPH-04 | T-54-02 | Zero-repaint hover scrub overlay & CPU <= 1.68% gating | automated | `./scripts/phase54-weather-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 54-04-01 | 04 | 4 | POPUP-03, POPUP-05 | T-54-01 | Atmospheric 2x2 grid & Shortest-path needle rotation | automated | `./scripts/phase54-weather-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 54-04-02 | 04 | 4 | POPUP-04, POPUP-06 | T-54-01 | EPA AQI 6-segment color badge & Astronomy lunar terminator arc | automated | `./scripts/phase54-weather-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 54-04-03 | 04 | 4 | INTG-04 | T-54-04 | Layout assembly, idle CPU <= 1.68%, dots-hyprland strict cleanliness | automated | `./scripts/phase54-weather-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/fixtures/weather/nominal.json` — mock standard sunny conditions
- [ ] `tests/fixtures/weather/severe_alerts.json` — mock severe thunderstorm/flood warnings
- [ ] `tests/fixtures/weather/heavy_rain.json` — mock heavy rainfall (>10mm) and 100% chance
- [ ] `tests/fixtures/weather/sparse_offline.json` — mock cold-boot null placeholders and stale flag
- [ ] `scripts/phase54-weather-assert.sh` — automated 5-section test assertion harness

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual smoothness of 60fps hover scrub and 400ms needle rotation | GRAPH-03, POPUP-05 | Requires Wayland compositor display interaction | Hover over weather bar, move mouse across graph, observe 60fps scrub and smooth compass needle animation without jerkiness |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** verified
