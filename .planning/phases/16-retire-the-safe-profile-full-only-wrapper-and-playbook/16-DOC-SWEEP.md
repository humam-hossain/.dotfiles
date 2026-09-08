# Phase 16 retirement sweep

Scope: the record of what Phase 16 changed where when it retired the safe profile from the project entirely — `arch/dots-hyprland.sh` and the machinery that only existed to serve the safe/dual-run model, the five assert scripts (two rewritten, two deleted, one created), the two operator documents `docs/dots-hyprland-workflow.md` and `docs/phase14-adopt-runbook.md`, and the planning artifacts that still promise a profile choice.

This is a findings report, not operator instruction. Stale strings are quoted verbatim below on purpose, which is why this phase's forbidden-string assertions are scoped to the operator-facing playbook and never to this file.

This file is also a marker. `scripts/phase13-d19-assert.sh` selects its wrapper drift baseline by testing for this file's presence, so moving or renaming it silently changes which commit the drift check compares `arch/dots-hyprland.sh` against.

## Corrections applied

Scope of this sweep (D-41): `arch/dots-hyprland.sh`, `scripts/phase12-full-smoke.sh`, `scripts/phase14-verify.sh`, `scripts/phase07-live-smoke.sh`, `scripts/phase14-preflight.sh`, `scripts/phase16-retire-assert.sh`, `docs/dots-hyprland-workflow.md`, and `docs/phase14-adopt-runbook.md`. Line numbers are taken from the pre-phase state at `7334498`; for the wrapper, which is deletion-heavy and whose line numbers all moved, the Line column names the symbol instead.

### `arch/dots-hyprland.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| `SAFE_DEFAULTS` | `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` | Array and its injection branch deleted; a bare `install` / `install-files` now builds `./setup <sub> --skip-backup` with no profile decision anywhere on the path (Plan 16-01, D-04) | HIGH |
| `needs_safe_defaults()` | `# Safe path keeps residual-protection note; full path must not claim skip-hyprland safety (Pitfall 5).` | Function and its comment deleted with the array they guarded (Plan 16-01, D-04) | MEDIUM |
| `backup_gate()` | `Backup gate (install and install-files only):` and `[FAIL] Aborted (backup gate). No ./setup invoked.` | Whole gate deleted; the upstream skip-backup flag is now forwarded on the two subcommands that read it, via a new `touches_files()` predicate (Plan 16-01, D-06) | HIGH |
| `PROTECT_EXPLICIT` | `After install / install-deps succeed, re-marks PROTECT_EXPLICIT packages as --asexplicit` | Package-marking cluster deleted whole: `PROTECT_EXPLICIT`, `resolve_real_package_name`, `collect_installed_protect_packages`, `collect_missing_protect_packages`, `protect_explicit_packages`, `install_missing_protect_packages`, `run_protect` (Plan 16-01, D-07) | HIGH |
| `ALLOWLIST` | `ALLOWLIST=(install install-deps install-setups install-files uninstall protect)` | `protect` removed from the allowlist, so the retired subcommand is refused by the array rather than by a missing function (Plan 16-01, D-07) | MEDIUM |
| `enable_hypr_ii_hooks()` | `Under the safe profile … the wrapper instead injects two hook lines into your own hyprland.conf` machinery | Session-hook cluster deleted whole: `list_hypr_ii_hook_target_files`, `list_active_hypr_ii_hook_files`, `list_any_hypr_ii_hook_files`, `file_has_active_ii_hooks`, `file_has_commented_ii_hooks`, `warn_hypr_ii_hooks`, `disable_hypr_ii_hooks`, `enable_hypr_ii_hooks`, plus `--keep-hypr-hooks` and the `uninstall_gate` hook parameter (Plan 16-01, D-08) | HIGH |
| `usage()` | `Protects personal hyprland.conf (full --skip-hyprland, not entry-only).` | Usage heredoc rewritten in one deliberate replacement to the surviving surface — five allowlisted subcommands, two wrapper-owned meta flags, four uninstall flags plus the guarded `--upstream-dangerous` hatch (Plan 16-02, D-13) | HIGH |
| `usage()` | `Note: once defaults inject --skip-hyprland there is no upstream undo flag.` | Deleted; nothing injects the flag any more, so the warning describes a path that no longer exists (Plan 16-02, D-13) | MEDIUM |
| `usage()` | `  ./arch/dots-hyprland.sh protect --install-missing` | Every `protect` example deleted from the help text along with the `protect flags:` block and `--skip-protect` (Plan 16-02, D-13) | MEDIUM |
| `usage()` | `                         Does NOT inject SAFE_DEFAULTS (--core --skip-hyprland --skip-sysupdate).` | Replaced by the `--full` ignored-alias note plus an explicit interactivity statement: the wrapper no longer prompts, upstream still greets and pauses (Plan 16-02, D-05) | HIGH |
| `run_safe_uninstall()` | `# Uninstall/protect are wrapper-owned (safe) — do NOT call upstream ./setup uninstall.` | Comment retired to a decision-ID citation; the `rc` accumulator was removed with its only setter and the function returns 0 explicitly, because a `return $rc` left behind aborts under `set -u` (Plan 16-01, D-10/D-11) | LOW |

### `scripts/phase12-full-smoke.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 96-119 | `FULL-02 safe residual still injected` / `FULL-02b install-files residual` | Inverted: a bare `install --dry-run` must now omit all three residual flags, and a bare `install-files --dry-run` must omit `--skip-hyprland` (Plan 16-02, D-34) | HIGH |
| 122-141 | `FULL-03 bare skip-backup refuse` and `FULL-03b dual-key allow` | Deleted; the refusal and `--allow-skip-backup` were removed by D-06, so both asserts tested a path that no longer exists (Plan 16-02, D-34) | MEDIUM |
| 144-150 | `FULL-05 protect + ii hooks plan` | Inverted to a ban: a dry-run must NOT mention `protect-list` or `ii hooks` (Plan 16-02, D-34) | MEDIUM |
| 153-158 | `D-02 --full refused on install-deps` | Inverted: `--full` on `install-deps` now exits 0 with the ignored-note (Plan 16-02, D-05) | LOW |
| 37-47 | `FULL-01 help lists --full` | Kept, retargeted: help still lists `--full`, now documented as an ignored no-op alias (Plan 16-02, D-05) | LOW |

### `scripts/phase14-verify.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 374-378 | `pass "ADOPT-04 tier-1 source 3 present and non-empty: $BACKUP_DIR"` | Deleted; no future install produces a backup, so the third rollback-source probe asserts a directory nothing will recreate (Plan 16-03, D-37) | MEDIUM |
| 386-390 | `pass "ADOPT-04 tier 3 reachable: protect --dry-run exits 0"` | Deleted; after 16-01 this probe hits the allowlist refusal and would have failed on every run (Plan 16-03, D-37) | HIGH |
| 394-420 | `# D-36 — the upstream backup actually ran, and holds the real pre-adopt conf` | Whole backup sha256/mtime block deleted with its `mktemp` handle and `trap` entry; the existing snapshot stays on disk, only the check goes (Plan 16-03, D-37) | MEDIUM |
| 380-385 | `ADOPT-04 tier 2 reachable: uninstall --dry-run exits 0` | Kept, relabelled to `D-10 wrapper removal path still reachable`; the probe's stdin feed, failure dump and tempfile survive verbatim (Plan 16-03, D-37) | LOW |
| 521 | D-38 finding text citing `PROTECT_EXPLICIT` | Reworded to state the observation the citation stood in for, since the identifier no longer exists; it stays a `[FINDING]`, not a `fail` (Plan 16-03, D-37) | MEDIUM |

