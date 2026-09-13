# Phase 18: Capture model — three trees and the collision map - Context

**Gathered:** 2026-09-13
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase makes a file's capture mechanism knowable from its location alone.

It delivers three top-level trees (`stow/`, `restow/`, `capture/`), each with a README stating its contract and its recovery command; a machine-readable collision map at `collision-map.tsv` that records, for every destination the vendored installer writes, which primitive it uses and what that primitive does to a symlink and to the repo copy; a generator that derives that map from the pinned submodule; and an assert script that fails when a file's actual tree placement contradicts what the map derives for it.

It also closes four standing debts that the taxonomy makes answerable: the two already-folded stow directories left over from Phase 17 (D-02) are unfolded; repo-root `.config/` is redistributed and removed (FIX-03); `arch/dots-hyprland.sh` learns to refuse `--exp-files`, whose alternate installer path voids every row of the map (CAP-08); and `verify` and `capture` become real allowlisted subcommands dispatched by `main` rather than being routed through `run_install_family`, which today makes them die in `preflight` (FIX-05, CAP-05).

`capture/` is legitimately empty when the phase ends. The mechanism ships here; its first inhabitant arrives in Phase 21. Criterion 7 is therefore proven against a fixture that the assert builds and tears down, not against a committed resident.

**Requirements covered:** CAP-01, CAP-02, CAP-03, CAP-05, CAP-07, CAP-08, FIX-03, FIX-05.

</domain>

<decisions>
## Implementation Decisions

### The collision map

- **D-01:** The map is a TSV at the repo root, `collision-map.tsv`, carrying a comment header with the pin SHA. Columns: `dest`, `primitive`, `symlink_outcome`, `repo_outcome`, `tree`, `source`. TSV over JSON or YAML because the file is read by humans during review, diffed by the assert, and cut by shell — and because a row moving must be visible as a one-line diff.

  ```
  # collision-map v1  pin=1a9ffb78f0c272a45f82342587dc3bec72762233
  # dest	primitive	symlink_outcome	repo_outcome	tree	source
  $XDG_CONFIG_HOME/quickshell	install_dir__sync	DESTROYED	untouched	restow	3.files-legacy.sh:26
  $XDG_CONFIG_HOME/hypr/custom	install_dir__ignore_existing	preserved	untouched	stow	3.files-legacy.sh:75
  $XDG_CONFIG_HOME/hypr/hyprland	install_dir__sync	DESTROYED	untouched	restow	3.files-legacy.sh:50
  ```

- **D-02:** The `find`-driven MISC loop at `3.files-legacy.sh:11` is expanded into concrete rows — roughly 28 rows in total at the current pin — rather than represented as a single glob row. A pin bump that adds a colliding file then visibly adds a row instead of silently changing what one row means.

- **D-03:** Rows are produced by a generator that walks the vendored tree and emits `dest`, `primitive` and `source` mechanically. The `primitive → (symlink_outcome, repo_outcome)` mapping is a hand-authored lookup of roughly seven entries, sourced from `.planning/research/PITFALLS.md:285-290`. The assert regenerates the map and diffs it against the checked-in file, which means a pin bump that moves a row fails as a diff and satisfies criterion 3 without additional machinery. An unrecognised primitive fails loudly rather than defaulting to a safe-looking value. — **Reversibility:** costly — the generator's output format becomes the checked-in artifact that the assert, both tree READMEs and the derived tree placement all read; changing the column set later means regenerating the map, rewriting the assert's parser and re-deriving every package's placement.

- **D-04:** Coverage is `3.files-legacy.sh` destinations only. `2.setups.sh` writes nothing capturable — its single link-touching line is `sudo ln -s` for a systemd unit outside `$HOME`. Font installation and installer state are excluded. The exclusion reasoning is recorded in the map header so a future reader does not have to rediscover it.

- **D-05:** The `tree` column is derived from the two outcome columns, never authored. Symlink preserved and repo untouched derives `stow`; symlink destroyed or repo overwritten derives `restow`; a writer that renames over the link — the `switchwall.sh` class, which is not an installer primitive at all — derives `capture`. The assert compares where a file actually sits against the derived value. — **Reversibility:** one-way — this is the property CAP-01 rests on. Allowing an authored override later would mean every reader must consult two sources to answer "how is this file captured", which is exactly the ambiguity the phase exists to remove.

- **D-06:** Paths are stored as literal `$XDG_CONFIG_HOME/...` and expanded at read time. This keeps the map host-independent and makes each row diff cleanly against the source line it came from. There is no `SKIP_*` column: Phase 16 retired the safe profile, so every `SKIP_*` is false on our one install path. The reasoning is recorded in the header.

