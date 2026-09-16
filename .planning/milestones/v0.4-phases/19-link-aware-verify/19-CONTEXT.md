# Phase 19: Link-aware `verify` - Context

**Gathered:** 2026-09-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 19 makes a destroyed symlink a loud failure. Today `run_verify` walks the repo side only: for every file under `stow/` and `restow/` it resolves `$HOME/<rel>` and asserts link identity before content. That walk can never see anything the repo does not already declare, so the two conditions that matter most — a folded ancestor directory and a stale or dangling link at a path the repo never named — are invisible to it (RESEARCH P-8).

This phase adds three things to `verify` and one thing beside it:

1. **A live-side sweep** over the 29 directories derived from the repo trees, classifying every entry it finds there.
2. **Exit-code discipline** — 0 clean, 1 drift, 2 precondition failure — plus `--strict` and `--quiet`.
3. **A repo-vs-`HEAD` content observation** for `stow/` and `restow/` paths, reported as `[INFO]` because it cannot distinguish an installer write-through from an uncommitted edit.
4. **An adversarial assert** at `scripts/phase19-link-aware-verify-assert.sh` that destroys a fixture on purpose and proves `verify` catches it.

Out of scope: `capture/` behaviour beyond what Phase 18 already shipped (the tree holds only `README.md` until Phase 21); any `.gitignore` change not justified by a measurement; a dedicated stray-temp-file check in `verify`; `verify --json`.

</domain>

<decisions>
## Implementation Decisions

Fifty-six decisions were taken across five discussion areas. The eleven marked **(review)** supersede an earlier answer in the same set — the superseded form is recorded in `19-DISCUSSION-LOG.md` and must not be implemented.

### Live-side sweep

- **D-01:** The sweep is bounded to managed directories. The root set is the dirname of every repo-side relative path under `stow/*/` and `restow/*/`, deduplicated, resolved as `$HOME/<rel>` with `XDG_CONFIG_HOME` ignored — `stow -t ~` ignores XDG entirely and the existing repo-side loop already resolves this way. Measured: 29 directories, all present live today. `capture/` is deliberately excluded from the live sweep.
- **D-02:** Non-recursive. The sweep lists the entries of each managed directory and never descends into unmanaged subtrees.
- **D-03:** One entry classifier governs every entry, evaluated as a single `case`:

  | Entry | Verdict |
  |---|---|
  | symlink into repo, declared path | skip — the repo-side pass owns it |
  | symlink into repo, undeclared path | `[FAIL]` stale link, naming link and target |
  | symlink into repo, dangling | `[FAIL]` |
  | symlink outside repo, resolves | silent |
  | symlink outside repo, dangling | `[INFO]` |
  | regular file matching `*.old` `*.new` `*.bak` `*.bak.*` | `[INFO]` installer backup artifact |
  | other regular file, package-owned directory (depth ≥ 2 below `$HOME`) | `[INFO]` unclaimed upstream stub |
  | other regular file, shared root (`$HOME`, `$HOME/.config`) | silent |
  | directory, or any other type | silent |

