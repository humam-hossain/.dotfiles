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

## Planning-artifact corrections

Filled after wave 5. The `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md` and `.planning/v0.3-MILESTONE-AUDIT.md` corrections are made by plans `16-07` through `16-09` and recorded here by plan `16-10`.

## Phase gate

Filled at the gate. Plan `16-10` records the D-40 gate transcript here: the phase-16 assert, `scripts/phase13-d19-assert.sh`, `scripts/phase12-full-smoke.sh`, `scripts/phase14-verify.sh` and `scripts/phase11-dispositions-assert.sh`, plus the post-change live login re-verify of the session.