### Tree layout and migration

- **D-07:** Migration moves only what the map says must move. The derived rule is run against all 18 current stow packages and only real collisions are relocated, keeping the diff small and every move justified by a row.

- **D-08:** A package that straddles two trees is split. `starship.toml` leaves `stow/zsh/` for its own `restow/starship/`; `stow/zsh/` keeps `.zprofile`, `.p10k.zsh` and `.zshrc` and stays in `stow/`. Every package then lives wholly in one tree, which is what makes CAP-01 true. Accepted cost: one more package, and `arch/zsh.sh` gains a second stow invocation.

- **D-09:** The `rsync-replace` / `cp-through` tag is derived from the map's `primitive` column, not stored on disk. `install_dir__sync` and `install_dir__sync_exclude` derive `rsync-replace`; `install_file` and `install_file__auto_backup` derive `cp-through`. `restow/README.md` carries a generated table listing each package with its tag and recovery command, in a region the generator owns. Same single-source-of-truth rule the `tree` column follows.

- **D-10:** The three affected stow call sites are retargeted at `../restow` using the same flags-only idiom Phase 17 established. Recovery stays documented prose in `restow/README.md` — the exact command per tag, copy-pasteable. No `restow-all` script ships, and the wrapper's install path is not changed to re-stow automatically. Accepted cost: the operator must run the recovery command after a dots-hyprland install.

- **D-11:** Each tree gets a `README.md`. `capture/` additionally gets a `.gitkeep` so the empty directory survives a clone. No per-tree `.gitignore` ships this phase: D-14 wanted rules driven by the map, and the map says nothing about generated files yet. D-14 defers once more, to Phase 21.

- **D-12:** Each README has four parts — a one-paragraph contract stating what the installer does to files in that tree; the exact recovery command; the membership rule stated as the map predicate, so a reader can place a new file without reading the map; and, for `restow/` only, the generated package-to-tag-to-recovery table. The contract prose is hand-written and reviewed; only the table is generated.

- **D-13:** A package is matched to a map row by prefix. A package belongs in `restow/` if any file it installs sits at or under a `dest` row whose outcome is destroyed or repo-overwritten. This matches how `rsync --delete` actually behaves — it does not care that our link is one level down inside the directory it is replacing. Exact-path matching was rejected because it would make the map depend on which files happen to exist on the host, destroying the host-independence D-06 establishes.

- **D-14:** `--no-folding` applies uniformly across all three trees. One idiom in every call site, one thing for the assert to check, and a smaller blast radius when a partial failure leaves a tree half-written.

### Unfolding the two folded directories

- **D-15:** Both folded directory symlinks found by Phase 17's D-02 audit — `~/.config/qBittorrent` and `~/.config/smartmontools` — are unfolded in this phase with `stow -D` followed by `stow --no-folding`. Every package then obeys the D-41 default and the assert needs no exception list. Neither package collides with the installer, so both stay in `stow/`.

- **D-16:** The consequence for qBittorrent is accepted deliberately: once unfolded, only the five tracked files stay linked, and runtime output — `rss/` additions, `.lock` files, sockets, GUI-created categories — stops landing inside the repo. This is the correct behavior and it retires the condition that `scripts/phase17-unblock-assert.sh:433-435` exists to police. A genuinely new category or feed now needs an explicit capture, which is what Phase 21 is for.

- **D-17:** The unfold is performed by hand during the phase and the assert checks the end state: both `~/.config` paths are real directories whose contents are links into `stow/`. No one-shot migration script ships.

- **D-18:** qBittorrent must not be running during the unfold. It rewrites `qBittorrent.conf` on exit, and the window between `stow -D` and the re-stow has no link at all — a write landing there creates a real file that the re-stow then refuses to overwrite, aborting mid-operation. This is an explicit plan precondition. `smartmontools` is unaffected, since `arch/scrutiny.sh` copies its files into `/etc` rather than reading the linked path.

- **D-19:** Neither package has a stow call site today — both were stowed by hand, so a fresh machine never links either one. Both are added: a new `arch/qbittorrent.sh`, and a stow line in `arch/scrutiny.sh`, each carrying the literal `--verbose=5 --no-folding` idiom. The call-site count asserted at `scripts/phase17-unblock-assert.sh:91` moves from 15 upward accordingly.

- **D-20:** The `probe.sock` / `probe.socket` / `probe.lock` ignore patterns at `scripts/phase17-unblock-assert.sh:433-435` are left untouched. That script is a closed phase's verification record, and editing it retroactively would make the Phase 17 record describe something Phase 17 did not verify. Phase 18's own assert simply does not carry those patterns.

