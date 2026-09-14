---
phase: "19"
slug: "link-aware-verify"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-14"
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None. Custom bash assert scripts under `scripts/`, per `.planning/codebase/TESTING.md` — this repo has no unit-test framework and must not gain one for this phase |
| **Config file** | none — by design |
| **Quick run command** | `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh verify` |
| **Full suite command** | `./scripts/phase19-link-aware-verify-assert.sh` |
| **Estimated runtime** | ~1 second for the quick run (0.97 s measured); the full sweep is Wave 0 work and not yet timed |

---

## Sampling Rate

- **After every task commit:** Run `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh verify`
- **After every plan wave:** Run `./scripts/phase19-link-aware-verify-assert.sh`
- **Before `/gsd-verify-work`:** All of `phase19`, `phase18`, `phase17`, `phase13-d19`, `phase12-full-smoke` and `phase14-verify` green on a clean tree — the shape STATE.md records for the Phase 16 D-40 gate
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _pending_ | — | — | VER-01 | — | Link identity is checked before content; a folded ancestor, a dangling link into the repo and a stale undeclared link are all named | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ❌ W0 | ⬜ pending |
| _pending_ | — | — | VER-01 | — | `verify` stays green on the real tree (criterion 5) | smoke | `./arch/dots-hyprland.sh verify` | ✅ | ⬜ pending |
| _pending_ | — | — | VER-02 | — | `capture/` drift reports as its own finding class, distinct from a link failure | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ❌ W0 | ⬜ pending |
| _pending_ | — | — | VER-03 | — | Exit 0 clean / 1 drift / 2 precondition; `--strict` promotes findings; `[PASS]`/`[FAIL]`/`[FINDING]`/`[INFO]` and the `=== done: ... ===` summary contract hold | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ❌ W0 | ⬜ pending |
| _pending_ | — | — | VER-03 | — | `--quiet` suppresses `[PASS]` lines only; output above the summary is byte-identical with and without `--strict` | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ❌ W0 | ⬜ pending |
| _pending_ | — | — | VER-04 | T-19-01 | The destructive `rsync -a --delete` fixture refuses to run unless its target is a scratch package and a scratch target directory | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ❌ W0 | ⬜ pending |
| _pending_ | — | — | VER-04 | — | The cp-through class is reported: link `[PASS]`, exit 0, content difference `[INFO]` | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ❌ W0 | ⬜ pending |
| _pending_ | — | — | regression | — | Phase 18, 17 and 13 asserts stay green after the wrapper edit | integration | `./scripts/phase18-capture-model-assert.sh && ./scripts/phase17-unblock-assert.sh && ./scripts/phase13-d19-assert.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs are filled in by the planner; this table is seeded from the Validation Architecture section of `19-RESEARCH.md`.*

---

## Wave 0 Requirements

- [ ] `scripts/phase19-link-aware-verify-assert.sh` — does not exist yet; covers VER-01 through VER-04
- [ ] A reusable fixture builder inside that script (the D-24 shape plus the working-directory fix recorded as Pitfall 1 in research). There is no shared fixture library in this repo and `.planning/codebase/TESTING.md` says not to add one, so factor it as functions inside the single script
- [ ] Framework install: none required

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| _none identified_ | — | — | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
