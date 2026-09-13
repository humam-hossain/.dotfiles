# Phase 18: Capture model — three trees and the collision map - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-13
**Phase:** 18-capture-model-three-trees-and-the-collision-map
**Areas discussed:** Collision map format, Tree layout + migration, Unfolding qBittorrent + smartmontools, Repo-root .config/ redistribution, --exp-files refusal + Q15, capture semantics, verify scope this phase, Assert + pin-bump simulation

---

## Collision map format

### Format and location

| Option | Selected |
|--------|----------|
| TSV at repo root | ✓ |
| JSON at repo root |  |
| YAML at repo root |  |
| You decide |  |

**User's choice:** TSV at repo root, comment header carrying pin SHA

### How to represent the find-driven loop at 3.files-legacy.sh:11

| Option | Selected |
|--------|----------|
| Expand to concrete rows | ✓ |
| One glob row |  |
| Both |  |

**User's choice:** Expand to concrete rows (~28 total at the pin)

### How rows are produced and what the assert compares

| Option | Selected |
|--------|----------|
| Generator + static outcome table | ✓ |
| Fully hand-authored |  |
| Hand-authored + SHA staleness gate |  |

**User's choice:** Generator walks vendor tree for dest/primitive/source; static hand-authored primitive->outcome lookup from PITFALLS.md:285-290; assert regenerates and diffs against checked-in map

### Coverage boundary

| Option | Selected |
|--------|----------|
| legacy only | ✓ |
| every install destination |  |
| legacy + documented exclusion list |  |

**User's choice:** 3.files-legacy.sh destinations only; exclusion reasoning recorded in map header

### What the tree column is

| Option | Selected |
|--------|----------|
| Derived from outcome | ✓ |
| Authored per row |  |
| Derived with override column |  |

**User's choice:** Derived from the two outcome columns, never authored

### Path spelling and SKIP_* column

| Option | Selected |
|--------|----------|
| Literal + no SKIP | ✓ |
| Expanded ~/ + no SKIP |  |
| Literal + SKIP column |  |

**User's choice:** Literal $XDG_CONFIG_HOME, expanded at read time; no SKIP_* column, reasoning in header

---

## Tree layout + migration

### Migration direction

| Option | Selected |
|--------|----------|
| Move only what the map says must move | ✓ |
| Move everything to restow/ by default |  |
| Audit-first, migrate in Phase 19 |  |

**User's choice:** Move only what the map says must move — run the derived rule against all 18 packages, relocate real collisions only

### Package granularity when a package straddles trees

| Option | Selected |
|--------|----------|
| Split the package | ✓ |
| Keep whole, file in the riskier tree |  |
| Keep whole, per-file exception list |  |

**User's choice:** Split the package — starship.toml leaves stow/zsh/ for its own restow/starship/; stow/zsh/ keeps .zprofile, .p10k.zsh, .zshrc

### Where the rsync-replace / cp-through tag lives

| Option | Selected |
|--------|----------|
| Derived from the map, rendered in README | ✓ |
| Per-package tag file |  |
| Tag encoded in the package directory name |  |

**User's choice:** Derived from the map's primitive column, rendered in restow/README.md as a generated table; no tag file on disk

### Stow call sites and where recovery lives

| Option | Selected |
|--------|----------|
| Retarget call sites; recovery documented only | ✓ |
| Retarget + a restow-all script |  |
| Retarget + wire recovery into the wrapper |  |

**User's choice:** Retarget arch/kitty.sh, arch/fish.sh and the new starship call site at ../restow; recovery documented in restow/README.md only, no new script and no wrapper change

### Tree-root files beyond packages

| Option | Selected |
|--------|----------|
| README per tree + .gitkeep in capture/ only | ✓ |
| README + .gitkeep + per-tree .gitignore now |  |
| README per tree, no .gitkeep, no .gitignore |  |

**User's choice:** README.md per tree plus .gitkeep in capture/ only; no per-tree .gitignore this phase, D-14 defers to Phase 21 when the first generated file arrives