### `scripts/phase07-live-smoke.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| whole file | `D-06 install --dry-run SAFE_DEFAULTS` residual-argv assert, the `protect asexplicit` and `enable ii hooks` post-install plan asserts, the `--skip-protect` omission assert, the six-assert `protect` block, and the LIVE-03 dual-run `Waybar` / `swaync` asserts | Deleted with `git rm`, 451 lines; every target was removed by 16-01 or accept-removed at the Phase 14 adopt. The surviving coverage lives in `scripts/phase12-full-smoke.sh`, `scripts/phase16-retire-assert.sh` and `scripts/phase14-verify.sh` (Plan 16-03, D-33) | HIGH |

### `scripts/phase14-preflight.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| whole file | `[ROTATED] old: /home/<you>/ii-original-dots-backup` and the mandatory-remediation rotation message (IN-11) | Deleted with `git rm`, 327 lines. This closes audit leftover IN-11 by deleting the script that carried the stale message rather than editing it. The adopt it gated ran on 2026-09-04 and nothing re-runs it. A runner sweep returned nothing outside `.git/`, `.planning/` and `docs/` (Plan 16-03, D-33) | HIGH |

### `docs/dots-hyprland-workflow.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 14 | `It covers two install profiles — the wrapper's **safe** default and the opt-in **full** profile — defined side by side in `Profiles: safe vs full` below.` | Rewritten; there is one install path and the purpose paragraph says so (Plan 16-04, W-1) | HIGH |
| 29 | `## Profiles: safe vs full` | Section deleted in full — heading, both subsections and the flag-axis table. The single surviving occurrence of the word "profile" is the sentence stating there is no profile to choose (Plan 16-04, W-1) | HIGH |
| 185 | `#   [CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)` | Replaced with output captured verbatim from `printf '' \| ./arch/dots-hyprland.sh install --dry-run` run against the binary 16-02 finalised (Plan 16-04, D-23/D-42) | HIGH |
| 196-220 | `### The backup gate` with its exact-token narrative, its `arch/dots-hyprland.sh:21` line citation and its `sha256sum` / `grep -qxF` verification recipe | Deleted, not softened. Replaced by one paragraph: no wrapper prompt, no wrapper-made snapshot, no undo — followed by the truthful interactivity note (Plan 16-04, D-15) | HIGH |
| 217 | `**Bare `--skip-backup` is refused.** The wrapper exits *before* the gate unless `--allow-skip-backup` is passed alongside it` | Deleted; both keys were removed by D-06, so the sentence described a refusal the wrapper no longer performs (Plan 16-04, D-15) | HIGH |
| 219 | `docs/phase14-adopt-runbook.md` §14 holds the three-tier rollback and is the only place those tiers are written down` | Every pointer at the tier list removed in one edit and replaced by one recovery paragraph — clean reinstall from the pinned submodule, never upstream's own removal subcommand, nothing preserved on install (Plan 16-04, D-20) | HIGH |
| 271 | `Under the safe profile there is no Lua entry and no rename: the wrapper instead injects two hook lines into your own `hyprland.conf`` | Replaced by a statement that ii owns the hooks — `hyprland/env.lua` and `hyprland/execs.lua` under `~/.config/hypr/` — and that the repo copy's two lines are dead archive nothing loads (Plan 16-04, D-08) | HIGH |
| 413 | `**Role 1 — rollback source.** It is tier-1 source 2 of `docs/phase14-adopt-runbook.md` §14` | §9's three roles rewritten; the tier-1-source-2 framing, the copy-aside-before-escalating subsection and the never-rotate subsection all removed as one unit (Plan 16-04, D-21) | MEDIUM |
| §10 | The three operator bullets guarding the update contract, plus the §10.4 package-marking subsection | Deleted whole; the update contract is one flat command, `./arch/dots-hyprland.sh install-files`, with no probe and no conditional (Plan 16-04, D-16/D-17/D-18) | MEDIUM |
| §11 | The retired-subcommand table row and the `Full hyprland.lua / ii hypr tree takeover` row | Deleted; both cite machinery or a scope claim the phase removed (Plan 16-04, W-2) | MEDIUM |

### `docs/phase14-adopt-runbook.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 81 | ``./scripts/phase14-preflight.sh` is **input 1** to the gate. Run it from the repo root:` | Converted to a record of the 2026-09-04 run; command fences carry record markers and no line begins with a bare invocation of the deleted script (Plan 16-05, D-19/D-33) | HIGH |
| 142-157 | `**Mandatory whenever the preflight's `ii-original-dots-backup` line came back as a `[FINDING]`**` | Rotation section records what happened at the `20260904T171128Z` timestamp and states plainly that the mechanism is retired — no snapshot is produced on future installs (Plan 16-05, D-27) | HIGH |
| 311-336 | `Three escalating tiers. Work them in order and stop as soon as you have a usable desktop.` | Tier list replaced wholesale with three plain statements: recovery is a clean reinstall from the pinned submodule, the wrapper never calls upstream's own removal subcommand, nothing is preserved on install (Plan 16-05, D-20) | HIGH |
| 334-336 | `# 3. The upstream backup directory, last because it is the source D-36 exists to distrust.` | Removed as a documented recovery route; the pre-adopt snapshot directories are acknowledged as present and untouched without being presented as a route (Plan 16-05, D-20) | MEDIUM |
| §17 | The canonical-document pointer | Now points at `docs/dots-hyprland-workflow.md` as the canonical operator document for install, update and recovery. Section count preserved at 17 under Phase 15 D-02 (Plan 16-05) | LOW |

### `scripts/phase16-retire-assert.sh`

Created, not corrected. 241 lines, non-mutating, dry-run argv only, never runs a live install.

| Line | Created content | Why | Severity |
|------|-----------------|-----|----------|
| 1-172 | The argv half — 17 hard asserts covering FULL-01/02/04 omission greps, the `--full` ignored-note, the `touches_files()` scoping of the upstream skip-backup flag, the absent confirmation prompt and the allowlist refusal | D-35 makes an executable contract the record of the retirement, because this repo's contract of record is an assert script rather than a checklist (Plan 16-01) | HIGH |
| 173-241 | The documentation half — a vacuity input guard, three file-wide bans and one section-scoped ban, taking the script from 17 to 23 `[PASS]` at `FAIL=0` | D-36. It is ban-only and scoped to `docs/dots-hyprland-workflow.md` alone, because `.planning/` artifacts legitimately carry the retired history and `scripts/phase10-inventory-assert.sh` actively requires it (Plan 16-04) | HIGH |

