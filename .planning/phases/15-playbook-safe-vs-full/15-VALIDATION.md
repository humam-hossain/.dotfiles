---
phase: "15"
slug: "playbook-safe-vs-full"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: true
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
- `./scripts/phase13-d19-assert.sh` → `FAIL=0` (15 PASS). Safe to run from a task verify block: it does not inspect the working tree.
- `./scripts/phase14-verify.sh` → `FAIL=0`, `FINDINGS=1` (the single finding is the expected D-38 loss; a second finding means something regressed)

> **D-35 timing caveat (measured 2026-09-05, planning session).** `scripts/phase14-verify.sh` additionally
> asserts a clean working tree outside `.planning/phases/14-live-full-adopt-verify/`, and emits
> `[FAIL] D-35 working tree is dirty …` when it is not. A task verify block runs *before* that task's
> commit, so this script cannot be used as a per-task regression floor — it would fail on the task's own
> uncommitted edit. It is therefore run once, at the phase gate in plan `15-06`, with the gate tolerating
> that one exact `[FAIL]` line and no other:
>
> ```bash
> ./scripts/phase14-verify.sh >/tmp/p15-gate-p14.txt 2>&1 || true
> test "$(grep -c '^\[FINDING\]' /tmp/p15-gate-p14.txt)" -eq 1
> test "$(grep '^\[FAIL\]' /tmp/p15-gate-p14.txt | grep -vc 'D-35 working tree is dirty')" -eq 0
> ```
>
> Per-task regression floor is `./scripts/phase13-d19-assert.sh` alone.

---

## Sampling Rate

- **After every task commit:** Run that task's `<automated>` verify block
- **After every plan wave:** Run `./scripts/phase13-d19-assert.sh`. Add `./scripts/phase14-verify.sh` only once the wave's commits have landed — see the D-35 timing caveat above
- **Before `/gsd-verify-work`:** Both existing suites green at the values above, and every task verify block green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

