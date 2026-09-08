# Phase 16 retirement sweep

Scope: the sweep of `arch/dots-hyprland.sh`, the assert scripts, the two operator documents, and the planning artifacts for post-retirement staleness, recording what this phase changed, corrected, deleted, or flagged.

This is a findings report, not operator instruction. Stale strings are quoted verbatim below on purpose, which is why this phase's forbidden-string assertions are scoped to the operator-facing playbook (`docs/dots-hyprland-workflow.md`) and never to this file.

This file is also a marker. `scripts/phase13-d19-assert.sh` selects its wrapper drift baseline by testing for this file's presence, so moving or renaming it silently changes which commit the drift check compares against.

## Corrections applied

### `arch/dots-hyprland.sh`

The wrapper was reduced from 1531 to 740 lines across plans 16-01 and 16-02. Corrections are listed by symbol name rather than line number, since most changes are deletions and the numbers shifted with every commit.

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| `SAFE_DEFAULTS` array | `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` | Deleted — full is the only behavior (Plan 16-01, D-04) | HIGH |
| `II_BACKUP_DIR` constant | `II_BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"` | Deleted — backups removed entirely (Plan 16-01, D-06) | HIGH |
| `needs_safe_defaults()` | Profile predicate gating SAFE_DEFAULTS injection | Deleted — replaced by `touches_files()` scoping `--skip-backup` (Plan 16-01, D-04) | HIGH |
| `backup_gate()` | Type-yes install confirmation prompting for a backup snapshot | Deleted — no wrapper prompt, no snapshot on future installs (Plan 16-01, D-06/D-09) | HIGH |
| `is_help_only_user_flags()` | Helper for the backup-gate heuristic | Deleted — sole caller was `backup_gate` (Plan 16-01, D-06) | LOW |
| `user_flags_contain()` | Helper for `--skip-backup` bare-refusal logic | Deleted — sole caller was inside deleted code (Plan 16-01, D-06) | LOW |
| `PROTECT_EXPLICIT` array | 60-entry package array for `--asexplicit` re-marking | Deleted — protect machinery removed entirely (Plan 16-01, D-07) | HIGH |
| protect cluster | `resolve_real_package_name`, `collect_installed_protect_packages`, `collect_missing_protect_packages`, `protect_explicit_packages`, `install_missing_protect_packages`, `run_protect` | Deleted — protect subcommand retired from ALLOWLIST (Plan 16-01, D-07) | HIGH |
| ii-hook cluster | `list_hypr_ii_hook_target_files`, `list_active_hypr_ii_hook_files`, `list_any_hypr_ii_hook_files`, `file_has_active_ii_hooks`, `file_has_commented_ii_hooks`, `warn_hypr_ii_hooks`, `disable_hypr_ii_hooks`, `enable_hypr_ii_hooks` | Deleted — ii owns the session hooks post-adopt (Plan 16-01, D-08) | HIGH |
| injection branch | `if needs_safe_defaults "$subcmd" && ((full == 0)); then … cmd+=(SAFE_DEFAULTS)` | Deleted — `cmd=(./setup "$subcmd")` with `--skip-backup` scoped by `touches_files` (Plan 16-01, D-04) | HIGH |
| `usage()` heredoc | Documented `SAFE_DEFAULTS`, backup gate, `--allow-skip-backup`, `--skip-protect`, `--keep-hypr-hooks`, protect subcommand | Rewritten to the surviving five-subcommand surface (Plan 16-02) | MEDIUM |
| function comments | `collect_ii_meta_packages` cited `--core`; `collect_ii_config_targets` cited `--skip-hyprland` | Retired to decision-ID citations D-04 and D-07 (Plan 16-02) | LOW |

### `scripts/phase12-full-smoke.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| FULL-02 block | `if grep -q -- '--skip-hyprland' "$DEFAULT_OUT"` — asserted residuals **present** | Inverted: asserts residuals **absent** from a bare install (Plan 16-02, D-34) | HIGH |
| FULL-02b block | `install-files` residual presence check | Inverted: asserts residuals absent (Plan 16-02, D-34) | HIGH |
| FULL-03 block | `--skip-backup` bare-refusal check — script exits non-zero expected | Deleted — refusal removed by D-06 (Plan 16-02, D-34) | MEDIUM |
| FULL-03b block | `--allow-skip-backup` dual-key acceptance check | Deleted — dual-key guard removed by D-06 (Plan 16-02, D-34) | MEDIUM |
| FULL-05 block | Assert dry-run mentions `protect-list` and `ii hooks` plan | Inverted to ban: dry-run must NOT mention those (Plan 16-02, D-34) | HIGH |
| install-deps refusal | `D-02 --full refused on install-deps` | Inverted: `--full` on `install-deps` now exits 0 with the ignored-note (Plan 16-02, D-34) | MEDIUM |