## Reviewed, no findings

### `scripts/phase10-inventory-assert.sh`
Read at the INV-04 block (`:135-140`). It deliberately **requires** the retired language — `(remains|still).{0,80}(safe|default|SAFE_DEFAULTS|dual-run)` — because it asserts the contents of a frozen Phase 10 record, `10-INVENTORY.md`, which described the machine as it stood before the adopt. Left unedited. This is the concrete reason D-36's ban is scoped to the playbook and never widened: a repository-wide ban on those tokens would put this script and the phase-16 gate in direct contradiction.

### `README.md`
Read in full. Its single wrapper mention (`:5`) names the fork, the submodule pin and `arch/dots-hyprland.sh` as a thin wrapper. It carries no profile claim, no backup claim and no dual-run destination. Nothing to correct.

### The archived `stow/` trees
`stow/waybar`, `stow/rofi` and `stow/swaync` stay in the repository untouched. They are the pre-adopt session artifacts; `Waybar`, `rofi` and `swaync` were accept-removed from the live session at Phase 11 D-11 and the trees are kept as archive, not as a supported path. No file under `stow/` was read for correction, because none of them is operator instruction.

## Flagged, not edited

Reviewed by targeted grep for the retired patterns rather than read line by line, because an exhaustive read of roughly thirty frozen artifacts is high cost for a report that changes nothing. The disposition vocabulary is Phase 15's, reused so one superseded-annotation form is used across the phase.

| File | Stale pattern | Why stale | Disposition |
|------|---------------|-----------|-------------|
| `.planning/phases/10-full-install-impact-inventory/**` (`10-INVENTORY.md`, `10-01`/`10-04`/`10-05` plans and summaries, `10-RESEARCH.md`, `10-VERIFICATION.md`, `10-VALIDATION.md`, `10-UAT.md`, `10-SECURITY.md`, `10-PLAN-CHECK.md`) | `SAFE_DEFAULTS`, `safe profile` | The whole phase's subject matter was the impact of *dropping* the residual triple. Its record is only readable if the triple is described as live. | flag, do not edit |
| `.planning/phases/11-disposition-decisions/**` (`11-DISPOSITIONS.md`, four plans and summaries, `11-VERIFICATION.md`, `11-VALIDATION.md`) | `SAFE_DEFAULTS` residual dispositions | The dispositions are the decision record that led to this retirement; rewriting them would erase the reasoning. `scripts/phase11-dispositions-assert.sh` actively requires the language. | flag, do not edit |
| `.planning/phases/12-wrapper-full-profile/12-02-PLAN.md`, `12-03-PLAN.md`, `12-02-SUMMARY.md` | `--full` as an opt-in profile, `backup gate` | Phase 12 built the opt-in profile this phase retired. The plans are the record of building it. | flag, do not edit |
| `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md`, `13-VERIFICATION.md` | `safe profile` context around the D-18 fence | Frozen authoring source of truth. It is also one side of the W-3 fence comparison added this phase, so editing it would move the assert's baseline. | flag, do not edit |
| `.planning/phases/14-live-full-adopt-verify/14-01-PLAN.md`, `14-01-SUMMARY.md`, `14-LIVE-VERIFY.md` | `PROTECT_EXPLICIT`, `backup gate` | The adopt-window record under Phase 15 D-02. `14-LIVE-VERIFY.md` is additionally the marker file the second drift baseline tier keys on. | flag, do not edit |
| `.planning/phases/15-playbook-safe-vs-full/15-05-PLAN.md`, `15-DOC-SWEEP.md` | `safe vs full`, `dual-run` | The previous sweep's record, and the format this file follows. | flag, do not edit |
| `.planning/milestones/v0.1-*`, `v0.2-*`, `v0.3-phases` | pre-adopt wrapper and session claims | Archived milestone artifacts. Out of scope by the same rule. | flag, do not edit |
| `.planning/codebase/ARCHITECTURE.md`, `CONCERNS.md`, `CONVENTIONS.md`, `STACK.md`, `STRUCTURE.md`, `TESTING.md` | `SAFE_DEFAULTS`, `protect`, `dual-run`, and references to `scripts/phase07-live-smoke.sh` and `scripts/phase14-preflight.sh`, both deleted this phase | Dated snapshots, all stamped `Analysis Date: 2026-08-21`. Six of the seven go false in this phase; `INTEGRATIONS.md` does not, because its one match is the pre-adopt `arch/waybar.sh` entry rather than a wrapper claim. | refresh by mapper re-run, do not hand-edit |

## Deferred fixes

| Item | What is wrong | Why not fixed here | Owner |
|------|---------------|--------------------|-------|
| WR-02 | The repo copy of the pre-adopt compositor config, `.config/hypr/hyprland.conf`, carries three roles at once — rollback source, frozen D-36 evidence, and pre-adopt hook-injection target. The third role died with D-08's session-hook deletion, so the file now carries two live roles and one dead one, and nothing states which of the remaining two governs. | CONTEXT.md places WR-02 outside this phase. Deciding what the file is for is a disposition question, not a staleness correction, and answering it inside a sweep would be inventing a decision the phase never took. | unowned |
| D-38 restoration | The `graphical-session.target` / `hyprland-session.service` autostart bootstrap was lost when the conf was renamed at the Phase 14 adopt, affecting xdg-desktop-portal ScreenCast, `wl-clip-persist` and the four workspace-pinned autostarts. | CONTEXT.md places it outside this phase. The fix is one `systemctl --user` line or one `custom/execs.lua` line, but it mutates the live session and this phase is non-mutating. `scripts/phase14-verify.sh` keeps emitting it as an allowed `[FINDING]`. | unowned |
| `.planning/codebase/` snapshot refresh | Six of the seven codebase snapshots describe `arch/dots-hyprland.sh` as it was before the retirement, and two of them cite scripts this phase deleted. All are stamped `Analysis Date: 2026-08-21`. | They are dated regenerable snapshots, not hand-maintained contracts, so a hand-edit would produce a document that claims to be a 2026-08-21 analysis while containing 2026-09-08 facts. Sites left to the re-map: `ARCHITECTURE.md:66, :138, :141, :153, :173, :260`; `STRUCTURE.md:107`; `STACK.md:65, :89`; `CONVENTIONS.md:11, :79, :83`; `CONCERNS.md:133`; `TESTING.md:24, :60, :113, :171`. `INTEGRATIONS.md` needs nothing — its one match is the pre-adopt `arch/waybar.sh` entry, not a wrapper claim. | refreshed by a `/gsd-map-codebase` re-run, not by hand |

The first two rows are the phase's only genuinely open items, and both are still without a home. The third is not a defect; it is a regeneration that is cheaper to run than to simulate.

## Planning-artifact corrections