### Repo-root `.config/` redistribution (FIX-03)

- **D-21:** Six scripts read repo-root `.config/`. Four of them read paths that do not exist at all and are broken today regardless of FIX-03 — `ubuntu/monitor_system.sh`, `ubuntu/xterm.sh`, `ubuntu/zsh.sh`, `arch/system_monitor.sh`, `debian/system_monitor.sh` — and are retargeted at their existing `stow/` equivalents. The two closed-phase asserts, `scripts/phase13-d19-assert.sh` and `scripts/phase14-verify.sh`, read `.config/hypr/custom/*.lua` and `hyprland.conf` as fixtures and are repointed at the new `stow/hypr/` location so they still run green. Editing them is unavoidable here, unlike D-20, because the file they read is being deleted.

- **D-22:** Where the repo copy and the live file differ, live content wins. Three files differ: `dolphinrc`, `kdeglobals` and `hypr/hyprland/scripts/launch_first_available.sh`. The repo copies are stale artifacts of a directory nothing links from, so the live content moves into the new tree location and the redistribution table records "content taken from live, repo copy was stale" for each. The other seven files match their live counterpart byte for byte and move unchanged.

- **D-23:** `hypr/hyprland.conf` has no live counterpart — the installer renamed it to `.old` back in Phase 14 (`3.files-legacy.sh:51-54`) — and `hypr/hyprland.conf.bak` is byte-identical to a backup that already exists live. Both go to `docs/archive/` with a note citing that source line and Phase 14. Neither belongs in a capture tree.

- **D-24:** The redistribution table lives in `18-CONTEXT.md` and in `docs/`, and is not machine-checked. It records a one-time move; after this phase repo-root `.config/` is gone permanently. The assert checks only the outcome: `.config/` absent, every named destination present, and no script referencing the old path.

- **D-25:** `hypr` becomes two packages with the same name in different trees — `stow/hypr/` and `restow/hypr/`. `hypr/custom/` is `install_dir__ignore_existing` and safe; `hypr/hyprland/` is `install_dir__sync` and destroyed. The tree decides the meaning of the name.

- **D-26:** The map is generated and checked in *before* any file moves. `hypridle.conf` and `hyprlock.conf` are `install_file__auto_backup`, which on firstrun does `mv $t $t.old` then `cp -f` — renaming the symlink away, which is a destroyed outcome and puts them in `restow/`, not where intuition would place them. Every package boundary must be a mechanical consequence of the map. This is a hard internal ordering for the plan: map, then move, then re-stow, then verify. D-18's mandated `custom/execs.lua → stow/hypr/` row is safe either way, since `install_dir__ignore_existing` preserves the link.

- **D-27:** `docs/archive/` does not exist yet and is created here as a flat directory holding retired files under their original basename, plus a `README.md` stating that nothing in it is live, nothing reads it, and each entry names why it was retired and the commit that retired it. Future basename collisions are resolved by prefixing.

- **D-28:** The removal is split into separate commits per disposition — moves into `stow/`, moves into `restow/`, moves into `docs/archive/`, script retargeting, then the final removal of the now-empty `.config/`. Each is independently revertible, and git records the unchanged moves as renames. Reverting a bad live-content adoption (D-22) is the likely failure mode, which is why granularity matters here.

- **D-29:** `launch_first_available.sh` stays in `restow/hypr/` tagged `rsync-replace`, despite being one file three directories deep inside a path the installer fully owns and `--delete`s on every run. Path depth is not a reason to break the rule, and the tag communicates precisely the fact that it is destroyed on every install until re-stowed.

### Refusing `--exp-files` (CAP-08) and closing Q15

- **D-30:** Q15 is answered. `vendor/dots-hyprland/sdata/subcmd-install/3.files-exp.sh` was read in full. The experimental path is complete and functional, not a stub. It reads its destinations from `3.files-exp.yaml` rather than from `3.files-legacy.sh`; it uses an entirely different primitive set (`sync` is `rsync -av --delete`, `soft` is `rsync -av`, `hard` is `cp -r`, `hard-backup` is `mv` to `.old.N` then `cp -r`, `soft-backup` is `cp -r` to `.new`, `skip-if-exists` is `cp -r` only when the destination is absent); and it runs an interactive `read -p` preference wizard unless `$ask` is false. Every row of the collision map is void under `--exp-files`, and every one of those primitives destroys or writes through a symlink. Refusal is the correct response.

