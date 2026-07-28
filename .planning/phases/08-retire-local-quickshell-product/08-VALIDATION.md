---
phase: 8
slug: retire-local-quickshell-product
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-27
validated: 2026-07-28
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Practical asserts only — **no** new `scripts/phase08-*` smoke suite (D-03).
> Closed by execute-phase verify:post → validate-phase (2026-07-28).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — inline bash asserts in plan task `<automated>` / verify blocks |
| **Config file** | none |
| **Quick run command** | Live health subset: `test ! -L ~/.config/quickshell && test -d ~/.config/quickshell && test -f ~/.config/quickshell/ii/shell.qml` |
| **Full suite command** | Health subset + post-RET absence asserts (`test ! -e .config/quickshell`; `test ! -e arch/quickshell.sh`) + optional `pgrep` dual-run soft checks |
| **Estimated runtime** | ~5 seconds for pure asserts; reinstall path minutes if triggered |

**Explicit non-gates (do not thrash on these):**
- `./scripts/phase07-live-smoke.sh` — expected red on D-04 after RET-01 (historical; D-11/D-12)
- `scripts/phase04-*.py` / phase02/03 asserts — not maintained this phase
- No pytest/jest/bats

---

## Sampling Rate

- **After every task commit:** Run the asserts that task just made true (e.g. after tree commit → path absent + live still healthy)
- **After every plan wave:** Full post-RET set (tree gone, script gone, live healthy)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds for pure asserts

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-T1 | 01 | 1 | RET-01 pre / LIVE hold | T-8-01, T-8-03 | Live path is real dir under `$HOME`, not symlink to repo | smoke (inline) | `test ! -L ~/.config/quickshell && test -d && -f ii/shell.qml`; readlink not under repo | inline | ✅ green |
| 08-01-T1b | 01 | 1 | RET-01 pre | T-8-01 | venv present | smoke (inline) | `test -d ~/.local/state/quickshell/.venv` | inline | ✅ green |
| 08-01-T1c | 01 | 1 | LIVE-02 hold | T-8-01 | hypr hooks still present in repo SoT | smoke (inline) | `grep` env + `qs -c ii` in repo hypr conf | inline | ✅ green |
| 08-02-T2 | 02 | 2 | RET-01 post | T-8-01 | In-repo product tree absent; live untouched | smoke (inline) | `test ! -e "$REPO_ROOT/.config/quickshell"`; re-run live health | inline | ✅ green |
| 08-03-T1 | 03 | 3 | RET-02 post | T-8-02 | `arch/quickshell.sh` hard-deleted | smoke (inline) | `test ! -e "$REPO_ROOT/arch/quickshell.sh"` | inline | ✅ green |
| 08-03-T2 | 03 | 3 | RET-02 | T-8-02 | Wrapper remains only install entry | smoke (inline) | `test -x arch/dots-hyprland.sh`; `bash -n` | existing wrapper | ✅ green |
| 08-03-T3 | 03 | 3 | LIVE-01 hold | T-8-03 | After deletes, live still real/not symlink | smoke (inline) | same LIVE-01 path asserts | inline | ✅ green |
| 08-03-T2b | 03 | 3 | Neg | T-8-02 | No non-planning caller of deleted installer | grep | `git grep -n 'arch/quickshell\.sh' -- arch scripts .config` (zero hits post-reword) | inline | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Gap classification (pre → post):**

| Item | Pre | Post |
|------|-----|------|
| 08-01 live health / LIVE-02 | pending map | COVERED (inline asserts + 08-01-SUMMARY) |
| 08-02 RET-01 tree absence | pending map | COVERED (`fb91789` + post asserts) |
| 08-03 RET-02 installer absence | pending map | COVERED (`81ac1e0` + zero grep hits) |
| LIVE-04 chrome re-ceremony | manual optional | Manual-only (D-03 — not a phase gate) |
| Reinstall backup gate | manual if health fails | N/A this run (health green → reinstall SKIPPED) |

---

## Wave 0 Requirements

- [x] **None for new test files** — D-03 forbids new smoke scripts
- [x] Framework install: none
- [x] Planner embedded inline verify commands in each plan task (not a missing phase08 script)
- [x] Planner documented that `phase07-live-smoke.sh` is expected red on D-04 after RET-01

*Existing bash + filesystem tools cover all phase requirements without new harness files.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Post-exec status |
|----------|-------------|------------|-------------------|------------------|
| Formal LIVE-04 chrome / UAT checklist re-ceremony | LIVE hold soft | D-03 defers formal UAT chrome; practical health only | Optional: visual glance that ii session still usable after retirement | Soft: `qs -c ii` + waybar observed running at close-out — not formal UAT |
| Interactive reinstall backup gate (only if health fails) | RET-01 pre repair | Wrapper requires operator `yes` | If reinstall needed: dry-run then live install; type exact `yes` | **Not exercised** — Task 2 SKIP (health green) |

*All core RET-01/RET-02 behaviors have automated filesystem/grep verification.*

---

## Threat Refs (from RESEARCH Security Domain)

| Threat ID | Severity | Disposition |
|-----------|----------|-------------|
| T-8-01 Live path deleted as "retirement" | high | mitigate — D-14 + verify live exists after |
| T-8-02 Old installer re-run / left callable | high | mitigate — D-04 hard delete + grep |
| T-8-03 Symlink regression | high | mitigate — health asserts before/after |
| T-8-04 Scope creep rewriting historical tests | medium | accept/mitigate — D-03/D-11 leave historical |
| T-8-05 Interactive reinstall without backup | high | mitigate — existing wrapper gate (N/A this run) |

---

## Validation Audit 2026-07-28

| Metric | Count |
|--------|-------|
| Gaps found (pending map rows) | 8 |
| Resolved (automated green) | 8 |
| Escalated / new tests required | 0 |
| Manual-only remaining | 2 (optional chrome; reinstall gate N/A) |
| New smoke scripts created | 0 (D-03) |

**Evidence run (orchestrator, 2026-07-28):** full suite 14/14 PASS — live path/venv/hypr; tree absent; installer absent; wrapper `bash -n`; zero `arch/quickshell.sh` refs under arch/scripts/.config; no phase08 smoke file.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — inline only)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter
- [x] `status: validated` set in frontmatter

**Approval:** validated 2026-07-28 (execute-phase verify:post / validate-phase; full suite green; no new harness)