Task IDs were assigned by the planner on 2026-09-05 and reference `{plan} T{n}` in
`.planning/phases/15-playbook-safe-vs-full/15-NN-PLAN.md`. Every command below was executed against the
pre-rewrite tree during planning, so each is known to run; the assertions are stated in the direction that
will hold *after* the rewrite. Status flips are set by `/gsd-validate-phase`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01 T2 | 15-01 | 1 | DOC-03 (D-15) | T-15-01 | doc names the probe that exists | agreement | `grep -q -- '-j status' docs/dots-hyprland-workflow.md && test -z "$(grep -l 'getoption configProvider' docs/dots-hyprland-workflow.md docs/phase14-adopt-runbook.md README.md .planning/PROJECT.md 2>/dev/null)"` | ✅ | ⬜ pending |
| 15-02 T2 | 15-02 | 2 | DOC-03 | T-15-06 | both profiles named | unit | `grep -qi 'profiles' docs/dots-hyprland-workflow.md && grep -q -- '--full' docs/dots-hyprland-workflow.md` | ✅ | ⬜ pending |
| 15-02 T2 | 15-02 | 2 | DOC-03 | — | flag-axis table names all three axes | unit | `for f in skip-hyprland core skip-sysupdate; do grep -q -- "--$f" docs/dots-hyprland-workflow.md \|\| exit 1; done` | ✅ | ⬜ pending |
| 15-02 T2 | 15-02 | 2 | DOC-03 | T-15-07 | playbook quotes live `SAFE_DEFAULTS` verbatim | agreement | `SD="$(grep -oP '^SAFE_DEFAULTS=\(\K[^)]+' arch/dots-hyprland.sh)" && grep -qF -- "$SD" docs/dots-hyprland-workflow.md` | ✅ | ⬜ pending |
| 15-02 T2 | 15-02 | 2 | DOC-03 (D-07) | T-15-06 | safe is still the default | unit | `grep -qiE 'default.*(safe\|SAFE_DEFAULTS)' docs/dots-hyprland-workflow.md` | ✅ | ⬜ pending |
| 15-02 T3 | 15-02 | 2 | DOC-03 (D-13) | T-15-08 | gate precedes first install command | ordering | line number of first `10-INVENTORY.md` < line number of first `./arch/dots-hyprland.sh install` | ✅ | ⬜ pending |
| 15-01 T2 · 15-02 T1 | 15-01, 15-02 | 1-2 | D-10 | — | three stale claims absent | forbidden-string | `! grep -qF 'reach dual-run' && ! grep -qF 'wrapper defaults **do not** replace' && ! grep -qF 'No Waybar cutover'` | ✅ | ⬜ pending |
| 15-03 T1 | 15-03 | 2 | D-19 | T-15-15 | preflight script untouched | guard | `test -z "$(git diff --name-only origin/main...HEAD -- scripts/phase14-preflight.sh)"` | ✅ | ⬜ pending |
| 15-03 T1 | 15-03 | 2 | DOC-03 (D-21) | T-15-11 | rollback tier-1 source 3 names the recoverable backup | agreement | `grep -q '3d17932a' docs/phase14-adopt-runbook.md && ! grep -qF 'the timestamped directory section 5 created' docs/phase14-adopt-runbook.md` | ✅ | ⬜ pending |
| 15-03 T2 | 15-03 | 2 | D-02 | T-15-14 | runbook structure preserved | unit | `test "$(grep -c '^## ' docs/phase14-adopt-runbook.md)" -eq 17` | ✅ | ⬜ pending |
| 15-04 T1 | 15-04 | 3 | DOC-03 (D-14) | T-15-16, T-15-17 | backup dir matches `II_BACKUP_DIR`; rotated form absent | agreement | `grep -q 'ii-original-dots-backup' … && ! grep -qE 'ii-original-dots-backup\.[0-9]{8}T' … && grep -q -- '--allow-skip-backup' …` | ✅ | ⬜ pending |
| 15-04 T3 | 15-04 | 3 | DOC-04 | T-15-19 | overlay dir named, one-way direction stated | unit | `grep -q '.config/hypr/custom' … && grep -qiE 'one-way\|repo *(→\|->\|to) *live' …` | ✅ | ⬜ pending |
| 15-04 T3 | 15-04 | 3 | DOC-04 | T-15-19 | named-file `cp -a` present, no mirroring delete | unit | `grep -q 'cp -a' … && test "$(grep -c 'rsync' docs/dots-hyprland-workflow.md)" -eq 0` | ✅ | ⬜ pending |
| 15-04 T3 | 15-04 | 3 | DOC-04 | — | fork boundary stated, `13-SOT-APPLY.md` cited | unit | `grep -q 'vendor/dots-hyprland' … && grep -q '13-SOT-APPLY.md' …` | ✅ | ⬜ pending |
| 15-05 T1 | 15-05 | 4 | D-09 / D-39 | T-15-24 | trio named literally; no collective noun | forbidden-string | `test "$(grep -oE '[A-Za-z0-9_-]*[Cc]hrome[A-Za-z0-9_-]*' <file> \| grep -vx 'google-chrome-stable' \| wc -l)" -eq 0` and `grep -cE '\brofi\b' … -ge 2` | ✅ | ⬜ pending |
| 15-05 T1 | 15-05 | 4 | D-17 | T-15-24 | D-38 loss stated as a possibility, not a certainty | forbidden-string | hedged `screen share … may` present; `screen share is broken` count 0 | ✅ | ⬜ pending |
| 15-05 T3 | 15-05 | 4 | D-23 | T-15-26 | every relative link and in-page anchor resolves | link check | link-resolution loop over the three prose docs + Outline-anchor slug loop over the playbook | ✅ | ⬜ pending |
| 15-06 T2 | 15-06 | 5 | D-22 | T-15-28, T-15-29 | frozen artifacts flagged, never edited; STATE/ROADMAP not directly edited | guard | `test -z "$(git diff --name-only origin/main...HEAD -- <4 frozen artifacts>)"` + `git diff --quiet HEAD -- .planning/STATE.md .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 15-06 T3 | 15-06 | 5 | scope fence | T-15-30 | no code, script, config, stow or vendor change in the phase's commit range | guard | `test -z "$(git diff --name-only origin/main...HEAD -- arch/ scripts/ .config/ stow/ vendor/)"` | ✅ | ⬜ pending |
| 15-06 T3 | 15-06 | 5 | DOC-03, DOC-04 | T-15-33 | phase gate: both suites at baseline | suite | `phase13-d19-assert.sh` 15 PASS / 0 FAIL; `phase14-verify.sh` 1 FINDING and no FAIL besides the D-35 dirty-tree line | ✅ | ⬜ pending |

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