### `scripts/phase14-verify.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| tier-1 source 3 probe | `ADOPT-04 tier-1 source 3 present and non-empty: $BACKUP_DIR` | Deleted — backup directory probe retired (Plan 16-03, D-37) | MEDIUM |
| tier 3 protect probe | `ADOPT-04 tier 3 reachable: protect --dry-run exits 0` | Deleted — protect subcommand retired (Plan 16-03, D-37) | MEDIUM |
| D-36 backup block | `sha256sum` / mtime integrity check on backup contents | Deleted — no future install produces a backup (Plan 16-03, D-37) | MEDIUM |
| surviving removal probe | `ADOPT-04 tier 2 reachable` | Relabelled to `D-10 wrapper removal path still reachable` (Plan 16-03, D-37) | LOW |
| two pre-adopt conf probes | `ADOPT-04 tier-1 source …` | Relabelled to `D-20 pre-adopt conf source …` (Plan 16-03) | LOW |
| D-38 finding text | Cited `PROTECT_EXPLICIT` | Reworded to describe the capability retirement (Plan 16-03, D-37) | LOW |

### `scripts/phase16-retire-assert.sh`

This is a **creation**, not a correction. The script was written in plan 16-01 (17 asserts) and extended in plan 16-04 (23 asserts). It is the non-mutating contract of record for the retirement, asserting:
- Residual-flag omission on bare `install` and `install-files`
- `--full` acceptance without forwarding
- Scoped `--skip-backup` forwarding
- Prompt absence on the install path
- Documentation vocabulary bans (`dual-run`, `safe profile`, `SAFE_DEFAULTS`, section-scoped `--skip-hyprland`)

### `scripts/phase07-live-smoke.sh` (deleted)

Deleted in plan 16-03 (D-33). Every one of its 451-line surface asserted machinery this phase removed: the protect subcommand, `--skip-protect`, hook disable, `SAFE_DEFAULTS` dry-run output, and Waybar/swaync in the session.

### `scripts/phase14-preflight.sh` (deleted)

Deleted in plan 16-03 (D-33). Its 327-line surface gated an adopt that ran on 2026-09-04 and nothing re-runs it. Its `--rotate-backup` mandatory-remediation message (IN-11) is closed by the deletion.

### `docs/dots-hyprland-workflow.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| `:14` (purpose) | `so a cold machine can reach … waybar + qs -c ii` | Rewritten to the full-only install destination (Plan 16-04, D-14) | HIGH |
| profiles section | `## Profiles: safe vs full` — entire section with subsections and flag-axis table | Deleted whole — one profile now (Plan 16-04, D-15) | HIGH |
| `:183-190` | `--full --dry-run` example + three quoted output lines including `[CONFIG] full profile: no SAFE_DEFAULTS injection` | Re-captured from the finalised binary: bare `install --dry-run`, output `./setup install --skip-backup` (Plan 16-04, D-23) | HIGH |
| backup gate subsection | `### The backup gate` — narrative, line-number citation, `sha256sum` recipe | Deleted — the gate is gone (Plan 16-04, D-06) | HIGH |
| hook ownership | `### Hooks after successful install` — described `enable_hypr_ii_hooks` | Replaced: ii owns hooks in `hyprland/env.lua` and `hyprland/execs.lua` (Plan 16-04, D-19) | MEDIUM |
| rollback pointers | Three pointers at `docs/phase14-adopt-runbook.md` §14 tier list | Replaced with clean-reinstall recovery paragraph in §9 (Plan 16-04, D-20) | HIGH |
| §10.3 | Three operator bullets + conditional apply command | One flat `./arch/dots-hyprland.sh install-files` (Plan 16-04, D-17) | MEDIUM |
| §10.4 | `### Protect` — package re-marking subsection | Deleted whole — protect is retired (Plan 16-04, D-18) | MEDIUM |
| §11 row | `Full hyprland.lua / ii hypr tree takeover | Out of scope` | Deleted — false post-adopt (Plan 16-04, D-15) | MEDIUM |
| `:529` | `## See also` pointer to runbook tier list | Stripped tier clause (Plan 16-04, D-20) | LOW |

