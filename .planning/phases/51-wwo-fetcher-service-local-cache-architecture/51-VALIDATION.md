---
phase: "51"
slug: "wwo-fetcher-service-local-cache-architecture"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-02"
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash assertion test harness (`scripts/phase51-weather-assert.sh`) + Python stdlib compile checks |
| **Config file** | `scripts/phase51-weather-assert.sh` |
| **Quick run command** | `./scripts/phase51-weather-assert.sh -s 1` |
| **Full suite command** | `./scripts/phase51-weather-assert.sh` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase51-weather-assert.sh -s 1`
- **After every plan wave:** Run `./scripts/phase51-weather-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | WWO-01 | T-51-01 | Key stored in .env mode 0600; ignored in git; python compiles cleanly | unit | `./scripts/phase51-weather-assert.sh -s 1` | ❌ W0 | ⬜ pending |
| 51-01-02 | 01 | 1 | WWO-01 | T-51-02 | `--status` and `--dry-run` CLI helpers work; city name resolved from config.json | integration | `./scripts/phase51-weather-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 51-02-01 | 02 | 2 | WWO-02 | T-51-03 | Dynamic budget formula clamped to >=3m floor; 470-call budget enforced; UTC midnight rollover | unit | `./scripts/phase51-weather-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 51-02-02 | 02 | 2 | WWO-03 | T-51-04 | Atomic replacement via `os.replace` within same runtime directory; schema validated | integration | `./scripts/phase51-weather-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 51-02-03 | 02 | 2 | WWO-04 | T-51-05 | Cold-boot offline skeleton provisioned; persistent cache fallback restored; network error preserves payload | integration | `./scripts/phase51-weather-assert.sh -s 5` | ❌ W0 | ⬜ pending |
| 51-03-01 | 03 | 3 | INTG-02 | T-51-06 | Stow link integrity; user units enabled; `./arch/dots-hyprland.sh verify --strict` zero errors | system | `./arch/dots-hyprland.sh verify --strict` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase51-weather-assert.sh` — automated multi-section assertion harness covering Sections 1–5
- [ ] `stow/weather/.config/weather/.env.example` — template for credentials

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real API Live Query | WWO-01 | Requires valid paid/trial API key not committed to git | Operator creates `~/.config/weather/.env`, runs `wwo-fetcher.py --force`, inspects `$XDG_RUNTIME_DIR/weather/weather.json` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