### README contents

| Option | Selected |
|--------|----------|
| Contract, recovery, membership rule, generated table | ✓ |
| Contract + recovery only |  |
| Fully generated READMEs |  |

**User's choice:** Four parts: contract paragraph, copy-pasteable recovery command, membership rule stated as the map predicate, and for restow/ a generated package->tag->recovery table in a generator-owned marked region

### How the derived rule matches a package to a map row

| Option | Selected |
|--------|----------|
| Prefix match | ✓ |
| Exact-path match only |  |
| Prefix match, but split packages on the boundary |  |

**User's choice:** Prefix match — a package belongs to restow/ if any file it installs sits at or under a dest row whose outcome is DESTROYED or repo-overwritten

### Does restow/ keep --no-folding

| Option | Selected |
|--------|----------|
| Yes, --no-folding everywhere | ✓ |
| Folding allowed in restow/ |  |

**User's choice:** Yes — --no-folding uniformly across all three trees, one idiom in every call site, smaller blast radius on partial failure

---

## Unfolding qBittorrent + smartmontools

### Unfold now or defer

| Option | Selected |
|--------|----------|
| Unfold now, as part of this phase | ✓ |
| Record and defer to Phase 19 |  |
| Unfold now, and make it an assert |  |

**User's choice:** Unfold both now as part of this phase — stow -D then stow --no-folding — so every package obeys the D-41 default and the assert needs no exception list

### Consequence for qBittorrent runtime files

| Option | Selected |
|--------|----------|
| Accept it — unfolding is the point | ✓ |
| Accept it, and note the follow-up |  |
| Leave qBittorrent folded, unfold smartmontools only |  |

**User's choice:** Accepted — only the 5 tracked files stay linked; rss/.lock, sockets and GUI-created categories stop leaking into the repo. Explicit capture is Phase 21's job

### Who performs the unfold

| Option | Selected |
|--------|----------|
| Executed by hand during the phase, asserted afterwards | ✓ |
| A one-shot migration script under scripts/ |  |
| Fold-detection in the assert only |  |

**User's choice:** Executed by hand during the phase; the assert checks the end state (both ~/.config dirs are real directories whose contents are links into stow/). No migration script ships

### Sequencing around the running app

| Option | Selected |
|--------|----------|
| Quit the app first, unfold, restart | ✓ |
| Unfold live, accept the race |  |

**User's choice:** Quit qBittorrent first, unfold, restart — recorded as an explicit plan precondition, because the window between stow -D and re-stow has no link and a write there breaks the re-stow. smartmontools is unaffected (arch/scrutiny.sh copies to /etc)

### Neither package has a stow call site

| Option | Selected |
|--------|----------|
| Add both call sites now | ✓ |
| Add the call sites, record as a finding only |  |
| Add only the scrutiny.sh line |  |

**User's choice:** Add both now — new arch/qbittorrent.sh plus a stow line in arch/scrutiny.sh, both with the literal --verbose=5 --no-folding idiom; the asserted call-site count moves from 15 toward 17+

### probe.sock/socket/lock ignore patterns in phase17-unblock-assert.sh:433-435

| Option | Selected |
|--------|----------|
| Leave them | ✓ |
| Retire them in this phase |  |
| Leave them, add a comment |  |

**User's choice:** Leave them untouched — that script is a closed phase's verification record. Phase 18's own assert simply does not carry the patterns

---

## Repo-root .config/ redistribution

### Six scripts read repo-root .config/ — what happens to them

| Option | Selected |
|--------|----------|
| Retarget the dead refs, repoint the closed asserts | ✓ |
| Retarget dead refs; let the closed asserts go red |  |
| Retarget everything, and add a grep assert |  |

