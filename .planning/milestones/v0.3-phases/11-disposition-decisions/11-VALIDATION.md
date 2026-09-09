---
phase: 11
slug: disposition-decisions
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-08
updated: 2026-08-09
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `11-RESEARCH.md` § Validation Architecture + CONTEXT D-01..D-32.
> Doc-only phase → structural/lint gates, not unit tests.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell/assert checklist (bash; no Jest/pytest for planning markdown) |
| **Config file** | none — Wave 0 `scripts/phase11-dispositions-assert.sh` |
| **Quick run command** | `test -f .planning/phases/11-disposition-decisions/11-DISPOSITIONS.md && rg -n 'Disposition|SAFE_DEFAULTS|waybar|hyprlock|migrate-to-hypr-custom' .planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` |
| **Full suite command** | `./scripts/phase11-dispositions-assert.sh` (+ `--strict`) + HIGH-path checklist in §8 |
| **Estimated runtime** | ~2–5 seconds |

---

## Sampling Rate

- **After every task commit:** `rg` section just written + enum spot-check
- **After every plan wave:** full HIGH-path checklist + chrome override language
- **Before `/gsd-verify-work`:** `11-DISPOSITIONS.md` committed; DISP-01..04 rg checks green; assert exit 0
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------------|-----------|-------------------|-------------|--------|
| 11-W0 | 01 | 0 | Nyquist W0 | T-11-01 | Read-only assert only; no setup install / XDG rsync | docs/structure | `test -x scripts/phase11-dispositions-assert.sh && bash -n … && ./scripts/phase11-dispositions-assert.sh` | ✅ | ✅ green |
| 11-DISP-01 | * | * | DISP-01 | T-11-01 | Every HIGH path dispositioned; enum only | docs/structure | `rg -F` each HIGH path; §8 cross-check table | ✅ | ✅ green (11-04) |
| 11-DISP-02 | * | * | DISP-02 | T-11-01 | Three flag axes + full profile drops all three + residual SAFE_DEFAULTS default | docs/structure | residual + drop-all-three language | ✅ | ✅ green |
| 11-DISP-03 | * | * | DISP-03 | T-11-02 | Chrome explicit accept-remove override (not silent keep) | docs/lint | waybar/rofi/swaync + accept-remove + emerged | ✅ | ✅ green (11-04) |
| 11-DISP-04 | * | * | DISP-04 | T-11-01 | hyprlock/hypridle no-touch + no QS lock investment | docs/structure | keep-personal + Quickshell lock ban | ✅ | ✅ green (11-04) |
| 11-D10 | * | * | D-10 | T-11-01 | No claim default wrapper is already full | docs/lint | Residual SAFE_DEFAULTS still-default language | ✅ | ✅ green |
| 11-PROCESS | * | * | process | T-11-01 | No live full install / destructive XDG mutation in Phase 11 | process | Plan bans; docs-only execution | process | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky/partial*

---

## Wave 0 Requirements

- [x] `11-DISPOSITIONS.md` — exists at D-01 path
- [x] `scripts/phase11-dispositions-assert.sh` — executable; `bash -n` clean; default + `--strict` exit 0
- [x] HIGH-path fixture list in §8 cross-check + assert progressive/strict samples
- [x] Framework install: none (`bash`, `rg`/`grep`, `test`)

*Nyquist for this phase = artifact structural completeness, not runtime session tests.*

---

## Requirement → Automated Gate Map

| Req ID | Behavior | Automated check | Status |
|--------|----------|-----------------|--------|
| DISP-01 | Every HIGH inventory path has disposition + rationale | `rg -F` each of 13 HIGH tokens; D-03 columns; enum only | ✅ |
| DISP-02 | Staged flag choices: all three axes + first full profile drops all three | Literals residual flags; SAFE_DEFAULTS still default | ✅ |
| DISP-03 | Dual-run chrome disposition explicit (accept-remove override of default-keep) | waybar/rofi/swaync; accept-remove; archive-in-repo; emerged | ✅ |
| DISP-04 | hyprlock/hypridle consistent with hyprlock mechanism, no QS lock | keep-personal; no Quickshell lock | ✅ |
| D-04 | No invented paths without emerged note | Manual spot-check + emerged note for chrome | ✅ process |
| D-10 | Default install remains safe | Residual SAFE_DEFAULTS still default | ✅ |
| D-16 | Must-migrate only monitors/workspaces/env | migrate-to-hypr-custom limited to those categories | ✅ |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Every disposition Path cites inventory row or UNKNOWN id | D-04 | Cross-file human judgment | Spot-check 5 HIGH + 3 chrome/lock rows against `10-INVENTORY.md` | ⬜ UAT |
| Chrome accept-remove overrides ROADMAP SC3 default-keep intentionally | DISP-03 / D-11 | Policy override language | Confirm §6 states explicit accept-remove + archive-in-repo (D-12) | ✅ structural |
| Pre-flight sync list is live→repo only (not executed this phase) | D-07 | Process gate | Confirm §1 documents gate; Phase 11 did not run rsync to XDG | ✅ process |
| Must-migrate set is only monitors/workspaces/env | D-16 | Category judgment | Confirm no autostart/chrome binds as migrate-to-hypr-custom | ✅ structural |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (assert + dispositions exist)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set after full HIGH coverage + assert green (11-04)
- [x] `wave_0_complete: true`
- [x] DISP-01..04 structural gates green via assert + rg

**Approval:** Phase 11 structural validation complete — 2026-08-09 (11-04). Human UAT remaining via `/gsd-verify-work` for D-04 spot-checks.