Scope of this section (D-41): the six planning artifacts that still asserted something the retirement made false. The corrections were made by plans `16-07` (the requirement set, the milestone audit), `16-08` (the project file, the Phase 11 disposition record) and `16-09` (the roadmap, the state file), and are recorded here by plan `16-10`. Where `16-CONTEXT.md` cited a line number it is reused; where it did not, the Line column names the row, the requirement ID or the section instead. Line numbers are pre-sweep, at `f0cfae9`.

Two of these files were swept under the **annotate-rather-than-rewrite** rule (D-29 for the project file, D-30 for the state file). A per-phase delivered line or a decision-log row is a true statement about what that phase shipped; rewriting it would make the file assert a falsehood about the past. Such a line keeps its text and gains a suffix. The suffix wording was fixed by plan `16-07` and reused verbatim by `16-08` and `16-09`, in exactly two clause variants:

- `**[superseded by Phase 16]** — the safe profile and its machinery were retired.`
- `**[superseded by Phase 16]** — the dual-run session ended at the Phase 14 adopt.`

Two variants rather than one because the two classes of falsified claim have different causes, and one clause would have been inaccurate on the other class. `grep -n 'superseded by Phase 16'` finds every annotated site: 23 lines in `.planning/PROJECT.md`, 8 in `.planning/STATE.md`, 1 in `.planning/REQUIREMENTS.md`, 1 in `.planning/ROADMAP.md`.

Stale text is quoted verbatim below except where the quote carried the collective noun this project bans (Phase 14 D-39). Those quotes are elided as `[…]` and marked; the elision is noted rather than silently smoothed, because this record must not carry the banned token.

### `.planning/REQUIREMENTS.md`

Plan `16-07`. Six rows rewritten, three deleted with their traceability entries, coverage arithmetic recomputed. `+24/−24`.

| Line or site | Stale text | Correction | Severity |
|--------------|-----------|------------|----------|
| `INV-04` | `Inventory records current SAFE_DEFAULTS behavior and that safe dual-run install remains available after this milestone` | Rewritten to a frozen-record statement: the inventory records the behavior *as Phase 10 found it*, not as a claim about the wrapper now. Kept mapped to Phase 10 — see the mapping conflict below (Plan 16-07, D-26) | HIGH |
| `FULL-01` | ``Operator can invoke a **documented explicit opt-in** full-install path (wrapper flag/profile or equivalent) that does not inject `--skip-hyprland` (and applies other flag drops only per DISP-02)`` | Rewritten: the wrapper's only install path is the full one, no subcommand injects the three residual flags, and there is no profile to choose. Re-mapped Phase 12 → Phase 16 (Plan 16-07, D-27) | HIGH |
| `FULL-02` | ``Default `./arch/dots-hyprland.sh install` / `install-files` **still** injects SAFE_DEFAULTS (`--core --skip-hyprland --skip-sysupdate`) — full is never accidental`` | Inverted: a bare `install` / `install-files` **is** the full behavior, and `--full` survives only as an announced no-op alias. Re-mapped to Phase 16 (Plan 16-07, D-27) | HIGH |
| `FULL-03` | ``Full path retains backup gate behavior and continues to refuse bare `--skip-backup` without explicit allow override`` | Row deleted, with its traceability entry, in the same edit (Plan 16-07, D-26) | HIGH |
| `FULL-04` | `Full path supports `--dry-run` showing argv **without** unwanted SAFE_DEFAULTS injection so operator can verify before mutation` | Rewritten: the install path supports `--dry-run`, printing the exact `./setup` argv. The "without unwanted injection" qualifier is meaningless once nothing injects. Re-mapped to Phase 16 (Plan 16-07, D-27) | MEDIUM |
| `FULL-05` | `After full install/deps, PROTECT_EXPLICIT re-mark (or equivalent protect) still runs so personal stack packages are not left only asdeps` | Row deleted, with its traceability entry (Plan 16-07, D-26) | HIGH |
| `ADOPT-03` | ``After adopt, operator-verified: monitors/layout per disposition, shell […] (`qs -c ii`) runs, and dual-run policy matches DISP-03`` — the elided word is the banned collective noun | Rewritten: monitors/layout per disposition and the ii shell (`qs -c ii`) running. The dual-run clause dropped because the policy it referenced ended at the Phase 14 adopt. Re-mapped to Phase 16 (Plan 16-07, D-27) | HIGH |
| `ADOPT-04` | ``Rollback guidance exists that does **not** use upstream `./setup uninstall` (backup restore and/or wrapper safe uninstall/protect only)`` | Row deleted, with its traceability entry (Plan 16-07, D-26) | HIGH |
| `DOC-03` | ``Playbook documents **safe vs full** install profiles, inventory→disposition→adopt sequence, and flag axes (`skip-hyprland` / `core` / `sysupdate`)`` | Rewritten to the single full-only install path plus the update and recovery contracts. Re-mapped Phase 15 → Phase 16 (Plan 16-07, D-27) | HIGH |
| `CUT-01` | `Remove Waybar/rofi/swaync from Hyprland startup once parity is accepted` | Annotated, not rewritten: the claim is a future requirement that the Phase 11 D-11 accept-remove decision and the Phase 14 adopt already delivered. It carries the phase's superseded suffix and stays outside the coverage count. This is the site where the annotation form was first applied (Plan 16-07) | MEDIUM |
| Out of Scope | `\| Waybar custom module ports (CUST-01..03) \| Separate parity track; dual-run remains valid \|` | Reason clause reworded: Waybar, rofi and swaync were accept-removed from the session at the Phase 14 adopt, so the ports are parity work with no v0.3 deliverable. The row itself stands (Plan 16-07) | MEDIUM |
| Out of Scope | `\| Removing Waybar/rofi/swaync by default (CUT-01) \| Only if DISP-03 explicitly accepts; default keep \|` and `\| Making full profile the default wrapper behavior \| Safe defaults remain default \|` | Both rows deleted: a milestone cannot exclude what it delivered, and the second describes the behavior that now ships (Plan 16-07) | MEDIUM |
| Traceability | `\| FULL-01 \| Phase 12 \| Complete \|` and the FULL-02 / FULL-04 / ADOPT-03 / DOC-03 rows | Re-mapped to Phase 16. `FULL-03`, `FULL-05` and `ADOPT-04` deleted from the table in the same edit as their checklist rows, because a row present in one and absent from the other is worse than either state (Plan 16-07, D-27) | MEDIUM |
| Coverage | `- v0.3 requirements: 22 total` / `- Mapped to phases: 22` | Recomputed to `19 total` / `19` / `Unmapped: 0`, with a note explaining the drop that names no retired ID — the plan's own orphan check bans all three file-wide — and points here for the identifiers (Plan 16-07, D-27) | HIGH |
| Footer | `*Last updated: 2026-08-03 after v0.3 roadmap mapping*` | Restamped to 2026-09-08 citing D-26 and D-27 | LOW |

### `.planning/v0.3-MILESTONE-AUDIT.md`

Plan `16-07`. Dispositioned in place, never pruned: every finding keeps its identifier, severity and original issue statement and gains `disposition` and `resolution` keys. `+199/−88`.