### `docs/phase14-adopt-runbook.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| §5 invocation sites | Six lines invoking `scripts/phase14-preflight.sh` as runnable steps | Converted to historical narrative — records of the 2026-09-04 run (Plan 16-05, D-25) | MEDIUM |
| backup rotation section | Described `--rotate-backup` as a live mechanism | Converted to historical record: the mechanism is retired (Plan 16-05, D-25) | MEDIUM |
| §14 rollback tiers | Three-tier recovery list with protect re-marking and backup rotation | Replaced with clean-reinstall narrative naming `vendor/dots-hyprland` (Plan 16-05, D-20) | HIGH |

## Reviewed, no findings

### `scripts/phase10-inventory-assert.sh`

Read in full. D-39 leaves it alone. Its `:135-136` keeps requiring "safe/default dual-run remains available" language in `10-INVENTORY.md` — that is a frozen-record check about what Phase 10 captured, not current policy. No conflict.

### `README.md`

Its single mention of `arch/dots-hyprland.sh` (`:5`) carries no profile or backup claim. No edit needed.

### Archived Waybar/rofi/swaync trees

`stow/waybar/.config/waybar`, `stow/rofi/.config/rofi`, `stow/swaync/.config/swaync` — the dual-run trees archived by Phase 11 D-12. They stay in the repo untouched.

## Flagged, not edited

| File | Line | Stale text | Why stale | Disposition |
|------|------|------------|-----------|-------------|
| `.planning/phases/15-playbook-safe-vs-full/15-CONTEXT.md` | passim | Safe-profile language, `hyprctl getoption configProvider`, timestamped backup form | Phase 15 frozen record | flag, do not edit |
| `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` | passim | Deferred IN-11 and dual-run restore path as unowned items | IN-11 closed by deletion; dual-run restore path retired by design | flag, do not edit |
| `.planning/phases/12-full-install-opt-in-profile/12-*.md` | passim | `--full` as an opt-in profile, `SAFE_DEFAULTS` injection as the default, backup gate as a live mechanism | Phase 12 frozen records | flag, do not edit |
| `.planning/phases/14-live-full-adopt-verify/14-*.md` | passim | Three-tier rollback, `PROTECT_EXPLICIT`, `phase14-preflight.sh` as a live script | Phase 14 frozen records | flag, do not edit |
| `.planning/milestones/v0.3-phases/10-*/10-INVENTORY.md` | passim | `SAFE_DEFAULTS` residual documented as available | Phase 10 frozen record — the inventory captured what existed at that time | flag, do not edit |
| `.planning/codebase/ARCHITECTURE.md` | `:66`, `:138`, `:141`, `:153`, `:173`, `:260` | Wrapper described with deleted machinery | Dated 2026-08-21 regenerable snapshot; refreshed by `/gsd-map-codebase` re-run, not hand-edited | flag, do not edit |
| `.planning/codebase/STRUCTURE.md` | `:107` | Wrapper line count and structure | Same dated snapshot | flag, do not edit |
| `.planning/codebase/STACK.md` | `:65`, `:89` | Wrapper references to deleted mechanisms | Same dated snapshot | flag, do not edit |
| `.planning/codebase/CONVENTIONS.md` | `:11`, `:79`, `:83` | Convention references to deleted patterns | Same dated snapshot | flag, do not edit |
| `.planning/codebase/CONCERNS.md` | `:133` | Concern referencing deleted mechanism | Same dated snapshot | flag, do not edit |
| `.planning/codebase/TESTING.md` | `:24`, `:60`, `:113`, `:171` | Assert descriptions pre-retirement | Same dated snapshot | flag, do not edit |

## Deferred fixes

| Item | What is wrong | Why not fixed here | Owner |
|------|---------------|--------------------|-------|
| WR-02 — the three roles of `.config/hypr/hyprland.conf` | The repo copy is simultaneously a rollback source, frozen D-36 evidence, and a pre-adopt hook-injection target. The hook-injection role dies in this phase (D-08), but the question of what the file is for stays open. | Bounded exposure (content is in git history). No owning phase. | unowned |
| D-38 — `graphical-session.target` autostart bootstrap | The `graphical-session.target` / `hyprland-session.service` bootstrap lost with the renamed conf. Affects `xdg-desktop-portal` ScreenCast, `wl-clip-persist`, and the four workspace-pinned autostarts. | Documented as a known loss in Phase 15; still no owner. Fix is one `systemctl --user start` or one line in `custom/execs.lua`. | unowned |

## Planning-artifact corrections

Filled after wave 5 (plan 16-10).

## Phase gate

Filled at the gate (plan 16-10).