- **D-31:** The refusal lands in `main()`, before the allowlist dispatch — a single gate scanning `"$@"` so it covers `install`, `install-files`, `uninstall` and any subcommand added later. Placing it in `run_install_family()`'s argument scan would leave `run_uninstall` uncovered and would put the burden on every future handler that forwards flags.

- **D-32:** Only `--exp-files` is refused, exactly as CAP-08 states. `--via-nix`, `--core` and the `--skip-*` family all still route through `3.files-legacy.sh`, so the map stays valid under them. `--fontset` changes what fontconfig installs from and is recorded as a known gap in the map's coverage, not turned into a refusal.

- **D-33:** The refusal exits 2 — a usage error, distinct from the wrapper's existing 1. The message names `3.files-exp.sh` and `3.files-exp.yaml`, states that their write primitives differ from the ones `collision-map.tsv` was derived from, and says that every row in the map would be void. It says nothing about possible future support.

- **D-34:** CAP-08 is asserted end-to-end: the assert invokes `arch/dots-hyprland.sh install --exp-files`, requires a non-zero exit, greps stderr for the map filename, and confirms `./setup` was never reached. Grepping the script for the presence of the guard would prove the text exists, not that it fires.

- **D-35:** Q15's finding is written into `.planning/research/PITFALLS.md` as a new section listing the experimental-path primitives alongside the existing legacy primitive table, marked as deliberately unmodelled. `18-CONTEXT.md` carries the conclusion and the refusal decision; the research document stays the place people look for installer write behavior.

### `capture` semantics (CAP-05, FIX-05)

- **D-36:** The dirty refusal acts per path. Dirty paths are reported and skipped, clean ones are captured, and the command exits non-zero if anything was skipped. An operator capturing ten files does not lose nine good captures to one conflict.

- **D-37:** "Dirty against HEAD" means any difference from HEAD, staged or unstaged — `git diff --quiet HEAD -- <path>`. Untracked paths are refused too, since there is no HEAD version to compare against and overwriting would destroy uncommitted work.

- **D-38:** `capture` walks `capture/*/` packages, derives each live path from the stow layout (`capture/foo/.config/x` maps to `$HOME/.config/x`), and copies live over the repo copy in the working tree. It never runs `git add` and never commits — the operator reviews `git diff` and commits. That is what keeps `git diff --cached` empty, as criterion 7 requires.

- **D-39:** Two guards. The path's repo mirror must live under `capture/`, and the live path must not be a symlink resolving into the repo. A live symlink means the file was stowed, capture would be a copy onto itself, and it is almost certainly operator error — refuse rather than proceed.

- **D-40:** Files present live but with no repo mirror are not captured. `capture` walks the repo side, not the live side; an unmirrored live file is reported as `[INFO]` so the operator can add it deliberately. This keeps capture a bounded refresh and stops lock files, caches and sockets from being committed — the same class of problem D-16 just solved for qBittorrent.

- **D-41:** When `capture/` is empty — the state this phase ships in — the exit code is 0 with an explicit "`capture/` is empty, nothing to capture" message, never silence. An empty `capture/` is documented and expected until Phase 21, so it must not make the repo red, and it must not be indistinguishable from a successful run.

- **D-42:** `capture` honours `--dry-run`, printing what would be copied and copying nothing. It is the only subcommand that writes into the repo, so a preview matters most here, and `--dry-run` is already in the wrapper's vocabulary. The assert covers it: a dry run leaves both the repo and `git status` unchanged.

- **D-43:** A repo mirror whose live counterpart is missing is skipped with a `[FINDING]` and contributes to the non-zero exit, the same treatment as a dirty mirror. The repo copy is never deleted — a vanished live counterpart means the app was uninstalled or the path moved, and both need a human.

- **D-44:** Criterion 7's fixture is built and torn down by the assert in a temporary directory used as `$HOME`: a throwaway `capture/` package plus a fake live file, against which the assert checks that the copy happened, that `git diff --cached` is empty afterwards, and that a dirty mirror is refused. Nothing fixture-shaped is committed, so `capture/` stays legitimately empty.

- **D-45:** That fixture needs no special flag or environment variable — `capture` reads `$HOME` normally and the assert runs it as `HOME=$tmpdir`. This imposes a real implementation constraint worth its own check: `capture` must never hardcode `/home/pera` and must not use `~` in a way that bypasses `$HOME`.

### `verify` scope this phase (FIX-05)

