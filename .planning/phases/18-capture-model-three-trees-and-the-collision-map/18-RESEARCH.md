# Phase 18: Capture model — three trees and the collision map - Research

**Researched:** 2026-09-13
**Domain:** GNU Stow tree taxonomy, shell-parsed installer collision modelling, bash subcommand dispatch
**Confidence:** HIGH

## Summary

This phase is almost entirely an **in-repo, first-party research problem**. Nothing it builds depends on an
external library, a framework version, or a community best practice — the ground truth is four files in the
vendored submodule at pin `1a9ffb78`, the wrapper, and the observable behaviour of `rsync`, `cp`, `mv`, `stow`
and `git` on this machine. Accordingly the research was conducted almost entirely by **reading source and
running falsification probes**, not by consulting documentation. Every outcome column in the collision map
was reproduced end-to-end in a scratch directory rather than inferred.

The good news: the CONTEXT's 61 decisions survive contact with the source. The 18-entry MISC loop, the ~28-row
map total, the three D-22 content hashes, the `3.files-exp.sh` primitive set and the `--exp-files` forwarding
path were all confirmed exactly as written. D-09's two corrections to the `PITFALLS.md` primitive table are
correct and necessary — `install_file__auto_backup` and bare `install_dir` both destroy the link, and the
existing table says otherwise or says nothing.

The bad news, and the reason this document is longer than "Light" research implies: **five decisions specify a
mechanism that does not do what the decision says it does.** D-37's dirty-check command cannot detect the
untracked case D-37 explicitly requires it to refuse. The FIX-03 moves will make `stow` exit 1, because every
live counterpart is a real file and stow refuses to overwrite one. The generator's row order is
non-deterministic unless it sorts. D-21 undercounts repo-root `.config/` readers by a factor of five. And
`install_file__auto_backup`'s destructive branch is *disabled on this machine right now*, so an empirical
spot-check of the map will contradict the map. Each is cheap to fix in planning and expensive to discover
during execution.

