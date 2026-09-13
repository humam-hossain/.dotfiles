# Phase 17 — deferred items

Out-of-scope discoveries logged during execution. Nothing here was fixed; each
row names what is broken, why it was left alone, and who should own it.

---

## D-1 — `scripts/phase14-verify.sh` aborts on a baseline fixture the v0.3 archive moved

**Found during:** plan 17-03, Task 3 (running the plan's wave-close verification).

**Symptom:**

```
$ ./scripts/phase14-verify.sh
[FAIL] baseline fixture missing: .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt
EXIT=1
```

The script aborts before its first assert, so it never reaches its own
`=== done: FAIL=n ===` line at all.

**Cause:** the fixture still exists — it was relocated by `f314491 chore: archive
v0.3 milestone` and now lives at
`.planning/milestones/v0.3-phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt`.
`scripts/phase14-verify.sh` still hard-codes the pre-archive
`.planning/phases/…` path.

**Pre-existing, not caused by 17-03.** The three commits in this plan touch only
`.gitattributes`, `.gitignore`, `.gitleaks.toml` and
`scripts/phase17-unblock-assert.sh` (`git diff --name-only b95917a4 HEAD`), and
`git check-ignore --no-index` exits 1 on the fixture path, so none of the new
ignore patterns reaches it.

**Why deferred:** out of scope under the executor scope boundary — this is a
failure in an unrelated file with an unrelated cause. Fixing it means editing a
Phase 14 artifact to be archive-aware, which is the same repair plan 17-02
already performed on `scripts/phase13-d19-assert.sh`.

**Suggested owner / fix:** whoever next touches Phase 14 verification. Apply the
17-02 pattern: resolve phase artifacts through a live-tree-then-milestone-archive
lookup instead of a hard-coded `.planning/phases/` path. See 17-02-SUMMARY.md,
pattern "Phase artifacts are resolved through a live-tree-then-milestone-archive
lookup".

**Impact if left:** Phase 17 plans whose `<verify>` block calls
`./scripts/phase14-verify.sh` (17-03 Task 2 does) cannot satisfy that one check.
The three live harnesses — `phase17-unblock-assert.sh`,
`phase16-retire-assert.sh`, `phase13-d19-assert.sh` — all close `FAIL=0`, so
phase coverage is intact apart from this stale path.

---

## D-2 — no repo-wide sweep for scripts hard-coding a pre-archive `.planning/phases/` path

**Found during:** plan 17-04, while re-running the sibling suites at wave close.

**Symptom:** the same defect has now appeared in two separate scripts. Plan
17-02 fixed it in `scripts/phase13-d19-assert.sh`; D-1 above records it still
open in `scripts/phase14-verify.sh`. Both hard-code a `.planning/phases/…` path
that `f314491 chore: archive v0.3 milestone` relocated to
`.planning/milestones/v0.3-phases/…`.

**Cause:** milestone archival moves phase directories, and nothing checks
whether a script still points at the old location. Each occurrence has been
found by a script failing at run time, one at a time.

**Why deferred:** this is a cross-cutting repository sweep, not a Phase 17
change. Phase 17's scope is the stow unblock and the session target; editing
every phase harness to be archive-aware is outside it, and doing it piecemeal as
each script happens to fail is what produced two separate fixes already.

**Suggested owner / fix:** Phase 18. Grep the repository for the literal
`.planning/phases/` outside `.planning/` itself, and convert each hit to the
live-tree-then-milestone-archive lookup that 17-02 established. See
17-02-SUMMARY.md, pattern "Phase artifacts are resolved through a
live-tree-then-milestone-archive lookup".

**Impact if left:** every future milestone archival silently breaks another
batch of harnesses, each discovered only when someone runs it.