**User's choice:** Retarget the 4 dead references (ubuntu/monitor_system.sh, ubuntu/xterm.sh, ubuntu/zsh.sh, arch/system_monitor.sh, debian/system_monitor.sh) at their existing stow/ equivalents — they are broken today regardless — and repoint the 2 closed-phase asserts (scripts/phase13-d19-assert.sh, scripts/phase14-verify.sh) at the new stow/hypr/ fixture path so they still run green. Editing them is unavoidable here because the file they read is being deleted

### Which content wins for the 3 files that differ from live

| Option | Selected |
|--------|----------|
| Live wins | ✓ |
| Repo wins |  |
| Live wins, but diff each first |  |

**User's choice:** Live wins — dolphinrc, kdeglobals and hypr/hyprland/scripts/launch_first_available.sh take their live content into the new tree location, because the repo copies are stale artifacts of a directory nothing links from. Each row records 'content taken from live, repo copy was stale'

### hyprland.conf (no live counterpart) and hyprland.conf.bak (identical to a live backup)

| Option | Selected |
|--------|----------|
| Both to docs/archive/ | ✓ |
| hyprland.conf to archive, delete the .bak |  |
| Both deleted as superseded |  |

**User's choice:** Both to docs/archive/ with a note citing 3.files-legacy.sh:51-54 and Phase 14 — neither belongs in a capture tree

### Where the redistribution table lives

| Option | Selected |
|--------|----------|
| In 18-CONTEXT.md and docs/, not machine-checked | ✓ |
| A second TSV the assert walks |  |
| Rows folded into collision-map.tsv |  |

**User's choice:** In 18-CONTEXT.md and docs/, not machine-checked — it records a one-time move. The assert checks only the outcome: .config/ absent, every destination present, no script references the old path

### Package naming when hypr straddles two trees

| Option | Selected |
|--------|----------|
| Two packages: stow/hypr/ and restow/hypr-hyprland/ | ✓ |
| Two packages, named hypr in both trees |  |
| Re-check each file's primitive before splitting |  |

**User's choice:** Two packages both named hypr — stow/hypr/ and restow/hypr/. The tree decides the meaning

### install_file__auto_backup outcome and phase sequencing

| Option | Selected |
|--------|----------|
| Map first, then fix package boundaries | ✓ |
| Treat install_file__auto_backup as cp-through |  |
| Give the primitive two rows per firstrun state |  |

**User's choice:** Map first, then package boundaries — the generator runs and collision-map.tsv is checked in before any file moves, so hypridle.conf and hyprlock.conf land where the map says (install_file__auto_backup renames the symlink away on firstrun, which is a DESTROYED outcome), not where intuition says. Hard internal ordering for the plan. D-18's execs.lua to stow/hypr/ is safe either way

### docs/archive/ convention (it does not exist yet)

| Option | Selected |
|--------|----------|
| Flat dir + one README |  |
| Mirror the original path under docs/archive/ | ✓ |
| Flat dir, files renamed with a phase prefix |  |

**User's choice:** Flat directory holding retired files under their original basename, plus README.md stating nothing here is live, nothing reads it, and each entry names why it was retired and the retiring commit. Future basename collisions resolve by prefixing

### Commit granularity for the removal

| Option | Selected |
|--------|----------|
| Separate commits per disposition | ✓ |
| One commit for the whole redistribution |  |
| Let the planner decide |  |

**User's choice:** Separate commits per disposition — moves into stow/, into restow/, into docs/archive/, script retargeting, then the final removal of the empty .config/. Each independently revertible; git records unchanged moves as renames

### launch_first_available.sh sitting inside an installer-owned --delete directory

| Option | Selected |
|--------|----------|
| Keep it in restow/hypr/, tagged rsync-replace | ✓ |
| Check whether the script is still ours to own |  |
| Move it out of the installer-owned directory |  |

**User's choice:** Keep it in restow/hypr/ tagged rsync-replace; path depth is not a reason to break the rule. It is destroyed on every install until re-stowed, which is exactly what the tag communicates

---

## --exp-files refusal + Q15

### Q15 — is 3.files-exp.sh reachable and does it void the map