- **D-04:** A managed file's ancestor directory that is itself a symlink into the repo is `[FAIL]` with the unfold command. Checked **before** the per-file link test, so one folded directory does not emit a failure per file underneath it.
- **D-05 (review):** `$HOME` and `$HOME/.config` are shared roots, exempt from the unclaimed-stub clause only. The artifact-shape clause, the link check, the folded-ancestor check and the dangling check all run there without exception. Measured: `$HOME` root holds 44 unrelated regular files and `.config` holds 27; both are directories every application writes into by convention, while every directory at depth ≥ 2 is owned by one application.
- **D-06 (review):** A dangling symlink is `[FAIL]` when its target resolves under the repo and `[INFO]` otherwise. Measured: `$HOME/.steampath` and `$HOME/.steampid` dangle on a healthy machine whenever Steam is not running. `PITFALLS.md` A-6 — repo unavailable at login — produces links that dangle *into* the repo, so it stays fully covered by the `[FAIL]` arm. — **Reversibility:** costly — the `[FINDING]` form makes `--strict` exit 1 on a clean tree, so reverting re-breaks the flag.
- **D-07:** The sweep is a separate pass that runs **after** the repo-side walk, as its own labelled section. The Phase 18 loop is not modified.
- **D-08 (review):** A managed directory absent from the live tree emits `[INFO] managed directory absent: <path>`. Silence was the exact ambiguity that the per-directory `[PASS]` exists to remove. All 29 directories now emit exactly one line on every run, so the line count is invariant. The repo-side pass still owns the per-file `[FAIL]` with the recovery stow command (D-54, Phase 18).
- **D-09:** A clean sweep prints one `[PASS]` per managed directory — 29 lines.
- **D-10:** A managed directory path containing a component that symlinks *outside* the repo is allowed; the sweep resolves through it and checks as normal. Only a symlink *into* the repo is the pathology criterion 1 names.
- **D-11:** An unreadable managed directory is `[FAIL]` naming the directory and the errno reason. `verify` must never report `[PASS]` for a condition it could not observe (`scripts/phase14-verify.sh`).

### Exit codes, `--strict`, `--quiet`

- **D-12:** Exit 2 means `verify` could not make a verdict **at all**, and is decided **before the walk starts**: `$HOME` unset or not a directory, `stow/` and `restow/` both absent, repo root unresolvable, a required binary missing. Any condition discovered *during* the walk — an unreadable directory included — is exit 1. The rule is positional, not semantic.
- **D-13:** `--strict` makes the run exit 1 iff `FAIL > 0 || FINDINGS > 0`. `[INFO]` never moves the exit code under any flag.
- **D-14:** Labels are fixed under `--strict`; only the exit code moves. A strict run and a normal run over the same tree produce byte-identical output above the summary line.
- **D-15:** An unknown flag exits 2. This changes the current exit-1 behaviour at `arch/dots-hyprland.sh:729` — an unknown flag means the tree was never examined.
- **D-16 (review):** D-53 (Phase 18) is narrowed to scope, not arguments: *no flag narrows what `verify` examines*. `--strict` makes the verdict harsher and `--quiet` makes the output shorter, both over the identical full sweep.
- **D-17:** On an exit-2 precondition failure `verify` prints `[FAIL] precondition: <reason>` to **stderr** and stops. It does **not** print the closing `=== done: ===` line — that line asserts a completed verdict.
- **D-18:** The summary line is frozen verbatim as `=== done: FAIL=n FINDINGS=n ===` (D-49, criterion 3).
- **D-19 (review):** The accepted flag surface is exactly `-h`, `--help`, `--strict`, `--quiet` — nothing else. `--quiet` was moved in from the deferred list. A closed surface is what makes D-15 meaningful; the phase assert enumerates the accepted set exhaustively.
- **D-20 (review):** `--quiet` suppresses `[PASS]` lines only. Measured clean-run volume without it: 94 repo-side `[PASS]` (88 `stow` + 6 `restow`) + 29 live-sweep `[PASS]` + 30 `[INFO]` = **153 lines, all green**. With it, roughly 31 lines. Without `--quiet` the signal this phase exists to produce is buried in its own success output.

### Content observation

- **D-21 (review):** `verify` reports a `stow/` or `restow/` path whose repo content differs from `HEAD` as `[INFO]`, never `[FINDING]`. It is computed as `git -C <repo root> diff --quiet HEAD -- <path>`, with the repo root resolved from the repo side via `get_main_repo_root()` independently of `$HOME`. The check **cannot** distinguish an installer write-through from an ordinary uncommitted edit — measured, `git diff --name-only HEAD -- stow restow` reports `stow/fish/.config/fish/config.fish` right now, which is the operator's own edit. Reporting that as drift would violate the `phase14-verify.sh` principle. Success criterion 5 mandates `[INFO]` independently.
- **D-22:** `capture/` content drift keeps its existing `[FINDING]` at `arch/dots-hyprland.sh:832`. It is a different observation with higher confidence: it compares two real artifacts — live file against repo mirror — and observes a genuine disagreement. The differing labels are correct, not an inconsistency.
- **D-23 (review):** `git` becomes a **declared required binary**; absent `git` is exit 2, checked in the precondition block. `get_main_repo_root()` already shells out to `git rev-parse` but falls back to `$REPO_ROOT`, so the dependency was soft until now; D-21's comparison has no fallback. D-47 forbids a `vendor/dots-hyprland` dependency, not a `git` one. — **Reversibility:** one-way — once `verify` exits 2 without `git`, any caller that runs it in a git-less context is a published contract break; reverting means dropping D-21 entirely.