| Line or site | Stale text | Correction | Severity |
|--------------|-----------|------------|----------|
| `B-1` (`:27-32`, `:234`) | `Playbook section 10.3 update contract skips the ii `hypr/` tree on an adopted machine.` with a recorded remedy of adding the opt-in flag to §10.3 | Dispositioned closed by the wrapper flip, not by the recorded remedy: plan `16-01` deleted the residual array and its injection branch, and plan `16-04` rewrote §10.3 to one flat `install-files`. The blocker and its original issue statement are kept verbatim (Plan 16-07, D-31) | HIGH |
| `B-2` (`:33-38`, `:235`) | `No dual-run restore path; safe re-install cannot complete post-adopt.` | Dispositioned closed by *retiring* the destination rather than documenting a route back to it — stated plainly as the opposite of the recorded remedy, and as deliberate (Plan 16-07, D-31) | HIGH |
| `W-1` | `Phase 11 env must-keep rows never annotated when Phase 13 reversed them.` | Marked resolved with a citation to plan `16-08`, which made the source correction in `11-DISPOSITIONS.md`, plus an explicit note that `16-07` does not pre-empt that edit (Plan 16-07) | MEDIUM |
| `W-2` | ``[…] archive path drift: `.config/{waybar,rofi,swaync}` recorded, `stow/{waybar,rofi,swaync}` actual.`` — the elided word is the banned collective noun | Marked resolved, citing plan `16-08` for the source correction. The audit's own evidence line was corrected at its own site to name `stow/waybar`, `stow/rofi` and `stow/swaync`, which exist (Plan 16-07) | MEDIUM |
| `W-3` | `Playbook duplicates the apply fence with no assert comparing the copies.` | Marked resolved, citing the fence-drift assert plan `16-06` added to `scripts/phase13-d19-assert.sh` (Plan 16-07) | MEDIUM |
| Requirement scope | `**Requirements in scope:** 22` and the disposition-matrix rows `\| FULL-03 \| 12 \| satisfied \| wired \| satisfied \|`, `\| FULL-05 \| 12 \| … \|`, `\| ADOPT-04 \| 14 \| satisfied \| wired (IN-11) \| satisfied \|` | Scope count and the three matrix rows removed together with the requirements they scored (Plan 16-07, D-27) | MEDIUM |
| Flow A (`:57-61`) | ``**Flow A — safe re-install: BROKEN.** … the final hop, dual-run restoration, has no artifact on an adopted machine … `list_hypr_ii_hook_target_files` (`arch/dots-hyprland.sh:651-665`) now finds only the repo copy`` | Retired out of the completion count rather than left counted as broken: its destination no longer exists, so "broken" would misdescribe it. The deleted-function citation is marked as removed in Phase 16 (Plan 16-07, D-31/D-33) | HIGH |
| Flow C (`:65`) | `status: "broken"` / `breaks_at: "apply hop"` | Moved to complete: the apply hop is now one flat `install-files`. Both section headings state the audit-time and post-disposition counts side by side rather than silently upgrading `1/3 complete` (Plan 16-07, D-31) | MEDIUM |
| Integration flows (`:...`) | ``Phase 11 DISP-02 → Phase 12 `--full` … prints `[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)``` and the `Phase 12 SAFE_DEFAULTS survives Phases 13-15` block citing `arch/dots-hyprland.sh:12` and `:1447-1449` | Evidence re-captured from the current wrapper's dry-run output rather than adjusted from memory. Quoted output strings, arrays and functions that no longer exist are either refreshed or kept as the historical statement with a note that Phase 16 removed the machinery (Plan 16-07, D-31) | HIGH |
| Tech debt `IN-11` (`:70`) | ``IN-11 open: scripts/phase14-preflight.sh:263-264 prints `--rotate-backup` as unconditional mandatory remediation … Suggested gate `[[ -f "$XDG/hypr/hyprland.conf" ]]` unimplemented.`` | Recorded as **closed by deletion**, not paid: plan `16-03` deleted the script whole. The original entry is kept verbatim as the record of what the debt was (Plan 16-07, D-33) | HIGH |
| Cosmetic `INFO 2` (`:71`) | ``check_tier1_source is applied to rollback sources 1-2 at scripts/phase14-verify.sh:372-373; source 3 gets presence and non-empty checks at :374-378`` | Moot after the `phase14-verify.sh` deletions in plan `16-03`; dispositioned as such (Plan 16-07, D-31) | LOW |
| Recommended closure | `Three deferred fixes recorded as unowned in 15-DOC-SWEEP.md` and the roadmap-footer staleness note | Rewritten to what the phase did. Both statements of the unowned count moved from 3 to 2 together rather than being patched in one place; the two survivors are still listed and no home was invented for either (Plan 16-07, D-31) | MEDIUM |
| `status:` and scores | `status: gaps_found` plus the scores block | **Left as measured** at their 2026-09-06 values. A `dispositioned` / `dispositioned_by` / `disposition_note` metadata block records the later state instead. An audit that rewrites its own scores stops being a measurement (Plan 16-07) | HIGH |

### `.planning/PROJECT.md`

Plan `16-08`. Swept under the annotate-rather-than-rewrite rule: current-state claims rewritten, per-phase delivered lines and key-decision rows annotated. `+33/−33`.

