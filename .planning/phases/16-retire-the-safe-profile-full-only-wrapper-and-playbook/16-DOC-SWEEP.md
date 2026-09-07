# Phase 16 retirement sweep

Scope: the wrapper (`arch/dots-hyprland.sh`), the assert scripts (`scripts/phase16-retire-assert.sh` created; `scripts/phase12-full-smoke.sh` and `scripts/phase14-verify.sh` rewritten; `scripts/phase07-live-smoke.sh` and `scripts/phase14-preflight.sh` deleted), the two operator documents (`docs/dots-hyprland-workflow.md`, `docs/phase14-adopt-runbook.md`), and the planning artifacts that still described a safe-by-default install.

This is a findings report, not operator instruction. Stale strings are quoted verbatim below on purpose, which is why this phase's forbidden-string assertions are scoped to the operator-facing playbook and never to this file.

This file is also a marker. `scripts/phase13-d19-assert.sh` selects its wrapper drift baseline by testing for this file's presence, so moving or renaming it silently changes which commit the drift check compares against.

## Corrections applied

One `### <file path>` subsection per file this phase changed, in wave order. Stale text is quoted from the pre-change files; the correction cites the plan that actually shipped it.

### `arch/dots-hyprland.sh`

Deletion-heavy: Line column uses the symbol name, not a line number.

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| `SAFE_DEFAULTS` | `` `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` `` | Deleted. Bare `install` / `install-files` now run full with no residual injection (Plan 16-01, D-04) | HIGH |
| `backup_gate` | `` `Bare --skip-backup is refused unless also passing --allow-skip-backup.` `` | Deleted the wrapper-owned install backup and its confirmation prompt. `touches_files()` forwards upstream `--skip-backup` on `install` / `install-files` only (Plan 16-01, D-06, D-09) | HIGH |
| `protect` | `` `protect          Re-mark personal-stack pkgs explicit; optional reinstall missing` `` | Subcommand removed from `ALLOWLIST`; refused as non-allowlisted rather than dispatched into a hole (Plan 16-01, D-07) | HIGH |
| hook cluster | `` `Protects personal hyprland.conf (full --skip-hyprland, not entry-only).` `` | Eight hypr hook helpers and every call site deleted. Live session loads via `hyprland.lua`; ii owns `hyprland/env.lua` and `hyprland/execs.lua` (Plan 16-01, D-08) | HIGH |
| `usage()` | `` `uninstall        Safe dual-run uninstall (wrapper-owned; see below)` `` | Heredoc rewritten to the surviving surface; dual-run qualifier gone; interactivity note says the wrapper prompts for nothing and upstream still greets and pauses (Plan 16-02, D-13) | MEDIUM |

### `scripts/phase12-full-smoke.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| FULL-02 | `` `fail "FULL-02 bare install --dry-run missing SAFE_DEFAULTS residuals"` `` | Inverted: a bare install must omit all three residuals (Plan 16-02, D-34) | HIGH |
| FULL-03 | `` `fail "FULL-03 install --full --skip-backup --dry-run should exit non-zero"` `` | Deleted. `--skip-backup` is no longer refused (Plan 16-02, D-06/D-34) | MEDIUM |
| FULL-05 | `` `pass "FULL-05 full dry-run plans protect-list + ii hooks"` `` | Inverted to a ban: dry-run must not mention `protect-list` or ii hooks (Plan 16-02, D-34) | MEDIUM |

### `scripts/phase14-verify.sh`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| ADOPT-04 tier 3 | `` `pass "ADOPT-04 tier 3 reachable: protect --dry-run exits 0"` `` | Probe deleted. After 16-01 the allowlist refuses `protect` (Plan 16-03, D-37) | HIGH |
| ADOPT-04 source 3 | `` `pass "ADOPT-04 tier-1 source 3 present and non-empty: $BACKUP_DIR"` `` | Probe deleted. No future install produces that directory (Plan 16-03, D-37) | MEDIUM |
| D-36 backup hash | `` `pass "D-36 backup copy sha256 matches the pre-adopt fixture ($BK_SHA)"` `` | Entire backup-integrity block deleted; on-disk snapshots left untouched (Plan 16-03, D-37) | MEDIUM |
| ADOPT-04 labels | `` `pass "ADOPT-04 tier 2 reachable: uninstall --dry-run exits 0"` `` | Surviving removal probe relabelled onto D-10; two pre-adopt conf probes relabelled onto D-20 (Plan 16-03) | LOW |

### `scripts/phase07-live-smoke.sh`

Deleted (`769bf9e`, Plan 16-03, D-33). −451 lines. The script asserted SAFE_DEFAULTS residual argv, `protect asexplicit`, enable-ii-hooks dry-run plans, and live dual-run of Waybar / swaync — every target 16-01 removed or Phase 14 accept-removed. Coverage now lives in `scripts/phase12-full-smoke.sh`, `scripts/phase16-retire-assert.sh`, and `scripts/phase14-verify.sh`.

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| file | the live-smoke runner itself | `git rm`; runner sweep outside `.git/`, `.planning/`, `docs/` returned none (Plan 16-03) | HIGH |

### `scripts/phase14-preflight.sh`

Deleted (`769bf9e`, Plan 16-03, D-33). −327 lines. Closed IN-11 by deletion: the script printed `--rotate-backup` as mandatory remediation, and running it today would rename a rollback source.

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| IN-11 | `` `./scripts/phase14-preflight.sh --rotate-backup` printed as mandatory remediation `` | Script deleted; nothing re-runs it (Plan 16-03, D-33) | HIGH |