- **D-46:** `verify` performs a real link-ness check, not a stub. For every package file it asserts that the live path is a symlink (`test -L`) and that `readlink -f` equals the repo path, *before* any content comparison. This is `PITFALLS.md:30`'s core constraint: both destroying primitives leave the repo file untouched, so a content-only check reports "no drift" in exactly the case that matters. Phase 19 extends it with content drift and the map cross-check. — **Reversibility:** costly — Phase 19's VER-03 contract builds on whatever shape `verify` has when this phase ends; changing its output contract or check order later means reworking VER-03's assertions too.

- **D-47:** The de-initialised-submodule requirement tests that `verify` does not depend on the vendored tree at all. It checks live symlinks against the repo's own trees, so no vendor file is needed. The mechanism was confirmed during discussion: `preflight` at `arch/dots-hyprland.sh:118` is called inside `run_install_family`, so any subcommand routed through it exits 1 when `vendor/dots-hyprland` has no `.git` — which is exactly the FIX-05 bug, and exactly why criterion 7 demands its own handler.

- **D-48:** `run_verify()` and `run_capture()` are functions in `arch/dots-hyprland.sh`, called from two new branches in `main`'s `case`. This matches the file's existing shape: `run_uninstall` is already a wrapper-owned subcommand that never calls `preflight`.

- **D-49:** Both speak the repo-standard assert vocabulary — `[PASS]`, `[FAIL]`, `[FINDING]`, `[INFO]` per path, plus the closing `=== done: FAIL=n ===` line, exiting non-zero when `n > 0`. One vocabulary across the repo; Phase 19 locks it further.

- **D-50:** `verify` checks `capture/` too, with the expectation inverted. For a `capture/` path it is a `[FAIL]` if the live path *is* a symlink into the repo, because that means the file was wrongly stowed and the installer's rename will destroy it. Content drift between live and repo is a `[FINDING]`, not a `[FAIL]` — drift is the normal state there until someone runs `capture`.

- **D-51:** The packages this phase moves are re-stowed as part of the migration, so `verify` ends green. Plan sequence: generate the map, move the files, `stow -D` from the old tree, `stow --no-folding` from the new one, then `verify`.

- **D-52:** `restow/starship/` is created, tagged `cp-through`, with its content as-is. Verified during discussion: `stow/zsh/.config/starship.toml` is byte-identical to `vendor/dots-hyprland/dots/.config/starship.toml`, so the repo has carried upstream's content since commit `2539238` accepted the overwrite. The mechanism is what this phase ships; whether the content is ours or upstream's is a separate preference question. The README note must say so, or a reader will find the package puzzling.

- **D-53:** `verify` takes no arguments and always walks all three trees. A partial verify that exits 0 reads identically to a full green run in scrollback, which is how false confidence starts.

- **D-54:** A repo file in `stow/` or `restow/` with no live counterpart is a `[FAIL]`, with a message naming the stow command that would fix it. The repo says the file should be linked and it is not — that is the silent drift `verify` exists to catch. Recorded assumption: this is a single-machine repo, so every package is expected to be installed. No per-package opt-out mechanism ships, since a fourth category of package metadata would contradict the thesis that location alone determines everything.

### Assert and pin-bump simulation (CAP-03)

- **D-55:** The pin bump is simulated without touching the real submodule. The generator takes a source-root argument defaulting to `vendor/dots-hyprland`; the assert builds a minimal fake dots-hyprland tree in a temporary directory with one primitive changed — `install_dir__ignore_existing` to `install_dir__sync` — runs the generator against it, and requires the resulting map to differ from the checked-in one. This proves the generator reacts to upstream, not merely that a diff can be produced.

- **D-56:** The mis-filed fixture is built and torn down by the assert and never committed: a distinctly-named throwaway package placed in the tree the map says it does not belong in, the placement check run, a non-zero exit required, then removal. Cleanup must survive a failing check, so it needs a `trap`. A permanently committed mis-filed fixture was rejected because it would need an exclusion list to stop `verify` flagging it — the exception mechanism this phase avoids everywhere else.

- **D-57:** One assert script ships: `scripts/phase18-capture-model-assert.sh`, matching the repo's existing `phaseNN` naming, with a section per ROADMAP criterion so that one command gives one verdict for the phase.

- **D-58:** The generator is written in bash, matching every other script in the repo. It parses `3.files-legacy.sh`'s primitive calls, expands the `find` loop, and emits TSV. Parsing shell with shell is fragile; the mitigation is D-03's rule that an unrecognised primitive fails loudly rather than defaulting.

