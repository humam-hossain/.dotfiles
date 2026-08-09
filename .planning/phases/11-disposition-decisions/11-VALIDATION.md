---
phase: 11
slug: disposition-decisions
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
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
| **Full suite command** | `./scripts/phase11-dispositions-assert.sh` (+ `--strict` after 11-04) + manual HIGH-path checklist |
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
| 11-W0 | 01 | 0 | Nyquist W0 | T-11-01 | Read-only assert only; no setup install / XDG rsync | docs/structure | `test -x scripts/phase11-dispositions-assert.sh && bash -n scripts/phase11-dispositions-assert.sh && ./scripts/phase11-dispositions-assert.sh` | ✅ | ✅ green (11-01) |
| 11-DISP-01 | * | * | DISP-01 | T-11-01 | Every HIGH path dispositioned; enum only | docs/structure | `rg -F` each HIGH path in `11-DISPOSITIONS.md`; enum tokens only | ⚠️ | ⬜ in progress (samples 11-01; full A 11-02; B/C 11-03; cross-check 11-04) |
| 11-DISP-02 | * | * | DISP-02 | T-11-01 | Three flag axes + full profile drops all three + residual SAFE_DEFAULTS default | docs/structure | `rg -n 'skip-hyprland\|--core\|skip-sysupdate\|SAFE_DEFAULTS' 11-DISPOSITIONS.md` | ✅ | ✅ green (11-01 §2) |
| 11-DISP-03 | * | * | DISP-03 | T-11-02 | Chrome explicit accept-remove override (not silent keep) | docs/lint | `rg -ni 'waybar\|rofi\|swaync' 11-DISPOSITIONS.md` + override language | ⚠️ | ⬜ stub green keywords (11-01); full polish 11-04 |
| 11-DISP-04 | * | * | DISP-04 | T-11-01 | hyprlock/hypridle no-touch + no QS lock investment | docs/structure | `rg -n 'hyprlock\|hypridle\|keep-personal\|Quickshell lock' 11-DISPOSITIONS.md` | ⚠️ | ⬜ stub (11-01); full 11-04 |
| 11-D10 | * | * | D-10 | T-11-01 | No claim default wrapper is already full | docs/lint | Residual SAFE_DEFAULTS still-default language present | ✅ | ✅ green (11-01) |
| 11-PROCESS | * | * | process | T-11-01 | No live full install / destructive XDG mutation in Phase 11 | process | Plan bans; verifier reads PLAN steps | process | ✅ green (docs-only execution) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky/partial*

---

## Wave 0 Requirements

- [x] `11-DISPOSITIONS.md` — exists at D-01 path (11-01)
- [x] `scripts/phase11-dispositions-assert.sh` — executable; `bash -n` clean; default mode exits 0 after 11-01
- [x] HIGH-path fixture samples planted as stubs/keywords for progressive expansion
- [x] Framework install: none (`bash`, `rg`/`grep`, `test`)

*Nyquist for this phase = artifact structural completeness, not runtime session tests.*  
*`nyquist_compliant: true` only after 11-04 full HIGH cross-check + assert green (including `--strict` if used).*

---

## Requirement → Automated Gate Map

| Req ID | Behavior | Automated check |
|--------|----------|-----------------|
| DISP-01 | Every HIGH inventory path has disposition + rationale | `rg -F` each HIGH path; columns Path\|Inventory risk\|Disposition\|Rationale\|Flag stage\|Inventory source; enum only |
| DISP-02 | Staged flag choices: all three axes + first full profile drops all three | Literals `--skip-hyprland`, `--core`, `--skip-sysupdate`; SAFE_DEFAULTS residual still default |
| DISP-03 | Dual-run chrome disposition explicit (accept-remove override of default-keep) | waybar/rofi/swaync present; accept-remove / D-11 override language; archive-in-repo |
| DISP-04 | hyprlock/hypridle consistent with hyprlock mechanism, no QS lock | hyprlock/hypridle keep-personal/no-touch; no QS lock investment |
| D-04 | No invented paths without emerged note | Manual: every Path cites inventory or emerged |
| D-10 | Default install remains safe | Residual SAFE_DEFAULTS still default language |
| D-16 | Must-migrate only monitors/workspaces/env | `migrate-to-hypr-custom` rows limited to those categories |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Every disposition Path cites inventory row or UNKNOWN id | D-04 | Cross-file human judgment | Spot-check 5 HIGH + 3 chrome/lock rows against `10-INVENTORY.md` |
| Chrome accept-remove overrides ROADMAP SC3 default-keep intentionally | DISP-03 / D-11 | Policy override language | Confirm section states explicit accept-remove + archive-in-repo (D-12) |
| Pre-flight sync list is live→repo only (not executed this phase) | D-07 | Process gate | Confirm dispositions document gate; Phase 11 plans do not run rsync to XDG |
| Must-migrate set is only monitors/workspaces/env | D-16 | Category judgment | Confirm no autostart/chrome binds as migrate-to-hypr-custom |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (assert + dispositions exist)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter after full HIGH coverage (11-04)

**Approval:** Wave 0 complete (11-01); phase structural complete pending 11-02..04
