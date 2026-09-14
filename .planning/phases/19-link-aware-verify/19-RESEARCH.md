# Phase 19: Link-aware `verify` - Research

**Researched:** 2026-09-14
**Domain:** POSIX shell (bash 5.3), GNU Stow 2.4.1, symlink semantics, git plumbing, Qt/KConfig atomic-write internals
**Confidence:** HIGH

## Summary

This phase has no library surface and no external dependency to choose. Everything it needs already exists in the repo: the output contract is frozen in `scripts/phase14-verify.sh`, the walk it extends is `run_verify()` in `arch/dots-hyprland.sh`, and the per-path expectations come out of Phase 18's `stow/` / `restow/` / `capture/` taxonomy. The research value here is therefore **measurement**, not stack selection — and every figure in `19-CONTEXT.md` was re-measured against the live tree today rather than trusted.

All of `19-CONTEXT.md`'s headline measurements reproduce exactly: 29 managed directories, 94 declared repo-side files (88 `stow/` + 6 `restow/`), 19 installer artifacts, 11 unclaimed stubs, 2 dangling links outside the repo, 1 file differing from `HEAD`, `capture/` holding only `README.md`. Two figures move: `[INFO]` volume is **32, not 30** (D-20 predates D-06's review, which converted the 2 non-repo dangling links from `[FINDING]` to `[INFO]`), and the clean-run line total is **157, not 153**. Three conditions the phase is being built to catch are measurably **absent from today's tree** — zero folded ancestor directories, zero stale links into the repo, zero dangling links into the repo — which is what makes success criterion 5 achievable.

Q3 is answered definitively and with a positive observation, not an absence: the `QSaveFile` temp file **is** observable in `git status --porcelain`, as `<target>.<6 random chars>`, in a two-syscall window at `commit()` time. Measured rate: **11 hits in 2000 `git status --porcelain` polls** during a 3000-write burst. The mechanism is read out of Qt's own source, not inferred. But the artifact is un-ignorable by any narrow `.gitignore` pattern (the suffix is random), it never persists past the failing rename, and KConfig's *other* artifact — `<target>.lock` — is already covered by the existing `.gitignore:61 *.lock`. **Recommendation: ship no `.gitignore` rule; D-42's "no dedicated check" already stands.** Record the measurement in `PITFALLS.md` per D-43 and move on.

The single largest planning risk found is not in `verify` at all — it is in the VER-04 harness. `run_verify()` reads `$REPO_ROOT` from `BASH_SOURCE` and `main_root` from `git rev-parse` **in the caller's cwd**. Setting only `HOME=$tmpdir` leaves the wrapper walking the *real* repo and the fixture is never examined. Proven below, with the working harness shape.

**Primary recommendation:** Extend `run_verify()` in place — one new labelled sweep pass after the `capture/` block, one widened flag parser, one `--strict` branch on the existing exit. Build the VER-04 harness as a self-contained scratch repo that holds a **copy of `arch/dots-hyprland.sh`**, and invoke it with cwd inside that scratch repo, not merely with `HOME` overridden.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Fifty-six decisions were taken across five discussion areas. The eleven marked **(review)** supersede an earlier answer in the same set — the superseded form is recorded in `19-DISCUSSION-LOG.md` and must not be implemented.

#### Live-side sweep

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

#### Exit codes, `--strict`, `--quiet`

- **D-12:** Exit 2 means `verify` could not make a verdict **at all**, and is decided **before the walk starts**: `$HOME` unset or not a directory, `stow/` and `restow/` both absent, repo root unresolvable, a required binary missing. Any condition discovered *during* the walk — an unreadable directory included — is exit 1. The rule is positional, not semantic.
- **D-13:** `--strict` makes the run exit 1 iff `FAIL > 0 || FINDINGS > 0`. `[INFO]` never moves the exit code under any flag.
- **D-14:** Labels are fixed under `--strict`; only the exit code moves. A strict run and a normal run over the same tree produce byte-identical output above the summary line.
- **D-15:** An unknown flag exits 2. This changes the current exit-1 behaviour at `arch/dots-hyprland.sh:729` — an unknown flag means the tree was never examined.
- **D-16 (review):** D-53 (Phase 18) is narrowed to scope, not arguments: *no flag narrows what `verify` examines*. `--strict` makes the verdict harsher and `--quiet` makes the output shorter, both over the identical full sweep.
- **D-17:** On an exit-2 precondition failure `verify` prints `[FAIL] precondition: <reason>` to **stderr** and stops. It does **not** print the closing `=== done: ===` line — that line asserts a completed verdict.
- **D-18:** The summary line is frozen verbatim as `=== done: FAIL=n FINDINGS=n ===` (D-49, criterion 3).
- **D-19 (review):** The accepted flag surface is exactly `-h`, `--help`, `--strict`, `--quiet` — nothing else. `--quiet` was moved in from the deferred list. A closed surface is what makes D-15 meaningful; the phase assert enumerates the accepted set exhaustively.
- **D-20 (review):** `--quiet` suppresses `[PASS]` lines only. Measured clean-run volume without it: 94 repo-side `[PASS]` (88 `stow` + 6 `restow`) + 29 live-sweep `[PASS]` + 30 `[INFO]` = **153 lines, all green**. With it, roughly 31 lines. Without `--quiet` the signal this phase exists to produce is buried in its own success output.

#### Content observation

- **D-21 (review):** `verify` reports a `stow/` or `restow/` path whose repo content differs from `HEAD` as `[INFO]`, never `[FINDING]`. It is computed as `git -C <repo root> diff --quiet HEAD -- <path>`, with the repo root resolved from the repo side via `get_main_repo_root()` independently of `$HOME`. The check **cannot** distinguish an installer write-through from an ordinary uncommitted edit — measured, `git diff --name-only HEAD -- stow restow` reports `stow/fish/.config/fish/config.fish` right now, which is the operator's own edit. Reporting that as drift would violate the `phase14-verify.sh` principle. Success criterion 5 mandates `[INFO]` independently.
- **D-22:** `capture/` content drift keeps its existing `[FINDING]` at `arch/dots-hyprland.sh:832`. It is a different observation with higher confidence: it compares two real artifacts — live file against repo mirror — and observes a genuine disagreement. The differing labels are correct, not an inconsistency.
- **D-23 (review):** `git` becomes a **declared required binary**; absent `git` is exit 2, checked in the precondition block. `get_main_repo_root()` already shells out to `git rev-parse` but falls back to `$REPO_ROOT`, so the dependency was soft until now; D-21's comparison has no fallback. D-47 forbids a `vendor/dots-hyprland` dependency, not a `git` one. — **Reversibility:** one-way — once `verify` exits 2 without `git`, any caller that runs it in a git-less context is a published contract break; reverting means dropping D-21 entirely.

#### Adversarial harness

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

#### Q3 — stray temp files

- **D-40:** Measure before deciding. `gsd-phase-researcher` polls `git status --porcelain` while driving a burst of Qt/KDE writes through the stowed `kdeglobals` and `dolphinrc` links, and records whether a temp file ever lands in the repo working tree.
- **D-41:** A `.gitignore` rule ships **only** if the measurement observes one, and then narrowly anchored to the observed path. `.gitignore`'s generated-theme block documents its slash-free patterns as deliberate; a temp-file rule has the opposite requirement and must not be mistaken for that convention.
- **D-42:** `verify` gains **no** dedicated stray-temp-file check. A temp file is transient by construction, so the check would flap between runs and make the verdict non-deterministic. D-38's bracket already catches one that outlives a run.
- **D-43:** The answer is written into `.planning/research/PITFALLS.md`, extending the existing A-6 entry, including the measurement method and the same-device caveat — `/home/pera` and the repo are both device `66311`, so a cross-filesystem rename failure is not a live concern but would become one if the repo moved to a separate mount.

### Claude's Discretion

- Section ordering and the exact wording of `[PASS]`/`[INFO]` strings, provided the four labels and the frozen summary line (D-18) are unchanged.
- Whether the entry classifier (D-03) is a `case` in the sweep loop or a helper function, provided it is a single decision point.
- Internal fixture-builder factoring inside the assert.

### Deferred Ideas (OUT OF SCOPE)