- **D-59:** The generator is `scripts/gen-collision-map.sh`. It takes an optional source root and emits the complete TSV, header included, to stdout. It never writes in place, so it can never leave a half-written map. Real regeneration is `scripts/gen-collision-map.sh > collision-map.tsv`, and both the assert's failure message and `restow/README.md` spell that out.

- **D-60:** The pin SHA in the header comes from `git -C vendor/dots-hyprland rev-parse HEAD` at generation time. The assert's regenerate-and-diff catches a stale SHA automatically, because the header is part of the diff. A pin bump therefore dirties the map even when no row moves — that is the intended signal that the map needs re-review, not an annoyance to engineer around.

- **D-61:** `verify` and `capture` are added to `ALLOWLIST` in `arch/dots-hyprland.sh:17`. The existing dispatch guard at lines 827-833 — deliberately written as an `if` block rather than the conjunction one-liner, per Phase 17's D-09 — is the hook that makes the whole thing testable, and is not changed. — **Reversibility:** one-way — once `verify` and `capture` are allowlisted subcommands of the wrapper, removing them breaks whatever documentation, muscle memory and later phases (19, 21) come to depend on them.

### Claude's Discretion

None. Every gray area presented was resolved by an explicit choice.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/ROADMAP.md` — Phase 18 goal, dependency on Phase 17, the seven success criteria, and the note that `capture/` is legitimately empty at the end of this phase
- `.planning/REQUIREMENTS.md` — CAP-01 (line 24), CAP-02 (25), CAP-03 (26), CAP-05 (28), CAP-07 (30), CAP-08 (31), FIX-03 (17), FIX-05 (19); mapping notes at lines 159-161 explain why FIX-03 and CAP-05 land here. CAP-04 (27) is already complete from Phase 17; CAP-06 (29) belongs to Phase 21
- `.planning/PROJECT.md` — the v0.4 "Personal config layer" milestone and decision D-41, which corrects the original capture model: stow symlinks with `--no-folding` are the default, the "atomic rewrite" exception is disproven, and capture is organised by installer collision class and write primitive rather than by atomicity

### Research feeding the map
- `.planning/research/PITFALLS.md` §line 30 — the single most important design constraint: both destroying primitives leave the repo file untouched, so a content-only `verify` reports "no drift" in exactly the case that matters. The drift check must assert link-ness first
- `.planning/research/PITFALLS.md` §lines 285-290 — the primitive-to-outcome table the map's static lookup is derived from
- `.planning/research/PITFALLS.md` §line 208 — `~/.config/hypr/hyprland/colors.lua` is matugen-generated and rewritten on every wallpaper change; relevant to Phase 21's `capture/` inhabitants, not to this phase

### Prior phase context
- `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-CONTEXT.md` — 23 decisions. D-02 hands the folded-directory audit to this phase; D-09 documents why the dispatch guard is an `if` block, which is the hook criterion 7 needs; D-14 defers per-tree `.gitignore` rules here; D-18 mandates that `.config/hypr/custom/execs.lua` appear as a row in the FIX-03 redistribution table, moving into `stow/hypr/`

### The vendored installer (pin `1a9ffb78f0c272a45f82342587dc3bec72762233`)
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — 79 lines; the map's sole source. The `find`-driven MISC loop is at line 11; `install_dir__sync` for quickshell at 26, for fish at 33, for `hypr/hyprland` at 50; the `hyprland.conf` rename at 51-54; `install_file__auto_backup` for hyprlock.conf at 56; `install_dir__ignore_existing` for `hypr/custom` at 75
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` — primitive definitions at lines 93, 102, 121, 130, 150 and 161; `cp -f` at line 49; the router that chooses between the legacy and experimental paths at line 222
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — `--exp-files` documented at line 33, present in the forwardable long-option list at line 50, and setting `EXPERIMENTAL_FILES_SCRIPT=true` at line 91
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-exp.sh` — 278 lines, read in full during this discussion; the reason `--exp-files` is refused
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-exp.yaml` — the destination source for the experimental path; modes `sync`, `soft`, `hard`, `soft-backup`, `hard-backup`, `skip`, `skip-if-exists`