### Adversarial harness

- **D-24:** The fixture is built in a `mktemp -d` used as `$HOME`, following the D-44/D-45 shape. Scratch package and scratch target both live inside it; the run is `HOME=$tmpdir run_verify`. The real `$HOME` is never a candidate target.
- **D-25:** The harness lives inside the phase assert (D-57), ungated. Destruction is scoped by construction rather than by a gate.
- **D-26:** Before `rsync -a --delete` runs, the target is `realpath`'d and the harness aborts unless it is a strict prefix match on the `mktemp -d` path captured at setup. Fails closed; the roadmap's two named refusal conditions — target under `$HOME/.config`, or inside a tracked repo tree — are satisfied automatically.
- **D-27:** The cp-through case asserts the link still `[PASS]`es, `verify` still exits 0, and the content change is named as `[INFO]` (D-21). This pins the boundary between the link class and the content class.
- **D-28:** The harness `git init`s the scratch package so D-21's code path runs against a real `HEAD`.
- **D-29:** The negative control uses the same fixture builder — run `verify` before the rsync (expect 0, path appears in a `[PASS]`) and after (expect 1, same path appears in a `[FAIL]`). Only the destructive command varies.
- **D-30:** `trap 'rm -rf "$tmpdir"' EXIT` is set immediately after `mktemp -d`, before anything is written into it. Unconditional — the transcript carries what a post-mortem needs.
- **D-31:** Missing `stow` or `rsync` is `[FAIL]` in the assert, naming the binary. An unprovable claim is a failed claim. This is distinct from `verify` itself, which needs neither (D-47) — though it now needs `git` (D-23).
- **D-32 (review):** The `install_file__auto_backup` case covers **both** branches of the primitive. `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:106-114` branches on `INSTALL_FIRSTRUN`: true does `mv $t $t.old` then copies — link destroyed, `.old` artifact; false does `cp_file $s $t.new` — link **intact**, `.new` sibling. Firstrun asserts `[FAIL]` on the missing link plus `[INFO]` on the `.old`; non-firstrun asserts `[PASS]` on the link plus `[INFO]` on the `.new`.
- **D-33:** Assertions check the path **and** that the `[FAIL]` line contains a `stow -t` recovery invocation naming the right package — that is D-54's whole value.
- **D-34 (review):** All four live-sweep pathologies stage **simultaneously in one scratch `$HOME`**: folded ancestor directory, dangling link into the repo plus the non-repo `[INFO]` variant, stale link into the repo at an undeclared path, and an unclaimed stub beside a managed link. One `verify` run asserts all four lines present and the exact `FAIL=n FINDINGS=n` counts. Five setup/teardown cycles become one, and the composite additionally proves counter aggregation — which no single-pathology fixture can test.
- **D-35 (review):** All three exit codes are proven against fixtures: 0 clean, 1 destroyed link, 1 under `--strict` on a findings-only fixture that exits 0 without it, 2 on an unknown flag. The findings-only fixture must stage a `capture/` package — after D-06 and D-21, `capture/` content drift and `capture/` missing-live-counterpart are the **only** `[FINDING]` sources in Phase 19.
- **D-36:** The last section is a read-only run against the real `$HOME`, after fixture teardown; `[FAIL]` if it does not exit 0. This checks success criterion 5 rather than asserting it.
- **D-37 (review):** `set -euo pipefail` stays. Expected non-zero exits are captured with stdout and stderr kept **separate**, not merged: `rc=0; HOME=$tmp run_verify >"$out" 2>"$err" || rc=$?`, comparing `rc` at each call site. Separation is what lets the exit-2 case prove the precondition reason lands on fd 2 and that `=== done:` appears in neither stream.
- **D-38:** `git status --porcelain` is captured at the top and again at the end; `[FAIL]` if they differ. This also catches a stray temp file that outlives the run.
- **D-39:** The script is `scripts/phase19-link-aware-verify-assert.sh` — slug matches the phase directory and the roadmap title exactly.