**User's choice:** Answered by reading all 278 lines. The exp path is complete and functional. It reads destinations from 3.files-exp.yaml rather than 3.files-legacy.sh, uses different primitives (mode sync = rsync -av --delete, soft = rsync -av, hard = cp -r, hard-backup = mv to .old.N then cp -r, soft-backup = cp -r to .new, skip-if-exists = cp -r only when absent), and runs an interactive read -p wizard unless $ask is false. Every row of the collision map is void under --exp-files. Refusal is the correct response

### Where the refusal lands

| Option | Selected |
|--------|----------|
| In main(), before the allowlist dispatch | ✓ |
| In run_install_family()'s arg scan |  |
| Both |  |

**User's choice:** In main(), before the allowlist dispatch — one gate scanning "$@" so it covers install, install-files, uninstall and any future subcommand

### Which flags join the refusal

| Option | Selected |
|--------|----------|
| --exp-files only | ✓ |
| --exp-files plus the undocumented --exp-files-* TODOs |  |
| --exp-files plus --via-nix and --core |  |

**User's choice:** --exp-files only, exactly as CAP-08 states. --via-nix, --core and the --skip-* family all still run 3.files-legacy.sh so the map stays valid under them. --fontset changes what fontconfig installs from and is recorded as a known map gap, not a refusal

### Exit code and message

| Option | Selected |
|--------|----------|
| Exit 2, message names the map file and what breaks |  |
| Exit 1, short message | ✓ |
| Exit 2, message plus a pointer to docs |  |

**User's choice:** Exit 2 (usage error, distinct from 1). Message names 3.files-exp.sh and 3.files-exp.yaml, states that the write primitives differ from those collision-map.tsv was derived from, and that every row in the map would be void

### How CAP-08 is asserted

| Option | Selected |
|--------|----------|
| Invoke the wrapper and check exit code + message |  |
| Grep the script for the guard | ✓ |
| Both |  |

**User's choice:** The assert actually invokes arch/dots-hyprland.sh install --exp-files, requires non-zero exit, greps stderr for the map filename, and confirms ./setup was never reached

### Where Q15's finding is recorded

| Option | Selected |
|--------|----------|
| PITFALLS.md gets a new section; CONTEXT.md summarises | ✓ |
| 18-CONTEXT.md only |  |
| A dedicated docs/ page on the exp path |  |

**User's choice:** PITFALLS.md gains a new section listing the exp-path primitives beside the existing legacy primitive table, marked deliberately unmodelled. 18-CONTEXT.md carries the one-line conclusion and the refusal decision

### Upstream's planned symlink support in the exp path

| Option | Selected |
|--------|----------|
| Note it as a deferred idea; refuse today regardless | ✓ |
| Say nothing; refuse and move on |  |
| Write the re-evaluation trigger into the refusal message |  |

**User's choice:** Recorded as a deferred idea — the exp path is where upstream intends first-class symlink support (symlink: true using ln, plus --exp-file-reset-symlink), so a future milestone should re-evaluate. Today those are unimplemented TODO comments, so the refusal stands and the message says nothing about future support

---

## capture semantics

### Granularity of the dirty refusal

| Option | Selected |
|--------|----------|
| Per-path skip, non-zero exit at the end | ✓ |
| Abort the whole run on the first dirty path |  |
| Per-path skip, exit 0 unless every path was skipped |  |

**User's choice:** Per-path skip — dirty paths are reported and skipped, clean ones are captured, and the command exits non-zero if anything was skipped

### What 'dirty against HEAD' means

| Option | Selected |
|--------|----------|
| Any difference from HEAD: staged or unstaged | ✓ |
| Unstaged changes only |  |
| Any difference plus refuse if the index has any staged change |  |

**User's choice:** Any difference from HEAD, staged or unstaged (git diff --quiet HEAD -- <path>). Untracked paths are also refused, since there is no HEAD version and overwriting would destroy uncommitted work

### What capture does and where its path list comes from