### The wrapper and existing asserts
- `arch/dots-hyprland.sh` — `ALLOWLIST` at line 17, `is_allowlisted` at 111, `preflight` at 118, `safe_rm_path` at 428-450, `touches_files` at ~715, `run_install_family` at 723, `main` at 790, the dispatch guard at 827-833
- `scripts/phase17-unblock-assert.sh` — the assert contract this phase's script follows; line 91 asserts the count of `arch/` stow call sites carrying `--verbose=5 --no-folding`; lines 433-435 hold the qBittorrent probe patterns that D-20 leaves in place
- `scripts/phase13-d19-assert.sh` and `scripts/phase14-verify.sh` — both read repo-root `.config/` as a fixture and are repointed by D-21

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **The assert contract.** `scripts/phase17-unblock-assert.sh` establishes the repo-wide `[PASS]` / `[FAIL]` / `[FINDING]` / `[INFO]` vocabulary plus the closing `=== done: FAIL=n ===` line. Both the new assert and the new `verify` subcommand adopt it verbatim.
- **The stow call-site idiom.** All 15 existing call sites are the single line `cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ <package>`. The three retargeted sites and the two new ones (`arch/qbittorrent.sh`, `arch/scrutiny.sh`) reuse it exactly, substituting `../restow` where the tree changes.
- **`run_uninstall` as a template.** It is already a wrapper-owned subcommand with its own `main` branch that does not call `preflight` — the precise shape `run_verify` and `run_capture` need.
- **`jq` and `yq`.** Both are present at `/usr/bin/` and already used across `arch/dots-hyprland.sh`, `scripts/phase14-verify.sh`, `scripts/nvim-validate.sh`, `arch/tools.sh`, `scripts/clone_repo.sh` and `scripts/nvim-audit-failures.sh`. Neither is required by D-58's bash generator, but `yq` is what makes `3.files-exp.yaml` readable if a future phase revisits D-30.
- **`.planning/research/PITFALLS.md:285-290`.** The primitive-to-outcome table already exists. The collision map is a derivation of completed research, not a new investigation — which is why the ROADMAP rates this phase's research as Light.

### Established Patterns

- **`--no-folding` everywhere (D-41).** Already the idiom in all 15 call sites; this phase closes the two exceptions rather than introducing the rule.
- **Flags-only stow invocations.** No call site passes a target other than `~`, and none uses `--adopt`. Confirmed during the codebase scout: `--adopt` appears nowhere under `arch/`, `scripts/`, `ubuntu/`, `debian/` or `docs/`, so CAP-07 is a documentation-plus-assert job, not a removal job.
- **Phase-scoped assert scripts.** `phase13-d19-assert.sh`, `phase14-verify.sh`, `phase17-unblock-assert.sh` — one per phase, named by phase, each a closed record once its phase ships. D-20 and D-21 both turn on respecting that.
- **Wrapper-owned meta flags.** `run_install_family` strips `--dry-run`, `--keep-backup` and `--full` before forwarding; everything else goes to `./setup` verbatim. That verbatim forwarding is exactly how `--exp-files` reaches upstream today, and D-31 gates it before dispatch rather than inside that scan.

### Integration Points

- **`main`'s `case` statement** (`arch/dots-hyprland.sh:813-822`) gains two branches, and `ALLOWLIST` (line 17) gains two entries.
- **`main`'s prologue** gains the `--exp-files` gate, placed after the help handling and before the allowlist check.
- **The three retargeted stow call sites** — `arch/kitty.sh:10`, `arch/fish.sh:26`, and a new one for starship — plus two additions in `arch/qbittorrent.sh` and `arch/scrutiny.sh`.
- **`scripts/phase17-unblock-assert.sh:91`** asserts a hard-coded count of `arch/` stow call sites; adding call sites changes that count, so the Phase 17 assert must still pass afterwards.
- **`scripts/phase13-d19-assert.sh:44-46,205-227`** and **`scripts/phase14-verify.sh:210-216,288,357,489`** hold the repo-root `.config/` fixture paths that D-21 repoints.

</code_context>

<specifics>
## Specific Ideas

**The redistribution table (FIX-03).** Twelve files leave repo-root `.config/`. Seven match their live counterpart byte for byte; three differ and take live content per D-22; two are archived per D-23. Final tree placement for the `hypr/` rows is pending the map, per D-26 — the table below records the disposition decided in discussion, and the plan must reconcile the `stow/hypr/` rows against the generated map before executing the moves.