| Line or site | Stale text | Correction | Severity |
|--------------|-----------|------------|----------|
| `:8` | `**In progress:** v0.3 Full ii install — Phases 10–14 complete; next is Phase 15 playbook safe vs full` | Rewritten to the current position (Plan 16-08, D-29) | MEDIUM |
| `:28` product surface | ``- Install entry: `arch/dots-hyprland.sh` → vendored `./setup``` and the `Session:` and `Rollback:` lines | All three brought to post-phase truth: one install path with no gate; ii owning the venv env and the `qs -c ii` exec-once; recovery as a clean reinstall from the pinned `vendor/dots-hyprland` submodule, matching what plan `16-05` made the runbook say. Waybar, rofi and swaync are named literally (Plan 16-08, D-29, plus deviation 3) | HIGH |
| Milestone goals | `- Safe full-install path: wrapper/playbook opt-in out of SAFE_DEFAULTS; backup gate preserved` and `- Document: playbook update for full vs dual-run/safe profiles` | Both rewritten to the single install path that shipped (Plan 16-08, D-29) | HIGH |
| `:43` | ``**Not this milestone:** … dual-run removal as a pure bar cutover (may follow after full hypr adopt if still dual-running […])`` — the elided word is the banned collective noun | **Annotated, not rewritten** — a documented deviation. It is a milestone-scope record made at definition time, the same class as the v0.2 line the plan leaves as history, and rewriting it would have removed one of the three occurrences of the banned collective noun that the previous phase deliberately froze in that file, breaking the plan's own count-of-exactly-3 gate (Plan 16-08, deviation 1) | MEDIUM |
| `:102`, `:105`, `:109`, `:117`, `:119`, `:125`, `:127` and 15 further delivered / key-decision lines | e.g. ``✓ Thin `arch/dots-hyprland.sh` wrapper around upstream `./setup` with safe dual-run defaults and backup gate — Phase 6 / WRAP-01..04``; ``✓ Full path keeps type-yes backup gate; bare `--skip-backup` refused without `--allow-skip-backup` — Phase 12 / FULL-03``; ``✓ Live full install ran only after the INV-* / DISP-* artifacts were satisfied, enforced by `scripts/phase14-preflight.sh` — Phase 14 / ADOPT-01`` | 22 sites annotated with the phase's superseded suffix, claim text preserved: 18 carrying the safe-profile clause and 4 carrying the dual-run clause (Plan 16-08, D-29) | HIGH |
| `:28`, `:128`, `:219` | `Three-tier rollback guidance` and ``runbook tier 1 opens by moving `hyprland.lua` aside`` | Token-level fixes on two annotated lines, because the plan's tier grep is file-wide while its instruction was site-scoped: `Rollback guidance in three tiers` and `the runbook's first rollback step opened by moving hyprland.lua aside`. Same assertions, and the second is additionally more honest, since plan `16-05` replaced the runbook's tier list (Plan 16-08, deviation 2) | MEDIUM |
| Active items | `- [ ] Playbook: full vs safe/dual-run install profiles` and the post-v0.2 reality line ``Default wrapper install still injects SAFE_DEFAULTS (`--core --skip-hyprland --skip-sysupdate`)`` | Rewritten as current state (Plan 16-08, D-29) | HIGH |
| `:160-161` | `- Move from protected dual-run adopt toward full ii session ownership when personal must-keeps are mapped.` | Rewritten: the move happened (Plan 16-08, D-29) | MEDIUM |
| Footer | `*Last updated: 2026-09-05 after Phase 14 verification close-out …*` | Restamped | LOW |

### `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md`

Plan `16-08`. This is a **frozen phase artifact** and one of the two sites where the freeze was overridden — see the frozen-artifact override below. `+4/−4`, and the file's assert was re-run after each edit.

| Line or site | Stale text | Correction | Severity |
|--------------|-----------|------------|----------|
| `:110` and the two neighbouring must-keep rows | ``D-16 only: dual-monitor setup → Phase 13 minimal `hypr/custom` overlay. Cite conf monitors ~29–30.``; the workspaces row `Cite conf ~76–87.`; the env row ``machine env paths including cursor theme/size and `ILLOGICAL_IMPULSE_VIRTUAL_ENV` → Phase 13 overlay`` | All three rewritten from intention to outcome (audit W-1, closed at source). Monitors and the eleven workspace pins were authored in Phase 13 as `general.lua` and applied live at the Phase 14 adopt. The env row states what actually happened rather than the happy version: Phase 13 D-21/D-08 narrowed it to no overlay content, so `env.lua` went live as a 1-byte require slot and ii's own `hyprland/env.lua` supplies `ILLOGICAL_IMPULSE_VIRTUAL_ENV` (Plan 16-08) | HIGH |
| `:201` archive policy | ``**Archive policy (D-12):** `.config/{waybar,rofi,swaync}` **remain in repo as archive** (pre-flight captures live).`` | Path corrected to `stow/waybar/.config/waybar`, `stow/rofi/.config/rofi` and `stow/swaync/.config/swaync`, which exist (audit W-2, closed at source). The rest of the statement is unchanged because it is still true (Plan 16-08) | HIGH |
| `accept-upstream` primary-entry row | — | **Byte-identical.** The override is site-scoped: only the two rows the audit named were touched (Plan 16-08) | — |

### `.planning/ROADMAP.md`

Plan `16-09`. Amended under the D-03 exception at the sites D-28 named. `+6/−6`.

| Line or site | Stale text | Correction | Severity |
|--------------|-----------|------------|----------|
| `:11` milestone prose | `wrapper gains an explicit full profile while safe defaults remain the default; live adopt is gated; playbook documents safe vs full.` | Rewritten: the wrapper's only install path is the full one, the residual defaults are retired, and the playbook documents that single install path. The first half — the inventory-then-disposition gate — is untouched, because that is how the milestone actually ran (Plan 16-09, D-28) | HIGH |
| `:13` | `**Not this milestone:** Waybar custom ports (CUST-*), default removal of Waybar/rofi/swaync (CUT-01), blind full install.` | The removal exclusion dropped: Phase 11 D-11 accepted it and the Phase 14 adopt executed it, and a milestone cannot exclude what it delivered. The custom-ports and blind-install exclusions stand (Plan 16-09, D-28) | MEDIUM |
| `:69` Phase 10 criterion 4 | `Inventory states that default wrapper install still uses SAFE_DEFAULTS and remains available after this milestone` | Corrected to mirror the rewritten `INV-04` word for word, so the roadmap and the requirement set cannot be read against each other (Plan 16-09, D-28) | HIGH |
| Phase 15 criterion 1 | `Playbook documents safe vs full profiles, inventory→disposition→adopt sequence, and flag axes` | Amended and annotated rather than left as history — a documented deviation. It is a present-tense claim about a document plan `16-04` rewrote full-only, and the task's own gate bans that literal file-wide while the plan's leave-as-history list names only Phases 11, 12 and 14. It now reads `both install profiles as they stood at Phase 15` plus the superseded suffix (Plan 16-09, deviation 1) | MEDIUM |
| Coverage line | `**Coverage:** v0.1 shipped · v0.2 shipped · v0.3 22/22 requirements mapped · 0 unmapped` | Recomputed to `19/19 requirements mapped · 0 unmapped`, read live from `.planning/REQUIREMENTS.md` rather than taken from the plan's prose. The v0.1 and v0.2 clauses are unchanged (Plan 16-09, D-27/D-28) | HIGH |
| Per-phase history for Phases 11, 12 and 14 | — | **Left as history**, as D-28 requires. Eight `SAFE_DEFAULTS` occurrences survive in the roadmap's history lines, and no successor phase was invented (Plan 16-09) | — |
| Footer | `*Last updated: 2026-09-07 — Phase 16 retitled …*` | Restamped citing D-27 and D-28 | LOW |

### `.planning/STATE.md`

Plan `16-09`. Same treatment as the project file: rewrite the present, annotate the carry-forward. `+18/−17`.

| Line or site | Stale text | Correction | Severity |
|--------------|-----------|------------|----------|
| Core value | `Full adopt done (Phase 14); remaining work is documentation.` | Rewritten: Phase 16 then retired the safe profile from the wrapper, the assert scripts and the operator documents, so there is one install path and nothing left to choose (Plan 16-09, D-30) | HIGH |
| `:73` | ``- Thin `arch/dots-hyprland.sh` only; SAFE_DEFAULTS + backup gate; array-exec `./setup``` | Rewritten to what survives — the array exec and nothing else: one full-only install path, no residual-flag injection, no backup gate, no package re-marking. The literal `SAFE_DEFAULTS + backup gate` additionally had to go because the task's current-state ban is file-wide; the Phase 6 decision row keeps the same claim in the reworded form `SAFE_DEFAULTS injection and the backup gate` (Plan 16-09, D-30, plus deviation 3) | HIGH |
| `:74` | ``- Live install at `~/.config/quickshell` (real tree); personal hypr hooks for env + `qs -c ii``` | Rewritten: ii owns the session hooks in its own Lua tree — `hyprland/env.lua` supplies the venv env and `hyprland/execs.lua` starts `qs -c ii` (Plan 16-09, D-30) | HIGH |
| `:78`, `:82`, `:83`, `:90`, `:149`, `:155` and the Waybar-cutover backlog row | e.g. `- v0.3: full install only after impact inventory + dispositions (not blind drop of SAFE_DEFAULTS)`; `- Phase 11: … residual still default (D-10) …`; ``- Phase 14: rollback is `docs/phase14-adopt-runbook.md` §14 — three tiers …`` | Seven entries annotated with the phase's superseded suffix, claim text preserved: six carrying the safe-profile clause and one — the backlog row whose reason was `DISP-03 defaults keep dual-run` — carrying the dual-run clause (Plan 16-09, D-30) | HIGH |
| `:107` | ``⚠️ [Phase 14] Review IN-11 left open: post-adopt, `scripts/phase14-preflight.sh` still prints `--rotate-backup` as "mandatory before go".`` | Moved from open concerns to resolved blockers, recorded as closed by deletion in plan `16-03`, matching the closure plan `16-07` wrote into the milestone audit (Plan 16-09, D-30) | HIGH |
| `:113-119` operator next steps | `1. /gsd-plan-phase 16 — close v0.3 audit gap DOC-03: B-1 playbook full-profile pin-bump path, B-2 documented route back to the safe dual-run profile`; `5. Default install without --full still injects SAFE_DEFAULTS (FULL-02; smoke 2026-08-18)` | Replaced with what is actually next, carrying forward the two retroactive Phase 13 checks that are still undone and adding the codebase-snapshot re-map (Plan 16-09, D-30) | HIGH |
| Next step 2 | ``Decide an […] for the open D-38 `graphical-session.target` item — Phase 15 scope, or its own phase`` — the elided word is the assignment noun this record's own gate bans within reach of that identifier, which is the same reason the state file could not keep it | Reworded to `Find a home for the open D-38 …; it stays open and unowned until then`. Same instruction, and it now states the unowned status explicitly rather than only implying it. The reword was forced: the task's ban regex matched the original phrasing (Plan 16-09, deviation 4) | MEDIUM |
| Roadmap-evolution entry | `- Phase 16 added: Close gap: DOC-03 — full-profile update path and dual-run restore` | Rewritten to record the retitle and the widening to the safe-profile retirement, and that both original items closed by retiring the destination rather than documenting a route to it (Plan 16-09, D-30) | MEDIUM |
| Phase 16 decision-log entry | `the phase superseded-annotation form is a bold bracketed suffix, **[superseded by Phase 16]**, followed by a short clause naming what delivered it` | Normalised so its only occurrence of the token is the canonical form followed by a canonical clause verbatim — a documented deviation. The task's gate caps distinct annotation spellings at 2, and this pre-existing quotation produced a third inside the gate's 60-character window. The entry's content is unchanged (Plan 16-09, deviation 2) | LOW |
| Phase-archives block | — | A pointer added to this file as the place the change set is recorded, so a future session reads it instead of re-deriving the change set from ten plan bodies (Plan 16-09) | — |
| Front matter, progress block, session fields, performance table | — | **Not hand-edited.** Those are tooling-written by `gsd-tools.cjs`; the diff was read line by line to confirm it (Plan 16-09) | — |

### The coverage change

v0.3 went from **22 requirements to 19**. Three rows were deleted outright rather than rewritten, together with their traceability entries, because in each case the machinery the row described was removed by this phase and there was no surviving behavior to restate:

- **`FULL-03`** — the backup gate and the refusal of a bare `--skip-backup` without an allow override. Plan `16-01` deleted the gate and both keys under D-06. A rewrite would have had to assert that the wrapper still prompts, or assert nothing.
- **`FULL-05`** — the post-install package re-marking pass. Plan `16-01` deleted the whole `PROTECT_EXPLICIT` cluster and removed `protect` from the allowlist under D-07. The capability is gone, not relocated.
- **`ADOPT-04`** — rollback guidance built on the three-tier list. Plans `16-04` and `16-05` replaced that list with a clean reinstall from the pinned submodule under D-20, and plan `16-03` deleted the two `phase14-verify.sh` probes that proved the tiers reachable. The recovery contract still exists and is documented, but it is not the thing this row promised.

Rewriting any of the three would have produced a requirement that describes a document rather than a capability. `INV-04`, `FULL-01`, `FULL-02`, `FULL-04`, `ADOPT-03` and `DOC-03` each had a surviving behavior to restate and were rewritten instead.

The three identifiers appear **nowhere in `.planning/REQUIREMENTS.md`**, not even in the coverage note explaining the drop: that plan's own orphan check bans them file-wide, so a note naming them would read as an orphan. The note describes what each row promised and points here. This file is where the identifiers live.

### The mapping-rule conflict, and how it resolved

D-27 is the general rule: a rewritten row maps to Phase 16 and becomes checked when Phase 16 verifies. D-26 is the specific rule, and for exactly one identifier the two disagree.

`INV-04` was rewritten. The general rule maps it to Phase 16. The specific rule keeps it at **Phase 10**, and the specific rule governed.

That is the right answer on its own terms and not only by precedence. `INV-04` records what the Phase 10 inventory *captured* — the machine as it stood before the adopt — rather than what the wrapper does now. It is a frozen record, and `scripts/phase10-inventory-assert.sh` is deliberately left verifying that frozen record under D-39: its `INV-04` block at `:135-140` still **requires** the retired language, `(remains|still).{0,80}(safe|default|SAFE_DEFAULTS|dual-run)`, in `10-INVENTORY.md`. Re-mapping the row to Phase 16 would have created pressure to "fix" that assert to agree, which would have deleted the only mechanical guarantee that the Phase 10 record still says what Phase 10 found. `./scripts/phase10-inventory-assert.sh` runs `FAIL=0` after the sweep, and that is the property the resolution protects.

This is also the concrete reason the D-36 documentation ban in `scripts/phase16-retire-assert.sh` is scoped to `docs/dots-hyprland-workflow.md` alone. A repository-wide ban on the retired tokens would put the Phase 10 assert and the Phase 16 gate in direct contradiction.

`DISP-03` stayed at Phase 11 untouched. The other five rewritten rows moved to Phase 16.

### The frozen-artifact override

Phase 15 **D-22** freezes phase artifacts: `.planning/phases/**` and `.planning/milestones/**` record what a phase shipped and are not rewritten when a later phase contradicts them. This phase's **D-03** overrides that freeze **at named sites only**, and the override was exercised at exactly four places:

1. `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md:110` — the three `migrate-to-hypr-custom` must-keep rows, rewritten from intention to outcome (audit W-1).
2. `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md:201` — the D-12 archive-policy path, corrected to the `stow/` trees that exist (audit W-2).
3. `.planning/ROADMAP.md:11` and `:13` — the milestone prose, plus `:69` and the Phase 15 criterion.
4. `.planning/ROADMAP.md` coverage line — 22/22 to 19/19.

The exception is recorded because no `gsd-tools.cjs` query handler edits milestone prose or success criteria; there was no tooling path to those sites.

**Everything else under `.planning/phases/**` and `.planning/milestones/**` stayed frozen.** The Phase 10, 12, 13, 14 and 15 directories were not edited, the archived `v0.1-*`, `v0.2-*` and `v0.3-phases` milestone trees were not edited, and the pre-milestone research files were not edited. Where those artifacts carry claims this phase falsified, they are listed above under **Flagged, not edited** and left as the record of what was true when written. The Phase 11 record's `accept-upstream` primary-entry row is byte-identical, which is what makes the override site-scoped rather than a licence to sweep the file.

## Phase gate

The D-40 gate, run by plan `16-10` on **2026-09-08** against a committed, clean working tree at `95b86fd`. `git status --porcelain` was empty before the first script started. That ordering is not incidental: `scripts/phase14-verify.sh`'s final assertion allows modifications only under a hard-coded `.planning/phases/14-live-full-adopt-verify/` prefix, and every path this phase touched is outside it, so the suite would have failed on a dirty tree for a reason unrelated to the session it is verifying.

Summary lines are quoted verbatim from the captured transcripts. Nothing below is paraphrased.

1. **`./scripts/phase16-retire-assert.sh`** — the phase's own retirement contract, 23 `[PASS]`.

   ```
   === done: FAIL=0 ===
   ```

2. **`./scripts/phase12-full-smoke.sh`** — the wrapper-behavior smoke, 16 `[PASS]`, covering the inverted FULL-02 residual-omission asserts, the `--full` ignored-note and the allowlist refusal.

   ```
   === done: FAIL=0 ===
   ```

3. **`./scripts/phase11-dispositions-assert.sh`** — the disposition record, 38 `[PASS]`. Added to the gate because the W-1 rewrite plan `16-08` made to `11-DISPOSITIONS.md` could have broken it.

   ```
   === done: FAIL=0 ===
   phase11 dispositions asserts OK
   ```

4. **`./scripts/phase13-d19-assert.sh`** — the overlay assert, 16 `[PASS]`, zero `[FAIL]`. Both drift checks are in it and both hold:

   ```
   [PASS] arch/dots-hyprland.sh unmodified since 0771cc2
   [PASS] W-3 docs/dots-hyprland-workflow.md apply fence matches the 13-SOT-APPLY.md D-18 fence
   === Phase 13 asserts: FAIL=0 ===
   ```

   The wrapper drift pin re-based by plan `16-06` still holds, which is the mechanical proof that nothing after that pin touched `arch/dots-hyprland.sh`. This file's own path is the marker that selects that baseline — see the note at the top of this record.

5. **`./scripts/phase14-verify.sh`** — the live verification suite, run against the running session, 33 `[PASS]`, zero `[FAIL]`, exactly one `[FINDING]`:

   ```
   [PASS] ADOPT-02 configProvider is 'lua', no longer the recorded pre-adopt 'hyprlang'
   [PASS] ADOPT-02 hyprland.conf absent — no .conf can win over the Lua entry
   [PASS] ADOPT-03 ii shell running: qs -c ii
   [PASS] ADOPT-03 waybar not running (Waybar/rofi/swaync accept-remove)
   [PASS] ADOPT-03 swaync not running (Waybar/rofi/swaync accept-remove)
   [FINDING] D-38 graphical-session.target is inactive — hyprland-session.service lost its autostart with the renamed conf (expected). This is why screen share may be broken. Phase 15 item.
   [PASS] D-35 git status --porcelain is clean apart from paths under .planning/phases/14-live-full-adopt-verify/
   === done: FAIL=0 FINDINGS=1 ===
   ```

   The finding is the known compositor-target autostart loss. It stays emitted and stays allowed, exactly as in the previous phase. It was not silenced, not resolved, and no home was found for it here — it is still listed in **Deferred fixes** above.

6. **`./scripts/phase10-inventory-assert.sh`** — not one of D-40's five, run anyway because plan `16-07`'s `INV-04` rewrite deliberately left this assert requiring the retired language in the frozen Phase 10 record. It is the check that would have gone red had anyone "fixed" the assert to agree with the rewrite. 29 `[PASS]`.

   ```
   === done: FAIL=0 ===
   phase10 inventory asserts OK
   ```

**Playbook cross-check.** `docs/dots-hyprland-workflow.md:326` quotes the live suite's summary line as its post-login expectation:

```
# expect: === done: FAIL=0 FINDINGS=1 ===   (the 1 finding is the D-38 known loss)
```

The line observed above is `=== done: FAIL=0 FINDINGS=1 ===`, byte-identical to the quoted expectation. **No mismatch, no finding, no follow-up owed.** The playbook was not edited during the gate, which would have dirtied the tree the gate had just certified.

**Human step — re-login: OUTSTANDING, not performed.**

The automated half of the session verification did run after this phase's changes rather than before them: item 5 above executed against the live compositor at `95b86fd` and confirms the session still loads through the ii Lua entry, that no `hyprland.conf` can win over it, that `qs -c ii` is running, and that Waybar and swaync are still stopped per the D-11 accept-remove. That is the strongest statement the automated suites can make.

It is not the same statement as a fresh login. Everything this phase changed lives in the git worktree, and nothing here ran an install, an uninstall or any package operation — but the phase did remove two safety mechanisms from the install path and delete the machinery that used to inject session hooks, and the only honest confirmation that a *new* session is unaffected is to end this one and start another. The executing agent cannot log the operator out, so this step is recorded as outstanding rather than claimed.

**What the operator still owes this gate.** Log out of the current Hyprland session completely, or reboot, then log back in and confirm:

- (a) the desktop comes up and the ii shell is running — the bar, the launcher and the notification surface all appear;
- (b) `hyprctl -j status | jq -r .configProvider` prints `lua`;
- (c) `./scripts/phase14-verify.sh` prints `=== done: FAIL=0 FINDINGS=1 ===`;
- (d) nothing that worked before the phase has stopped working, beyond the compositor-target autostart loss already recorded above as a known, unowned loss.

Record the date and the observed result below this paragraph when it is done. If (d) surfaces something new, record it as a finding and name the plan that owns the file rather than fixing it here — a fix at the gate re-dirties the tree the gate certified and invalidates the run that found the defect.

| Step | Date | Result |
|------|------|--------|
| Re-login re-verify (D-40 human step) | — | **outstanding** — awaiting the operator |

**Gate result.** All five D-40 scripts plus the Phase 10 assert are green on a committed, clean tree, with the one known finding still emitted and still allowed. No defect was found, so nothing was handed to a follow-up. The one step this record cannot close by itself is the re-login above.
