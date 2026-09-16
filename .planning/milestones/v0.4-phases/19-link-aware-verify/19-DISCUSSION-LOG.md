# Phase 19: Link-aware `verify` - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `19-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-09-14
**Phase:** 19-link-aware-verify
**Areas discussed:** Live-side sweep, Exit codes and --strict, Adversarial harness, Q3 stray temp files, Decision review
**Decisions recorded:** 56

Four gray areas were selected at the outset. A fifth — **Decision review** — was opened when the operator asked, at the Area 4 continue-check, to "review all the decisions and find any conflicting decisions and find decisions that can simplify things". That review found six conflicts and six collapse candidates, every one measured against the live tree rather than argued in the abstract; the operator adopted all of them. Eight earlier answers were superseded as a result, and both forms are recorded below — the superseded form is marked and must not be implemented.

One review item was corrected twice. S-1 first narrowed the unclaimed-stub rule to installer-artifact filename shapes; measuring the live tree then showed that rule would skip all 11 of the files success criterion 5 actually names, because they are plain files. The final rule keys on shared root versus package-owned directory instead.

---

## Live-side sweep

### Does verify gain a live-side walk, and over what root?

| Option | Selected |
|--------|----------|
| Bounded to managed dirs (Recommended) | ✓ |
| Full ~/.config walk + ignore list |  |
| No live walk |  |

**Chosen:** Bounded to managed dirs — walk only the directories derived from repo-tree relative paths (29 of them), not a full ~/.config traversal

### Inside a managed directory, what counts as an entry the live walk examines?

| Option | Selected |
|--------|----------|
| Same dir only, non-recursive (Recommended) | ✓ |
| Recursive from each managed root |  |
| Same dir only, and only files whose basename the repo claims |  |

**Chosen:** Same dir only, non-recursive — list entries of directories that directly contain a repo-managed file; never descend into unmanaged subtrees

### How does the live walk decide an unclaimed neighbour is worth an [INFO] line?

| Option | Selected |
|--------|----------|
| Real file beside a managed symlink (Recommended) | ✓ |
| Only if collision-map.tsv lists it as a vendor dest |  |
| Only dangling links and folded dirs — no stub lines at all |  |

**Chosen:** Two clauses, both keyed on observable properties (S-1, corrected). (a) In ANY managed directory, a regular non-symlink entry whose name matches *.old, *.new, *.bak or *.bak.* gets one [INFO] as an installer backup artifact. (b) In a PACKAGE-OWNED managed directory only — depth >= 2 below $HOME — any other regular non-symlink entry gets one [INFO] as an unclaimed upstream stub. Measured on the live tree: 19 artifacts + 11 stubs = 30 [INFO] lines, against 52 for the original 'any regular file anywhere' rule. No collision-map lookup, holding D-05.

**Superseded form — do not implement:** Real file beside a managed symlink — any regular non-symlink entry in a managed dir gets one [INFO]; no collision-map lookup, holding D-05.

### A managed file's ancestor directory is itself a symlink into the repo (stow folded it). What does verify report?

| Option | Selected |
|--------|----------|
| [FAIL] with the unfold command (Recommended) | ✓ |
| [FINDING] — recorded, does not move the exit code |  |
| You decide |  |

**Chosen:** [FAIL] with the unfold command, checked before the per-file link test so one folded dir does not emit duplicate failures

### How does the stub rule handle $HOME root, where 6 managed links sit among 44 unrelated regular files?

| Option | Selected |
|--------|----------|
| Exempt $HOME root from the stub check (Recommended) | ✓ |
| Apply it uniformly, accept 44 INFO lines |  |
| Only name dotfile-looking neighbours in $HOME root |  |

**Chosen:** $HOME root and $HOME/.config are both SHARED ROOTS and are exempt from clause (b) of the stub rule only (S-1, corrected). SUPERSEDES the original '$HOME root only' exemption: the axis is shared root versus package-owned directory, not one hardcoded path. Measured: $HOME root holds 44 unrelated regular files and .config holds 27, and both are directories every application on the system writes into by convention; every directory at depth >= 2 is owned by exactly one application. Clause (a) — the artifact shapes — still applies in the shared roots, and link, folded-ancestor and dangling checks run everywhere without exception.