| Option | Selected |
|--------|----------|
| Copy live to repo in the working tree; path list derived from capture/ | ✓ |
| Take explicit paths as arguments |  |
| Walk capture/, with optional path arguments to narrow |  |

**User's choice:** Walks capture/*/ packages, derives each live path from the stow layout (capture/foo/.config/x maps to $HOME/.config/x), and copies live over the repo copy in the working tree. Never runs git add, never commits — the operator reviews git diff and commits, which keeps git diff --cached empty as criterion 7 requires

### Direction and membership guards

| Option | Selected |
|--------|----------|
| Refuse any path outside capture/, and refuse if live is a symlink | ✓ |
| Membership guard only |  |
| Link-ness guard only |  |

**User's choice:** Two guards: the path's repo mirror must live under capture/, and the live path must not be a symlink resolving into the repo (capture would then be a copy onto itself and is almost certainly operator error). Refuse rather than copy

### Fixture design, since capture/ ships empty

| Option | Selected |
|--------|----------|
| Assert creates it in a temp HOME, tears it down |  |
| A committed fixture package under capture/ | ✓ |
| A fixture under a separate tests/ directory |  |

**User's choice:** The assert builds a throwaway capture/ package and a fake live file under a temp directory used as $HOME, runs capture, checks the copy happened, that git diff --cached is empty, and that a dirty mirror is refused — then tears it all down. Nothing fixture-shaped is committed, so capture/ stays legitimately empty

### How the fixture overrides HOME

| Option | Selected |
|--------|----------|
| capture reads $HOME normally; the assert sets HOME | ✓ |
| An explicit --target flag mirroring stow -t |  |
| An env var like DOTFILES_CAPTURE_ROOT |  |

**User's choice:** No special flag or variable — capture reads $HOME normally and the assert runs it as HOME=$tmpdir. This imposes a real implementation constraint: capture must never hardcode /home/pera and must not use ~ in a way that ignores $HOME. Worth its own assert

### Files present live but with no repo mirror

| Option | Selected |
|--------|----------|
| No — capture only refreshes files the repo already tracks | ✓ |
| Yes — mirror the live tree into the repo |  |
| No by default, yes behind a flag |  |

**User's choice:** Not captured. capture walks the repo side, not the live side; an unmirrored live file is reported as [INFO] so the operator can add it deliberately. Keeps capture a bounded refresh and stops lock files, caches and sockets from being committed

### Exit code when capture/ is empty

| Option | Selected |
|--------|----------|
| Exit 0 with an explicit message | ✓ |
| Exit non-zero |  |
| Exit 0 silently |  |

**User's choice:** Exit 0 with an explicit 'capture/ is empty, nothing to capture' message — never silent. An empty capture/ is the documented shipping state until Phase 21, so it must not make the repo red

### Does capture honour --dry-run

| Option | Selected |
|--------|----------|
| Yes | ✓ |
| No — the diff is already the preview |  |

**User's choice:** Yes — prints what would be copied and copies nothing. capture is the only subcommand that writes into the repo, so a preview matters most here, and --dry-run is already in the wrapper's vocabulary. Asserted: dry-run leaves both the repo and git status unchanged

### Repo mirror exists but the live file is missing

| Option | Selected |
|--------|----------|
| Skip with a [FINDING], contribute to non-zero exit | ✓ |
| Skip silently, exit 0 |  |
| Delete the repo mirror to match live |  |

**User's choice:** Skip with a [FINDING] and contribute to the non-zero exit, same as a dirty mirror. Never delete the repo copy — a vanished live counterpart means the app was uninstalled or the path moved, and both need a human

---

## verify scope this phase

### How much verify does in this phase

| Option | Selected |
|--------|----------|
| A real link-ness check over stow/ and restow/ |  |
| A minimal stub that exits 0 |  |
| Link-ness check plus the map cross-check | ✓ |

**User's choice:** A real link-ness check, not a stub: for every package file, assert the live path is a symlink (test -L) and that readlink -f equals the repo path, BEFORE any content comparison — PITFALLS.md:30's core constraint. Phase 19 extends it with content drift and the map cross-check