### Q3 — stray temp files

- **D-40:** Measure before deciding. `gsd-phase-researcher` polls `git status --porcelain` while driving a burst of Qt/KDE writes through the stowed `kdeglobals` and `dolphinrc` links, and records whether a temp file ever lands in the repo working tree.
- **D-41:** A `.gitignore` rule ships **only** if the measurement observes one, and then narrowly anchored to the observed path. `.gitignore`'s generated-theme block documents its slash-free patterns as deliberate; a temp-file rule has the opposite requirement and must not be mistaken for that convention.
- **D-42:** `verify` gains **no** dedicated stray-temp-file check. A temp file is transient by construction, so the check would flap between runs and make the verdict non-deterministic. D-38's bracket already catches one that outlives a run.
- **D-43:** The answer is written into `.planning/research/PITFALLS.md`, extending the existing A-6 entry, including the measurement method and the same-device caveat — `/home/pera` and the repo are both device `66311`, so a cross-filesystem rename failure is not a live concern but would become one if the repo moved to a separate mount.

### Claude's Discretion

- Section ordering and the exact wording of `[PASS]`/`[INFO]` strings, provided the four labels and the frozen summary line (D-18) are unchanged.
- Whether the entry classifier (D-03) is a `case` in the sweep loop or a helper function, provided it is a single decision point.
- Internal fixture-builder factoring inside the assert.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 19 — the goal statement, five success criteria, and the destructive-by-construction warning governing VER-04
- `.planning/REQUIREMENTS.md` lines 62-65 — VER-01 through VER-04 verbatim
- `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-CONTEXT.md` — the three-tree taxonomy and the carried-forward decisions D-05, D-44/D-45, D-46, D-47, D-49, D-50, D-53, D-54, D-57, D-61 that Phase 19 narrows rather than replaces

### The code being changed
- `arch/dots-hyprland.sh` — `run_verify()` at lines 737-845 is the function this phase extends; `get_main_repo_root()` at 715-722; the unknown-flag exit at 753 that D-15 changes; the `capture/` `[FINDING]` at 832 that D-22 preserves; the `ALLOWLIST` at 17
- `scripts/phase14-verify.sh` — the fixed output contract and the governing principle that `verify` never reports `[PASS]` for a condition it could not observe