### `docs/dots-hyprland-workflow.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 18 | `` `keep DRY — run ./arch/dots-hyprland.sh help for the full allowlist, safe defaults, backup gate, uninstall, and protect behavior` `` | Cross-reference rewritten to the surviving help surface; profiles section deleted whole (Plan 16-04) | HIGH |
| 185 | `` `[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)` `` | Replaced with wrapper output re-captured from the 16-02 binary: `./setup install --skip-backup` (Plan 16-04, D-23) | HIGH |
| 192 | `` `Dropping --full gives the safe profile instead` `` | One install path; the only surviving "profile" sentence states there is no profile to choose (Plan 16-04) | HIGH |
| 247–248 | `` `uninstall` / `protect` dual-run table rows `` | Retired-subcommand row deleted; uninstall described as wrapper-owned removal (Plan 16-04) | MEDIUM |
| 494 | `` `### 10.4 Optional: protect after deps demotion` `` | Subsection deleted; §10.3 is one flat `./arch/dots-hyprland.sh install-files` (Plan 16-04, D-17) | HIGH |

### `docs/phase14-adopt-runbook.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 84 | `` `./scripts/phase14-preflight.sh` `` as a step to run now | Command fences converted to records of the 2026-09-04 run (Plan 16-05, D-25) | HIGH |
| 149 | `` `./scripts/phase14-preflight.sh --rotate-backup` `` | Rotation section is historical narrative; mechanism retired (Plan 16-05) | HIGH |
| §14 | three-tier rollback list (tier 1 / tier 2 / tier 3) | Replaced with clean-reinstall from `vendor/dots-hyprland`; wrapper never calls upstream's own removal subcommand (Plan 16-05, D-20) | HIGH |

### `scripts/phase16-retire-assert.sh`

Creation, not a correction. Plan 16-01 landed the wrapper-behavior half (17 hard asserts). Plan 16-04 added the ban-only documentation gate, playbook-scoped, with a negative control — 23 PASS, `FAIL=0`. The documentation ban stays scoped to `docs/dots-hyprland-workflow.md` and is never pointed at this sweep file.

## Reviewed, no findings

### `scripts/phase10-inventory-assert.sh`

Read. It deliberately requires retired language inside a frozen Phase 10 record. Widening this phase's documentation ban to cover that file would make two asserts contradict each other. Left alone (D-39).

### `README.md`

Read. Its single wrapper mention carries no profile or backup claim. Left alone.

### Archived Waybar / rofi / swaync trees

The `stow/` trees stay in the repo untouched (D-12). They are archive, not operator instruction.

## Flagged, not edited

Frozen artifacts under `.planning/phases/**` and `.planning/milestones/**` that now contradict current state are left as records of what those phases shipped. D-03 overrides that freeze at exactly two named sites (W-1 / W-2 in `11-DISPOSITIONS.md`, and ROADMAP milestone prose plus the coverage line), both of which land in later waves of this phase, not here.

The six dated `.planning/codebase/` snapshots (all stamped `2026-08-21`) describe the wrapper as it was before this phase and go false here. They are regenerable mapper output, not hand-maintained contracts, so they are left untouched and refreshed by a `/gsd-map-codebase` re-run afterwards rather than hand-edited.

| File | Line | Stale text | Why stale | Disposition |
|------|------|------------|-----------|-------------|
| `.planning/codebase/ARCHITECTURE.md` | 66, 138, 141, 153, 173, 260 | wrapper described with residual injection / backup gate / protect | Phase 16 deleted that machinery | flag; mapper re-run |
| `.planning/codebase/STRUCTURE.md` | 107 | same | same | flag; mapper re-run |
| `.planning/codebase/STACK.md` | 65, 89 | same | same | flag; mapper re-run |
| `.planning/codebase/CONVENTIONS.md` | 11, 79, 83 | same | same | flag; mapper re-run |
| `.planning/codebase/CONCERNS.md` | 133 | same | same | flag; mapper re-run |
| `.planning/codebase/TESTING.md` | 24, 60, 113, 171 | same | same | flag; mapper re-run |
| `.planning/phases/**` (except the two D-03 sites) | — | any claim that a bare install still injects residuals | frozen phase record | flag, do not edit |
| `.planning/milestones/**` | — | same class of claim | frozen milestone record | flag, do not edit |

`PROJECT.md` and `STATE.md` current-state vs history sweeps are D-29 / D-30 and land in plans 16-08 / 16-09. They are not edited here.

## Deferred fixes

| Item | What is wrong | Why not fixed here | Owner |
|------|---------------|--------------------|-------|
| WR-02 — three roles of the repo copy `.config/hypr/hyprland.conf` | The file is simultaneously a rollback source, frozen D-36 evidence, and a pre-adopt hook-injection target. The hook-injection role dies in this phase; the question of what the file is for stays open. | CONTEXT.md "Not in this phase". No owner was assigned. | unowned |
| D-38 `graphical-session.target` autostart bootstrap | `graphical-session.target` / `hyprland-session.service` bootstrap, `wl-clip-persist`, and the four workspace-pinned autostarts were lost with the renamed conf. Screen share may stop working. | CONTEXT.md "Not in this phase". Documented as a known loss in Phase 15; still no owner. `phase14-verify.sh` keeps emitting it as an allowed `[FINDING]`. | unowned |

## Planning-artifact corrections

Filled after wave 5 (plans 16-07, 16-08, 16-09). This heading exists so the marker file is complete in shape; the rows are not claimed yet.

## Phase gate

Filled at the gate by plan 16-10. This heading exists so the marker file is complete in shape; the gate has not run.