### What the de-initialised-submodule requirement is testing

| Option | Selected |
|--------|----------|
| verify must not depend on the vendor tree at all | ✓ |
| verify degrades gracefully |  |
| verify reads collision-map.tsv instead |  |

**User's choice:** That verify does not depend on the vendor tree at all. It checks live symlinks against the repo's own trees, so no vendor file is needed. Confirmed mechanism: preflight (arch/dots-hyprland.sh:118) is called inside run_install_family, so any subcommand routed through it exits 1 when vendor/dots-hyprland has no .git — which is exactly the FIX-05 bug

### Where verify and capture logic lives

| Option | Selected |
|--------|----------|
| Functions in arch/dots-hyprland.sh, called from main | ✓ |
| Separate scripts under scripts/ |  |
| A shared library file |  |

**User's choice:** run_verify() and run_capture() as functions in arch/dots-hyprland.sh, called from two new branches in main's case — matching the existing shape, where run_uninstall is already a wrapper-owned subcommand that never calls preflight

### Output vocabulary

| Option | Selected |
|--------|----------|
| Repo-standard contract plus closing done line | ✓ |
| Quiet on success, loud on failure |  |
| Assert contract plus a leading summary |  |

**User's choice:** Repo-standard [PASS]/[FAIL]/[FINDING]/[INFO] per path plus the closing === done: FAIL=n === line, exiting non-zero when n>0. Same contract as every assert script in the repo

### How verify treats capture/

| Option | Selected |
|--------|----------|
| verify checks capture/ with the inverted expectation | ✓ |
| verify skips capture/ this phase |  |
| verify checks capture/ for content drift only |  |

**User's choice:** Checks it too, with the inverted expectation: [FAIL] if a live capture/ path IS a symlink into the repo, because that means the file was wrongly stowed and the installer's rename will destroy it. Content drift between live and repo is [FINDING], not [FAIL] — drift is the normal state until someone runs capture

### Ordering against the packages this phase moves

| Option | Selected |
|--------|----------|
| Re-stow as part of the migration | ✓ |
| Move in the repo, let verify report red |  |
| Re-stow, but scope verify to unmoved packages |  |

**User's choice:** Re-stow as part of the migration so verify ends green. Plan sequence: map, then move, then stow -D from the old tree and stow --no-folding from the new one, then verify

### Whether restow/starship/ deserves to exist

| Option | Selected |
|--------|----------|
| Yes — create it, tagged cp-through, content as-is | ✓ |
| Stop tracking it |  |
| Create it and restore pre-overwrite content from history |  |

**User's choice:** Yes — created, tagged cp-through, content as-is. Verified during discussion that stow/zsh/.config/starship.toml is byte-identical to vendor/dots-hyprland/dots/.config/starship.toml, so the repo has carried upstream's content since commit 2539238 accepted the overwrite. The mechanism is what ships; whether the content is ours or upstream's is a separate preference question. The README note must say so

### verify arguments and default scope

| Option | Selected |
|--------|----------|
| No arguments — always all three trees | ✓ |
| Optional tree or package argument |  |
| No arguments, --dry-run as a no-op alias |  |

**User's choice:** No arguments — always walks all three trees. A partial verify that exits 0 is a misleading artifact

### Repo file in stow/ or restow/ with no live counterpart

| Option | Selected |
|--------|----------|
| [FAIL] | ✓ |
| [FINDING] — report, do not fail |  |
| [FAIL] with a documented per-package opt-out |  |

**User's choice:** [FAIL], with a message naming the stow command that would fix it. The repo says the file should be linked and it is not — that is exactly the silent drift verify exists to catch. Recorded assumption: this is a single-machine repo, so every package is expected to be installed

---

## Assert + pin-bump simulation

### How the pin bump is simulated without touching the real submodule