### Why link-ness comes first
- `.planning/research/PITFALLS.md` §30 — both destroying installer primitives leave the repo file untouched, so a content-only `verify` reports "no drift" in exactly the case that matters
- `.planning/research/PITFALLS.md` §100-115 — entry A-6, repo unavailable at login, the `-xtype l` sweep mandate, and the same-device `66311` measurement; D-43 extends this entry
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — `install_dir__sync` (destroys), `install_dir__ignore_existing` (preserves), `install_file` (writes through the link), `inline_rename`
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` lines 102-114 — `install_file__auto_backup`, both `INSTALL_FIRSTRUN` branches, the basis of D-32

### Conventions
- `.planning/codebase/TESTING.md` — assert-script conventions; no unit-test framework
- `.gitignore` — the generated-theme block's explicit "slash-free ON PURPOSE" prose that D-41 must not contradict
- `collision-map.tsv` — read for context only; D-05 bars `verify` from consulting it at runtime

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `run_verify()`'s `pass()` / `fail()` / `finding()` / `info()` printf helpers and the `fail_count` / `finding_count` accumulators already implement the output contract. The live sweep appends to the same counters and the same summary line.
- `get_main_repo_root()` resolves the repo root through `git rev-parse --path-format=absolute --git-common-dir` with a `$REPO_ROOT` fallback, independently of `$HOME`. D-21 and D-28 depend on that independence — the harness sets `HOME=$tmpdir` and the repo root must not follow it.
- The repo-side walk's `find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z` idiom gives deterministic ordering. The root-set derivation (D-01) reuses it.
- `scripts/phase14-verify.sh` supplies the boilerplate: `set -euo pipefail`, `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`, `cd "$REPO_ROOT"`.

### Established Patterns

- Link-ness is asserted before content, unconditionally (D-46). The live sweep sits after the repo-side walk but the ordering rule holds inside each.
- `verify` reads only the repo's own trees and the live filesystem. It never touches `vendor/dots-hyprland` and runs to a real exit code with the submodule de-initialised (D-47).
- `$HOME` is never hardcoded and `~` is never used in a way that bypasses it (D-44/D-45) — this is what makes the `HOME=$tmpdir` harness possible at all.
- One assert script per phase (D-57), named `phaseNN-<slug>-assert.sh`.

### Integration Points

- Dispatch arms at `arch/dots-hyprland.sh:1112-1116`; `verify` and `capture` are already in the `ALLOWLIST` at line 17 (D-61).
- The flag parser at lines 738-755 currently accepts only `-h|--help`; D-19 widens it to four flags and D-15 changes its rejection exit code.
- The summary line and exit at lines 840-845 gain the `--strict` branch (D-13).
- The live sweep is new code inserted between the `capture/` block ending at line 838 and the summary at 840.

### Measurements taken during discussion

All figures are from the live tree on 2026-09-14 and should be re-measured, not trusted, if the tree has moved:

- 29 managed directories derived from `stow/*/` + `restow/*/`; all 29 present live.
- 94 repo-side files: 88 under `stow/`, 6 under `restow/`.
- 30 `[INFO]` lines under D-03: 19 installer artifacts (18 `.bak`/`.bak.<epoch>`, 1 `.old`) + 11 unclaimed stubs in package-owned directories.
- 71 regular files suppressed by the shared-root exemption: 44 in `$HOME` root, 27 in `.config`.
- 2 dangling links on a healthy tree: `$HOME/.steampath`, `$HOME/.steampid`, both resolving outside the repo.
- 1 file differing from `HEAD`: `stow/fish/.config/fish/config.fish`, an uncommitted operator edit.
- `capture/` holds only `README.md`.
- `/home/pera` and the repo are both device `66311`.

</code_context>

<specifics>
## Specific Ideas

- The entry classifier (D-03) is the shape the user asked for explicitly: one decision point, not five independent rules scattered through a loop.
- The composite fixture (D-34) was chosen over per-pathology fixtures because it proves counter aggregation as a side effect. That property is the reason to prefer it, and the plan should not split it back apart for readability.
- Success criterion 5 is checked, not asserted (D-36) — the assert runs `verify` against the real tree read-only and reports what it finds, rather than encoding today's tree into an expectation that rots.
- The phrase to keep in mind for every `[INFO]` decision: `verify` never reports a condition it could not observe. It is why D-21 is `[INFO]` and D-22 is `[FINDING]`, and why D-11 exists at all.

</specifics>

<deferred>
## Deferred Ideas

- `verify --json` — structured output for downstream phases that gate on `verify`. No consumer exists yet; revisit when one does.
- A dedicated stray-temp-file check in `verify` (D-42) — deliberately out of scope, and likely out of scope permanently, because a transient file makes a verdict non-deterministic.
- Claiming the 11 unclaimed upstream stubs that D-03 surfaces. Phase 19 only names them; deciding which belong in a tree is Phase 20/21 work.

</deferred>

---

*Phase: 19-link-aware-verify*
*Context gathered: 2026-09-14*