**Superseded form — do not implement:** Exempt $HOME root from the stub check; still run link, folded-ancestor and dangling checks on the 6 managed paths there.

### A dangling symlink turns up inside a managed directory. What does verify report?

| Option | Selected |
|--------|----------|
| [FAIL] if it points into the repo, [FINDING] otherwise (Recommended) | ✓ |
| [FAIL] for any dangling link in a managed dir |  |
| [FINDING] for all of them |  |

**Chosen:** [FAIL] if its target resolves under the repo; [INFO] otherwise. SUPERSEDES the original '[FINDING] otherwise' (C-1). Measured: $HOME/.steampath and $HOME/.steampid dangle on a healthy machine whenever Steam is not running, so a [FINDING] there made `verify --strict` exit 1 on a clean tree from day one. PITFALLS A-6 (repo unavailable at login) produces links that dangle INTO the repo, so it stays fully covered by the [FAIL] arm.

**Superseded form — do not implement:** [FAIL] if its target resolves under the repo, [FINDING] otherwise.

### How does the live-side sweep sit against the existing repo-side walk in run_verify?

| Option | Selected |
|--------|----------|
| Separate pass, repo-side first (Recommended) | ✓ |
| Interleaved — one walk, both checks per path |  |
| Live sweep first, as a precondition gate |  |

**Chosen:** Separate pass, repo-side first — keep the Phase 18 loop untouched, add the live sweep as its own labelled section afterwards

### The script defines XDG_CONFIG_HOME but stow always lands paths under $HOME/.config. Which does the live sweep resolve against?

| Option | Selected |
|--------|----------|
| $HOME/<rel> only, ignore XDG_CONFIG_HOME (Recommended) | ✓ |
| Resolve via XDG_CONFIG_HOME |  |
| $HOME/<rel>, plus [FINDING] when XDG_CONFIG_HOME is set to a non-default value |  |

**Chosen:** $HOME/<rel> only, ignore XDG_CONFIG_HOME — matches what stow -t ~ actually does and what the existing repo-side loop does

### A derived managed directory does not exist live at all. What does the live sweep do?

| Option | Selected |
|--------|----------|
| Skip silently — the repo-side pass already failed it (Recommended) | ✓ |
| [FAIL] naming the directory once |  |
| [INFO] naming the directory |  |

**Chosen:** [INFO] managed directory absent: <path> — SUPERSEDES 'skip silently' (C-2). Silence was the exact ambiguity the per-directory [PASS] of decision 10 exists to remove. With this, all 29 managed directories emit exactly one line on every run and the line count is invariant. The repo-side pass still owns the per-file [FAIL] with the recovery stow command (D-54).

**Superseded form — do not implement:** Skip silently — the repo-side pass already emitted [FAIL] no live counterpart per file with the recovery stow command (D-54).

### What does the live sweep print when it finds nothing wrong?

| Option | Selected |
|--------|----------|
| One [PASS] per managed directory (Recommended) | ✓ |
| Silence — only report pathologies |  |
| One [PASS] summarising the whole sweep |  |

**Chosen:** One [PASS] per managed directory (29 lines) — a silent pass is indistinguishable from a skipped directory (D-53 reasoning)

### A managed directory's path contains a component that is a symlink pointing outside the repo. What does the sweep do?

| Option | Selected |
|--------|----------|
| Allow it, resolve through, check as normal (Recommended) | ✓ |
| [FINDING] naming the out-of-repo ancestor link |  |
| [FAIL] — any symlinked ancestor is a precondition violation |  |

**Chosen:** Allow it, resolve through, check as normal — only a symlink into the repo is the pathology criterion 1 names

### An entry in a managed directory is a symlink into the repo at a path the repo's managed file set does not declare (stale stow link).

| Option | Selected |
|--------|----------|
| [FAIL] naming the stale link and its target (Recommended) | ✓ |
| [FINDING] — recorded, no exit-code effect |  |
| [INFO] — treat it like any unclaimed neighbour |  |

**Chosen:** [FAIL] naming the stale link and its target — the repo-side walk can never see it, since it only visits declared paths

### An entry in a managed directory is a symlink that resolves fine but points outside the repo.