- `verify --json` — structured output for downstream phases that gate on `verify`. No consumer exists yet; revisit when one does.
- A dedicated stray-temp-file check in `verify` (D-42) — deliberately out of scope, and likely out of scope permanently, because a transient file makes a verdict non-deterministic.
- Claiming the 11 unclaimed upstream stubs that D-03 surfaces. Phase 19 only names them; deciding which belong in a tree is Phase 20/21 work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VER-01 | `verify` asserts link identity before content for `stow/` and `restow/` paths — a destroyed symlink is the failure a content-only check cannot see | The existing repo-side walk (`arch/dots-hyprland.sh:770-808`) already does `test -L` + `readlink -f` equality before content and needs no reordering. What is missing is the folded-ancestor test (§Pattern 2), the `-xtype l` dangling arm (§Pattern 3) and the undeclared-stale-link arm — all three delivered by the new live-side sweep. Prototype run below: 29 dirs classified, 0 pathologies on today's tree |
| VER-02 | `verify` diffs content for `capture/` paths and reports drift | The `capture/` block at `arch/dots-hyprland.sh:812-838` already implements the inverted expectation plus `cmp -s` drift as `[FINDING]`; D-22 preserves it unchanged. `capture/` holds only `README.md` today, so the block is currently vacuous — the D-35 findings-only fixture is the only way to exercise it |
| VER-03 | `verify` has defined exit codes — 0 clean, 1 drift, 2 precondition failure — and a `--strict` mode | Measured current behaviour: `verify --bogus` → exit 1, `verify --strict` → exit 1 (rejected as unknown). Both change. The frozen contract, the four labels and the `=== done: FAIL=n FINDINGS=n ===` line are quoted verbatim in §Output Contract |
| VER-04 | `verify` is proven adversarially — stow a file, run `rsync -a --delete` over it, and confirm `verify` fails | Both destruction classes reproduced end to end in a scratch tree today (§Code Examples). The harness shape that actually works — and the one that silently doesn't — are in §Pitfall 1, the highest-value finding in this document |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Repo-side declared-path walk (link identity) | Wrapper subcommand `run_verify()` | — | Already there; Phase 18 owns it and D-07 forbids modifying the loop |
| Live-side sweep over managed directories | Wrapper subcommand `run_verify()`, new pass | — | D-07: separate labelled pass appended after the `capture/` block; shares the same counters |
| Entry classification (D-03) | Single `case` / helper inside the sweep | — | One decision point is the explicit user requirement; scattering it across the loop is the failure mode being avoided |
| Repo-vs-`HEAD` content observation | `git` plumbing invoked by `run_verify()` | — | D-21/D-23 make `git` a hard dependency; no filesystem substitute exists |
| Exit-code discipline and flag parsing | Wrapper subcommand prologue | `main()` dispatch at `arch/dots-hyprland.sh:1108-1119` | D-12 makes exit 2 positional (pre-walk), so it must live above the walk in the same function |
| Adversarial destruction and fixture staging | `scripts/phase19-link-aware-verify-assert.sh` | — | D-25: never inside `verify`. Scoped by `mktemp -d` construction, not by a runtime gate |
| Stray-temp-file containment | `.gitignore` (existing `*.lock` rule) | — | Measured: the one persistent-capable artifact is already covered; the transient one is not expressible as a pattern |

## Standard Stack

### Core

No new libraries, no new binaries, no package installs. Everything below already exists on the machine and in the repo.

