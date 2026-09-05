---
phase: "15"
slug: "playbook-safe-vs-full"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-05"
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

This is a documentation-only phase. "Validation" means deterministically verifying prose
claims: required strings present, forbidden strings absent, cross-reference links resolving,
and commands quoted in the playbook agreeing with the real scripts they describe.

Source: `15-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertions inline in each task's `<automated>` verify block (`grep`, `git diff --quiet`, `test -e`). No test runner exists in this repo and none should be invented (CONVENTIONS.md: "Do not invent a CI linter"). |
| **Config file** | none |
| **Quick run command** | The task's own `<automated>` block (grep/link assertions over `docs/dots-hyprland-workflow.md`) |
| **Full suite command** | `./scripts/phase13-d19-assert.sh && ./scripts/phase14-verify.sh` |
| **Estimated runtime** | ~15 seconds |

**Scope note:** the phase fence in `15-CONTEXT.md` reads "No code, wrapper, script, or session
behaviour changes in this phase." A new `scripts/phase15-docs-assert.sh` would be a new script,
so the assertions live inline in task verify blocks instead (research Assumption A4, resolved
toward the conservative reading). The command shapes are identical either way.

**Existing suites must stay green and are the regression floor:**
- `./scripts/phase13-d19-assert.sh` → `FAIL=0` (15 PASS)
- `./scripts/phase14-verify.sh` → `FAIL=0`, `FINDINGS=1` (the single finding is the expected D-38 loss; a second finding means something regressed)

---

## Sampling Rate

- **After every task commit:** Run that task's `<automated>` verify block
- **After every plan wave:** Run `./scripts/phase13-d19-assert.sh && ./scripts/phase14-verify.sh`
- **Before `/gsd-verify-work`:** Both existing suites green at the values above, and every task verify block green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

Task IDs are assigned by the planner; this table is seeded from the requirement/decision map in
`15-RESEARCH.md` § Validation Architecture and is completed by `/gsd-validate-phase`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | DOC-03 | — | N/A | unit | `grep -qi 'safe profile' docs/dots-hyprland-workflow.md && grep -q -- '--full' docs/dots-hyprland-workflow.md` | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-03 | — | N/A | unit | flag-axis table names `--skip-hyprland`, `--core`, `--skip-sysupdate` | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-03 | — | N/A | agreement | playbook quotes live `SAFE_DEFAULTS` verbatim from `arch/dots-hyprland.sh:12` | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-03 (D-13) | — | N/A | ordering | first `10-INVENTORY.md` mention precedes first `./arch/dots-hyprland.sh install` line | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-03 (D-07) | — | N/A | unit | `grep -qiE 'default.*(safe\|SAFE_DEFAULTS)' docs/dots-hyprland-workflow.md` | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-03 (D-14) | — | N/A | agreement | backup dir matches `II_BACKUP_DIR` default; rotated `.<timestamp>` form absent | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-03 (D-15) | — | N/A | agreement | verify block uses `hyprctl -j status` probe; `getoption configProvider` absent | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-04 | — | N/A | unit | `.config/hypr/custom` named plus one-way repo→live direction stated | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-04 | — | N/A | unit | named-file `cp -a` apply present; `rsync --delete` absent | ✅ | ⬜ pending |
| TBD | TBD | TBD | DOC-04 | — | N/A | unit | `vendor/dots-hyprland` fork boundary stated; `13-SOT-APPLY.md` cited | ✅ | ⬜ pending |
| TBD | TBD | TBD | D-09 / D-39 | — | N/A | forbidden-string | literal `Waybar`/`rofi`/`swaync` used; no "chrome" as a collective noun (exclude `google-chrome` autostart line before matching) | ✅ | ⬜ pending |
| TBD | TBD | TBD | D-10 | — | N/A | forbidden-string | all three stale claims absent (dual-run purpose line, "No Waybar cutover", "wrapper defaults **do not** replace") | ✅ | ⬜ pending |
| TBD | TBD | TBD | D-23 | — | N/A | link check | every relative Markdown link in `docs/dots-hyprland-workflow.md`, `docs/phase14-adopt-runbook.md`, `README.md` resolves | ✅ | ⬜ pending |
| TBD | TBD | TBD | D-19 | — | N/A | guard | `git diff --quiet HEAD -- scripts/phase14-preflight.sh` | ✅ | ⬜ pending |
| TBD | TBD | TBD | D-22 | — | N/A | guard | `git diff --quiet HEAD -- .planning/STATE.md .planning/ROADMAP.md` | ✅ | ⬜ pending |
| TBD | TBD | TBD | scope fence | — | N/A | guard | `git diff --quiet HEAD -- arch/ scripts/ .config/ stow/ vendor/` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No framework install, no new test file, no
shared fixture. Every assertion above is a `grep`/`git`/`test` invocation available in the repo today,
and the two existing assert scripts already run standalone.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Playbook reads as a single linear spine (D-03) with no parallel safe/full tracks | DOC-03 | Prose structure is not mechanically checkable beyond heading counts | Read the rewritten `docs/dots-hyprland-workflow.md` top to bottom; confirm one clone → pin → install → session → verify → update sequence with no branched track |
| Playbook is truthful for a cold machine first, current state as a short note (D-04) | DOC-03 | Audience framing is editorial | Confirm the opening walkthrough addresses a machine with no prior install; the post-adopt state note is short and clearly secondary |
| Deviation from the literal text of D-08 / D-14 / D-15 is accepted | DOC-03 | Research Corrections 1–2 replace strings named in locked decisions with verified ones | `checkpoint:human-verify` in the plan, presenting the probe output from `15-RESEARCH.md` § Ground-Truth Corrections |
| Correcting runbook §14 tier-1 rollback source 3 is inside D-21, not a D-02 structural change | DOC-03 | Decision-boundary judgment | `checkpoint:human-verify` in the plan (research Assumption A2) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