| Option | Selected |
|--------|----------|
| Silent — not a regular file, not a repo link, not this tool's business (Recommended) | ✓ |
| [INFO] naming it as an unclaimed neighbour |  |
| [FINDING] — a foreign link in a managed dir is worth flagging |  |

**Chosen:** Silent — not a regular file, not a repo link, not this tool's business

### A real subdirectory sits inside a managed directory but the repo declares nothing in it.

| Option | Selected |
|--------|----------|
| Silent — stub rule is regular files only (Recommended) | ✓ |
| [INFO] naming unclaimed subdirectories too |  |
| Silent, but [INFO] if the subdirectory contains a symlink into the repo |  |

**Chosen:** Silent — the stub rule is regular files only; directories are neither descended into nor named

### The sweep cannot read a managed directory (permissions, or a mount that went away).

| Option | Selected |
|--------|----------|
| [FAIL] naming the directory and the errno reason (Recommended) | ✓ |
| [INFO] — a condition this run could not observe, named not skipped |  |
| Exit 2 — precondition failure, the whole run is untrustworthy |  |

**Chosen:** [FAIL] naming the directory and the errno reason — verify must never report [PASS] for a condition it could not observe

### Where does the managed-directory root set come from?

| Option | Selected |
|--------|----------|
| Derived at runtime from the trees (Recommended) | ✓ |
| Static list in the script |  |
| Derived, with an explicit extras list appended |  |

**Chosen:** Derived at runtime from the trees — walk stow/*/ and restow/*/, strip package prefix, dirname, dedupe (29 dirs today)

---

## Exit codes and --strict

### What earns exit 2 (precondition failure) rather than exit 1 (drift)?

| Option | Selected |
|--------|----------|
| verify could not make a verdict at all (Recommended) | ✓ |
| Also includes environment pathologies found mid-run |  |
| Exit 2 only for explicit refusals |  |

**Chosen:** verify could not make a verdict at all — $HOME unset or not a directory, stow/ and restow/ both absent, repo root unresolvable, required binary missing. Exit 1 stays 'I looked, and the tree is wrong.'

### What exactly does --strict promote?

| Option | Selected |
|--------|----------|
| Every [FINDING] counts toward the exit code (Recommended) | ✓ |
| Findings and INFO both promote |  |
| Only capture/ content drift promotes |  |

**Chosen:** Every [FINDING] counts toward the exit code — exit 1 iff FAIL>0 or FINDINGS>0. [INFO] never moves the exit code under any flag.

### Under --strict, does a promoted finding still print as [FINDING]?

| Option | Selected |
|--------|----------|
| Yes — labels are fixed, only the exit code moves (Recommended) | ✓ |
| No — promoted findings print as [FAIL] |  |
| Keep [FINDING], add a one-line strict banner at the top |  |

**Chosen:** Yes — labels are fixed, only the exit code moves. A strict run and a normal run over the same tree produce byte-identical output above the summary.

### With exit 2 defined as 'could not make a verdict at all', what should an unknown flag now exit?

| Option | Selected |
|--------|----------|
| Exit 2 (Recommended) | ✓ |
| Keep exit 1 |  |
| Exit 2, and also print the accepted flag list |  |

**Chosen:** Exit 2 — changes the existing exit 1 behaviour at arch/dots-hyprland.sh:729, since an unknown flag means the tree was never examined

### --strict is an argument. How does Phase 19 reconcile that with D-53?

| Option | Selected |
|--------|----------|
| Narrow D-53 to scope, not arguments (Recommended) | ✓ |
| Treat it as a deliberate supersession of D-53 |  |
| Keep D-53 literally; make strict an env var |  |

**Chosen:** Narrow D-53 to scope, not arguments — restate as 'no flag narrows what verify examines'. --strict makes the verdict harsher over the identical full sweep, so it is compliant by construction.

### On an exit-2 precondition failure, does verify still print the closing === done: === line?

| Option | Selected |
|--------|----------|
| No — exit 2 prints the reason and nothing else (Recommended) | ✓ |
| Yes — always print it, with counts reflecting what ran |  |
| Yes, but with a distinct marker |  |

**Chosen:** No — exit 2 prints [FAIL] precondition: <reason> to stderr and stops. The summary line asserts a completed verdict.