| Tool | Version (verified today) | Purpose | Why Standard |
|------|--------------------------|---------|--------------|
| `bash` | 5.3.15(1)-release `[VERIFIED: bash --version]` | Implementation language of `arch/dots-hyprland.sh` and every `scripts/phaseNN-*` assert | Repo convention; `.planning/codebase/TESTING.md` states there is no unit-test framework and asserts are bash/Python scripts |
| `git` | 2.55.0 `[VERIFIED: git --version]` | D-21's `diff --quiet HEAD`, `get_main_repo_root()`'s `rev-parse`, D-38's porcelain bracket | Becomes a **declared required binary** under D-23 |
| GNU `find` | findutils 4.11.0 at `/usr/bin/find` `[VERIFIED: /usr/bin/find --version]` | `-print0`, `-mindepth/-maxdepth`, `-xtype l` | Already the idiom at `arch/dots-hyprland.sh:807` and throughout `scripts/` |
| GNU `stow` | 2.4.1 `[VERIFIED: stow --version]` | VER-04 fixture staging only | Repo already pins this version in `scripts/phase17-unblock-assert.sh:47` |
| `rsync` | 3.5.0-g471e17dc, protocol 32 `[VERIFIED: rsync --version]` | VER-04's destructive command | The exact primitive `install_dir__sync` uses |
| coreutils `readlink` / `realpath` | 9.11 `[VERIFIED: readlink --version]` | `-f` canonicalisation; `realpath` for D-26's prefix guard | Already used at `arch/dots-hyprland.sh:793-794` |
| `cmp` | diffutils 3.12 `[VERIFIED: cmp --version]` | `capture/` drift, unchanged from Phase 18 | — |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `PySide6` | 6.11.2 / Qt 6.11.2 `[VERIFIED: python3 -c "import PySide6..."]` | Q3 measurement only — driving `QSaveFile` writes | Research instrument, **not** a phase dependency. Do not add it to any shipped script |
| `kwriteconfig6` | KDE Frameworks 6, present on PATH `[VERIFIED: command -v kwriteconfig6]` | Q3 measurement of the real KConfig writer | Research instrument only |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-file `git diff --quiet HEAD -- <path>` ×94 (D-21's literal form) | One batched `git diff --name-only HEAD -- stow restow` into a lookup set | Measured: 0.437 s vs 0.006 s `[VERIFIED: time, this session]`. Identical results. **D-21 is a locked decision and 0.44 s is not a problem** — total `verify` wall time today is 0.97 s. Honour D-21 literally; the batch is documented only so the cost is a known quantity, not a surprise |
| Bash globbing `for e in "$d"/* "$d"/.*` to list entries | `find "$d" -mindepth 1 -maxdepth 1 -print0` | Globbing needs `nullglob` + `dotglob` + explicit `.`/`..` filtering and still breaks on newline-bearing names. `find -print0` is already the repo idiom and is the recommendation |
| `readlink -f` for the dangling arm | `readlink` (raw) + manual resolution against the entry's directory | `readlink -f` returns **empty** for a dangling link, so it cannot tell you *where* the link pointed. The `[FAIL]`-vs-`[INFO]` split in D-06 keys on whether the *unresolved* target lands under the repo, so the raw form is required for that branch. Both are needed (see Pitfall 4) |
| `find ~/.config -xtype l` as a global sweep | Per-directory `-maxdepth 1` inside the bounded root set | Measured: a global sweep surfaces 4 extra dangling links in unmanaged directories (`google-chrome/SingletonCookie`, `SingletonLock`, `discord/SingletonCookie`, `SingletonLock`) `[VERIFIED: find output, this session]`. D-01/D-02's bounded, non-recursive sweep excludes them by construction, which is what keeps criterion 5 quiet |

**Installation:** none. This phase installs nothing.

## Package Legitimacy Audit

**Not applicable — this phase installs no external packages.** Every tool used is either already present on the machine (bash, git, find, stow, rsync, coreutils, diffutils) or already a repo file. No `npm`/`pip`/`cargo` surface exists in this repo. The Package Legitimacy Gate is therefore vacuous and the `package-legitimacy check` seam was not run.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Output Contract (frozen — reuse, do not reinvent)

Quoted verbatim from the source of truth.

`scripts/phase14-verify.sh:24-30` `[VERIFIED: scripts/phase14-verify.sh:24-30]`:

```
# Output levels:
#   [PASS]     hard condition satisfied
#   [FAIL]     hard condition violated — moves the exit code
#   [FINDING]  observed condition recorded and dispositioned in 14-LIVE-VERIFY.md;
#              FINDINGS never move the exit code (D-14, D-38)
#   [INFO]     a condition this run could not observe, named rather than skipped
```

`scripts/phase14-verify.sh:32-41` `[VERIFIED: scripts/phase14-verify.sh:32-41]`:

```bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
```

Closing lines, `scripts/phase14-verify.sh` (final 5 lines) `[VERIFIED: scripts/phase14-verify.sh, tail]`:

```bash
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

The governing principle, `scripts/phase14-verify.sh:10-14` `[VERIFIED: scripts/phase14-verify.sh:10-14]`:

```
#   - Never reports a [PASS] for a condition it could not observe. An unobservable
#     condition emits [INFO] or [FINDING], never a pass and never a silent skip.
#     The same rule runs in the other direction: an unobservable condition is never
#     reported as a specific defect either. A compositor this script cannot reach
#     produces ONE failure saying so, not a wall of "the overlay did not load".
```

`run_verify()` already carries an identical, function-local copy of the four helpers, with lowercase counters `[VERIFIED: arch/dots-hyprland.sh:759-763]`:

```bash
  local fail_count=0
  local finding_count=0
  pass() { printf '[PASS] %s\n' "$1"; }
  fail() { printf '[FAIL] %s\n' "$1"; fail_count=$((fail_count + 1)); }
  finding() { printf '[FINDING] %s\n' "$1"; finding_count=$((finding_count + 1)); }
  info() { printf '[INFO] %s\n' "$1"; }
```

and closes with `[VERIFIED: arch/dots-hyprland.sh:840-845]`:

```bash
  echo "=== done: FAIL=$fail_count FINDINGS=$finding_count ==="
  if ((fail_count > 0)); then
    exit 1
  fi
  exit 0
```

**Contract consequences for the planner:**
- The new sweep appends to `fail_count` / `finding_count` — do **not** introduce a third counter. D-18 freezes the summary to two.
- D-13's `--strict` is a **one-line change** to the `if ((fail_count > 0))` condition: `if ((fail_count > 0)) || { ((strict)) && ((finding_count > 0)); }`. The `echo` above it is untouched, which is exactly what D-14 requires (byte-identical output above the summary line).
- D-17's exit-2 path must `return`/`exit` **before** the `echo "=== done: ..."` line, and write to `>&2`. Placing the precondition block at the very top of `run_verify()` satisfies both D-12's positional rule and D-17's no-summary rule with one placement.

## Architecture Patterns

### System Architecture Diagram

```
                        argv ──► run_verify()
                                     │
                    ┌────────────────┴──────────────────┐
                    │  1. FLAG PARSE (D-19, closed set) │
                    │     -h/--help ─► usage; exit 0    │
                    │     --strict  ─► strict=1         │
                    │     --quiet   ─► quiet=1          │
                    │     anything else ─► exit 2 ──────┼──► stderr, NO summary line
                    └────────────────┬──────────────────┘
                                     │
                    ┌────────────────┴──────────────────┐
                    │  2. PRECONDITIONS (D-12, pre-walk)│
                    │     $HOME set and is a dir?       │
                    │     stow/ or restow/ present?     │
                    │     repo root resolvable?         │
                    │     git on PATH? (D-23)           │
                    │     any miss ─► exit 2 ───────────┼──► stderr, NO summary line
                    └────────────────┬──────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
┌───────────────────┐   ┌────────────────────────┐   ┌───────────────────────┐
│ PASS A            │   │ PASS B                 │   │ PASS C (NEW, D-07)    │
│ repo-side walk    │   │ capture/ walk          │   │ live-side sweep       │
│ (Phase 18, D-07   │   │ (Phase 18, unchanged)  │   │                       │
│  forbids editing) │   │                        │   │ root set = dirname of │
│                   │   │ live is link into repo │   │ every declared rel,   │
│ for each of 94    │   │   ─► [FAIL] wrongly    │   │ deduped, $HOME/<rel>  │
│ declared files:   │   │        stowed          │   │  = 29 directories     │
│                   │   │ live absent            │   │                       │
│ folded ancestor?  │   │   ─► [FINDING]         │   │ per directory:        │
│   ─► [FAIL] (NEW, │   │ cmp -s mismatch        │   │  absent  ─► [INFO]    │
│       D-04, once  │   │   ─► [FINDING] (D-22)  │   │  unreadable ─► [FAIL] │
│       per dir)    │   │ else ─► [PASS]         │   │  else ─► [PASS] + walk│
│ -e || -L ?        │   └──────────┬─────────────┘   │        entries        │
│   ─► [FAIL] +stow │              │                 │                       │
│ -L ?              │              │                 │ per entry ─► D-03     │
│   ─► [FAIL] +stow │              │                 │   single classifier   │
│ readlink -f eq?   │              │                 │   (9 arms, one case)  │
│   ─► [FAIL] +stow │              │                 └───────────┬───────────┘
│ dangling into     │              │                             │
│  repo? ─► [FAIL]  │              │                             │
│ (NEW, D-06)       │              │                             │
│ else ─► [PASS]    │              │                             │
│   + git diff HEAD │              │                             │
│     ─► [INFO]     │              │                             │
│       (NEW, D-21) │              │                             │
└─────────┬─────────┘              │                             │
          │                        │                             │
          └────────────────────────┴─────────────────────────────┘
                                     │
                                     ▼
                    ┌────────────────────────────────────┐
                    │ 3. SUMMARY (D-18, frozen verbatim) │
                    │  === done: FAIL=n FINDINGS=n ===   │
                    │                                    │
                    │  exit 1 iff FAIL>0                 │
                    │       or (strict && FINDINGS>0)    │
                    │  else exit 0                       │
                    └────────────────────────────────────┘

  --quiet suppresses [PASS] emission only. It changes nothing above about which
  paths are examined (D-16) and nothing about the counters.
```

### Component Responsibilities

| File | Responsibility in this phase |
|------|------------------------------|
| `arch/dots-hyprland.sh` `run_verify()` (lines 737-845) | All three passes, flag parse, preconditions, summary. The only production file this phase edits |
| `arch/dots-hyprland.sh` `usage()` (lines 25-…) | Flag surface documentation — `verify` currently documented as taking no flags at line 32 `[VERIFIED: arch/dots-hyprland.sh:32]`; D-19 adds three |
| `arch/dots-hyprland.sh` `get_main_repo_root()` (lines 715-722) | Unchanged. Supplies D-21's `-C` argument and the repo-prefix criterion for D-03/D-06 |
| `scripts/phase19-link-aware-verify-assert.sh` (new) | Every fixture, every destruction, every exit-code assertion, the composite D-34 sweep fixture, the D-36 read-only real-tree run |
| `.planning/research/PITFALLS.md` | D-43's Q3 record, appended to entry A-6 |

### Recommended Structure of the New Sweep Pass

```
run_verify()
├── parse_flags            # D-19 closed set; unknown → exit 2 (D-15)
├── check_preconditions    # D-12; all exit 2; stderr; no summary (D-17)
├── pass A: repo-side walk         # existing loop, + D-04 ancestor pre-check, + D-21 content INFO
├── pass B: capture/ walk          # existing, unchanged (D-22)
├── pass C: live-side sweep        # NEW
│   ├── derive_managed_roots       # D-01, reuses the find|sort -z idiom
│   ├── derive_declared_set        # associative array keyed on "$HOME/$rel"
│   └── for each root:
│       ├── absent      → info     # D-08
│       ├── unreadable  → fail     # D-11
│       └── pass + for each entry: classify_entry   # D-03, ONE case
└── summary + exit         # D-18, D-13
```

### Pattern 1: Derive the managed root set from the repo trees

Reuses the existing deterministic-ordering idiom at `arch/dots-hyprland.sh:807` `[VERIFIED: arch/dots-hyprland.sh:807]` (`find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z`).

```bash
# Proven this session: yields exactly 29 roots and 94 declared paths.
declare -A MANAGED_ROOTS=() DECLARED=()
for tree in stow restow; do
  [[ -d "$REPO_ROOT/$tree" ]] || continue
  for pkg_dir in "$REPO_ROOT/$tree"/*; do
    [[ -d "$pkg_dir" ]] || continue
    while IFS= read -r -d '' file_path; do
      rel="${file_path#"$pkg_dir"/}"
      DECLARED["$HOME/$rel"]=1
      d="$(dirname "$rel")"
      if [[ "$d" == "." ]]; then
        MANAGED_ROOTS["$HOME"]=1
      else
        MANAGED_ROOTS["$HOME/$d"]=1
      fi
    done < <(find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z)
  done
done
```

**Note the `dirname` → `.` case.** Six `stow/` files live directly at `$HOME` (`.zshrc`, `.zprofile`, `.p10k.zsh`, `.tmux.conf`, `.Xresources`, `define.sh`) `[VERIFIED: find $HOME -maxdepth 1 -type l output, this session]`. `dirname` returns `"."` for these and naive concatenation yields `$HOME/.` — a path that is *equal in effect* but *unequal as a string*, which would produce a 30th root and a duplicate `[PASS]`. `$HOME` is one of the 29; it must be canonicalised explicitly.

Iterate `"${!MANAGED_ROOTS[@]}"` through `LC_ALL=C sort` for deterministic output — bash associative-array iteration order is hash order, not insertion or lexical order.

### Pattern 2: Folded-ancestor check, once per directory (D-04)

```bash
# Walk components from the managed root up to (not including) $HOME.
# Runs BEFORE the per-file link test so one folded dir is one [FAIL], not N.
cur="$d"
while [[ "$cur" != "$HOME" && "$cur" != "/" ]]; do
  if [[ -L "$cur" ]]; then
    t="$(readlink -f -- "$cur" || true)"
    if [[ "$t" == "$main_root"/* ]]; then
      fail "folded ancestor directory: $cur -> $t — unfold with: cd $tree && stow -D --no-folding -t ~ $pkg && stow --no-folding -t ~ $pkg"
    fi
  fi
  cur="$(dirname "$cur")"
done
```

**Measured on today's tree: zero folded ancestors.** `[VERIFIED: find $HOME/.config -maxdepth 6 -type l -lname '*.dotfiles*' with -d test, this session]` — and zero under Phase 17's own narrower predicate (`-maxdepth 2`) too. `STATE.md` records that Phase 17's audit found **two** and handed them to Phase 18; Phase 18's redistribution resolved both. This is what makes success criterion 5 achievable, and it also means **the check has no live positive to validate against** — the D-34 composite fixture is the only proof it works.

### Pattern 3: The D-03 entry classifier — one `case`, nine arms

```bash
classify_entry() {   # $1 = absolute entry path, $2 = its managed root, $3 = shared-root flag
  local e="$1" d="$2" shared="$3" b t raw abs
  b="${e##*/}"
  if [[ -L "$e" ]]; then
    t="$(readlink -f -- "$e" 2>/dev/null || true)"
    if [[ -n "$t" && -e "$t" ]]; then
      case "$t" in
        "$main_root"/*)
          [[ -n "${DECLARED[$e]:-}" ]] && return 0          # arm 1: repo-side pass owns it
          fail "stale link into repo at an undeclared path: $e -> $t"   # arm 2
          ;;
        *) : ;;                                              # arm 4: outside repo, resolves — silent
      esac
      return 0
    fi
    # dangling — resolve the RAW target manually; readlink -f is empty here
    raw="$(readlink -- "$e")"
    case "$raw" in /*) abs="$raw" ;; *) abs="$d/$raw" ;; esac
    case "$abs" in
      "$main_root"/*) fail "dangling symlink into repo: $e -> $raw" ;;   # arm 3 (PITFALLS A-6)
      *)              info "dangling symlink (outside repo): $e -> $raw" ;;  # arm 5
    esac
    return 0
  fi
  if [[ -f "$e" ]]; then
    case "$b" in
      *.old|*.new|*.bak|*.bak.*) info "installer backup artifact: $e"; return 0 ;;  # arm 6
    esac
    ((shared)) && return 0                                   # arm 8: shared root — silent
    info "unclaimed upstream stub: $e"                        # arm 7
    return 0
  fi
  return 0                                                    # arm 9: directory or other — silent
}
```

The arm ordering matters: **artifact shape is tested before the shared-root exemption** (D-05 says the exemption covers the unclaimed-stub clause *only*). Measured, this ordering is what keeps `$HOME/.zshrc.bak.1782461414`, `$HOME/.zprofile.bak`, `$HOME/.config/kdeglobals.bak.1789328215`, `$HOME/.config/dolphinrc.bak.1789328215` and `$HOME/.config/mimeapps.list.bak` visible — 5 of the 19 artifacts sit in the two shared roots `[VERIFIED: classifier prototype output, this session]`. Invert the order and those 5 vanish.

### Anti-Patterns to Avoid

- **`((n++))` under `set -euo pipefail`.** `bash -c 'set -euo pipefail; n=0; ((n++)); echo reached'` **aborts** — post-increment returns the *old* value, 0, which `((…))` reports as status 1 `[VERIFIED: bash -c, this session]`. The wrapper is `set -euo pipefail` at line 2. Every existing counter uses `n=$((n + 1))`; the new sweep must too.
- **Bash globbing to enumerate directory entries.** `for e in "$d"/* "$d"/.*` needs `nullglob`, `dotglob`, and an explicit `.`/`..` filter, and setting shell options inside a sourced library function leaks. Use `find "$d" -mindepth 1 -maxdepth 1 -print0`.
- **Shelling out to `git` 94 times when one call answers.** D-21 locks the per-file form and it costs 0.44 s, which is fine — but do not add *further* per-file `git` calls on top. If the untracked-file gap (Pitfall 5) is closed, batch `git ls-files -- stow restow` once into a set rather than running `git ls-files --error-unmatch` per path.
- **A third counter, or a renamed summary line.** D-18 freezes `=== done: FAIL=n FINDINGS=n ===` verbatim. `scripts/phase17-unblock-assert.sh` uses a *different* contract (`=== done: FAIL=n ===`, three prefixes, one counter) `[VERIFIED: scripts/phase17-unblock-assert.sh, tail]` — do not copy from that one.
- **Hard-coding a total line count in the assert.** The `[INFO]` volume moves with the operator's uncommitted edits (D-21) and with whatever `.bak` files the last install left. `FAIL=n FINDINGS=n` counts are stable (D-13: `[INFO]` never moves them); line counts are not.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonicalising a symlink chain | Manual `readlink` loop with a depth counter | `readlink -f --` | coreutils 9.11 handles loops, relative targets and `..` components; the existing walk already uses it at `arch/dots-hyprland.sh:793-794` |
| Detecting a dangling symlink | `[[ -L "$p" && ! -e "$p" ]]` scattered inline | `find -maxdepth 1 -xtype l` for the sweep, and the single `-L`/`-e` test inside the classifier | `-xtype l` is precisely the predicate `PITFALLS.md` A-6 mandates, and a single inline test inside one `case` preserves D-03's one-decision-point requirement |
| Deciding whether a path is under the repo | String `==` on `$REPO_ROOT` prefixes of the *unresolved* argument | `readlink -f` (or `realpath -m`) first, then a `"$main_root"/*` glob | `STATE.md` Phase 17: *"a `$HOME`-shaped path can reach the repo through a symlink and one already does — `~/.config/systemd/user/hyprland-session.service` resolves into `stow/systemd/` and is accepted by a literal prefix test, refused by the resolved comparison"* |
| "Is this repo file different from `HEAD`" | `sha256sum` against `git cat-file` output | `git diff --quiet HEAD -- <path>` (D-21) | Handles mode bits, `text=auto eol=lf` from `.gitattributes` (FIX-06), and staged-but-uncommitted state correctly. Measured: a staged-only change is correctly reported as differing `[VERIFIED: scratch repo probe, this session]` |
| Atomic-write temp-file detection | An inotify watcher or a polling loop inside `verify` | Nothing — D-42 | Measured window is two syscalls wide. Any check is a coin flip, and a non-deterministic verdict is worse than no check |
| Comparing two files byte-wise | `diff -q` or `cmp` reimplemented in bash | `cmp -s` (already at `arch/dots-hyprland.sh:833`) | — |

**Key insight:** every primitive this phase needs is already invoked somewhere in `arch/dots-hyprland.sh` or `scripts/phase1[478]-*.sh`. The phase is a composition exercise, not an implementation one. The one genuinely new primitive is `find -xtype l`, and `PITFALLS.md` A-6 names it explicitly as the mandated form.

## Runtime State Inventory

Phase 19 adds a subcommand behaviour and an assert script. It renames nothing, moves no tracked file, and changes no on-disk data format. The inventory is therefore short but is answered explicitly rather than omitted.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None** — verified: the phase writes no datastore. `verify` is read-only by contract (`scripts/phase14-verify.sh:5-8`) and the assert's only writes are inside a `mktemp -d` | none |
| Live service config | **None** — verified: no systemd unit, timer, or external service references `verify`. CAP-06's timer is Phase 21 work and is not yet created | none |
| OS-registered state | **None** — verified: `arch/dots-hyprland.sh` is invoked manually; no `.desktop`, no `exec-once`, no `pm2`/`systemd` registration names `verify` | none |
| Secrets/env vars | **None new.** `verify` reads `$HOME` only. `XDG_CONFIG_HOME` is defaulted at `arch/dots-hyprland.sh:19` but D-01 deliberately ignores it for the sweep root set — this is a *reading* constraint on the new code, not a variable to change | none — but the sweep must resolve `$HOME/<rel>`, never `$XDG_CONFIG_HOME/<rel>` |
| Build artifacts | **Two stale-constant couplings, both live.** (1) `scripts/phase17-unblock-assert.sh:89-90` counts `grep -ho -- '--verbose=5 --no-folding' arch/*.sh` and asserts `-eq 18`; measured today: 18, with **0** occurrences inside `arch/dots-hyprland.sh` `[VERIFIED: grep -c, this session]`. (2) `scripts/phase13-d19-assert.sh` selects a wrapper-drift baseline SHA and re-pins on every wrapper edit, per `STATE.md` Phase 16/17 entries | **(1)** If a recovery message in `run_verify()` gains the literal adjacent pair `--verbose=5 --no-folding`, `PAIR_COUNT` becomes 19 and `phase17-unblock-assert.sh` fails. Writing `stow --no-folding -t ~ $pkg` (without `--verbose=5` adjacent) adds **no** match and is safe. **(2)** The wrapper drift baseline will need re-pinning after this phase's edit — `STATE.md` records this as a recurring per-phase step |

## Common Pitfalls

### Pitfall 1: `HOME=$tmpdir` alone does not point `verify` at the fixture — the highest-value finding here

**What goes wrong:** D-24 says the run is `HOME=$tmpdir run_verify`. That is necessary and *not sufficient*. `run_verify()` reads two independent roots:

- `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"` `[VERIFIED: arch/dots-hyprland.sh:12]` — from the script's own location.
- `main_root="$(get_main_repo_root)"`, which is `dirname "$(git rev-parse --path-format=absolute --git-common-dir)"` `[VERIFIED: arch/dots-hyprland.sh:715-722]` — from the **process cwd**, with a `$REPO_ROOT` fallback.

Neither follows `$HOME`. Overriding only `HOME` makes `verify` walk the *real* 94 declared paths against a scratch `$HOME` where none of them exist — 94 `[FAIL]`s, and the fixture never examined.

**Measured, this session.** A scratch repo was built with one `stow/fixture` package and a copy of `arch/dots-hyprland.sh`, then stowed into a scratch `$HOME`:

- Run with `HOME=$scratch` but cwd = **real** repo:
  `[FAIL] symlink points elsewhere: …/home/.config/fixpkg/conf -> …/repo/stow/fixture/.config/fixpkg/conf (expected ) — recover with: cd stow && stow -t ~ fixture` → exit 1
- Run with `HOME=$scratch` and cwd = **scratch** repo:
  `[PASS] verified: …/home/.config/fixpkg/conf -> …/repo/stow/fixture/.config/fixpkg/conf` → exit 0

**Why it happens:** `REPO_ROOT` came from the copied script (scratch), `main_root` came from `git rev-parse` in the real repo's cwd. `canonical_repo` was then built from the *real* root, pointing at a path that does not exist — and `readlink -f` on a path whose parent is missing returns the **empty string**, producing the literal message `(expected )`.

**How to avoid:** the harness must satisfy all three roots at once:
1. `HOME="$tmp/home"`
2. the wrapper invoked is `"$tmp/repo/arch/dots-hyprland.sh"` (a copy), so `REPO_ROOT` resolves into the scratch repo
3. the invocation's **cwd is `$tmp/repo`**, so `git rev-parse` resolves into the scratch repo's `.git` — which D-28's `git init` created

`( cd "$tmp/repo" && HOME="$tmp/home" ./arch/dots-hyprland.sh verify )` in a subshell satisfies all three and leaves the assert's own cwd (the real `REPO_ROOT`, per the boilerplate) untouched.

**Warning signs:** a `[FAIL]` line reading `(expected )` with nothing after `expected`; or a FAIL count near 94 on a fixture that stages one file.

### Pitfall 2: `stow` emits *relative* links, so the scratch repo must live beside the scratch `$HOME`

**What goes wrong:** `stow --no-folding -t "$TH" fixture` produced `conf -> ../../../repo/stow/fixture/.config/fixpkg/conf` `[VERIFIED: ls -l on the scratch tree, this session]`. This matches the live tree, where `~/.config/dolphinrc -> ../github_repo/.dotfiles/restow/dolphinrc/.config/dolphinrc` `[VERIFIED: ls -la ~/.config/dolphinrc, this session]`.

**Why it happens:** GNU Stow computes the shortest relative path from the target directory to the stow directory.

**How to avoid:** D-24 already says scratch package and scratch target both live inside the one `mktemp -d` — this is the mechanical reason why. If they were split across two `mktemp -d` calls the relative path still resolves (both under `/tmp`), but it becomes long, brittle, and the D-26 prefix guard has two prefixes to check instead of one. Keep the single-root shape.

**Warning signs:** a link whose `readlink` output contains a `..` chain longer than the fixture's own depth.

### Pitfall 3: `readlink -f` returns empty for a dangling link, and empty compares equal to nothing useful

**What goes wrong:** `readlink -f -- "$p"` on a dangling link returns the empty string, not the intended target. The `[FAIL]`-vs-`[INFO]` split in D-06 keys on *where the link pointed*, which `-f` has just discarded. Worse, the existing walk at `arch/dots-hyprland.sh:793-797` compares `live_target` against `repo_target` — if both happen to be empty, the mismatch test passes and a broken pair is reported `[PASS]`.

**How to avoid:** for the dangling arm use raw `readlink -- "$p"` and resolve manually against the entry's directory (see Pattern 3). For the existing walk, the `-e`/`-L` guards above it already prevent the both-empty case for the *live* side; the *repo* side has no such guard, which is the `(expected )` message from Pitfall 1.

**Warning signs:** the string `(expected )` or `-> ` with nothing after the arrow in any `[FAIL]` line.

### Pitfall 4: `restow/kdeglobals/` is entirely invisible to `git status`, which blunts D-38

**What goes wrong:** `.gitignore:37` is the slash-free pattern `kdeglobals` `[VERIFIED: .gitignore:37]`, deliberately unanchored so it matches at any depth. It therefore matches the **directory** `restow/kdeglobals/` as well as the file. Measured `[VERIFIED: git check-ignore -v --no-index, this session]`:

```
restow/dolphinrc/.config/dolphinrc.AbC123      VISIBLE
restow/dolphinrc/.config/dolphinrc.lock        IGNORED by .gitignore:61:*.lock
restow/kdeglobals/.config/kdeglobals.AbC123    IGNORED by .gitignore:37:kdeglobals
restow/starship/.config/starship.toml.AbC123   VISIBLE
restow/hypr/.config/hypr/hyprlock.conf.AbC123  VISIBLE
stow/fish/.config/fish/config.fish.AbC123      VISIBLE
```

`restow/kdeglobals/.config/kdeglobals` is nevertheless **tracked** (`git ls-files restow` lists it `[VERIFIED: git ls-files restow, this session]`) — a `.gitignore` line never untracks a tracked file, exactly as the `.gitignore` comment block states.

**Consequence:** D-38's `git status --porcelain` bracket cannot see *any* new untracked file appearing under `restow/kdeglobals/`. The assert's self-check is blind in exactly the one package most likely to be written by a Qt app.

**How to avoid:** if the D-38 bracket is meant to be complete, use `git status --porcelain --ignored` and filter the known-ignored prefixes, rather than plain `--porcelain`. Measured baseline for the filtered form on today's tree: ` M stow/fish/.config/fish/config.fish`, `!! .commandcode/`, `!! scripts/__pycache__/` `[VERIFIED: git status --porcelain --ignored, this session]`. **Do not** "fix" this by rewriting the `kdeglobals` pattern — `.gitignore:29-35` explicitly forbids that, and D-41 forbids contradicting it.

### Pitfall 5: D-21's content check is blind to untracked repo-side files

**What goes wrong:** `verify` enumerates repo-side files with `find "$pkg_dir" -type f`, i.e. from the **filesystem**. D-21 then asks `git diff --quiet HEAD -- <path>`. For a file that exists on disk but was never committed, `git diff HEAD` reports nothing and returns **0** — "matches HEAD" — which is false.

**Measured, this session** `[VERIFIED: scratch repo probe]`:

```
untracked file present. git diff --quiet HEAD -- it:
rc=0 (0 = 'no difference')
git status:
 M restow/dolphinrc/.config/dolphinrc
?? restow/dolphinrc/.config/untracked-newfile
--- ls-files --error-unmatch probe ---
tracked? rc=1
```

A staged-but-uncommitted change *is* correctly reported as differing (rc=1), so only the fully-untracked case is blind.

**How to avoid:** pair the diff with a trackedness test and emit a distinct `[INFO]` — still `[INFO]`, because `verify` cannot distinguish a deliberate new addition awaiting commit from a stray file, and D-21's principle (`verify` never reports a condition it could not observe) governs. Batch `git ls-files -z -- stow restow` once into a set rather than 94 `--error-unmatch` calls.

**Warning signs:** a newly added `stow/` file that `verify` reports silently while `git status` shows it as `??`.

### Pitfall 6: the D-20 line-count figures are 2-4 short and one of them is volatile

**What goes wrong:** D-20 states 153 clean-run lines (94 + 29 + 30). Re-measured today the `[INFO]` total is **32**, not 30, because D-06's review moved the 2 non-repo dangling links (`$HOME/.steampath`, `$HOME/.steampid`) from `[FINDING]` to `[INFO]` after the 30 was counted. Adding D-21's content `[INFO]` (currently 1) and the summary line gives **157**, and `--quiet` gives **34**, not "roughly 31".

**Measured breakdown** `[VERIFIED: classifier prototype + verify run, this session]`:

| Class | Count |
|---|---|
| repo-side `[PASS]` | 94 (88 `stow` + 6 `restow`) |
| sweep per-directory `[PASS]` | 29 |
| `[INFO]` installer artifact | 19 |
| `[INFO]` unclaimed stub | 11 |
| `[INFO]` dangling outside repo | 2 |
| `[INFO]` repo differs from `HEAD` (D-21) | 1 — **volatile** |
| summary line | 1 |
| **total** | **157** |
| **with `--quiet`** | **34** |

Suppressed by the shared-root exemption: 66 regular files (D-05's "44 + 27 = 71" counted the 5 artifact-shaped ones too; 66 + 5 = 71 ✓).

**How to avoid:** do not encode 153 or 157 in the assert. Assert the `FAIL=n FINDINGS=n` counters, which `[INFO]` cannot move (D-13).

### Pitfall 7: `find` on PATH may not be the `find` you think it is

**What goes wrong:** during this session `type -a find` reported a shell function shadowing `find`, and `find --version` answered `bfs 4.1.1`. `/usr/bin/find` is GNU findutils 4.11.0 `[VERIFIED: /usr/bin/find --version + pacman -Qo /usr/bin/find, this session]`.

**Root cause:** the shadowing function came from an agent-session shell snapshot (`/home/pera/.claude/shell-snapshots/…`), **not** from the machine's configuration. A non-interactive `bash` script invoking `find` gets `/usr/bin/find`.

**How to avoid:** nothing to do in shipped code — but an interactive rehearsal of a sweep command in this session's shell could produce breadth-first ordering and mislead. Rehearse with `/usr/bin/find` explicitly, or from a clean `bash -lc`.

### Pitfall 8: destructive-harness precedent — this repo has destroyed its own tree once

`STATE.md`, Phase 17 `[VERIFIED: .planning/STATE.md, Decisions section]`:

> *"Every assert-harness subshell exercising a destructive function shadows `rm` with a no-op after loading the code under test — The plan['s] non-mutating by construction claim was conditional on the guard under test being correct; performing the plan['s] own commented-out-clause check deleted `README.md`, the `stow/` tree and the vendored submodule. A verifier whose safety depends on the correctness of the code it verifies is not safe. All files were restored from git and the fixture now enforces non-mutation instead of assuming it."*

D-26's `realpath` prefix guard is the right shape *because of this*. The lesson generalises: the guard must not depend on the correctness of anything the harness is testing. Capture the `mktemp -d` path into a read-only-by-convention variable at setup, `realpath` the rsync target at call time, and compare the two resolved strings — never a literal prefix on the unresolved argument (`STATE.md` Phase 17, `safe_rm_path`).

## Code Examples

Every example below was executed this session; outputs are verbatim.

### Both destruction classes, reproduced

```bash
# --- rsync-replace class (VER-04's named command) -------------------------
R="$T/repo"; TH="$T/home"
mkdir -p "$R/stow/fixture/.config/fixpkg" "$TH/.config/fixpkg"
printf 'v1\n' > "$R/stow/fixture/.config/fixpkg/conf"
( cd "$R/stow" && stow --no-folding -t "$TH" fixture )
# => conf -> ../../../repo/stow/fixture/.config/fixpkg/conf

printf 'vendorcontent\n' > "$T/vendor/fixpkg/conf"
rsync -a --delete "$T/vendor/fixpkg/" "$TH/.config/fixpkg/"

# MEASURED RESULT:
#   -rw-r--r-- 1 pera pera 14 .../home/.config/fixpkg/conf
#   is link: NO
#   repo file content: v1          <-- repo UNTOUCHED
```

The repo file still reads `v1`. **A content-only `verify` would report "no drift" here** — `PITFALLS.md:30`'s core claim, reproduced on this machine today.

```bash
# --- cp-through class (D-27) ---------------------------------------------
cp -f "$T/vendor/fixpkg/conf" "$TH/.config/fixpkg/conf"

# MEASURED RESULT:
#   is link: yes                   <-- link INTACT
#   repo now: vendorcontent        <-- repo OVERWRITTEN through the link
```

The link passes every `test -L` / `readlink -f` assertion and the repo file is now byte-identical to the vendor copy. Only D-21's `git diff HEAD` observation can see it — as `[INFO]`, which is exactly the boundary D-27 exists to pin.

### The working VER-04 harness shape

```bash
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT                 # D-30: immediately, before any write
T_REAL="$(realpath "$T")"               # D-26: captured at setup

mkdir -p "$T/repo/arch" "$T/repo/stow/fixture/.config/fixpkg" "$T/home/.config/fixpkg"
cp "$REPO_ROOT/arch/dots-hyprland.sh" "$T/repo/arch/"      # Pitfall 1, requirement 2
printf 'v1\n' > "$T/repo/stow/fixture/.config/fixpkg/conf"
( cd "$T/repo" && git init -q . \
    && git -c user.email=t@t -c user.name=t commit -qm init --allow-empty \
    && git add -A && git -c user.email=t@t -c user.name=t commit -qm fixture )   # D-28
( cd "$T/repo/stow" && stow --no-folding -t "$T/home" fixture )

run_fixture_verify() {                  # D-37: streams kept separate
  local rc=0
  ( cd "$T/repo" && HOME="$T/home" ./arch/dots-hyprland.sh verify "$@" ) \
    >"$OUT" 2>"$ERR" || rc=$?
  printf '%s' "$rc"
}

# D-29 negative control — same builder, only the destructive command varies
rc="$(run_fixture_verify)"              # expect 0, path in a [PASS]

# D-26 fail-closed guard, evaluated at call time on the RESOLVED path
victim="$T/home/.config/fixpkg"
victim_real="$(realpath "$victim")"
case "$victim_real" in
  "$T_REAL"/*) : ;;
  *) fail "refusing rsync --delete: $victim_real is not under $T_REAL"; exit 1 ;;
esac
rsync -a --delete "$T/vendor/fixpkg/" "$victim/"

rc="$(run_fixture_verify)"              # expect 1, same path in a [FAIL]
```

### Current behaviour that VER-03 changes

```
$ ./arch/dots-hyprland.sh verify --bogus ; echo rc=$?
rc=1                                    # D-15 makes this 2

$ ./arch/dots-hyprland.sh verify --strict ; echo rc=$?
rc=1                                    # rejected as an unknown flag; D-19 accepts it

$ ./arch/dots-hyprland.sh verify ; echo rc=$?
... 94 [PASS] lines ...
=== done: FAIL=0 FINDINGS=0 ===
rc=0                                    # 0.97 s wall time
```

## Q3 — Does the `QSaveFile` temp file ever land in `git status`? (D-40 → D-43)

### Answer: yes, measurably — and no `.gitignore` rule should ship anyway

### The mechanism, read out of Qt's source

`QSaveFile::open()` resolves the symlink chain and writes to the **resolved** path `[CITED: qt/qtbase 6.11 src/corelib/io/qsavefile.cpp]`:

```cpp
// "Resolve symlinks. Don't use QFileInfo::canonicalFilePath so it
// still give the expected target even if the file does not exist"
d->finalFileName = d->fileName;
if (existingFile.isSymLink()) { ... d->finalFileName = existingFile.filePath(); }
```

The temp file is then opened with `O_TMPFILE` — **no directory entry at all** `[CITED: qt/qtbase 6.11 src/corelib/io/qtemporaryfile.cpp:255]`:

```cpp
file = QT_OPEN(p, O_TMPFILE | QT_OPEN_RDWR | QT_OPEN_LARGEFILE, static_cast<mode_t>(mode));
```

At `commit()` → `renameOverwrite()` → `materializeUnnamedFile(newName, Overwrite)` `[CITED: qtemporaryfile.cpp:454-484]`:

```cpp
// Use linkat to materialize the file
QFileSystemEntry dst(newName);
if (materializeAt(dst)) return success(dst);

if (errno == EEXIST && mode == Overwrite) {
    // retry by first creating a temporary file in the right dir
    if (!materializeAsTemplate(templateName)) return false;
    // then rename the materialized file to target (same as renameOverwrite)
    QFSFileEngine::close();
    return QFSFileEngine::renameOverwrite(newName);
}
```

and the template is `finalFileName + ".XXXXXX"` `[CITED: qtemporaryfile.cpp:71]` — six random characters.

**So:** when the target already exists (the normal case), `linkat()` to the final name fails `EEXIST`, Qt materialises the file under `<resolved-target>.<6 chars>` in the resolved directory — *inside the repo working tree* — and then `rename(2)`s it over the target. The named window is **two syscalls wide**.

### Measurement 1 — hold the write open, look for a name: nothing

```
open: True
resolved dir: .../q3/repo/restow/dolphinrc/.config
entries during open window: ['dolphinrc']
git status --porcelain during window:  <empty>
git status --porcelain --ignored during window:  <empty>
commit: True
is symlink still: True
git status after commit:  M restow/dolphinrc/.config/dolphinrc
```

Consistent with `O_TMPFILE`: during the *write*, the temp file has no name. This is why a naive probe reports "never observable" — and it would be the wrong answer.

### Measurement 2 — burst of writes, concurrent polling: observed

3000 `QSaveFile` write/commit cycles through the stowed link (PySide6 6.11.2 / Qt 6.11.2), with a concurrent loop running `git status --porcelain` and `ls -A`:

```
distinct temp names caught by ls:
  dolphinrc.CZEiob  dolphinrc.CzeWRN  dolphinrc.eciQcr  dolphinrc.ejHxVY
  dolphinrc.GntEUa  dolphinrc.hbuMfO  dolphinrc.ItVSSm  dolphinrc.nCvUqN
  ... (19 distinct names)

distinct lines caught by git status --porcelain:
  ?? restow/dolphinrc/.config/dolphinrc.cOPxwV
  ?? restow/dolphinrc/.config/dolphinrc.flPwfR
  ?? restow/dolphinrc/.config/dolphinrc.IRNAxN
  ... (14 distinct names)
```

Quantified in a second, isolated run: **`git_status_polls=2000  git_status_hits=11`** — ≈ **0.55 %** of polls during a 3000-write burst. Every observed name is `dolphinrc.` + exactly 6 mixed-case alphanumerics, matching the `.XXXXXX` template.

`[VERIFIED: this session — scratch git repo on device 66311, same filesystem as the real repo]`

### Measurement 3 — the real KConfig writer produces a *different*, already-ignored artifact

60 `kwriteconfig6` writes through the same link produced exactly one extra directory entry, `dolphinrc.lock`, and it was gone after the process exited. `.gitignore:61` is `*.lock` `[VERIFIED: git check-ignore -v --no-index, this session]`, so it is already covered and would never appear in `git status --porcelain`.

### Recommendation

**Ship no `.gitignore` rule.** D-41 permits one only if the measurement observes an artifact *and* the rule can be narrowly anchored. The measurement observed one; the anchoring is impossible:

1. The suffix is **six random characters**. The only pattern that matches is `*.??????`, which would also ignore `foo.python`, `bar.config`, `x.backup`, `y.script` — an enormous over-match, and precisely the kind of unanchored rule `.gitignore:29-35` warns about.
2. The artifact **cannot persist**. It exists between `linkat()` and `rename(2)`; on failure Qt calls `fe->remove()` (`qsavefile.cpp` commit path). There is no state a rule would protect against.
3. The one artifact that *could* outlive a process — KConfig's `<target>.lock` — is already ignored by the existing `*.lock` line. That rule was shipped for a different reason and happens to do this job.

**D-42 stands unchanged:** no dedicated stray-temp-file check in `verify`. A 0.55 %-visible artifact makes a verdict a coin flip.

**One correction to D-38:** the porcelain bracket is blind under `restow/kdeglobals/` (Pitfall 4). If the bracket is to be honest, use `git status --porcelain --ignored` with a known-prefix filter.

**Same-device caveat for the `PITFALLS.md` A-6 extension (D-43):** re-verified today — `/home/pera`, `/home/pera/github_repo/.dotfiles` and `/home/pera/.config` are all device `66311`, filesystem type `ext2/ext3` `[VERIFIED: stat -c '%d %n' and stat -f -c '%n %T', this session]`. Because the temp file is materialised in the resolved directory (inside the repo) and renamed within that same directory, a cross-filesystem rename is structurally impossible *here*. If the repo ever moves to a separate mount, nothing changes either — the `linkat`/`rename` pair still happens entirely inside the repo's filesystem. The genuine cross-device hazard A-6 describes is a *different* one: `QSaveFile` creating the target through a dangling link at default umask.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `verify` as a content-drift checker | Link identity asserted before content, unconditionally | Phase 18, D-46 | Already shipped; Phase 19 adds the three conditions the repo-side walk structurally cannot see |
| `verify` walks the repo side only | Repo-side walk **plus** a bounded live-side sweep | Phase 19, D-01/D-07 | A stale link at an undeclared path, and a folded ancestor, become visible for the first time |
| Exit 1 for everything non-green | 0 / 1 / 2 with a positional exit-2 rule | Phase 19, D-12 | A caller can distinguish "tree is bad" from "I could not look" |
| Qt atomic writes framed as a symlink threat ("atomic writes" exception list) | Three trees keyed on the *installer's* write primitive | v0.4 start, `STATE.md` | `QSaveFile` is the **safest** writer, not a threat; the real destroyers are `rsync -a --delete`, `cp -f`, and `switchwall.sh`'s bare `mv` |

**Deprecated/outdated:**
- **D-20's 153/31 line figures** — superseded by D-06's own review; re-measured as 157/34 (Pitfall 6).
- **The claim that two folded directory symlinks exist** (`STATE.md`, Phase 17) — true when written, **false today**; Phase 18's redistribution resolved both. Re-measured: zero.
- **`arch/dots-hyprland.sh:729`** as the location of the unknown-flag exit, cited in D-15 — the actual line in the current file is **753** `[VERIFIED: arch/dots-hyprland.sh:752-756]`. The code is the one D-15 describes; only the line number has drifted.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The D-34 composite fixture can stage all four pathologies without any of them masking another (e.g. the folded-ancestor `[FAIL]` suppressing the per-file check underneath it, per D-04's own "one failure not N" rule) | Architecture Patterns | Medium — if the folded directory hides the stale link staged beneath it, the composite proves three pathologies and silently skips one. Stage the four in **disjoint** managed directories and the interaction disappears |
| A2 | `git init` + one commit in the scratch repo is enough for `get_main_repo_root()`; no `.gitattributes`, no config beyond `user.name`/`user.email` is required | Code Examples | Low — `git rev-parse --git-common-dir` needs only a `.git`. But the real repo has `* text=auto eol=lf` (FIX-06), so a fixture with CRLF content could diff differently than the same content would in the real repo. Keep fixture content LF-only |
| A3 | D-21's `[INFO]` for a repo/`HEAD` mismatch should be emitted per **file**, not aggregated per package | Output Contract | Low — wording is Claude's discretion. Per-file matches the surrounding `[PASS]` granularity and is what the 157-line figure assumes |
| A4 | No caller outside this repo invokes `arch/dots-hyprland.sh verify` and depends on exit 1 for an unknown flag (D-15's contract change) | Runtime State Inventory | Low — grep found dispatch only at `arch/dots-hyprland.sh:1112-1116` and references in `scripts/phase18-capture-model-assert.sh`. A fresh-machine bootstrap (BOOT-04, Phase 23) will consume the new codes and does not exist yet |
| A5 | Phase 18's `scripts/phase18-capture-model-assert.sh` Section 7a (wrapper verify/capture dispatch) does not assert the unknown-flag exit code, so D-15 will not break it | Runtime State Inventory | Medium — not read in full this session (the file is 47 KB; only its head, section headers and tail were read). **The planner must grep Section 7a for `verify --` and for an exit-code assertion before landing D-15.** If it does assert exit 1, that assert needs the same-commit update |

## Open Questions (RESOLVED)

All three were decided during planning. Each carries its resolution and the plan that owns it; none is outstanding.

1. **Does `scripts/phase18-capture-model-assert.sh` Section 7a assert `verify`'s unknown-flag exit code?**
   - What we know: the section exists (`arch/dots-hyprland.sh` line 689 header: *"Section 7a / ROADMAP criterion 7: wrapper-owned verify and capture dispatch"*), and D-15 changes that code from 1 to 2.
   - What's unclear: whether the assertion is on the exit code, on the `[FAIL] Unknown verify flag(s)` message, or only on dispatch reachability.
   - Recommendation: a two-line grep during planning (`grep -n 'verify --\|Unknown verify flag' scripts/phase18-capture-model-assert.sh`). If it asserts, the update belongs in the **same commit** as D-15, or the repo is red between commits.
   - **(RESOLVED — owner: plan `19-01`, Task 1.)** The grep was run during planning. Section 7a asserts dispatch reachability and reports `rc`; it never asserts `rc -eq 1` for a rejected flag. D-15's 1→2 change therefore needs no same-commit edit to `scripts/phase18-capture-model-assert.sh`, and `19-01` Task 1 carries `./scripts/phase18-capture-model-assert.sh` exiting 0 as an acceptance criterion so the conclusion is re-checked rather than trusted. Assumption A5 is discharged by the same grep.

2. **Should D-04's folded-ancestor `[FAIL]` recovery text name `stow -D` + re-stow, or just point at a doc?**
   - What we know: `scripts/phase17-unblock-assert.sh:917` states the recovery as *"a `stow -D` plus a re-stow with `--no-folding`"*. D-04 says "with the unfold command".
   - What's unclear: whether embedding the literal adjacent pair `--verbose=5 --no-folding` is intended. It would push `PAIR_COUNT` from 18 to 19 and fail `phase17-unblock-assert.sh:90`.
   - Recommendation: write `stow -D --no-folding -t ~ <pkg> && stow --no-folding -t ~ <pkg>` — correct, and adds zero matches to the `--verbose=5 --no-folding` pair grep. Verified: that grep is for the adjacent pair only, and `arch/dots-hyprland.sh` contains 0 occurrences today.
   - **(RESOLVED — owner: plan `19-02`, which emits the message; asserted in plan `19-03`, Task 2; guarded in plan `19-01`, Task 1.)** The recommendation is adopted as written: the folded-ancestor `[FAIL]` names the unstow-and-re-stow pair rather than pointing at a doc, in the non-adjacent form, per `19-PATTERNS.md` §`scripts/phase17-unblock-assert.sh:89-90`. `19-03` Task 2 asserts the recovery text is present on the folded-ancestor line, and `19-01` Task 1 carries the zero-occurrence count for `arch/dots-hyprland.sh` plus a green `./scripts/phase17-unblock-assert.sh` as acceptance criteria, so the pair total stays 18.

3. **Is the untracked-repo-side-file gap (Pitfall 5) in scope for this phase?**
   - What we know: D-21 specifies the diff and nothing else; the gap is real and measured.
   - What's unclear: whether closing it counts as a D-21 extension or a new decision.
   - Recommendation: treat it as in scope and `[INFO]`-labelled — it costs one batched `git ls-files` call, it cannot change any exit code, and leaving it open means `verify` silently reports a never-committed `stow/` file as matching `HEAD`, which is a false statement of the kind the `phase14-verify.sh` principle forbids.
   - **(RESOLVED — owner: plan `19-02`, Task 3.)** Decided IN SCOPE, as `[INFO]`, per the recommendation, and recorded in the code as an extension of D-21 rather than as a new decision. The tracked set is read once with a single `git ls-files -z -- stow restow` before the walk — not per-path — and the untracked arm is its own `[INFO]` class, worded distinctly from the differs-from-`HEAD` one. `19-02` Task 3 asserts it against a never-committed repo-side file with `rc` and both counters staying 0.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | everything | ✓ | 5.3.15(1) | — |
| `git` | D-21, D-23, D-28, D-38, `get_main_repo_root()` | ✓ | 2.55.0 | none — D-23 makes absence exit 2 by design |
| GNU `find` | root-set derivation, entry enumeration, `-xtype l` | ✓ | findutils 4.11.0 (`/usr/bin/find`) | — (see Pitfall 7 on PATH shadowing) |
| GNU `stow` | VER-04 fixture only | ✓ | 2.4.1 | none — D-31 makes absence `[FAIL]` in the assert |
| `rsync` | VER-04 destruction only | ✓ | 3.5.0 protocol 32 | none — D-31 makes absence `[FAIL]` in the assert |
| `readlink` / `realpath` | canonicalisation, D-26 guard | ✓ | coreutils 9.11 | — |
| `cmp` | `capture/` drift | ✓ | diffutils 3.12 | — |
| `mktemp` | fixtures | ✓ | coreutils 9.11 | — |
| `vendor/dots-hyprland` submodule | **nothing** | ✓ (initialised) | pin `1a9ffb78…` | D-47 requires `verify` to work without it; the assert must not read it |
| `PySide6` / Qt | Q3 research only | ✓ | 6.11.2 / 6.11.2 | not a phase dependency |
| `kwriteconfig6` | Q3 research only | ✓ | KF6 | not a phase dependency |
| `strace` | would have been nice for Q3 | ✗ | — | Qt source + the hold-open/burst probe pair answered it without syscall tracing |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `strace` — substituted by reading `qtemporaryfile.cpp` directly and by the two complementary empirical probes.

## Validation Architecture

`.planning/config.json` sets `workflow.nyquist_validation: true` `[VERIFIED: .planning/config.json]`, so this section applies.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None. Custom bash assert scripts under `scripts/`, per `.planning/codebase/TESTING.md` (*"This repo has **no unit-test framework**… Do not add a JS/Python test runner unless a phase explicitly requires it"*) |
| Config file | none — by design |
| Quick run command | `./arch/dots-hyprland.sh verify` (0.97 s measured) |
| Full suite command | `./scripts/phase19-link-aware-verify-assert.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VER-01 | link identity before content; folded ancestor; dangling into repo; stale undeclared link | integration (fixture) | `./scripts/phase19-link-aware-verify-assert.sh` — D-34 composite fixture section | ❌ Wave 0 |
| VER-01 | real-tree green (criterion 5) | smoke (read-only) | `./arch/dots-hyprland.sh verify` — asserted by D-36's final section | ✅ `arch/dots-hyprland.sh` exists; the sweep does not |
| VER-02 | `capture/` drift is `[FINDING]`, distinct from a link failure | integration (fixture) | assert script — D-35 findings-only fixture (must stage a `capture/` package; `capture/` holds only `README.md` live) | ❌ Wave 0 |
| VER-03 | exit 0 / 1 / 2; `--strict`; frozen output contract | integration (fixture) | assert script — D-35's four exit-code cases, D-37's separated streams, D-17's stderr-only exit-2 | ❌ Wave 0 |
| VER-03 | `--quiet` suppresses `[PASS]` only; D-14 byte-identical output above the summary | integration (fixture) | assert script — `diff <(verify) <(verify --strict)` above the summary line must be empty | ❌ Wave 0 |
| VER-04 | rsync-replace class named by `verify`; negative control | integration (destructive fixture) | assert script — D-26 guard, D-29 before/after pair | ❌ Wave 0 |
| VER-04 | cp-through class: link `[PASS]`, exit 0, content `[INFO]` | integration (destructive fixture) | assert script — D-27 | ❌ Wave 0 |
| VER-04 | `install_file__auto_backup` both `INSTALL_FIRSTRUN` branches | integration (fixture) | assert script — D-32 | ❌ Wave 0 |
| regression | Phase 18 asserts still green after the wrapper edit | integration | `./scripts/phase18-capture-model-assert.sh` | ✅ exists |
| regression | stow call-site pair count unchanged at 18 | integration | `./scripts/phase17-unblock-assert.sh` | ✅ exists |
| regression | wrapper drift baseline re-pinned | integration | `./scripts/phase13-d19-assert.sh` | ✅ exists |

### Sampling Rate

- **Per task commit:** `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh verify` (~1 s)
- **Per wave merge:** `./scripts/phase19-link-aware-verify-assert.sh`
- **Phase gate:** all of `phase19`, `phase18`, `phase17`, `phase13-d19`, `phase12-full-smoke`, `phase14-verify` green on a clean tree — the shape `STATE.md` records for the Phase 16 D-40 gate

### Wave 0 Gaps

- [ ] `scripts/phase19-link-aware-verify-assert.sh` — does not exist; covers VER-01…VER-04
- [ ] A reusable fixture builder inside it (D-24 shape + the cwd fix from Pitfall 1) — there is no shared fixture library in this repo and `.planning/codebase/TESTING.md` says not to add one; factor it as functions inside the single script (explicitly Claude's discretion per CONTEXT)
- [ ] Framework install: **none required**

## Security Domain

`security_enforcement` is not set to `false` anywhere in `.planning/config.json`, so the section is included. This phase has no network surface, no authentication, no session, no user input beyond `argv`, and writes nothing outside a `mktemp -d`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | no identity surface |
| V3 Session Management | no | no sessions |
| V4 Access Control | no | single-user local tool |
| V5 Input Validation | **yes** | D-19's closed flag surface *is* the allow-list. `argv` is the only untrusted input; unknown flags are refused (exit 2, D-15) rather than forwarded. Mirrors the existing `ALLOWLIST` subcommand gate at `arch/dots-hyprland.sh:17` |
| V6 Cryptography | no | nothing hashed or signed |
| V12 File & Resource | **yes** | The destructive harness. Controls: `mktemp -d` scoping (D-24), `realpath` prefix guard evaluated at call time (D-26), unconditional `trap … EXIT` set before the first write (D-30) |
| V14 Configuration | **yes** | `verify` is read-only against `$HOME` and the repo by contract (`scripts/phase14-verify.sh:5-8`); the new sweep must hold that line — it `stat`s, `readlink`s and `find`s, and writes nothing |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal through a symlinked component reaching the repo | Tampering | Compare `realpath`/`readlink -f`-resolved strings, never a literal prefix on the unresolved argument. `STATE.md` Phase 17 records the live instance: `~/.config/systemd/user/hyprland-session.service` resolves into `stow/systemd/` |
| `rsync -a --delete` escaping the fixture | Tampering / Denial | D-26's fail-closed `realpath` prefix guard against the `mktemp -d` captured at setup. **Precedent: this repo destroyed `README.md`, `stow/` and the submodule once (`STATE.md`, Phase 17)** |
| A verifier whose safety depends on the code under test | Tampering | `STATE.md` Phase 17's own conclusion: *"A verifier whose safety depends on the correctness of the code it verifies is not safe."* D-26's guard is in the harness, not in `verify` |
| Word-splitting / glob injection on a path with spaces or newlines | Tampering | `find -print0` + `read -r -d ''`, `--` before every path argument, every expansion quoted. The existing walk already does this |
| `set -e` masking a failed check (e.g. `((n++))` aborting mid-walk) | Denial of verification | `n=$((n + 1))` form only; `|| true` on probes whose non-zero status is expected; `local x; x="$(cmd)"` split across two statements so `local` does not swallow the exit status |
| Fixture leakage into the real tree | Tampering | D-38's porcelain bracket, plus the Phase 18 assert's `FIXTURE_LEAK` self-check pattern (`scripts/phase18-capture-model-assert.sh`, tail) — and Pitfall 4's `--ignored` correction |

## Sources

### Primary (HIGH confidence)

- `scripts/phase14-verify.sh` (read in full this session) — the frozen output contract, the four labels, the summary line, the governing "never `[PASS]` what you could not observe" principle
- `arch/dots-hyprland.sh` lines 1-60, 700-900, 1100-1130 (read this session) — `ALLOWLIST`, `usage()`, `get_main_repo_root()`, `run_verify()`, `run_capture()`, `main()` dispatch
- `collision-map.tsv` (read in full) — the 29 installer destinations, the derived `tree` column, the `install_file__auto_backup` firstrun note underpinning D-32
- `.gitignore` (read in full) — the slash-free-on-purpose prose (lines 29-35), `*.lock` (line 61), `kdeglobals` (line 37)
- `.planning/codebase/TESTING.md` — assert-script conventions, "no unit-test framework"
- `.planning/research/PITFALLS.md` §30 and §A-6 — the write-primitive catalogue, the `-xtype l` mandate, the device-`66311` caveat
- `.planning/STATE.md` — the Phase 17 destructive-harness incident, the folding-audit handoff, the v0.4 three-tree framing
- `scripts/phase17-unblock-assert.sh` lines 47-51, 87-95, 905-936 — the `PAIR_COUNT -eq 18` coupling and the D-02 folding audit
- `scripts/phase18-capture-model-assert.sh` head + section headers + tail — the assert prologue shape and `FIXTURE_LEAK` self-check
- **Direct measurement on the live tree and in scratch repos, 2026-09-14** — all counts, timings, exit codes, and both Q3 probes

### Secondary (MEDIUM confidence)

- `qt/qtbase` 6.11 `src/corelib/io/qsavefile.cpp` — symlink resolution and the `commit()` path `[CITED]`
- `qt/qtbase` 6.11 `src/corelib/io/qtemporaryfile.cpp` lines 71, 245-275, 310-330, 385-412, 425-500 (fetched and read this session) — `.XXXXXX` template, `O_TMPFILE`, `materializeUnnamedFile`, the `EEXIST` → materialise-as-template → `renameOverwrite` sequence `[CITED]`

### Tertiary (LOW confidence)

- None. No claim in this document rests on a web search or on training knowledge alone.

## Metadata

**Confidence breakdown:**

- Standard stack: **HIGH** — no library selection to make; every tool version confirmed by running it this session
- Output contract: **HIGH** — quoted verbatim from two files read in full
- Architecture / sweep design: **HIGH** — the classifier was prototyped and run against the live tree, reproducing every `19-CONTEXT.md` figure and correcting two
- Pitfalls: **HIGH** — Pitfalls 1, 3, 5, 6, 7 were each reproduced with a concrete command this session; Pitfalls 2, 4 are direct measurements; Pitfall 8 is quoted from `STATE.md`
- Q3 answer: **HIGH** — mechanism read from Qt source, behaviour confirmed by two complementary probes, rate quantified (11/2000)
- VER-04 harness shape: **HIGH** — the failing form and the working form were both executed, with verbatim output
- Phase 18 assert cross-coupling (A5): **MEDIUM** — the 47 KB file was not read in full; one grep closes it

**Research date:** 2026-09-14
**Valid until:** 2026-10-14 (30 days — bash, coreutils, stow, rsync and git are stable; the *tree measurements* are volatile and D-36's read-only real-tree run is the mechanism that keeps them honest rather than frozen)