| Source path | Disposition | Destination | Note |
|---|---|---|---|
| `.config/dolphinrc` | move, live content wins | `restow/` (MISC loop, `install_file` → cp-through) | repo copy was stale |
| `.config/kdeglobals` | move, live content wins | `restow/` (MISC loop, `install_file` → cp-through) | repo copy was stale |
| `.config/hypr/custom/env.lua` | move as-is | `stow/hypr/` | `install_dir__ignore_existing`, link preserved |
| `.config/hypr/custom/execs.lua` | move as-is | `stow/hypr/` | **mandated by Phase 17 D-18 — this row must not go missing** |
| `.config/hypr/custom/general.lua` | move as-is | `stow/hypr/` | `install_dir__ignore_existing`, link preserved |
| `.config/hypr/hypridle.conf` | move as-is | per map (`install_file__auto_backup` → likely `restow/`) | resolve against the generated map per D-26 |
| `.config/hypr/hyprlock.conf` | move as-is | per map (`install_file__auto_backup` → likely `restow/`) | resolve against the generated map per D-26 |
| `.config/hypr/hyprland-gui.conf` | move as-is | per map | not a legacy-script destination; confirm during generation |
| `.config/hypr/hyprpaper.conf` | move as-is | per map | not a legacy-script destination; confirm during generation |
| `.config/hypr/hyprland/scripts/launch_first_available.sh` | move, live content wins | `restow/hypr/` tagged `rsync-replace` | D-29; destroyed on every install until re-stowed |
| `.config/hypr/hyprland.conf` | archive | `docs/archive/` | no live counterpart; installer renamed it to `.old` in Phase 14 |
| `.config/hypr/hyprland.conf.bak` | archive | `docs/archive/` | byte-identical to a backup that already exists live |

**The collision set against today's packages.** Computed during discussion against the 18 current `stow/` packages:

| Package | Colliding path | Primitive | Outcome | Derived tree |
|---|---|---|---|---|
| `kitty` | `$XDG_CONFIG_HOME/kitty` | `install_dir__sync` | link destroyed | `restow/`, `rsync-replace` |
| `fish` | `$XDG_CONFIG_HOME/fish` | `install_dir__sync_exclude conf.d` | link destroyed | `restow/`, `rsync-replace` |
| `zsh` (`starship.toml` only) | `$XDG_CONFIG_HOME/starship.toml` | `install_file` → `cp -f` | link kept, repo overwritten | `restow/starship/`, `cp-through` |

The `starship.toml` loss is not hypothetical — it already happened at commit `2539238`, "accept upstream's starship.toml overwrite as a known loss (D-17)", and the repo has carried upstream's bytes ever since (D-52).

**The MISC loop at the current pin** expands to 17 entries, which the generator must reproduce: `chrome-flags.conf` (file), `code-flags.conf` (file), `darklyrc` (file), `dolphinrc` (file), `foot` (dir), `fuzzel` (dir), `kdeglobals` (file), `kde-material-you-colors` (dir), `kitty` (dir), `konsolerc` (file), `Kvantum` (dir), `matugen` (dir), `mpv` (dir), `starship.toml` (file), `thorium-flags.conf` (file), `wlogout` (dir), `xdg-desktop-portal` (dir), `zshrc.d` (dir).

**The folded-directory audit (Phase 17 D-02).** `find ~/.config -maxdepth 2 -type l -lname '*.dotfiles*'` returned 24 entries, of which exactly two are folded directories — `~/.config/qBittorrent` and `~/.config/smartmontools` (D-15). The other 22 are individual file links and need no action.

**CAP-07 is already satisfied structurally.** `--adopt` appears in no script under `arch/` or `scripts/`. What this phase adds is the documented ban with its stated exception — interactive use only, on a clean tree, one path at a time — plus an assert that the string stays absent.

</specifics>

<deferred>
## Deferred Ideas

- **Wire `restow/` recovery into the wrapper's install path** so no manual re-stow step is needed after a dots-hyprland install. Deferred: no CAP or FIX requirement asks for it, it changes install behavior on a working daily driver, and it belongs with the Phase 19 verify contract or later.
- **Per-tree `.gitignore` rules (Phase 17 D-14).** Deferred to Phase 21: the map says nothing about generated files yet, and `capture/` is empty until its first inhabitant arrives.
- **Treat qBittorrent as a `capture/` candidate** so GUI-created categories and RSS feeds can be pulled back deliberately. Deferred to Phase 21, which owns `capture/` inhabitants. Unfolding (D-16) is what makes the need visible.
- **Re-evaluate the `--exp-files` refusal** once upstream implements `symlink: true` and `--exp-file-reset-symlink` in `3.files-exp.sh`. Both are unimplemented TODO comments at pin `1a9ffb78`; if they land, the experimental path becomes *better* for a symlink-based dotfiles repo than the legacy path, and the refusal should be re-examined rather than treated as permanent.
- **Restore a custom `starship.toml`** from before commit `2539238`. Deferred: changing the running prompt configuration is a preference decision, not a taxonomy one. D-52 creates the correct slot for it.

</deferred>

---

*Phase: 18-capture-model-three-trees-and-the-collision-map*
*Context gathered: 2026-09-13*