### Does the closing summary line change shape in Phase 19?

| Option | Selected |
|--------|----------|
| No — `=== done: FAIL=n FINDINGS=n ===` verbatim (Recommended) | ✓ |
| Append the effective exit code |  |
| Append a strict marker when the flag is set |  |

**Chosen:** No — '=== done: FAIL=n FINDINGS=n ===' verbatim, as D-49 locked and criterion 3 restates

### What is the complete accepted flag surface for verify when Phase 19 ends?

| Option | Selected |
|--------|----------|
| `-h`/`--help` and `--strict`, nothing else (Recommended) | ✓ |
| Add `--quiet` to suppress [PASS] lines |  |
| Add `--json` for machine consumption |  |

**Chosen:** -h/--help, --strict and --quiet, nothing else. AMENDED to admit --quiet (S-6). A closed surface is what makes the exit-2-on-unknown-flag rule meaningful; the phase assert enumerates the accepted set exhaustively.

**Superseded form — do not implement:** -h/--help and --strict, nothing else.

---

## Adversarial harness

### Where does the harness build its fixture?

| Option | Selected |
|--------|----------|
| Temp dir used as $HOME, D-44/D-45 shape (Recommended) | ✓ |
| Scratch dirs under the repo, real $HOME untouched |  |
| Scratch dirs under $XDG_RUNTIME_DIR |  |

**Chosen:** mktemp -d used as $HOME (D-44/D-45 shape) — scratch package and scratch target inside it, run HOME=$tmpdir verify. Real $HOME is never a candidate target.

### Where does the destructive harness live?

| Option | Selected |
|--------|----------|
| Inside the phase assert, scripts/phase19-*-assert.sh (Recommended) | ✓ |
| Its own gated destructive script |  |
| Both — assert runs it, but it is separately executable |  |

**Chosen:** Inside the phase assert (D-57). The fixture is contained in a mktemp -d that is never the real $HOME, so destruction is scoped by construction rather than by a gate.

### How is the destructive target guarded before rsync -a --delete runs?

| Option | Selected |
|--------|----------|
| Allowlist — target must resolve under the mktemp dir this run created (Recommended) | ✓ |
| Denylist — refuse the roadmap's two named conditions |  |
| Both — allowlist plus the two explicit denials |  |

**Chosen:** Allowlist — realpath the target, abort unless it is a strict prefix match on the mktemp -d path captured at setup. Fails closed; the roadmap's two named conditions are satisfied automatically.

### What does the harness assert for the cp-through case?

| Option | Selected |
|--------|----------|
| Link checks still PASS, and verify emits [INFO] naming the path (Recommended) | ✓ |
| verify exits 1 and names the path |  |
| verify is silent; the harness asserts git status instead |  |

**Chosen:** Link checks still PASS, verify still exits 0, and the repo-vs-HEAD content change is named as [INFO] — NOT [FINDING]. cp-through is not a link failure; this pins the boundary between the two classes. See the Decision review entry on why [INFO] is the correct confidence level here.

### How does verify compute 'repo content differs from HEAD' in a scratch fixture?

| Option | Selected |
|--------|----------|
| git -C <repo root> diff --quiet HEAD -- <path>, repo root found from the repo side (Recommended) | ✓ |
| Skip the HEAD check when the repo root is not a git work tree |  |
| Compare against the vendor submodule copy instead of HEAD |  |

**Chosen:** git -C <repo root> diff --quiet HEAD -- <path>, repo root resolved from the repo side via get_main_repo_root() independently of $HOME. The harness git inits the scratch package so the same code path runs against a real HEAD.

### How is the negative control staged?

| Option | Selected |
|--------|----------|
| Same fixture builder, run verify before and after the rsync (Recommended) | ✓ |
| Two independent fixtures built from the same function |  |
| Negative control only, plus a mocked failure for the positive case |  |

**Chosen:** Same fixture builder — run verify before the rsync (expect 0, path shows [PASS]) and after (expect 1, same path in a [FAIL]). Only the destructive command varies.

### What happens to the mktemp -d fixture when the harness fails mid-run?

