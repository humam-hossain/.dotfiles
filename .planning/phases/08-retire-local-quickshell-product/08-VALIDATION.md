---
phase: 8
slug: retire-local-quickshell-product
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-27
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Practical asserts only — **no** new `scripts/phase08-*` smoke suite (D-03).

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
| 08-01-xx | 01 | 1 | RET-01 pre / LIVE hold | T-8-01, T-8-03 | Live path is real dir under `$HOME`, not symlink to repo | smoke (inline) | `test ! -L ~/.config/quickshell && test -d ~/.config/quickshell && test -f ~/.config/quickshell/ii/shell.qml`; `case $(readlink -f ~/.config/quickshell) in *REPO*) false;; esac` | inline | ⬜ pending |
| 08-01-xx | 01 | 1 | RET-01 pre | T-8-01 | venv present | smoke (inline) | `test -d ~/.local/state/quickshell/.venv` | inline | ⬜ pending |
| 08-01-xx | 01 | 1 | LIVE-02 hold | T-8-01 | hypr hooks still present in repo SoT | smoke (inline) | `grep` env + `qs -c ii` in repo hypr conf | inline | ⬜ pending |
| 08-02-xx | 02 | 2 | RET-01 post | T-8-01 | In-repo product tree absent; live untouched | smoke (inline) | `test ! -e "$REPO_ROOT/.config/quickshell"`; re-run live health | inline | ⬜ pending |
| 08-03-xx | 03 | 3 | RET-02 post | T-8-02 | `arch/quickshell.sh` hard-deleted | smoke (inline) | `test ! -e "$REPO_ROOT/arch/quickshell.sh"` | inline | ⬜ pending |
| 08-03-xx | 03 | 3 | RET-02 | T-8-02 | Wrapper remains only install entry | smoke (inline) | `test -x arch/dots-hyprland.sh` | existing wrapper | ⬜ pending |
| 08-03-xx | 03 | 3 | LIVE-01 hold | T-8-03 | After deletes, live still real/not symlink | smoke (inline) | same LIVE-01 path asserts | inline | ⬜ pending |
| 08-03-xx | 03 | 3 | Neg | T-8-02 | No non-planning caller of deleted installer | grep | `git grep -n 'arch/quickshell\.sh' -- arch scripts .config 2>/dev/null` (allow style comment only) | inline | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs finalized by planner — map rows above are requirement-level placeholders seeded from RESEARCH Validation Architecture.*

---

## Wave 0 Requirements

- [x] **None for new test files** — D-03 forbids new smoke scripts
- [x] Framework install: none
- [ ] Planner must embed inline verify commands in each plan task (not reference a missing phase08 script)
- [ ] Planner must **document** that `phase07-live-smoke.sh` is expected red on D-04 after RET-01 so executors do not thrash

*Existing bash + filesystem tools cover all phase requirements without new harness files.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Formal LIVE-04 chrome / UAT checklist re-ceremony | LIVE hold soft | D-03 defers formal UAT chrome; practical health only | Optional: visual glance that ii session still usable after retirement if session is running |
| Interactive reinstall backup gate (only if health fails) | RET-01 pre repair | Wrapper requires operator `yes` | If reinstall needed: `./arch/dots-hyprland.sh --dry-run install` then live `install`; type exact `yes` at backup gate; never `--skip-backup` without `--allow-skip-backup` |

*All core RET-01/RET-02 behaviors have automated filesystem/grep verification.*

---

## Threat Refs (from RESEARCH Security Domain)

| Threat ID | Severity | Disposition |
|-----------|----------|-------------|
| T-8-01 Live path deleted as "retirement" | high | mitigate — D-14 + verify live exists after |
| T-8-02 Old installer re-run / left callable | high | mitigate — D-04 hard delete + grep |
| T-8-03 Symlink regression | high | mitigate — health asserts before/after |
| T-8-04 Scope creep rewriting historical tests | medium | accept/mitigate — D-03/D-11 leave historical |
| T-8-05 Interactive reinstall without backup | high | mitigate — existing wrapper gate |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