| Option | Selected |
|--------|----------|
| Generator takes a source-root argument; assert points it at a fixture vendor tree | ✓ |
| Copy the checked-in map, edit one row, diff it |  |
| Both |  |

**User's choice:** The generator takes a source-root argument (default vendor/dots-hyprland). The assert builds a minimal fake dots-hyprland tree in a temp dir with one primitive changed (install_dir__ignore_existing to install_dir__sync), runs the generator against it, and requires the resulting map to differ from the checked-in one. Proves the generator reacts to upstream, not merely that a diff can be produced

### The mis-filed fixture

| Option | Selected |
|--------|----------|
| Built and torn down by the assert | ✓ |
| A permanently committed mis-filed fixture |  |
| Fixture built in a temp copy of the repo trees |  |

**User's choice:** Built and torn down by the assert, never committed — a distinctly-named throwaway package placed in the wrong tree, the placement check run, non-zero required, then removed. Cleanup must survive failure, so it needs a trap

### Assert script count and name

| Option | Selected |
|--------|----------|
| One: scripts/phase18-capture-model-assert.sh | ✓ |
| Two: phase assert plus a standing check-collision-map.sh |  |
| One assert plus the generator as a separate script |  |

**User's choice:** One: scripts/phase18-capture-model-assert.sh, matching the repo's phaseNN naming, with a section per ROADMAP criterion so one command gives one verdict for the phase

### Generator language

| Option | Selected |
|--------|----------|
| bash | ✓ |
| python3 |  |
| bash but emit via jq |  |

**User's choice:** bash, matching every other script in the repo. It parses 3.files-legacy.sh's primitive calls, expands the find loop, and emits TSV. The fragility of parsing shell with shell is mitigated by the Area 1 rule that an unrecognised primitive fails loudly rather than defaulting

### Generator path and output contract

| Option | Selected |
|--------|----------|
| scripts/gen-collision-map.sh, writes to stdout |  |
| scripts/gen-collision-map.sh, writes in place | ✓ |
| arch/dots-hyprland.sh gains a gen-map subcommand |  |

**User's choice:** scripts/gen-collision-map.sh, taking an optional source root and emitting the full TSV including the comment header to stdout. Never writes in place, so it can never half-write the map. Real regeneration is 'scripts/gen-collision-map.sh > collision-map.tsv'; the assert diffs its output against the checked-in file and its failure message spells out the redirection

### Pin SHA in the header

| Option | Selected |
|--------|----------|
| Generator reads it; assert fails on mismatch | ✓ |
| Generator reads it; assert warns on SHA-only mismatch |  |
| SHA recorded manually |  |

**User's choice:** Generator reads it from the submodule with git -C vendor/dots-hyprland rev-parse HEAD at generation time. The assert's regenerate-and-diff catches a stale SHA automatically because the header is part of the diff, so a pin bump dirties the map even when no row moves. That is the intended signal: the map needs re-review

---

## Claude's Discretion

None. Every gray area presented was resolved by an explicit choice; no question was deferred back to Claude.

## Deferred Ideas

- **Wire restow/ recovery into the wrapper's install path so no manual re-stow step is needed** — No CAP or FIX requirement asks for it; changes install behavior on a working daily driver; belongs with the Phase 19 verify contract or later
- **Per-tree .gitignore rules (D-14)** — The map says nothing about generated files yet; capture/ is empty until Phase 21 brings its first inhabitant
- **Treat qBittorrent as a capture/ candidate so GUI-created categories and RSS feeds can be pulled back deliberately** — Phase 21 owns capture/ inhabitants; unfolding is what makes the need visible
- **Re-evaluate the --exp-files refusal once upstream implements symlink: true and --exp-file-reset-symlink in 3.files-exp.sh** — Both are unimplemented TODO comments at pin 1a9ffb78; if they land, the exp path becomes better for a symlink-based dotfiles repo than the legacy path
- **Restore a custom `starship.toml`** from before commit `2539238` — changing the running prompt configuration is a preference decision, not a taxonomy one.