| Option | Selected |
|--------|----------|
| EXIT trap removes it unconditionally (Recommended) | ✓ |
| Trap removes it, unless KEEP_FIXTURE=1 is set |  |
| Leave it on failure, remove it on success |  |

**Chosen:** trap 'rm -rf "$tmpdir"' EXIT set immediately after mktemp -d, before anything is written into it. Unconditional; the transcript carries what a post-mortem needs.

### The harness needs stow and rsync present. What if they are missing?

| Option | Selected |
|--------|----------|
| [FAIL] in the assert — an unprovable claim is a failed claim (Recommended) | ✓ |
| [INFO] and skip the adversarial section |  |
| Construct the fixture symlink by hand, no stow dependency |  |

**Chosen:** [FAIL] in the assert naming the missing binary — an unprovable claim is a failed claim. Distinct from verify itself, which by D-47 needs neither.

### Does the harness exercise install_file__auto_backup (the other destroying primitive)?

| Option | Selected |
|--------|----------|
| Yes — third case, and assert the .old artifact is named (Recommended) | ✓ |
| No — rsync case is sufficient |  |
| Yes, but only assert the [FAIL] — ignore the .old artifact |  |

**Chosen:** Yes — and BOTH branches of the primitive (C-6). vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:106-114 branches on INSTALL_FIRSTRUN: true does `mv $t $t.old` then copies (link destroyed, .old artifact); false does `cp_file $s $t.new` (link INTACT, .new sibling). Fixture covers both: firstrun asserts [FAIL] missing link plus [INFO] on the .old artifact; non-firstrun asserts [PASS] on the link plus [INFO] on the .new sibling.

**Superseded form — do not implement:** Yes — third case, and assert the <name>.old artifact surfaces as [INFO] while the missing link is [FAIL].

### Does the assert check the text of the [FAIL] message, or only that the path is named?

| Option | Selected |
|--------|----------|
| Path named, plus the recovery command is present (Recommended) | ✓ |
| Path named only |  |
| Exact full-line match |  |

