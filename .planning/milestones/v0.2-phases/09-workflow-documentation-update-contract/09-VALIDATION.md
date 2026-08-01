---
phase: 9
slug: workflow-documentation-update-contract
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-29
validated: 2026-08-01
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Documentation phase — content greps and structural asserts only; **no** new `scripts/phase09-*` harness.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — inline bash + `rg` / `test` in plan task `<automated>` / verify blocks |
| **Config file** | none |
| **Quick run command** | `test -f docs/dots-hyprland-workflow.md && rg -q 'arch/dots-hyprland\.sh' docs/dots-hyprland-workflow.md` |
| **Full suite command** | DOC-01 section greps + DOC-02 pin-bump + non-primary greps + negative retired-installer greps + README/PROJECT cross-link asserts (see map below) |
| **Estimated runtime** | ~2–5 seconds |

**Explicit non-gates (do not thrash on these):**
- Live dual-run chrome re-ceremony (LIVE-04 visual) — optional human skim; not required to *author* docs
- Historical `scripts/phase0x*` expected red/stale — leave frozen (Phase 8 D-11/D-12)
- No pytest/jest/bats

---

## Sampling Rate

- **After every task commit:** Run the greps that task just made true
- **After every plan wave:** Full suite for that plan’s requirement IDs
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-T1 | 01 | 1 | DOC-01 | T-9-01, T-9-02 | Playbook file exists with install chain headings | smoke (inline) | `test -f docs/dots-hyprland-workflow.md` | ❌ W0→create | ⬜ pending |
| 09-01-T2 | 01 | 1 | DOC-01 | T-9-01 | Clone + recursive submodule documented | grep | `rg -n 'clone|--recurse-submodules|submodule update --init --recursive' docs/dots-hyprland-workflow.md` | playbook | ⬜ pending |
| 09-01-T3 | 01 | 1 | DOC-01 | T-9-03, T-9-04 | Wrapper install + dry-run + backup + skip-hyprland + dual-run | grep | `rg` for `arch/dots-hyprland.sh`, `--dry-run`, backup/`yes`, `--skip-hyprland`, `qs -c ii`, `waybar`, `ILLOGICAL_IMPULSE` | playbook | ⬜ pending |
| 09-01-T4 | 01 | 1 | DOC-01 | T-9-02 | Does not instruct running retired installer as current path | neg-grep | zero instructional `arch/quickshell.sh` as current step in playbook | playbook | ⬜ pending |
| 09-02-T1 | 02 | 2 | DOC-02 | T-9-05 | Pin-bump sequence (fetch upstream, bump parent, re-run setup) | grep | `rg` upstream/fetch + parent pin/gitlink/submodule + re-run `install`/`install-files` | playbook | ⬜ pending |
| 09-02-T2 | 02 | 2 | DOC-02 | T-9-05 | exp-merge marked non-primary / experimental | grep | `rg -n 'exp-merge' docs/dots-hyprland-workflow.md` near non-primary/experimental language | playbook | ⬜ pending |
| 09-02-T3 | 02 | 2 | DOC-02 | T-9-05 | Online cache install marked non-primary | grep | `rg -n 'cache|online' docs/dots-hyprland-workflow.md` with non-primary framing | playbook | ⬜ pending |
| 09-03-T1 | 03 | 3 | DOC-01, DOC-02 | T-9-06 | Root README discovers playbook | grep | `rg -n 'dots-hyprland-workflow\|Desktop shell\|illogical' README.md` | README | ⬜ pending |
| 09-03-T2 | 03 | 3 | DOC-01, DOC-02 | T-9-06 | PROJECT workflow doc checklist closed or linked | grep | PROJECT.md references playbook or checks off workflow doc item | PROJECT | ⬜ pending |
| 09-03-T3 | 03 | 3 | DOC-01 | T-9-02 | Non-planning surfaces do not re-teach `arch/quickshell.sh` as current installer | neg-grep | `git grep` scoped to README/docs/arch (excl. planning history) | multi | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] **None for new test files** — docs phase uses inline `rg`/`test` only
- [x] Framework install: none
- [x] Existing infrastructure: bash + ripgrep (assumed on operator/dev machine; same as prior phases)
- [x] `wave_0_complete: true` — no missing test stubs to create before Wave 1

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Clean-read completeness | DOC-01, DOC-02 / SC-3 | Subjective “no tribal knowledge” bar | Skim `docs/dots-hyprland-workflow.md` without chat history; confirm you could clone→dual-run and pin-bump without asking |
| Optional live dual-run chrome | LIVE-04 hold (not DOC gate) | Visual | Only if validating machine state matches docs; not required to ship doc text |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (N/A — none)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter after execute/validate-phase

**Approval:** pending