**Primary recommendation:** Plan the map generator first and freeze its output before any file moves (D-26 is
right and is the phase's hard ordering constraint) — but insert two prerequisites the CONTEXT does not carry:
a deterministic `sort` in the generator, and an explicit "remove the live real file, then stow" step in every
migration task. Then correct D-37's dirty check to a two-part test (tracked-ness *and* diff) before writing
`run_capture`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Collision map derivation | Build-time script (`scripts/gen-collision-map.sh`) | — | Reads the vendored submodule; must be re-runnable against an arbitrary source root (D-55) so the pin-bump simulation works without touching the real submodule |
| Collision map storage | Repo data (`collision-map.tsv`) | — | Checked-in artifact; the diff *is* the regression signal (D-03, D-60) |
| Tree placement enforcement | Phase assert (`scripts/phase18-capture-model-assert.sh`) | — | Compares filesystem reality against map-derived expectation; the only consumer that needs both |
| Live→repo copy (`capture`) | Wrapper subcommand (`arch/dots-hyprland.sh`) | git working tree | Writes into the repo working tree only; never the index (D-38) |
| Link-ness drift check (`verify`) | Wrapper subcommand (`arch/dots-hyprland.sh`) | filesystem | Must not touch the vendored tree at all (D-47) — that is what makes it survive a de-initialised submodule |
| `--exp-files` refusal | Wrapper `main()` prologue | — | Must gate *before* allowlist dispatch so it covers every present and future handler (D-31) |
| Repo→live linking | GNU Stow, invoked from `arch/*.sh` | — | Unchanged mechanism; only the source tree argument moves (`../stow` → `../restow`) |

**Tier misassignment risk to watch:** `capture` and `verify` must live in the *wrapper* tier, not the
*upstream installer* tier. Upstream `./setup` has no `verify` and no `capture` subcommand
[VERIFIED: vendor/dots-hyprland/setup:57,69,91,104,117 — the case arms are `install-deps|install-setups|install-files)`,
`install)`, `install-deps)`, `install-setups)`, `install-files)`]. Adding them to `ALLOWLIST` *without* the
matching `main` branches routes them into `run_install_family`'s `*)` catch-all, which execs `./setup verify`
against an upstream that does not define it. D-48 and D-61 are therefore a matched pair and must land in the
same commit.

## User Constraints (from CONTEXT.md)

### Locked Decisions

All 61 decisions D-01 through D-61 in
`.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-CONTEXT.md` are locked. They are not
restated here; the planner MUST read that file. This research amends **five** of them on evidence (see
`## Decisions Requiring Amendment`) and confirms the rest.

The structural shape they lock:

- Map is a TSV at repo root, `collision-map.tsv`, six columns `dest / primitive / symlink_outcome / repo_outcome / tree / source`, pin SHA in a comment header (D-01, D-60)
- Coverage is every destination `3.files-legacy.sh` writes, MISC loop expanded to concrete rows, `2.setups.sh` excluded (D-02, D-04)
- `tree` and the `rsync-replace`/`cp-through` tag are **derived from the two outcome columns**, never authored (D-05, D-09)
- `capture` never appears in the `tree` column; `capture/` membership is hand-assigned prose (D-05)
- Generator is bash, `scripts/gen-collision-map.sh`, stdout-only, optional source root argument (D-58, D-59)
- Hard internal ordering: **map → move → re-stow → verify** (D-26, D-51)
- One assert ships: `scripts/phase18-capture-model-assert.sh`, one section per ROADMAP criterion (D-57)
- `--exp-files` refused in `main()` before allowlist dispatch, exit 2 (D-31, D-33)
- `verify`/`capture` are `run_verify()`/`run_capture()` called from new `main` branches, never through `preflight` (D-48, D-61)
- `capture` never runs `git add`, never commits, honours `--dry-run`, refuses dirty mirrors per path (D-36, D-38, D-42)
- Closed-phase asserts are not retroactively edited except the one authorised `-eq 15` → `-eq 18` bump (D-20, D-21)

### Claude's Discretion

> **None. Every gray area presented was resolved by an explicit choice.**

Research therefore recommends *corrections to locked decisions where evidence contradicts them*, and does not
propose alternatives to anything the evidence supports.

### Deferred Ideas (OUT OF SCOPE)

- Wire `restow/` recovery into the wrapper's install path so no manual re-stow step is needed after a dots-hyprland install.
- Per-tree `.gitignore` rules (Phase 17 D-14) — deferred to Phase 21.
- Treat qBittorrent as a `capture/` candidate so GUI-created categories and RSS feeds can be pulled back deliberately — deferred to Phase 21.
- Re-evaluate the `--exp-files` refusal once upstream implements `symlink: true` and `--exp-file-reset-symlink`.
- Restore a custom `starship.toml` from before commit `2539238`.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAP-01 | Capture mechanism knowable from location alone — three trees with distinct semantics | Verified primitive→outcome matrix (below) makes the `stow`/`restow` split mechanically derivable. `capture/` has no derivable member at this pin — confirmed: no legacy primitive renames over a link except `inline_rename`, which is a one-off named path, not a class. D-05's hand-assignment is forced by the evidence, not a shortcut. |
| CAP-02 | Collision map checked in as data, derived from vendored scripts at the pinned SHA | Full 28-row destination enumeration verified against the pin (below). Pin `1a9ffb78f0c272a45f82342587dc3bec72762233` confirmed. Generator determinism pitfall identified (P-3). |
| CAP-03 | Assert fails when declared mechanism contradicts the map; map cannot rot against a submodule bump | D-03's regenerate-and-diff is sound. D-55's fake-tree simulation works because the generator takes a source root. Trap-based cleanup (D-56) is required — probes confirm a failing check mid-script leaves fixtures behind under `set -e`. |
| CAP-05 | `capture` copies live→repo for `capture/` paths only, never stages, skips dirty mirrors | **D-37's specified command is defective** — see F-8. Corrected two-part dirty test provided in Code Examples. |
| CAP-07 | `--adopt` appears in no script; ban documented with its exception | Absence confirmed across `arch/ scripts/ ubuntu/ debian/ docs/ stow/`. Ban rationale verified empirically — `--adopt` exits 0 and replaces repo content with live content (F-7). |
| CAP-08 | Wrapper refuses `--exp-files` rather than forwarding it | Forwarding path confirmed live: `options.sh:50` carries `exp-files` in the getopt long list, `:91` sets `EXPERIMENTAL_FILES_SCRIPT=true`, `3.files.sh:221-224` routes on it. Experimental primitive set confirmed disjoint from the legacy set (F-6). |
| FIX-03 | Repo-root `.config/` retired; contents redistributed; no script reads that path | All 12 files enumerated and hashed; D-22's three-file drift table reproduced exactly. **Blast radius is 30 files / 53 lines, not D-21's six** (F-9). Stow-conflict trap identified (F-2). |
| FIX-05 | `verify`/`capture` first-class subcommands, `verify` runs without an initialised submodule | Current failure mode measured: both exit at the allowlist check, not at `preflight`. Upstream has no such subcommands, so allowlisting alone is actively harmful (see Architectural Responsibility Map). |

## Project Constraints (from CLAUDE.md)

**No `./CLAUDE.md` or `./.claude/CLAUDE.md` exists in this repository** [VERIFIED: `ls -la CLAUDE.md .claude/CLAUDE.md AGENTS.md` returned "No such file or directory" for all three]. `.planning/config.json` names `claude_md_path: "./.claude/CLAUDE.md"` but that file is absent.

**No project skills directory exists** [VERIFIED: `ls .claude/skills .agents/skills` returned nothing].

The binding conventions are therefore the repo's own established patterns, documented under
`## Architecture Patterns` below, plus the locked decisions in CONTEXT.md.

Relevant settings read from `.planning/config.json` [VERIFIED: .planning/config.json]:
- `workflow.nyquist_validation: true` → Validation Architecture section included
- `workflow.security_enforcement: true`, `security_asvs_level: 1` → Security Domain section included
- `commit_docs: true` → this file is committed
- `granularity: "fine"`, `mode: "yolo"`

## Standard Stack

This phase installs **no new packages**. Everything it needs is already present and already used elsewhere in
the repo.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GNU Stow | 2.4.1 | repo→live symlinking for all three trees | Already the repo's sole linking mechanism at 15 call sites; Phase 17 standardised `--verbose=5 --no-folding` on it [VERIFIED: `stow --version` → `stow (GNU Stow) version 2.4.1`] |
| bash | 5.3.15(1) | generator, assert, wrapper subcommands | D-58 mandates bash for the generator to match every other script in the repo [VERIFIED: `bash --version`] |
| git | 2.55.0 | pin SHA, dirty detection, rename-preserving moves | D-60's `git -C vendor/dots-hyprland rev-parse HEAD`; D-37's dirty test [VERIFIED: `git --version`] |
| GNU coreutils | 9.11 | `realpath`, `readlink`, `cp`, `mv`, `sort` | `realpath -f` equality is D-46's link-ness test [VERIFIED: `realpath --version`] |
| GNU findutils | 4.11.0 | reproducing the installer's MISC loop | The generator must run the *same* `find` expression the installer runs [VERIFIED: `/usr/bin/find --version` → `find (GNU findutils) 4.11.0-modified`; `pacman -Qo /usr/bin/find` → `owned by findutils 4.11.0-1`] |
| rsync | 3.5.0 | not called by this phase's code — but its behaviour *is* the map | Every `DESTROYED` row is an rsync or mv outcome [VERIFIED: `rsync --version`] |
| GNU diffutils `cmp` | 3.12 | byte-comparison in `verify`/assert | Already used by `scripts/phase13-d19-assert.sh:206` [VERIFIED: `cmp --version`] |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `jq` | 1.8.2 | JSON handling | Present and already used in `arch/dots-hyprland.sh`, `scripts/phase14-verify.sh`. **Not needed this phase** — the map is TSV by D-01 [VERIFIED: `jq --version`] |
| `yq` | v4.53.3 (mikefarah) | YAML handling | Present. Only relevant if a future phase revisits D-30 and models `3.files-exp.yaml` [VERIFIED: `yq --version`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| TSV map (D-01) | JSON + `jq` | `jq` is present, but a row move would show as a multi-line reformat rather than D-01's required one-line diff. TSV is correct. Do not revisit. |
| bash generator (D-58) | Python (`scripts/phase0{2,3,4}-*.py` set precedent) | Python precedent exists in `scripts/`, but D-58 is locked and the parse is a handful of `grep`/`case` operations. Not worth reopening. |

**Installation:** none required. No `npm`/`pip`/`cargo` step exists in this phase.

## Package Legitimacy Audit

**Not applicable — this phase installs no external packages.**

The phase adds two bash scripts (`scripts/gen-collision-map.sh`, `scripts/phase18-capture-model-assert.sh`),
two shell functions in an existing file, three READMEs, one TSV data file, and moves existing tracked files
between directories. No registry (npm, PyPI, crates.io) is contacted. No `postinstall` surface exists.

| Package | Registry | Verdict | Disposition |
|---------|----------|---------|-------------|
| *(none)* | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

Every tool the phase depends on is already installed on the target machine and already invoked by existing
committed scripts — see `## Environment Availability`.

## The Verified Primitive Matrix

This is the single most load-bearing table in the phase: D-05's `tree` column and D-09's recovery tag are both
derived from its two outcome columns. **Every row was reproduced end-to-end in a scratch directory**, not
inferred from the function bodies.

| Primitive | Definition | Underlying command | symlink_outcome | repo_outcome | Derived `tree` | Derived tag |
|-----------|-----------|--------------------|-----------------|--------------|----------------|-------------|
| `install_file` | `3.files.sh:93-101` → `cp_file` `:46-52` | `cp -f "$s" "$t"` | **preserved** | **OVERWRITTEN** | `restow` | `cp-through` |
| `install_file__auto_backup` (firstrun) | `3.files.sh:102-120` | `mv $t $t.old` then `cp_file` | **DESTROYED** | untouched | `restow` | `rsync-replace` |
| `install_file__auto_backup` (re-run) | `3.files.sh:113-114` | `cp_file $s $t.new` | preserved | untouched | *(see F-5)* | *(see F-5)* |
| `install_dir` | `3.files.sh:121-129` → `rsync_dir` `:53-59` | `rsync -a` | **DESTROYED** | untouched | `restow` | `rsync-replace` |
| `install_dir__sync` | `3.files.sh:130-138` → `rsync_dir__sync` `:67-76` | `rsync -a --delete` | **DESTROYED** | untouched | `restow` | `rsync-replace` |
| `install_dir__sync_exclude` | `3.files.sh:161-172` → `:77-92` | `rsync -a --delete --exclude …` | **DESTROYED** | untouched | `restow` | `rsync-replace` |
| `install_dir__ignore_existing` | `3.files.sh:150-160` | **short-circuits on `[ -d $t ]`** | **preserved** | untouched | `stow` | *(n/a — `stow/`)* |
| `inline_rename` *(D-03 special case)* | `3.files-legacy.sh:51-54` | `mv` | **DESTROYED** | untouched | `restow` | `rsync-replace` |

**Probe evidence** (all run in a scratch dir against `rsync 3.5.0`, `stow 2.4.1`, `coreutils 9.11`):

```
PROBE 1  [ -d symlink-to-dir ]                    → TRUE    (ignore_existing SKIPS)
PROBE 2  rsync -a --delete over dest symlink      → dest becomes REGULAR-FILE, repo content "MYREPO" intact
PROBE 3  cp -f onto dest symlink                  → dest stays SYMLINK, repo content becomes "UPSTREAM"
PROBE 4  [ -f symlink-to-file ] → TRUE; mv $t $t.old → link gone from $t, .old IS the moved symlink, repo intact
PROBE 5  rsync -a --ignore-existing over symlink  → dest stays SYMLINK, repo intact
PROBE 6  rsync -a (no --delete) over dest symlink → dest becomes REGULAR-FILE, repo intact
```

[VERIFIED: falsification probes run this session; outputs quoted above]

## Findings That Amend Locked Decisions

### F-1 — `PITFALLS.md:285-290` must NOT be copied verbatim into the generator's lookup

D-03 says the `primitive → (symlink_outcome, repo_outcome)` lookup is "sourced from
`.planning/research/PITFALLS.md:285-290`". That table has a defect D-09 already half-caught. The verbatim row is:

> `| install_dir / install_dir__ignore_existing | 3.files.sh:121-160 | rsync -a [--ignore-existing], gated on [ -d $t ] | install_dir__ignore_existing is a **no-op** when the target exists (incl. as a symlink) — this is why hypr/custom/ is safe |`

[VERIFIED: .planning/research/PITFALLS.md:288 — quoted verbatim above]

It lumps two primitives with **opposite** outcomes into one row, and describes only the benign one. Bare
`install_dir` is **not** gated on `[ -d $t ]` in the protective sense — `3.files.sh:121-129` only emits a
`warning_overwrite` and then calls `rsync_dir` unconditionally, which PROBE 6 shows replaces the symlink with a
regular file. D-09 is correct that `install_dir` "was absent from the table entirely"; the sharper statement is
that it is *present but misdescribed*, which is worse, because a generator author copying the table would
produce a benign row for the `$XDG_DATA_HOME/konsole` destination at `3.files-legacy.sh:18`.

**Action for the planner:** the hand-authored lookup is seven entries as D-03 says, but it is authored **from
the verified matrix above**, not transcribed from PITFALLS. Add a task to correct `PITFALLS.md:288` by splitting
the row — D-35 already opens that file for the Q15 section, so this rides along at no extra cost. Note the
Phase 17 precedent recorded in STATE.md: PITFALLS is treated as *frozen history* for ban-greps, but D-35
explicitly authorises adding to it this phase, and a factual correction with a dated note is additive rather
than a green-washing edit.

### F-2 — The FIX-03 moves will make `stow` exit 1 (stow will not overwrite a real file)

**None of the 12 files in repo-root `.config/` has a symlinked live counterpart.** Every live counterpart is a
plain file [VERIFIED: per-file `test -L` sweep this session — all twelve report `file` or `ABSENT`, none report
`LINK`].

GNU Stow 2.4.1 refuses to stow over an existing non-link, and **exits 1** in both simulate and real mode:

```
CONFLICT when stowing pkg: cannot stow ../tree/pkg/.config/hypr/custom/env.lua over existing target
.config/hypr/custom/env.lua since neither a link nor a directory and --adopt not specified
All operations aborted.
simulate exit=1
real     exit=1
target after real run: REAL-FILE
```

After `rm`-ing the live real file, the identical invocation exits 0 and produces a `LINK`.
[VERIFIED: stow conflict probe run this session; outputs quoted above]

Every `arch/*.sh` call site is `set -euo pipefail` [VERIFIED: `head -3` of `arch/kitty.sh`, `arch/fish.sh`,
`arch/zsh.sh`, `arch/scrutiny.sh` each show `set -euo pipefail`], and the call-site idiom
`cd … && stow …` is the script's last statement — so a conflict aborts the installer script with exit 1.

**This is the phase's most likely execution-time failure.** D-51's plan sequence ("move the files, `stow -D`
from the old tree, `stow --no-folding` from the new one") has no step that clears the live real file, because
for the *already-stowed* packages (`kitty`, `fish`, `zsh`) `stow -D` removes the link and leaves nothing behind
— which is why the omission is invisible when reasoning about those three. But the FIX-03 hypr files were
**never stowed**; there is no link to remove, only a real file to get out of the way.

**Action for the planner:** every FIX-03 migration task that ends in a `stow` must carry an explicit preceding
step: resolve the content decision per D-22, then `mv` the live real file aside (not `rm` — keep a rollback
until the stow is confirmed), then stow, then confirm `test -L`. This is the legitimate, documented path that
makes `--adopt` unnecessary — and it is worth saying so in `docs/` beside the CAP-07 ban, because `--adopt`
exists precisely to paper over this situation.

### F-3 — The generator must `sort`; `find` output order is not deterministic

The installer's MISC loop uses `find … -exec basename {} \;` with no sort
[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh:11 — `for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' ! -name 'fontconfig' -exec basename {} \;); do`].

GNU `find` returns entries in readdir order, not sorted order. Running that exact expression against the pin
produced:

```
starship.toml  darklyrc  code-flags.conf  dolphinrc  mpv  thorium-flags.conf  kitty  fuzzel
zshrc.d  kdeglobals  xdg-desktop-portal  wlogout  Kvantum  matugen  chrome-flags.conf
konsolerc  kde-material-you-colors  foot
```

[VERIFIED: find expression executed verbatim against the pinned tree this session; output quoted above]

Readdir order depends on the filesystem and on directory-entry history — a fresh `git clone` on a different
machine, or the same clone after files are added and removed, can yield a different order. D-03's whole
mechanism is "the assert regenerates the map and diffs it against the checked-in file". A non-deterministic
row order makes that diff fire spuriously on a clean tree and destroys the signal.

**Action for the planner:** `scripts/gen-collision-map.sh` must emit rows through a deterministic sort (sort the
MISC expansion by basename, and emit the named non-MISC rows in a fixed hand-written order, or sort the whole
body by `dest` after the header). State the ordering rule in the map header so a future reader knows the order
is a generator guarantee and not an accident. Add an assert sub-check: regenerate twice and require byte-identical output.

### F-4 — `install_dir__ignore_existing` skips a folded `custom/` end-to-end (Q5 ANSWERED: yes)

ROADMAP's Q5 asked whether the skip is real end-to-end or only true of `[ -d symlink-to-dir ]` in isolation.
It is real, and the reason is structural rather than incidental:

```
function install_dir__ignore_existing(){
  local s=$1
  local t=$2
  if [ -d $t ];then
    echo -e "${STY_BLUE}[$0]: \"$t\" already exists, will not do anything.${STY_RST}"
  else
    echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
    v rsync_dir__ignore_existing $s $t
  fi
}
```

[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:150-160 — quoted verbatim above]

The `[ -d $t ]` guard short-circuits the **entire** function; `rsync_dir__ignore_existing` is never reached when
the destination exists. PROBE 1 confirms `[ -d ]` is true for a symlink-to-directory, so a *folded* `custom/`
skips. PROBE 5 confirms that even if the inner rsync *were* reached, `--ignore-existing` preserves the symlink.
The outcome is `preserved`/`untouched` under **both** folding states — which is why D-26 can correctly say the
Phase 17 D-18 mandated `custom/execs.lua → stow/hypr/` row "is safe either way."

**Upstream quirk worth recording in `stow/README.md`:** because the guard short-circuits, a *new* file added to
`dots/.config/hypr/custom/` upstream is **never** installed once `~/.config/hypr/custom` exists. The primitive's
name promises rsync `--ignore-existing` per-file merge semantics; the wrapper function delivers all-or-nothing
directory semantics. That is a benefit for `stow/` membership and a trap for anyone expecting upstream additions
to appear. [VERIFIED: 3.files.sh:150-160 quoted above — the `else` branch is the only path to `rsync_dir__ignore_existing`]

### F-5 — `install_file__auto_backup`'s destructive branch is currently DISABLED on this machine

This is the finding most likely to cause a mid-phase argument, because an operator spot-checking the map will
observe behaviour that contradicts it.

The firstrun marker exists:
```
-rw------- 1 pera pera 77338 Sep  4 23:34 installed_listfile
-rw-r--r-- 1 pera pera     0 Sep  4 23:34 installed_true
```
[VERIFIED: `ls -l ~/.config/illogical-impulse/` this session; `FIRSTRUN_FILE="${DOTS_CORE_CONFDIR}/installed_true"` at vendor/dots-hyprland/sdata/lib/environment-variables.sh:30]

`3.files.sh:206-210` sets `INSTALL_FIRSTRUN=false` when that file exists, so `install_file__auto_backup` takes
the `:113-114` branch — `cp_file $s $t.new` — which writes a sidecar and leaves the target entirely alone. The
live filesystem shows exactly this, with both sidecars present:

```
-rw-r--r--  1 pera pera   359 Aug  5 02:07 hypridle.conf
-rw-r--r--  1 pera pera   718 Sep  4 23:34 hypridle.conf.new
-rw-r--r--  1 pera pera   554 Sep  5 10:52 hyprlock.conf
-rw-r--r--  1 pera pera  1887 Sep  4 23:34 hyprlock.conf.new
```
[VERIFIED: `ls -la ~/.config/hypr/` this session; quoted verbatim above]

So `hypridle.conf` and `hyprlock.conf` are `restow/` members per D-26 — **correct**, but only because the
worst-case branch is one flag away, not because it is the branch that runs today. `--firstrun` is in upstream's
getopt long-option list and is forwarded verbatim by the wrapper
[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/options.sh:50 — `-l help,force,firstrun,fontset:,clean,…`],
and deleting `installed_true` re-arms it.

**Action for the planner:** the map's `symlink_outcome` for `install_file__auto_backup` must record the
**firstrun** outcome (`DESTROYED`), and the row must carry that reasoning — the header comment is the natural
place, alongside D-04's exclusion reasoning and D-06's `SKIP_*` reasoning. Add an explicit `[INFO]` line to the
assert stating that the destructive branch is currently disarmed on this host, so a green run is not read as
evidence that the benign branch is the modelled one. Without this, a future reader runs an install, sees
`hyprlock.conf` survive, and "corrects" the map to `stow/` — re-creating the exact loss the phase exists to prevent.

### F-6 — Q15 ANSWERED and D-30's claims confirmed; `--exp-files` is forwardable today

Every D-30 claim about `3.files-exp.sh` checks out. The file is 278 lines
[VERIFIED: `wc -l` → `278 vendor/dots-hyprland/sdata/subcmd-install/3.files-exp.sh`].

Primitive set, confirmed disjoint from the legacy set:
```
221:        v rsync -av --delete "${excludes[@]}" "$from/" "$to/"    # sync
225:        v rsync -av "${excludes[@]}" "$from" "$to"               # soft
231:        v rsync -av "${excludes[@]}" "$from/" "$to/"
238:      v cp -r "$from" "$to"                                      # hard
247:          v cp -r "$from" "$to"                                  # hard-backup
258:          v cp -r "$from" "$to.new"                              # soft-backup
271:        v cp -r "$from" "$to"                                    # skip-if-exists
```
[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files-exp.sh:217-272; command lines quoted verbatim above]

Interactive wizard confirmed at `read -p "Enter choice [1-2]: "` on lines 45, 58 and 71
[VERIFIED: 3.files-exp.sh:45,58,71]. This alone justifies refusal from a non-interactive wrapper.

The two TODOs the deferred-ideas section hangs on are present and unimplemented:
```
15:# TODO: Implement bool key symlink (both read-write and read-only), when the value of `symlink` is true, then instead using `rsync` or `cp`, use `ln`.
16:# TODO: add --exp-file-reset-symlink  Try to remove all symlink in .config and .local, which point to the local repo
```
[VERIFIED: 3.files-exp.sh:15-16 — quoted verbatim above]

The forwarding path is live and unguarded:
- `options.sh:33` documents the flag under "New features (experimental)"
- `options.sh:50` carries `exp-files` in the getopt long list
- `options.sh:91` — `--exp-files) EXPERIMENTAL_FILES_SCRIPT=true;shift;;`
- `3.files.sh:221-224` — `case "${EXPERIMENTAL_FILES_SCRIPT}" in true)source sdata/subcmd-install/3.files-exp.sh;; *)source sdata/subcmd-install/3.files-legacy.sh;; esac`

[VERIFIED: lines quoted verbatim from the two files]

And the wrapper's `run_install_family` scan strips only `--dry-run`, `--keep-backup` and `--full`; everything
else falls through to `user_flags+=("$arg")` and is forwarded
[VERIFIED: arch/dots-hyprland.sh:732-753 — the `case "$arg" in` block has exactly those three arms plus `*)`].
D-31's placement in `main()` rather than in that scan is therefore correct: the scan is reached only for the
install family, and `run_uninstall` has its own argument handling.

### F-7 — CAP-07's ban rationale verified empirically

REQUIREMENTS CAP-07 asserts `--adopt` "silently replaces repo content with live content at exit 0"
[VERIFIED: .planning/REQUIREMENTS.md:30 — `- [ ] **CAP-07**: \`stow --adopt\` appears in no script — it silently replaces repo content with live content at exit 0`].

Reproduced exactly:
```
repo file before: REPO-CONTENT      live file before: LIVE-CONTENT
stow --no-folding --adopt -t $HOME pkg   →  exit 0
repo file now contains: LIVE-CONTENT
live is: LINK
```
[VERIFIED: `--adopt` probe run this session; output quoted above]

Absence confirmed: `grep -rn -- '--adopt' arch/ scripts/ ubuntu/ debian/ docs/ stow/` returns no matches
[VERIFIED: grep run this session, zero hits]. CAP-07 is a documentation-plus-assert job as the CONTEXT states.

Note that stow's own conflict message *advertises* the flag — `"…and --adopt not specified"` (F-2). That is
precisely why the ban needs the documented exception rather than a bare prohibition: an operator hitting the
F-2 conflict is told by the tool itself to reach for the banned flag.

### F-8 — D-37's dirty-check command cannot do what D-37 requires (CAP-05 blocker)

D-37 states: *"'Dirty against HEAD' means any difference from HEAD, staged or unstaged — `git diff --quiet HEAD
-- <path>`. **Untracked paths are refused too**, since there is no HEAD version to compare against and
overwriting would destroy uncommitted work."*

The specified command **reports untracked paths as clean**:

```
capture/pkg/.config/tracked.conf     git diff --quiet HEAD -> 1 (reports DIRTY)
capture/pkg/.config/untracked.conf   git diff --quiet HEAD -> 0 (reports CLEAN)
capture/pkg/.config/absent.conf      git diff --quiet HEAD -> 0 (reports CLEAN)
```
[VERIFIED: git dirty-check probe in a throwaway repo this session; output quoted above. git 2.55.0]

`git diff HEAD -- <pathspec>` only considers tracked paths; an untracked file matches no index entry and no
HEAD entry, so the diff is empty and the command exits 0. A nonexistent path behaves identically — which means
the naive test *also* silently passes for a typo'd path.

This is a genuine data-loss path: the second requirement of criterion 7 is "refuses any path whose repo mirror
is already dirty against `HEAD`". An untracked repo mirror is the case where the operator has the *most*
uncommitted work at stake and no way to recover it, and it is exactly the case the specified command waves through.

**Corrected test** (see Code Examples for the full function):
```bash
git ls-files --error-unmatch -- "$p" >/dev/null 2>&1 || return 1   # untracked → refuse
git diff --quiet HEAD -- "$p"                                       # tracked → 0 clean, 1 dirty
```
[VERIFIED: same probe — `git ls-files --error-unmatch` returned `UNTRACKED` for the untracked path and
`git status --porcelain -- <path>` returned `?? capture/pkg/.config/untracked.conf`]

`git status --porcelain -- "$p"` with a non-empty result is an equally correct single-command alternative and
catches both conditions at once; it is marginally harder to reason about because it also reports ignored-file
states under some flag combinations. Either is acceptable; the two-part test is more explicit about *which*
refusal reason to print, which D-36's per-path reporting wants anyway.

**Action for the planner:** amend D-37 to the two-part test, and add an assert sub-check that an untracked
mirror is refused — otherwise the defect ships green, because the happy-path fixture in D-44 commits its
fixture and never exercises the untracked case.

### F-9 — FIX-03's criterion-6 blast radius is 30 files, not D-21's six

D-21 states *"Six scripts read repo-root `.config/`"* and names five plus two asserts. The actual count of
files containing a working-directory- or `$REPO_ROOT`-relative `.config/` reference is **30 files across 53
lines** [VERIFIED: anchored grep run this session over `arch/ scripts/ ubuntu/ debian/`, excluding `~/`,
`$HOME`, `${HOME}`, `XDG_CONFIG_HOME` and `/home/` forms]:

```
19 scripts/phase17-unblock-assert.sh     14 scripts/nvim-validate.sh
 8 scripts/phase13-d19-assert.sh          5 scripts/phase14-verify.sh
 2 ubuntu/zsh.sh                          2 ubuntu/monitor_system.sh
 2 debian/zsh.sh                          1 scripts/nvim-audit-failures.sh
 1 arch/system_monitor.sh                 1 debian/system_monitor.sh
 1 each: ubuntu/{yazi,xterm,wezterm,tools,tmux,rofi,nvim,kitty,define,alacritty}.sh
 1 each: debian/{yazi,xterm,wezterm,tools,tmux,rofi,nvim,kitty,define,alacritty}.sh
```

The gap is not dangerous — it is a **scoping** problem, not a correctness one. Almost every one of these
references a repo-root path that **does not exist today**:

```
.config/system_monitor/ping   MISSING     .config/nvim          MISSING
.config/.tmux.conf            MISSING     .config/define.sh     MISSING
.config/.zshrc                MISSING     .config/.p10k.zsh     MISSING
.config/.Xresources           MISSING     .config/waybar        MISSING
.config/systemd/user/ping-viz.service     MISSING
```
[VERIFIED: per-path `test -e` sweep this session; output quoted above]

So they are broken *today*, independently of FIX-03, and deleting `.config/` breaks nothing new. But criterion 6
says "**no script reads that path**", and a literal assert over `arch/ scripts/ ubuntu/ debian/` fails against
30 files on day one.

Three specific traps inside that set:

1. **`scripts/phase17-unblock-assert.sh` holds 19 hits that are quoted grep *patterns*, not reads** — e.g.
   `HYPR_COPY_HITS="$(grep -c -F -- 'cp -rf .config/hypr/' "$HYPR_INSTALLER" || true)"` at line 199. D-20
   forbids editing that file. A criterion-6 assert must not count them.
2. **`arch/dots-hyprland.sh:446` is a live-path glob, not a repo path** — `*/.config/hypr|*/.config/hypr/*)`
   inside `safe_rm_path`'s "never hypr" belt [VERIFIED: arch/dots-hyprland.sh:444-450 — `# Extra belt: never hypr` /
   `case "$path" in` / `*/.config/hypr|*/.config/hypr/*)`]. Deleting or retargeting it would weaken FIX-04.
3. **`scripts/nvim-validate.sh` (14 sites) and `scripts/nvim-audit-failures.sh`** read `$REPO_ROOT/.config/nvim`,
   which is `MISSING` — the real tree is `stow/nvim/`. Neither is in D-21's list. These are live, currently-run
   validation scripts, not closed-phase records, so retargeting them is safe and probably overdue.

**Action for the planner:** this needs an explicit scope decision (see Open Questions Q-1). The
cheapest defensible reading is to scope criterion 6's assert to *the twelve files actually being moved* — i.e.
assert that no script references `.config/hypr/`, `.config/dolphinrc` or `.config/kdeglobals` relative to the
repo root — and to retarget `scripts/nvim-validate.sh` + `scripts/nvim-audit-failures.sh` as a bonus, since they
are genuinely broken and genuinely in `scripts/`. Reuse Phase 17's anchored-grep technique, which already solved
the bare-vs-anchored discrimination problem:

```bash
grep -c -E '(^|[[:space:]])\.config/' "$FILE"
```
[VERIFIED: scripts/phase17-unblock-assert.sh:223 — quoted verbatim; the rationale is at :212-220,
"A path anchored to the home directory (`~/.config/...`, `$HOME/.config/...`) or to the script's own location
(`$REPO_ROOT/.config/...`) has the configuration component preceded by a slash, not by whitespace, and is
correct — so it must not false-positive here"]

Note that the Phase 17 pattern deliberately treats `$REPO_ROOT/.config/...` as **correct**, because Phase 17 was
banning cwd-relative paths. FIX-03 bans the path itself regardless of anchoring, so the phase-18 assert needs a
*second* pattern for the `$REPO_ROOT/` form. Do not copy the Phase 17 regex unchanged.

## Additional Verified Findings

### F-10 — `arch/zsh_powerlevel.sh:61` is a second `zsh` stow call site

D-08 splits `starship.toml` out of `stow/zsh/` and says "`arch/zsh.sh` gains a second stow invocation". But two
files stow the `zsh` package today:

```
arch/zsh.sh:43:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ zsh
arch/zsh_powerlevel.sh:61:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ zsh
```
[VERIFIED: `grep -rn 'stow ' arch/` this session; lines quoted verbatim]

D-19's arithmetic (15 → 18: `arch/qbittorrent.sh` +1, `arch/scrutiny.sh` +1, starship +1) is **correct and
unaffected** — it assumes exactly one new starship line. But the planner should decide deliberately whether
`arch/zsh_powerlevel.sh` also needs the starship line. If it does, the constant is 19, not 18, and D-20's
authorised bump changes. Recommendation: put the starship line in `arch/zsh.sh` only (as D-08 says), and note in
`restow/README.md` that `zsh_powerlevel.sh` is a prompt-theme installer that does not own starship. Flag it to
the operator rather than silently duplicating.

Current pair count confirmed at **15** [VERIFIED: `grep -rn -- '--verbose=5 --no-folding' arch/ | wc -l` → `15`,
matching the `grep -ho … | wc -l` form the assert uses at scripts/phase17-unblock-assert.sh:89].

### F-11 — `phase17-unblock-assert.sh` has a *second* hard-coded constant, and it survives untouched

Beyond the `-eq 15` at line 90 that D-20 authorises changing, the script carries an explicit 14-element file
list:

```bash
SYNTAX_FILES=(
  arch/alacritty.sh  arch/btop.sh  arch/define.sh  arch/fish.sh  arch/hyprland.sh
  arch/kitty.sh  arch/nvim.sh  arch/rofi.sh  arch/tmux.sh  arch/wezterm.sh
  arch/xterm.sh  arch/yazi.sh  arch/zsh.sh  arch/zsh_powerlevel.sh
)
…
if [[ "${#SYNTAX_FILES[@]}" -eq 14 && "$SYNTAX_MISSING" -eq 0 ]]; then
```
[VERIFIED: scripts/phase17-unblock-assert.sh:115-135 — quoted verbatim]

**Good news:** this check counts the *list*, not the filesystem, and only asserts each listed file still
exists. Adding `arch/qbittorrent.sh` and `arch/scrutiny.sh` does not change `${#SYNTAX_FILES[@]}`, so it stays
green with no edit. D-20's single authorised edit is sufficient.

**Caveat to record:** its PASS message — *"all 14 files holding a stow call site are present"* — becomes
factually stale once 16 files hold call sites. D-20's principle says leave it; the message describes what Phase
17 verified, and Phase 18's own assert carries the current count. Recommend an `[INFO]` line in the phase-18
assert noting the staleness so the next reader is not confused, rather than editing the closed record.

### F-12 — D-22's three-file drift table reproduces exactly

All three content decisions verified byte-for-byte this session:

| File | vendor | live | repo | CONTEXT claim | Verified |
|---|---|---|---|---|---|
| `dolphinrc` | `14d27634` | `f236ddd7` | `217cc293` | all three differ → live wins | ✅ exact match |
| `kdeglobals` | `c212651f` | `412a05b0` | `c360d020` | all three differ → live wins | ✅ exact match |
| `hypr/hyprland/scripts/launch_first_available.sh` | `40618524…` | `40618524…` | `60318150…` | live ≡ vendor → repo wins | ✅ exact match, live md5 identical to vendor |

[VERIFIED: `md5sum` run this session against vendor/live/repo for each; the first 8 hex chars match the CONTEXT
table for `dolphinrc`/`kdeglobals`, and the full md5 `406185243dd4904d92fdd782c97f1213` is identical for
vendor and live on `launch_first_available.sh` while repo is `603181500b9bc190545d8441b3d38133`]

The remaining nine files: eight are byte-identical to their live counterpart, and `hypr/hyprland.conf` has
**no live counterpart at all** (confirmed `ABSENT`, with `~/.config/hypr/hyprland.conf.old` present at 15301
bytes dated Aug 15 — the Phase 14 rename). `hypr/hyprland.conf.bak` is identical to a live `.bak` that does
exist. The CONTEXT's "seven match / three differ / two archived" arithmetic is consistent: the two archived
files are `hyprland.conf` (no live) and `hyprland.conf.bak` (identical), leaving 7 identical + 3 differing among
the ten redistributed.
[VERIFIED: per-file repo-vs-live md5 sweep and `ls -la ~/.config/hypr/` this session]

### F-13 — The 28 map rows, enumerated against the pin

D-02's "roughly 28 rows" resolves to **exactly 28**: 18 MISC-loop rows plus 10 named rows.

MISC loop expansion — the 18 entries, with the `[ -d ]` / `[ -f ]` discrimination at `3.files-legacy.sh:14-15`:

| dir (→ `install_dir__sync`) | file (→ `install_file`) |
|---|---|
| `foot`, `fuzzel`, `kde-material-you-colors`, `kitty`, `Kvantum`, `matugen`, `mpv`, `wlogout`, `xdg-desktop-portal`, `zshrc.d` (10) | `chrome-flags.conf`, `code-flags.conf`, `darklyrc`, `dolphinrc`, `kdeglobals`, `konsolerc`, `starship.toml`, `thorium-flags.conf` (8) |

[VERIFIED: the installer's own `find` expression executed against the pinned tree, then each result classified
with `test -d`; both lists quoted from that run. Matches `.planning/research/PITFALLS.md:294`'s enumeration and
the CONTEXT's 18-entry list exactly.]

The 10 named rows:

| # | dest | primitive | source |
|---|------|-----------|--------|
| 1 | `$XDG_DATA_HOME/konsole` | `install_dir` | `3.files-legacy.sh:18` |
| 2 | `$XDG_CONFIG_HOME/quickshell` | `install_dir__sync` | `3.files-legacy.sh:26` |
| 3 | `$XDG_CONFIG_HOME/fish` | `install_dir__sync_exclude` | `3.files-legacy.sh:33` |
| 4 | `$XDG_CONFIG_HOME/fontconfig` | `install_dir__sync` | `3.files-legacy.sh:41` |
| 5 | `$XDG_CONFIG_HOME/hypr/hyprland` | `install_dir__sync` | `3.files-legacy.sh:50` |
| 6 | `$XDG_CONFIG_HOME/hypr/hyprland.conf` | `inline_rename` | `3.files-legacy.sh:51-54` |
| 7 | `$XDG_CONFIG_HOME/hypr/hyprlock.conf` | `install_file__auto_backup` | `3.files-legacy.sh:56` |
| 8 | `$XDG_CONFIG_HOME/hypr/hyprland.lua` | `install_file` | `3.files-legacy.sh:61` |
| 9 | `$XDG_CONFIG_HOME/hypr/hypridle.conf` | `install_file__auto_backup` | `3.files-legacy.sh:68` |
| 10 | `$XDG_CONFIG_HOME/hypr/custom` | `install_dir__ignore_existing` | `3.files-legacy.sh:75` |
| 11 | `$XDG_DATA_HOME/icons/illogical-impulse.svg` | `install_file` | `3.files-legacy.sh:79` |

That is **11**, not 10 — `hyprland.lua` at line 61 is a destination the CONTEXT never names. 18 + 11 = **29**.
D-02's "roughly 28" is one short. `hyprland.lua` is `install_file` → `cp-through` → `restow/`, and it exists
live (`-rw-r--r-- 1 pera pera 1204 Sep  4 23:34 hyprland.lua`), so it is a real destination, not a dead branch.
It is gated by `SKIP_HYPRLAND_ENTRY`, which D-06 establishes is false on our one install path.
[VERIFIED: 3.files-legacy.sh:58-63 — `for i in hyprland.lua ; do` / `case "${SKIP_HYPRLAND_ENTRY}" in` /
`true) true;;` / `*) install_file "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i" ;;`; and
`ls -la ~/.config/hypr/` shows the live file]

**Action for the planner:** expect 29 rows and treat D-02's "roughly 28" as satisfied. Do not let an assert
hard-code 28 — better, do not hard-code a row count at all; the regenerate-and-diff already covers it, and a
count constant is one more thing a pin bump falsifies (exactly the `-eq 15` problem D-20 had to work around).

**Two coverage gaps to record in the map header**, neither a defect:
- `3.files-legacy.sh:42` — the `--fontset` alternate fontconfig source. D-32 already records this as a known gap.
- `3.files-legacy.sh:72` — the fedora-only `execs.conf` append (`if [ "$OS_GROUP_ID" = "fedora" ]`). Unreachable on Arch. [VERIFIED: 3.files-legacy.sh:71-73]

### F-14 — Current `verify`/`capture` failure mode, measured

```
$ ./arch/dots-hyprland.sh verify
[FAIL] Unknown or non-allowlisted subcommand: verify
[FAIL] Allowlisted: install install-deps install-setups install-files uninstall
[FAIL] For other ops use vendor/dots-hyprland/./setup directly.
```
[VERIFIED: command run this session; output quoted above. Same for `capture`.]

They exit at `main`'s allowlist check (`arch/dots-hyprland.sh:804-809`), **not** at `preflight`. D-47's
description of the FIX-05 bug ("`preflight` … so any subcommand routed through it exits 1") describes the
failure mode that *would* exist after D-61's allowlist addition if D-48's dispatch branches were omitted — not
the failure mode today. That makes D-48 and D-61 a strictly-ordered pair within a single commit: allowlist-then-
dispatch is a working change, allowlist-only is a regression that reaches `./setup verify`.

`ALLOWLIST=(install install-deps install-setups install-files uninstall)` confirmed at line 17, and the
dispatch `case` at 814-821 has exactly one named arm (`uninstall)`) plus the `*)` catch-all
[VERIFIED: arch/dots-hyprland.sh:17, :814-821 — quoted from the read].

## Architecture Patterns

### System Architecture Diagram

```
 vendor/dots-hyprland @ pin 1a9ffb78            arch/*.sh call sites
 ┌──────────────────────────────┐               ┌─────────────────────────┐
 │ 3.files-legacy.sh  (79 ln)   │               │ stow --verbose=5        │
 │  • MISC find loop  :11       │               │      --no-folding -t ~  │
 │  • named dests :18…:79       │               └───────────┬─────────────┘
 │ 3.files.sh  primitive defs   │                           │
 └──────────┬───────────────────┘                           │
            │ parsed by                                     │ links
            ▼                                               ▼
 ┌──────────────────────────────┐   emits   ┌─────────────────────────────┐
 │ scripts/gen-collision-map.sh │──stdout──▶│  collision-map.tsv          │
 │  arg: [source-root]          │           │  # pin=<sha>                │
 │  + 7-entry primitive lookup  │           │  dest prim sym repo tree src│
 │  + deterministic sort  (F-3) │           └──────────┬──────────────────┘
 └──────────┬───────────────────┘                      │ read by
            │                                          │
    ┌───────┴────────┐                    ┌────────────┴─────────────┐
    │ D-55 fake tree │                    │                          │
    │ (tmp, 1 prim   │                    ▼                          ▼
    │  changed)      │       ┌───────────────────────┐   ┌──────────────────────┐
    └───────┬────────┘       │ derive tree column    │   │ restow/README.md     │
            │                │  preserved+untouched  │   │  generated tag table │
            ▼                │      → stow/          │   │  (generator-owned)   │
 ┌──────────────────────────┐│  destroyed|overwritten│   └──────────────────────┘
 │ scripts/phase18-…assert  ││      → restow/        │
 │  §1 three READMEs        │└───────────┬───────────┘
 │  §2 map + pin SHA        │            │ prefix-match (D-13)
 │  §3 regen-diff + fixture │            ▼
 │  §4 --exp-files refused  │   ┌────────────────────────────────────┐
 │  §5 --adopt absent       │   │ REPO TREES                         │
 │  §6 .config/ gone        │   │  stow/    (installer never collides│
 │  §7 verify + capture     │   │  restow/  (installer overwrites)   │
 └──────────┬───────────────┘   │  capture/ (writer renames; EMPTY)  │
            │ compares          └──────────┬─────────────────────────┘
            ▼                              │
 ┌──────────────────────────────┐          │
 │ arch/dots-hyprland.sh        │          │
 │  main() prologue             │          │
 │   └─ --exp-files gate → exit2│          │
 │  ALLOWLIST + case            │          │
 │   ├─ run_verify()  ──────────┼──────────┤ test -L + readlink -f  (no vendor read)
 │   └─ run_capture() ──────────┼──────────┤ live ──cp──▶ repo working tree only
 │  run_install_family()        │          │            (never git add)
 │   └─ preflight ──▶ ./setup   │          ▼
 └──────────────────────────────┘     $HOME/.config/…  (live)
```

Entry points: a pin bump (left), an operator running an `arch/*.sh` (top right), an operator running
`arch/dots-hyprland.sh verify|capture` (bottom). The only write-into-the-repo arrow is `run_capture()`, and it
stops at the working tree.

### Recommended Project Structure

```
<repo root>
├── collision-map.tsv          # D-01 — generated artifact, checked in
├── stow/                      # installer never collides — link preserved, repo untouched
│   └── README.md              # contract + recovery + membership predicate (D-12)
├── restow/                    # installer overwrites — re-stow or git checkout
│   └── README.md              # + generator-owned package→tag→recovery table (D-12)
├── capture/                   # writer renames over the link — copy only; EMPTY this phase
│   └── README.md              # keeps the empty dir alive in a clone (D-11, no .gitkeep)
├── docs/
│   └── archive/               # NEW (D-27) — flat, original basenames
│       └── README.md          # nothing live, nothing reads it, why + retiring commit
└── scripts/
    ├── gen-collision-map.sh   # D-59 — stdout only, optional source root
    └── phase18-capture-model-assert.sh   # D-57 — one section per ROADMAP criterion
```

`.config/` at the repo root is **deleted** (FIX-03).

### Pattern 1: The repo assert contract

**What:** three prefixes, one counter, one closing line.
**When to use:** the new assert *and* `run_verify`/`run_capture` (D-49).

```bash
# Source: scripts/phase17-unblock-assert.sh:36-41 (verified verbatim)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
# … closing: echo "=== done: FAIL=$FAIL ==="; exit $(( FAIL > 0 ))
```

D-49 adds a fourth prefix `[FINDING]` for `verify`/`capture`. Note the sibling `scripts/phase14-verify.sh` uses
a *different* contract (second counter + fourth prefix), and phase17's header explicitly says it "is not copied
here beyond its info() helper line" [VERIFIED: scripts/phase17-unblock-assert.sh:26-29]. Phase 18 needs the
four-prefix form, so it is closer to phase14's shape than phase17's — state which you are following in the
script header, as both predecessors did.

### Pattern 2: The stow call-site idiom

**What:** one line, flags in fixed order, target always `~`, no package-path argument.
**When to use:** all five touched/new call sites.

```bash
# Source: arch/kitty.sh:10 (verified verbatim)
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ kitty

# Retargeted form — only the tree component changes:
cd "$(dirname "${BASH_SOURCE[0]}")/../restow" && stow --verbose=5 --no-folding -t ~ kitty
```

The fixed flag order is what lets `scripts/phase17-unblock-assert.sh:89` count occurrences of one literal and
call it a complete audit. Preserve the order exactly.

`arch/hyprland.sh` uses a `$REPO_ROOT`-based variant (`cd "$REPO_ROOT/stow" && stow …`) which carries the same
literal and is counted identically [VERIFIED: arch/hyprland.sh:42,46].

### Pattern 3: Vacuity guards before every ban-grep

**What:** assert the scoped tree exists and is non-empty *before* running a grep that passes on absence.
**When to use:** criterion 5 (`--adopt` absent) and criterion 6 (`.config/` absent) — both are ban-greps, and
both pass trivially if their search path is wrong.

```bash
# Source: scripts/phase17-unblock-assert.sh:54-60 (verified)
# "A ban-grep over a missing directory, or over a directory holding none of the
#  files it means to police, passes while observing nothing."
ARCH_SH_COUNT="$(find arch -maxdepth 1 -type f -name '*.sh' | wc -l || true)"
if [[ -d arch && "$ARCH_SH_COUNT" -gt 0 ]]; then …
```

This matters more in Phase 18 than in Phase 17, because criterion 6 asserts a directory is **gone** — and a
grep for readers of a deleted path is structurally a ban-grep over something that no longer exists.

### Pattern 4: Trap-based fixture cleanup

**What:** fixtures built by the assert must be removed even when the check they support fails.
**When to use:** D-44 (`capture` fixture in a tmp `$HOME`), D-55 (fake dots-hyprland tree), D-56 (mis-filed package).

D-56 calls for a throwaway package placed **inside the real repo tree**. Under `set -euo pipefail`, a `fail()`
that increments a counter does not abort — but any *other* non-zero command between creation and cleanup does,
and the fixture is then committed by the next operator who runs `git add -A`. The Phase 17 execution record in
STATE.md documents exactly this class of accident ("performing the plan's own commented-out-clause check
deleted README.md, the stow/ tree and the vendored submodule"). Use `trap 'rm -rf "$FIXTURE"' EXIT` set
immediately after `mktemp -d`, and prefer `mktemp -d` outside the repo for everything except D-56's placement
check, which by definition must sit inside a tree.

### Anti-Patterns to Avoid

- **Copying the primitive lookup from `PITFALLS.md:285-290`.** It misdescribes `install_dir` (F-1). Author from the verified matrix.
- **Hard-coding a row count in the assert.** The regenerate-and-diff already covers it, and a count constant is the `-eq 15` problem again (F-13, F-11).
- **Reaching for `--adopt` when stow reports the F-2 conflict.** Stow's own error message suggests it; CAP-07 bans it; the correct move is `mv` the live file aside then stow.
- **Editing a closed-phase assert to make it green.** STATE.md records the Phase 17 precedent: "A gate turned green by rewriting the historical record is a false green." D-20's single authorised bump is the exception, not the rule.
- **Deriving the `tree` column from the `primitive` column.** D-05/D-09 derive from the two *outcome* columns so a new primitive needs no second lookup. Two `install_file__auto_backup` rows with different firstrun states would otherwise disagree.
- **Verifying the map by running an install and observing.** F-5 — the destructive `auto_backup` branch is disarmed on this host right now, so observation contradicts the (correct) map.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting a dirty repo mirror | A `cmp` against a stashed copy, or a hand-rolled `git status` parser | `git ls-files --error-unmatch` + `git diff --quiet HEAD --` (F-8) | Staged-vs-unstaged, untracked and absent are four distinct states; only git knows all four |
| Resolving a symlink to compare against a repo path | String manipulation on `readlink` output | `realpath -f` / `readlink -f` equality (D-46) | Relative link targets (`../github_repo/.dotfiles/stow/…` — the actual form on this host) do not compare as strings |
| Linking repo→live | `cp`/`ln -s` loops | GNU Stow 2.4.1 with the fixed flag idiom | Conflict detection, `-D` removal and `--no-folding` semantics are the whole point of the taxonomy |
| Preserving file history across the FIX-03 moves | `cp` + `rm` | `git mv`, or plain `mv` + `git add -A` | git records unchanged moves as renames (D-28); `cp`+`rm` loses the link to history and makes D-28's per-disposition reverts much harder |
| Making the map diffable | A serializer | Plain TSV + a deterministic sort (D-01, F-3) | One-line diff per moved row is the entire regression signal |
| Parsing `3.files-exp.yaml`, if a future phase revisits D-30 | A bash YAML reader | `yq` v4.53.3, already installed | Out of scope this phase; noted so nobody writes one |

**Key insight:** every "custom solution" temptation in this phase is a temptation to *approximate a state
machine with fewer states than it has*. The dirty check has four states, not two. The primitive outcomes have
two independent axes (link, repo), not one. The `auto_backup` primitive has two branches, not one. Each
reduction produces code that is right on the happy path and silently wrong exactly where the phase's value lies.

## Runtime State Inventory

This is a refactor/migration phase (file moves + path retargeting), so the inventory is mandatory.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | **None.** No database, no datastore keys the phase's renames touch. The installer's `INSTALLED_LISTFILE` at `~/.config/illogical-impulse/installed_listfile` (77338 bytes) records *live* destination paths, not repo paths, so moving repo files between `stow/` and `restow/` does not stale it. [VERIFIED: `ls -l ~/.config/illogical-impulse/` this session; `realpath -se "$2" >> "${INSTALLED_LISTFILE}"` at 3.files.sh:51 writes the destination, not the source] | none |
| **Live service config** | **Two live folded directory symlinks** must be unfolded by hand (D-15/D-17): `~/.config/qBittorrent -> ../github_repo/.dotfiles/stow/qbittorrent/.config/qBittorrent` and `~/.config/smartmontools -> ../github_repo/.dotfiles/stow/smartmontools/.config/smartmontools` [VERIFIED: `ls -ld` + `readlink` this session; both link targets quoted verbatim]. **qBittorrent must not be running** during the unfold (D-18). No n8n/Datadog/Tailscale/Cloudflare equivalent exists in this repo. | `stow -D` then `stow --no-folding`, by hand, per D-17 |
| **OS-registered state** | **One systemd user unit is stow-linked:** `~/.config/systemd/user/hyprland-session.service` resolves into `stow/systemd/` — recorded in STATE.md as the reason `safe_rm_path` compares realpath-resolved strings. Phase 18 does **not** move `stow/systemd/`, so no re-registration is needed. No Task Scheduler / pm2 / launchd equivalent. [VERIFIED: STATE.md Phase 17 decision entry; `scripts/phase17-unblock-assert.sh:783-789` asserts the unit stays in state `linked`] | none — but do not move `stow/systemd/` |
| **Secrets / env vars** | **None.** `.gitleaks.toml` exists at the repo root but no secret key name is renamed by this phase. No `.env` is read by any path the phase touches. [VERIFIED: repo-root listing this session] | none |
| **Build artifacts / installed packages** | **Three live sidecar artifacts already exist and will confuse a naive verify:** `~/.config/hypr/hypridle.conf.new`, `~/.config/hypr/hyprlock.conf.new` (both from `install_file__auto_backup`'s non-firstrun branch) and `~/.config/hypr/hyprland.conf.old` (from the Phase 14 `inline_rename`). None is tracked; none should be. `scripts/__pycache__/` exists under `scripts/` and is unrelated. [VERIFIED: `ls -la ~/.config/hypr/` and `ls scripts/` this session] | none — but `verify` must not treat a `.new`/`.old` sidecar as a missing-live-counterpart `[FAIL]` under D-54 |

**The canonical question — after every file in the repo is updated, what still holds the old arrangement?**
Answer: the two folded directory symlinks (handled by D-15), and nothing else. Because repo-root `.config/` was
**never stowed** (F-2: all twelve live counterparts are real files), there is no live symlink pointing at the
about-to-be-deleted `.config/` tree. That is the single fact that makes FIX-03 a low-risk move.

## Common Pitfalls

### P-1: Stow aborts the migration because the live file is real, not a link
**What goes wrong:** `stow --no-folding -t ~ hypr` exits 1 with `CONFLICT … since neither a link nor a directory and --adopt not specified`; under `set -euo pipefail` the calling `arch/*.sh` dies.
**Why it happens:** repo-root `.config/` was never stowed; all twelve live counterparts are plain files (F-2).
**How to avoid:** in every FIX-03 migration task, resolve the D-22 content decision, `mv` the live file aside, stow, confirm `test -L`, then remove the aside copy in a later commit.
**Warning signs:** `stow -n` (simulate) also exits 1 — use it as a cheap pre-check before the real run. It is non-mutating and gives the exact conflict list.

### P-2: The dirty check waves an untracked mirror through
**What goes wrong:** `capture` overwrites an untracked repo mirror and the operator's uncommitted work is unrecoverable — no HEAD version, no stash, no reflog.
**Why it happens:** `git diff --quiet HEAD -- <path>` exits 0 for untracked *and* for nonexistent paths (F-8).
**How to avoid:** two-part test — tracked-ness first, then diff. See Code Examples.
**Warning signs:** a `capture` run that reports zero skips on a tree you know has new files in it.

### P-3: The assert's regenerate-and-diff fires on a clean tree
**What goes wrong:** CI-equivalent green run turns red for nobody's reason; the signal is discarded as flaky and the real pin-bump signal is then ignored too.
**Why it happens:** `find` returns readdir order, which is filesystem- and history-dependent (F-3).
**How to avoid:** deterministic sort in the generator; assert that two consecutive regenerations are byte-identical.
**Warning signs:** the diff shows the same rows in a different order with no content change.

### P-4: An empirical check of the map contradicts the map
**What goes wrong:** someone runs `install-files`, watches `hyprlock.conf` survive intact, and "corrects" it from `restow/` to `stow/`.
**Why it happens:** `installed_true` exists, so `install_file__auto_backup` takes the benign `.new` branch (F-5). The destructive branch is one `--firstrun` away.
**How to avoid:** record the firstrun reasoning in the map header; emit an explicit `[INFO]` from the assert naming the disarmed branch.
**Warning signs:** live `.new` sidecars present — which they are, right now, for both `hypridle.conf` and `hyprlock.conf`.

### P-5: Criterion 6's assert fails against 30 files on day one
**What goes wrong:** "no script reads that path" is asserted literally and the phase cannot go green without touching 30 files, including a closed-phase record D-20 forbids editing.
**Why it happens:** D-21 scoped the problem to six scripts; the real count of repo-root-relative `.config/` references is 30 files / 53 lines, most pointing at already-missing paths (F-9).
**How to avoid:** scope the assert to the twelve files actually being moved; exclude quoted grep patterns using Phase 17's anchored-pattern technique; exclude `arch/dots-hyprland.sh:446`, which is a live-path glob protecting FIX-04.
**Warning signs:** an assert pattern that matches `'cp -rf .config/hypr/'` inside a single-quoted grep argument.

### P-6: Allowlisting `verify`/`capture` without the dispatch branches
**What goes wrong:** `./arch/dots-hyprland.sh verify` reaches `run_install_family` → `preflight` → `cd $II_ROOT && ./setup verify` against an upstream with no such subcommand.
**Why it happens:** `main`'s `case` has one named arm and a `*)` catch-all (F-14); adding to `ALLOWLIST` alone moves the failure from a clean refusal to an upstream invocation.
**How to avoid:** D-61 (allowlist) and D-48 (branches) in one commit. Assert both: `verify` exits non-zero-or-zero *on its own terms* and never prints `[INSTALL] ./setup verify`.
**Warning signs:** the string `./setup verify` anywhere in output.

### P-7: A fixture survives a failing assert
**What goes wrong:** D-56's deliberately mis-filed package, or D-44's tmp-`$HOME` fixture, is left behind and gets committed.
**Why it happens:** cleanup placed after the check rather than in a `trap`; `set -e` exits early on an unrelated command.
**How to avoid:** `trap 'rm -rf "$F"' EXIT` immediately after `mktemp -d`. D-56 explicitly calls for this.
**Warning signs:** `git status` non-empty after an assert run — the assert should be strictly non-mutating on the tracked tree.

### P-8: `verify` flags the `.new`/`.old` sidecars
**What goes wrong:** D-54 makes "repo file with no live counterpart" a `[FAIL]`; the inverse — live files with no repo mirror — must be `[INFO]` per D-40, and the three existing sidecars are exactly that.
**Why it happens:** `~/.config/hypr/` currently holds `hypridle.conf.new`, `hyprlock.conf.new` and `hyprland.conf.old`, all untracked and all correctly so.
**How to avoid:** `verify` walks the **repo** side (D-40's rule for `capture` applies equally here), so sidecars are never visited. Confirm the implementation does not walk live.
**Warning signs:** `verify` output naming a `.new` or `.old` path.

## Code Examples

### The corrected dirty check (D-37, amended per F-8)

```bash
# Two-part test. `git diff --quiet HEAD --` alone reports untracked AND absent
# paths as clean (verified: both exit 0), which is the exact case D-37 means to
# refuse. Tracked-ness must be established first.
#
# Returns: 0 = clean and safe to capture
#          1 = dirty/untracked/absent — skip this path, contribute to non-zero exit
mirror_is_capturable() {
  local p="$1"
  if [[ ! -e "$p" ]]; then
    printf '[FINDING] repo mirror does not exist: %s\n' "$p"
    return 1
  fi
  if ! git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
    printf '[FINDING] repo mirror is untracked (no HEAD version to recover): %s\n' "$p"
    return 1
  fi
  if ! git diff --quiet HEAD -- "$p"; then
    printf '[FINDING] repo mirror is dirty against HEAD: %s\n' "$p"
    return 1
  fi
  return 0
}
```
[VERIFIED: `git ls-files --error-unmatch` returns non-zero for untracked; `git diff --quiet HEAD --` returns
0 for untracked and 0 for absent — both measured this session in a throwaway repo on git 2.55.0]

### The link-ness check (D-46 — `PITFALLS.md:30`'s core constraint)

```bash
# Order matters: link-ness BEFORE content. Both destroying primitives leave the
# repo file untouched, so a content-only comparison reports "no drift" in exactly
# the case that matters.
check_linked() {
  local live="$1" repo="$2"
  if [[ ! -L "$live" ]]; then
    printf '[FAIL] not a symlink: %s — recover with: cd %s && stow --verbose=5 --no-folding -t ~ %s\n' \
      "$live" "$TREE" "$PKG"
    return 1
  fi
  if [[ "$(readlink -f -- "$live")" != "$(readlink -f -- "$repo")" ]]; then
    printf '[FAIL] symlink points elsewhere: %s -> %s (expected %s)\n' \
      "$live" "$(readlink -f -- "$live")" "$repo"
    return 1
  fi
  return 0
}
```
Note `readlink -f` on both sides, not a string compare: the live links on this host are **relative**
(`../github_repo/.dotfiles/stow/qbittorrent/.config/qBittorrent`), so raw `readlink` output never equals an
absolute repo path. [VERIFIED: `readlink ~/.config/qBittorrent` this session returned the relative form quoted above]

### Deterministic MISC-loop expansion (D-58 + F-3)

```bash
# Reproduces vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh:11-17
# verbatim in its exclusions and its [ -d ]/[ -f ] discrimination, then SORTS.
# The installer does not sort; the generator must, or the checked-in map's row
# order depends on readdir order and the regenerate-and-diff fires spuriously.
SRC_ROOT="${1:-vendor/dots-hyprland}"
find "$SRC_ROOT/dots/.config/" -mindepth 1 -maxdepth 1 \
     ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' ! -name 'fontconfig' \
     -exec basename {} \; \
| LC_ALL=C sort \
| while IFS= read -r i; do
    if   [ -d "$SRC_ROOT/dots/.config/$i" ]; then prim=install_dir__sync
    elif [ -f "$SRC_ROOT/dots/.config/$i" ]; then prim=install_file
    else continue
    fi
    emit_row "\$XDG_CONFIG_HOME/$i" "$prim" "3.files-legacy.sh:11"
  done
```
`LC_ALL=C` pins collation so `Kvantum` sorts consistently against lowercase names across locales.

### The `--exp-files` gate (D-31, D-33)

```bash
# In main(), AFTER the help arm and BEFORE the allowlist check, so it covers
# install / install-files / uninstall and any subcommand added later.
for _arg in "$@"; do
  if [[ "$_arg" == "--exp-files" ]]; then
    echo "[FAIL] Refusing --exp-files." >&2
    echo "[FAIL] It routes installation through sdata/subcmd-install/3.files-exp.sh," >&2
    echo "[FAIL] which reads its destinations from 3.files-exp.yaml and uses a different" >&2
    echo "[FAIL] set of write primitives (rsync -av --delete, rsync -av, cp -r, cp -r to" >&2
    echo "[FAIL] .old.N / .new) from the ones collision-map.tsv was derived from." >&2
    echo "[FAIL] Every row of collision-map.tsv would be void under this flag." >&2
    exit 2
  fi
done
```
The loop scans `"$@"` including `$1`; that is harmless, since no allowlisted subcommand is named `--exp-files`.
Exit 2 distinguishes usage error from the wrapper's existing 1 (D-33).

### The assert's CAP-08 end-to-end check (D-34)

```bash
# Behavioural, not textual: grepping for the guard proves the text exists,
# not that it fires. Capture stderr, require non-zero, require the map filename,
# and require that ./setup was never announced.
OUT="$(./arch/dots-hyprland.sh install --exp-files 2>&1)"; RC=$?
if [[ "$RC" -ne 0 ]] \
   && grep -q 'collision-map.tsv' <<<"$OUT" \
   && ! grep -q '\./setup' <<<"$OUT"; then
  pass "4 --exp-files refused with exit $RC, names the collision map, never reached ./setup"
else
  fail "4 --exp-files was not refused correctly (rc=$RC)"
  printf '%s\n' "$OUT"
fi
```
Note `RC=$?` must immediately follow the assignment; under `set -e` wrap the call so a non-zero exit does not
abort the assert — `OUT="$(… 2>&1)" || RC=$?` is the safer spelling.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| "Atomic rewrite" exception list (PROJECT.md original D-41) | Three trees keyed on **installer collision class and write primitive** | v0.4 start (STATE.md) | Research falsified the atomicity framing — Qt `QSaveFile` resolves symlinks and is the *safest* writer; the real threats are `rsync -a --delete`, `cp -f` and bare `mv` |
| Safe/full install profiles with `SKIP_*` gating | Full is the only behaviour; `SAFE_DEFAULTS` retired | Phase 16 | D-06 can drop the `SKIP_*` column from the map entirely — every `SKIP_*` is false on the one install path |
| `stow -v=5` | `stow --verbose=5 --no-folding` at all 15 call sites | Phase 17 | The fixed flag order is what lets one counted grep audit every site; preserve it |
| Folded stow directories tolerated | `--no-folding` universal; the two survivors unfolded here | Phase 17 → 18 | Removes the "installer writes into the repo" class (PITFALLS D-2) |

**Deprecated / outdated in this repo:**
- Repo-root `.config/` as a second authoring tree — retired by FIX-03 this phase.
- `ubuntu/` and `debian/` config-copy scripts — 20 of them reference repo-root `.config/<pkg>` paths that no longer exist (F-9). Broken today, out of scope, worth a backlog item.
- `PITFALLS.md:288`'s merged `install_dir` / `install_dir__ignore_existing` row — factually misleading (F-1).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `capture/` has no derivable member at this pin because no legacy primitive renames over a link except the one-off `inline_rename` — supporting D-05's hand-assignment | CAP-01 / Requirements | Low. If a future primitive does, D-05's "never appears in the column" rule needs revisiting. The claim rests on the verified 7-primitive matrix, which is complete for `3.files-legacy.sh`, but `switchwall.sh`/matugen were **not** read this session (they are Phase 21 scope per the CONTEXT's canonical refs). |
| A2 | Scoping criterion 6's assert to the twelve moved files is the intended reading of "no script reads that path" | F-9 / P-5 / Q-1 | Medium. If the intended reading is literal and repo-wide, the phase gains ~20 file edits in `ubuntu/`+`debian/`. Needs user confirmation — see Q-1. |
| A3 | `arch/zsh_powerlevel.sh` should **not** gain a starship stow line, keeping D-19's count at 18 | F-10 | Low-medium. If it should, the D-20 authorised constant is 19, not 18, and the authorisation text needs amending. Needs user confirmation — see Q-2. |
| A4 | Correcting `PITFALLS.md:288` is additive and permitted, riding along with D-35's authorised edit to that file | F-1 | Low. STATE.md's Phase 17 precedent treats PITFALLS as frozen for *ban-grep* purposes; D-35 explicitly opens it this phase. A dated correction note is the conservative form. |
| A5 | The three live `.new`/`.old` sidecars need no disposition this phase | Runtime State Inventory | Low. They are untracked, correctly so, and `verify` walks the repo side. If a later phase wants them archived, that is Phase 21 scope. |

**Every other claim in this document is `[VERIFIED]` by a source read or a probe run this session.** No claim
in this research rests on training knowledge about a third-party library, and no claim rests on absent evidence.

## Open Questions

1. **Q-1 — How literally should criterion 6's "no script reads that path" be scoped?**
   - *What we know:* 30 files / 53 lines reference a repo-root-relative `.config/` path. Only 12 files live there. Nearly every reference points at an already-missing path and is broken today (F-9). D-21 names six scripts.
   - *What's unclear:* whether FIX-03 owns the whole `ubuntu/`+`debian/` legacy set, or only the paths it deletes.
   - *Recommendation:* scope the assert to the twelve moved files (`.config/hypr/`, `.config/dolphinrc`, `.config/kdeglobals`), and additionally retarget `scripts/nvim-validate.sh` + `scripts/nvim-audit-failures.sh` because they are in `scripts/`, currently broken, and cheap. File the `ubuntu/`+`debian/` set as a backlog item. Confirm with the user before planning — it is a ±20-file scope swing.

2. **Q-2 — Does `arch/zsh_powerlevel.sh` also need the starship stow line?**
   - *What we know:* it independently stows the `zsh` package at line 61 (F-10). D-08 mentions only `arch/zsh.sh`. D-19's 15→18 arithmetic assumes one new starship line.
   - *What's unclear:* whether an operator who runs only `zsh_powerlevel.sh` should get starship.
   - *Recommendation:* no — keep one starship line in `arch/zsh.sh`, note the boundary in `restow/README.md`, keep the constant at 18. Cheap to reverse if wrong.

3. **Q-3 — Does the map carry 29 rows where D-02 says "roughly 28"?**
   - *What we know:* 18 MISC + 11 named = 29. The extra is `$XDG_CONFIG_HOME/hypr/hyprland.lua` (`install_file`, `3.files-legacy.sh:61`), which the CONTEXT never enumerates and which exists live (F-13).
   - *What's unclear:* nothing factual — only whether "roughly 28" is satisfied by 29.
   - *Recommendation:* yes, proceed with 29 and do not hard-code any count. `hyprland.lua` is `cp-through` → `restow/`; note it in the redistribution reconciliation, since it is a hypr destination the FIX-03 table does not mention (it has no repo-root `.config/` counterpart, so it creates no move — only a map row).

4. **Q-4 — Is `run_capture`'s "live path must not be a symlink resolving into the repo" guard (D-39) checkable before `capture/` has any inhabitant?**
   - *What we know:* D-44's fixture builds a throwaway package in a tmp `$HOME`. D-41 requires the empty case to exit 0 with an explicit message.
   - *What's unclear:* whether the assert exercises the D-39 refusal, which needs a live symlink into the fixture repo.
   - *Recommendation:* build it — the fixture already controls both sides, so `ln -s` into the fixture's repo mirror is one line. Otherwise D-39 ships unexercised and Phase 21 discovers it.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| GNU Stow | all three trees; migration; assert | ✓ | 2.4.1 | — |
| bash | generator, assert, wrapper functions | ✓ | 5.3.15(1) | — |
| git | pin SHA, dirty check, rename-preserving moves | ✓ | 2.55.0 | — |
| GNU findutils `find` | reproducing the MISC loop | ✓ | 4.11.0 (`/usr/bin/find`, owned by `findutils 4.11.0-1`) | — |
| GNU coreutils | `realpath`, `readlink`, `cp`, `mv`, `sort`, `mktemp` | ✓ | 9.11 | — |
| rsync | not invoked by phase code; its behaviour is the map | ✓ | 3.5.0 | — |
| diffutils `cmp` | byte comparison in verify/assert | ✓ | 3.12 | — |
| `jq` | not needed (map is TSV) | ✓ | 1.8.2 | — |
| `yq` | not needed this phase (D-30 deferred) | ✓ | v4.53.3 | — |
| `vendor/dots-hyprland` submodule | generator source; pin SHA | ✓ | pin `1a9ffb78f0c272a45f82342587dc3bec72762233` | D-55's fake tree for the simulation only |
| **`shellcheck`** | static analysis of new bash | **✗** | — | `bash -n` syntax check only — the technique `scripts/phase17-unblock-assert.sh:110-145` already uses |
| **`bats`** | bash unit testing | **✗** | — | The repo's own assert-script pattern (see Validation Architecture) |
| CI runner | — | **✗** (no `.github/workflows`) | — | Asserts are run by hand; that is the established repo model |

**Missing dependencies with no fallback:** none.

**Missing dependencies with fallback:**
- `shellcheck` — use `bash -n` per the Phase 17 precedent. Do not add a `shellcheck` install task; it would be the phase's only new package and CONTEXT authorises none.
- `bats` — the repo has never used it; `scripts/phase*-assert.sh` is the established test vehicle.

**Note on interactive-shell aliasing:** an interactive `find --version` on this host reports `bfs 4.1.1` because
the user's zsh aliases `find`. Scripts using `#!/usr/bin/env bash` resolve `find` via PATH to `/usr/bin/find`
(GNU findutils 4.11.0). [VERIFIED: `ls -l /usr/bin/find`, `/usr/bin/find --version`, `pacman -Qo /usr/bin/find`
this session]. The generator is unaffected, but do not debug it from an interactive zsh prompt and assume parity.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | **None installed.** The repo's convention is standalone `scripts/phaseNN-*-assert.sh` executables using the `[PASS]`/`[FAIL]`/`[INFO]` contract |
| Config file | none — by design |
| Quick run command | `./scripts/phase18-capture-model-assert.sh` |
| Full suite command | `./scripts/phase18-capture-model-assert.sh && ./scripts/phase17-unblock-assert.sh && ./scripts/phase16-retire-assert.sh && ./scripts/phase14-verify.sh && ./scripts/phase13-d19-assert.sh && ./scripts/phase12-full-smoke.sh && ./scripts/phase11-dispositions-assert.sh && ./scripts/phase10-inventory-assert.sh` |

Existing assert inventory [VERIFIED: `ls scripts/` this session]: `phase02-config-assert.py`,
`phase03-config-assert.py`, `phase04-ipc-reload-assert.py`, `phase10-inventory-assert.sh`,
`phase11-dispositions-assert.sh`, `phase12-full-smoke.sh`, `phase13-d19-assert.sh`, `phase14-verify.sh`,
`phase16-retire-assert.sh`, `phase17-unblock-assert.sh`.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CAP-01 | three trees exist, each README has contract + recovery + membership rule; every `restow/` package tagged | integration | `./scripts/phase18-capture-model-assert.sh` §1 | ❌ Wave 0 |
| CAP-02 | `collision-map.tsv` present, covers every `3.files-legacy.sh` destination, records pin SHA | integration | `./scripts/phase18-capture-model-assert.sh` §2 | ❌ Wave 0 |
| CAP-03 | mis-filed fixture → non-zero; simulated pin bump moves a row | integration | `./scripts/phase18-capture-model-assert.sh` §3 | ❌ Wave 0 |
| CAP-03 | generator is deterministic (regen twice, byte-identical) — **added per F-3** | unit | `./scripts/phase18-capture-model-assert.sh` §3 | ❌ Wave 0 |
| CAP-08 | `install --exp-files` exits non-zero, names the map, never reaches `./setup` | e2e | `./scripts/phase18-capture-model-assert.sh` §4 | ❌ Wave 0 |
| CAP-07 | `--adopt` absent under `arch/` and `scripts/`; ban documented with exception | unit | `./scripts/phase18-capture-model-assert.sh` §5 | ❌ Wave 0 |
| FIX-03 | `.config/` absent; every destination present; no in-scope script reads the path | integration | `./scripts/phase18-capture-model-assert.sh` §6 | ❌ Wave 0 |
| FIX-05 | `verify` allowlisted, own handler, real exit code with submodule de-initialised | e2e | `./scripts/phase18-capture-model-assert.sh` §7 | ❌ Wave 0 |
| CAP-05 | `capture` copies live→repo for a fixture; `git diff --cached` empty; dirty mirror refused | integration | `./scripts/phase18-capture-model-assert.sh` §7 | ❌ Wave 0 |
| CAP-05 | **untracked** mirror refused — **added per F-8** | integration | `./scripts/phase18-capture-model-assert.sh` §7 | ❌ Wave 0 |
| CAP-05 | `--dry-run` leaves repo and `git status` unchanged (D-42) | integration | `./scripts/phase18-capture-model-assert.sh` §7 | ❌ Wave 0 |
| CAP-05 | empty `capture/` → exit 0 with explicit message (D-41) | integration | `./scripts/phase18-capture-model-assert.sh` §7 | ❌ Wave 0 |
| — | Phase 17 regression: 18 call sites still carry the literal pair | regression | `./scripts/phase17-unblock-assert.sh` | ✅ exists (constant bumped per D-20) |
| — | Phase 13/14 regressions after the D-21 fixture repoint | regression | `./scripts/phase13-d19-assert.sh`, `./scripts/phase14-verify.sh` | ✅ exist (paths repointed) |

**Manual-only:** the D-15/D-17 unfold of `~/.config/qBittorrent` and `~/.config/smartmontools`. Justification:
D-17 explicitly declines to ship a migration script, D-18 requires qBittorrent to not be running, and the window
between `stow -D` and the re-stow is unsafe to automate. The assert checks the **end state** only (both paths
are real directories whose contents are links into `stow/`), which is automatable and is what D-17 specifies.

### Sampling Rate
- **Per task commit:** `bash -n` on every touched script, plus `./scripts/phase18-capture-model-assert.sh` for the sections already implemented
- **Per wave merge:** `./scripts/phase18-capture-model-assert.sh` + `./scripts/phase17-unblock-assert.sh` (the call-site count changes in this phase, so it is the highest-risk regression)
- **Phase gate:** the full eight-script suite green before `/gsd-verify-work`, matching the Phase 16 D-40 gate precedent recorded in STATE.md

### Wave 0 Gaps
- [ ] `scripts/gen-collision-map.sh` — generator; CAP-02, CAP-03
- [ ] `scripts/phase18-capture-model-assert.sh` — seven sections, one per ROADMAP criterion; all requirements
- [ ] `collision-map.tsv` — generated artifact, committed **before** any file move (D-26)
- [ ] `stow/README.md`, `restow/README.md`, `capture/README.md` — CAP-01
- [ ] `docs/archive/README.md` — D-27; the directory does not exist [VERIFIED: `ls -d docs/archive` → No such file or directory; `docs/` holds only `dots-hyprland-workflow.md` and `phase14-adopt-runbook.md`]
- [ ] Framework install: **none** — the repo's assert-script model is the framework

## Security Domain

`workflow.security_enforcement: true`, `security_asvs_level: 1` [VERIFIED: .planning/config.json].

This phase ships no network surface, no authentication, no session handling and no user-facing input. Its
security-relevant surface is **local filesystem and shell argument handling** in three new code paths:
`gen-collision-map.sh`, `run_capture()` and `run_verify()`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface |
| V3 Session Management | no | No sessions |
| V4 Access Control | **yes** (weakly) | `run_capture` must write only under `capture/`; `safe_rm_path`'s existing repo-refusal (FIX-04) is the analogous prior control |
| V5 Input Validation | **yes** | Path validation on `capture` targets; `--exp-files` refusal is itself an input-validation control (CAP-08) |
| V6 Cryptography | no | No crypto. `md5sum` appears only in this research document as a content-comparison convenience, never as a security control |
| V12 File & Resource | **yes** | Symlink-following writes, TOCTOU between the dirty check and the copy, fixture cleanup |
| V14 Configuration | **yes** | The wrapper's flag-forwarding boundary; `.gitleaks.toml` already present at repo root |

### Known Threat Patterns for bash + filesystem

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal out of `capture/` via `..` in a derived live path | Elevation of Privilege | D-39's guard: resolve with `realpath` and require the result to be under `$REPO_ROOT/capture/`. Compare **resolved** strings, never a literal prefix on the unresolved argument — this is exactly the defect STATE.md records Phase 17 fixing in `safe_rm_path` |
| Writing through a symlink into an unintended target | Tampering | D-39's second guard: refuse when the live path is a symlink resolving into the repo. This is the same class as the `cp -f` corruption the whole phase exists to model |
| TOCTOU between `mirror_is_capturable` and the copy | Tampering | Single-machine, single-operator repo; the window is unexploitable here. Record as accepted rather than engineered around |
| Word-splitting / glob expansion on unquoted paths | Tampering | Quote every expansion; `IFS=` on every `read`; `--` before pathspecs in every `git` invocation (the examples above do this) |
| Fixture left behind and committed | Tampering | `trap … EXIT` per P-7; assert must leave `git status` empty |
| Flag smuggling to upstream `./setup` | Elevation of Privilege | The CAP-08 gate in `main()` before dispatch (D-31). Note the gate is a **deny-list of one** by D-32's explicit choice — `--via-nix`, `--core`, `--skip-*` and `--fontset` still forward. That is a deliberate, documented accepted risk, not an oversight |
| Secret leakage through captured config content | Information Disclosure | `.gitleaks.toml` exists at repo root; FIX-06 already covers the capture trees. `capture/` is empty this phase, so the surface is zero until Phase 21 |

**Accepted risk to record:** D-32 refuses exactly one flag. An operator can still reach a code path the map does
not model via `--fontset` (`3.files-legacy.sh:42`, a different fontconfig source). D-32 records this as a map
coverage gap rather than a refusal; the map header should say so explicitly so the gap is auditable.

## Sources

### Primary (HIGH confidence)

**First-party source reads, this session** — the pinned submodule at `1a9ffb78f0c272a45f82342587dc3bec72762233`:
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — read in full (79 lines); every destination and line number cited above
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:1-240` — all primitive definitions, the firstrun logic, the legacy/experimental router
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-exp.sh` — primitive set (:217-272), wizard (:45,58,71), TODOs (:15-16), line count
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh:28-55, 85-95` — `--exp-files` documentation, getopt list, variable set
- `vendor/dots-hyprland/sdata/lib/environment-variables.sh:30` — `FIRSTRUN_FILE`
- `vendor/dots-hyprland/setup:28-30, 57-117` — the upstream subcommand set
- `arch/dots-hyprland.sh` — `ALLOWLIST` :17, `is_allowlisted` :109-115, `preflight` :117-129, `safe_rm_path` hypr belt :444-450, `touches_files` :716-721, `run_install_family` :723-788, `main` :790-822, dispatch guard :824-833
- `scripts/phase17-unblock-assert.sh` — contract :26-41, stow simulate :43-52, vacuity guard :54-60, pair count :85-96, syntax-file guard :110-140, anchored-pattern technique :212-232, probe patterns :425-436
- `.planning/research/PITFALLS.md:28-30, 275-294` — the design constraint and the primitive table
- `.planning/phases/18-.../18-CONTEXT.md` — all 61 decisions
- `.planning/REQUIREMENTS.md:14-31, 155-162`; `.planning/ROADMAP.md:125-135`; `.planning/STATE.md`
- `.planning/config.json`

**Falsification probes run this session** (scratch directories, no repo mutation):
- PROBES 1–6: the primitive outcome matrix against `rsync 3.5.0` / `coreutils 9.11`
- Stow conflict probe: simulate and real exit codes, before and after removing the live real file (`stow 2.4.1`)
- `--adopt` probe: exit code and post-state content direction
- git dirty-check probe: `git diff --quiet HEAD --` vs `git ls-files --error-unmatch` vs `git status --porcelain` across tracked-dirty / untracked / absent (`git 2.55.0`)
- MISC `find` expansion: the installer's exact expression against the pinned tree, plus `[ -d ]` classification
- Content hash sweep: vendor/live/repo `md5sum` for all 12 repo-root `.config/` files
- Repo-root `.config/` reader census: anchored grep over `arch/ scripts/ ubuntu/ debian/`
- Environment sweep: `--version` on 11 tools; `pacman -Qo /usr/bin/find`
- FIX-05 current behaviour: `./arch/dots-hyprland.sh verify` and `capture`

### Secondary (MEDIUM confidence)

None. No documentation lookup was required — this phase has no third-party library surface, and the research
seam (`research-plan`) was not exercised because every question resolved against first-party source or a probe.

### Tertiary (LOW confidence)

None. No claim in this document rests on WebSearch or on unverified training knowledge. The five items in the
Assumptions Log are scope/judgement calls, not factual gaps.

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — no external packages; every tool's presence and version measured directly
- Architecture: **HIGH** — every integration point read at its cited line number in the current working tree
- Primitive matrix: **HIGH** — all seven rows reproduced end-to-end by probe, not inferred
- Pitfalls: **HIGH** — P-1, P-2, P-3, P-4, P-5, P-6 each rest on a probe or a verbatim source read; P-7 and P-8 rest on source reads plus the STATE.md Phase 17 incident record
- Scope questions (Q-1, Q-2): **MEDIUM** — the *facts* are verified; the *scoping intent* needs user confirmation

**Research date:** 2026-09-13
**Valid until:** valid while `vendor/dots-hyprland` stays pinned at `1a9ffb78f0c272a45f82342587dc3bec72762233`. A pin bump invalidates the 29-row enumeration, the MISC 18-entry list, and every cited line number in `3.files-legacy.sh` / `3.files.sh` / `options.sh` / `3.files-exp.sh` — which is precisely the rot D-60 makes visible. The non-submodule findings (F-2, F-3, F-7, F-8, F-9, F-10, F-11) are independent of the pin.