**Chosen:** Path named, plus the recovery command is present — assert the line contains a `stow -t` invocation naming the right package (D-54's value).

### Which live-sweep pathologies get their own fixture case?

| Option | Selected |
|--------|----------|
| Folded ancestor directory | ✓ |
| Dangling link into the repo | ✓ |
| Stale link into the repo at an undeclared path | ✓ |
| Unclaimed stub beside a managed link | ✓ |

*Multi-select — every listed pathology was chosen.*

**Chosen:** All four, staged simultaneously in ONE scratch $HOME (S-4) — folded ancestor directory, dangling link into the repo (plus the non-repo [INFO] variant), stale link into the repo at an undeclared path, and an unclaimed installer-artifact stub beside a managed link. One verify run, assert all four lines present AND the exact `FAIL=n FINDINGS=n` counts. Collapses 5 setup/teardown cycles into 1 and additionally proves the counters aggregate, which no single-pathology fixture can test.

**Superseded form — do not implement:** All four — each staged as its own separate fixture case, with the non-repo variant reported as [FINDING].

### Does the assert also exercise --strict and the exit-2 path?

| Option | Selected |
|--------|----------|
| Yes — all three exit codes proven against fixtures (Recommended) | ✓ |
| Exit 0 and 1 only |  |
| Yes, and also assert strict output is byte-identical above the summary |  |

**Chosen:** Yes — all three exit codes proven against fixtures: 0 clean, 1 destroyed link, 1 under --strict on a findings-only fixture that exits 0 without it, 2 on an unknown flag. The findings-only fixture must stage a capture/ package: after C-1 and C-3, capture/ content drift and capture/ missing-live-counterpart are the only [FINDING] sources in Phase 19.

### Does the assert run verify against the real $HOME as a final step?

| Option | Selected |
|--------|----------|
| Yes — read-only real-tree run as the last section (Recommended) | ✓ |
| Yes, but as [FINDING] not [FAIL] |  |
| No — fixtures only |  |

**Chosen:** Yes — read-only real-tree run as the last section, after fixture teardown, [FAIL] if it does not exit 0. Checks criterion 5 rather than asserting it.

### How is set -euo pipefail reconciled with deliberately expecting non-zero exits?

| Option | Selected |
|--------|----------|
| Keep set -euo pipefail; capture exits with `|| rc=$?` (Recommended) | ✓ |
| Drop set -e for the assert script |  |
| Wrap each expectation in an `if ! ...; then` helper |  |

**Chosen:** Keep the boilerplate; capture stdout and stderr SEPARATELY, not merged: `rc=0; HOME=$tmp run_verify >"$out" 2>"$err" || rc=$?` and compare rc to the expected code at each call site. AMENDED from `2>&1` (C-5) so the exit-2 case can prove the precondition reason lands on fd 2 and that `=== done:` appears in neither stream.

**Superseded form — do not implement:** Keep the boilerplate; capture with `rc=0; HOME=$tmp run_verify >"$out" 2>&1 || rc=$?` and compare rc to the expected code at each call site.

### How does the assert prove it left the real $HOME and the repo untouched?

| Option | Selected |
|--------|----------|
| git status --porcelain unchanged before and after (Recommended) | ✓ |
| Assert the 6 $HOME-root managed links still resolve |  |
| Rely on the allowlist guard alone |  |

**Chosen:** Capture git status --porcelain at the top and again at the end; [FAIL] if they differ. Also catches a stray temp file, which is the next area's subject.

### What is the assert script named?

| Option | Selected |
|--------|----------|
| scripts/phase19-link-aware-verify-assert.sh (Recommended) | ✓ |
| scripts/phase19-verify-assert.sh |  |
| scripts/phase19-link-aware-assert.sh |  |

**Chosen:** scripts/phase19-link-aware-verify-assert.sh — slug matches the phase directory and roadmap title exactly

---

## Q3 stray temp files

### Is the QSaveFile temp-file question answered by measurement or by assumption?

| Option | Selected |
|--------|----------|
| Measure first — hand it to the phase researcher | ✓ |
| Assume it happens and ship a .gitignore rule now |  |
| Assume it does not and document the assumption |  |

**Chosen:** Measure first — hand it to the gsd-phase-researcher: poll `git status --porcelain` while driving a burst of Qt/KDE writes through the stowed kdeglobals/dolphinrc links, and record whether any temp file ever lands in the repo working tree.

### Does Phase 19 ship a .gitignore rule for stray temp files?

| Option | Selected |
|--------|----------|
| Only if the measurement observes one | ✓ |
| Ship a defensive rule regardless |  |
| Never — keep .gitignore free of speculative rules |  |

**Chosen:** Only if the measurement observes one, and then narrowly anchored to the observed path rather than slash-free. .gitignore's generated-theme block documents the slash-free convention as deliberate; a temp-file rule has the opposite requirement and must not be mistaken for that pattern.

### Does verify gain a dedicated stray-temp-file check?

| Option | Selected |
|--------|----------|
| No — out of scope for Phase 19 | ✓ |
| Yes — [FINDING] on any untracked file in the trees |  |
| Yes, but only under --strict |  |

**Chosen:** No — out of scope for Phase 19. A temp file is transient by construction, so a check for one would flap between runs and make verify's verdict non-deterministic. The assert's `git status --porcelain` before/after bracket already catches a temp file that outlives the run.

### Where does the answer get written down?

| Option | Selected |
|--------|----------|
| PITFALLS.md, extending the A-6 entry | ✓ |
| A new standalone research note |  |
| CONTEXT.md only |  |

**Chosen:** PITFALLS.md, extending the existing A-6 entry — including the measurement method and the same-device caveat (/home/pera and the repo are both device 66311, so cross-filesystem rename failure is not a live concern but would become one if the repo moved to a separate mount).

---

## Decision review

### C-1: dangling link outside the repo — [FINDING] made --strict fail a healthy machine.

| Option | Selected |
|--------|----------|
| Demote non-repo dangling to [INFO] | ✓ |
| Scope --strict to FAIL + repo-related FINDINGS only |  |
| [FINDING] only for dangling links the repo declares |  |

**Chosen:** Demoted to [INFO]. Measured on the live tree: $HOME/.steampath -> /home/pera/.steam/sdk32/steam and $HOME/.steampid -> /home/pera/.steam/steam.pid both dangle whenever Steam is not running. Under the original rule `verify --strict` exited 1 on a clean tree with zero drift, making the flag unusable from the day it shipped. Dangling INTO the repo stays [FAIL], so PITFALLS A-6 loses no coverage.

### C-2: absent managed directory was silent, contradicting the per-directory [PASS].

| Option | Selected |
|--------|----------|
| [INFO] managed directory absent | ✓ |
| Keep silent and drop the per-directory [PASS] |  |
| [FINDING] on an absent managed directory |  |

**Chosen:** Absent directory now emits [INFO] managed directory absent: <path>. Decision 10 emits one [PASS] per managed directory precisely because a silent pass is indistinguishable from a skipped one; the original decision 9 reintroduced that ambiguity. Every one of the 29 managed directories now emits exactly one line on every run.

### C-3: is repo-vs-HEAD content drift the same condition as capture/ content drift?

| Option | Selected |
|--------|----------|
| Keep [INFO] for HEAD drift, [FINDING] for capture/ drift | ✓ |
| Promote HEAD drift to [FINDING] for consistency |  |
| Demote capture/ drift to [INFO] for consistency |  |

**Chosen:** No — and the labels correctly differ. capture/ compares two real artifacts (live file vs repo mirror) and observes a genuine disagreement, so [FINDING] at arch/dots-hyprland.sh:833 is right. The stow/restow repo-vs-HEAD check cannot distinguish an installer write-through from an ordinary uncommitted edit: measured right now, `git diff --name-only HEAD -- stow restow` reports stow/fish/.config/fish/config.fish, which is the operator's own edit. Reporting that as drift would violate the phase14-verify.sh principle that verify never reports a condition it could not observe. So it stays [INFO].

### C-4: the repo-vs-HEAD check made git a verify dependency that no decision declared.

| Option | Selected |
|--------|----------|
| git is required; exit 2 when missing | ✓ |
| Content check degrades silently when git is absent |  |
| Drop the HEAD check from verify entirely |  |

**Chosen:** git is now a declared required binary, checked in the precondition block; absent git is exit 2. get_main_repo_root() at arch/dots-hyprland.sh:715-722 already shells out to `git rev-parse --path-format=absolute --git-common-dir`, but it falls back to $REPO_ROOT, so git was soft until now. The HEAD comparison has no fallback, so the dependency becomes hard and must be stated. D-47 forbids a vendor/dots-hyprland dependency, not a git one.

### C-5: the exit-2 assert would have grepped for a line that is never printed.

| Option | Selected |
|--------|----------|
| Capture stdout and stderr separately | ✓ |
| Keep 2>&1 and assert on merged text only |  |
| Print the precondition failure to stdout instead |  |

**Chosen:** Harness capture changed from `2>&1` to separate streams. Exit codes decision 6 sends `[FAIL] precondition: <reason>` to stderr and suppresses `=== done: ===`; a merged capture cannot prove the fd-2 routing. The exit-2 case now asserts the reason line appears on stderr and that `=== done:` appears in neither stream.

### C-6: the auto_backup fixture asserted the wrong artifact name and covered one branch of two.

| Option | Selected |
|--------|----------|
| Cover both INSTALL_FIRSTRUN branches | ✓ |
| Cover the firstrun branch only |  |
| Assert on any *.old/*.new/*.bak sibling without branching |  |

**Chosen:** Fixture now covers both branches. vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:106-114 writes $t.old and destroys the link only when INSTALL_FIRSTRUN is true; otherwise it writes $t.new beside an intact link. Of the 19 backup artifacts on this disk exactly one is named .old (.config/hypr/hyprland.conf.old); the other 18 are .bak / .bak.<epoch> from a different code path, which is why the stub rule keys on all four shapes rather than on .old alone.

### S-1: was the stub rule's $HOME-root exemption carved on the right axis?

| Option | Selected |
|--------|----------|
| Artifact shapes everywhere plus plain files in package-owned dirs | ✓ |
| Artifact shapes only |  |
| Any regular file, $HOME root exempt (original) |  |
| Any regular file, no exemption |  |

**Chosen:** No, and the first replacement was also wrong. The original rule exempted $HOME root alone while .config, with 27 unrelated regular files, had no exemption. Narrowing the rule to installer-artifact shapes fixed the noise but under-delivered success criterion 5: measured, the files that criterion names — .config/hypr/hyprland.lua, .config/hypr/custom/{rules,keybinds,variables}.lua, .config/kitty/kitty.conf.upstream and 6 others — are plain files, not artifacts, and the narrow rule would have skipped all 11. Final rule has two clauses: artifact shapes (*.old|*.new|*.bak|*.bak.*) everywhere, plus any other regular file in a package-owned directory at depth >= 2 below $HOME. Shared roots $HOME and $HOME/.config are exempt from the second clause only. Measured output: 19 + 11 = 30 [INFO] lines on a clean tree.

### S-2: five separate entry rules governed one loop.

| Option | Selected |
|--------|----------|
| One case statement over entry type | ✓ |
| Keep five independent rules |  |

**Chosen:** Collapsed into a single entry classifier, one case statement, evaluated per entry of a managed directory: symlink into the repo at a declared path -> skip, the repo-side pass owns it; symlink into the repo at an undeclared path -> [FAIL] stale link; symlink into the repo that dangles -> [FAIL]; symlink outside the repo that resolves -> silent; symlink outside the repo that dangles -> [INFO]; regular file matching *.old|*.new|*.bak|*.bak.* -> [INFO] stub; any other regular file -> silent; directory or other type -> silent.

### S-3: three decisions described one flag surface.

| Option | Selected |
|--------|----------|
| Collapse to one rule | ✓ |
| Keep as three decisions |  |

**Chosen:** Restated as one rule: verify accepts exactly -h, --help, --strict and --quiet; any other argument is exit 2; no flag narrows what verify examines. That last clause is the narrowed form of D-53 — --strict makes the verdict harsher and --quiet makes the output shorter, both over the identical full sweep.

### S-4: three decisions described one root set.

| Option | Selected |
|--------|----------|
| Collapse to one rule | ✓ |
| Keep as three decisions |  |

**Chosen:** Restated as one rule: the managed-directory root set is the dirname of every repo-side relative path under stow/*/ and restow/*/, deduplicated, resolved as $HOME/<rel> with XDG_CONFIG_HOME ignored. Measured: 29 directories, all present live today. capture/ is deliberately excluded from the live sweep — it holds only README.md until Phase 21.

### S-5: the harness had grown to roughly 14 fixture sections, larger than the verify change itself.

| Option | Selected |
|--------|----------|
| One composite fixture for all four pathologies | ✓ |
| One fixture per pathology |  |

**Chosen:** The four live-sweep pathologies stage simultaneously in one scratch $HOME and are proven by a single verify run asserting all four lines plus the exact FAIL/FINDINGS counts. Five setup/teardown cycles become one, and the composite additionally proves counter aggregation, which no single-pathology fixture can test. The negative control stays — it is the same fixture run twice, so it costs nothing.

### S-6: --quiet was deferred, but a clean run is far louder than estimated.

| Option | Selected |
|--------|----------|
| Bring --quiet into Phase 19 scope | ✓ |
| Keep --quiet deferred to a later phase |  |

**Chosen:** --quiet moves into Phase 19 scope and is removed from deferred_ideas. Measured clean-run volume: 94 repo-side [PASS] (88 stow + 6 restow) + 29 live-sweep [PASS] + 30 [INFO] (19 installer artifacts + 11 unclaimed stubs) = 153 lines, all green. --quiet suppresses [PASS] lines only, leaving roughly 31 lines on a healthy run. Without it the signal the phase exists to produce is buried in its own success output.

---

## Claude's Discretion

- Section ordering and the exact wording of `[PASS]` / `[INFO]` strings, provided the four labels and the frozen summary line are unchanged.
- Whether the entry classifier is a `case` in the sweep loop or a helper function, provided it is a single decision point.
- Internal fixture-builder factoring inside the assert script.

## Deferred Ideas

- verify --json structured output for downstream phases that gate on verify
- A dedicated stray-temp-file check in `verify` — deliberately out of scope, and likely permanently so, because a transient file makes a verdict non-deterministic.
- Claiming the 11 unclaimed upstream stubs the live sweep surfaces. Phase 19 only names them; deciding which belong in a tree is Phase 20/21 work.

---

*Phase: 19-link-aware-verify*
*Discussion closed: 2026-09-14*
