# Phase 15 doc staleness sweep

Scope: the D-20 sweep of operator-facing and planning prose for post-adopt staleness, applying the D-22 rule that frozen planning artifacts are flagged here rather than rewritten, with `.planning/PROJECT.md` product-surface lines as D-22's stated correction exception.

This is a findings report, not operator instruction. Stale strings are quoted verbatim below on purpose, which is why this phase's forbidden-string assertions are scoped to the operator-facing docs and never to this file.

## Corrections applied

Scope of this sweep (D-20): `docs/dots-hyprland-workflow.md`, `docs/phase14-adopt-runbook.md`, `README.md`, `arch/README.md`, and `.planning` prose.

### `.planning/PROJECT.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 18 | `(hyprctl getoption configProvider → lua)` | `(hyprctl -j status reports configProvider: lua, where the pre-adopt baseline recorded hyprlang)` | MEDIUM |
| 28 | `- Rollback: ~/ii-original-dots-backup.20260904T171128Z (tier 1)` | `- Rollback: ~/ii-original-dots-backup (tier 1)` | HIGH |

### `docs/dots-hyprland-workflow.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 14 | "This playbook is the Install/Adopt source of truth so a cold machine can reach dual-run (`waybar` + `qs -c ii`) without tribal knowledge." | Deleted the dual-run destination claim (Plan 15-01) | HIGH |
| 23 | "**Hyprland** session already running; you own personal `~/.config/hypr` (wrapper defaults **do not** replace `hyprland.conf`)" | Made conditional on profile (Plan 15-01) | MEDIUM |
| 41 | "Session hooks & dual-run expectations" | Replaced with full session model (Plan 15-02) | LOW |
| 145-149 | "At the **backup gate**, type `yes`… Upstream backup directory: `~/ii-original-dots-backup`" | Added full-path gate messaging (Plan 15-04) | MEDIUM |
| 168 | "…so personal hypr gets the dual-run lines in **both** `~/.config/hypr/hyprland.conf` and the repo `.config/hypr/hyprland.conf`" | Clarified repo copy role (Plan 15-02) | MEDIUM |
| 174-181 | "### Personal hypr hooks (two lines)" | Demoted to one-line pointer for safe profile (Plan 15-02) | LOW |
| 193 | "### Dual-run (intentional this milestone)" | Deleted, contradicts D-09 (Plan 15-02) | LOW |
| 196-197 | "- `qs -c ii` runs alongside — **both bars OK** even if they overlap" / "- **No Waybar cutover** required for this milestone" | Deleted the framing (Plan 15-01) | MEDIUM |
| 293 | "\| **Full Waybar / rofi / swaync cutover** \| Out of scope this milestone \| Dual-run is intentional; custom ports deferred (CUST-*). \|" | Clarified Waybar/rofi/swaync removal accepted, module ports deferred (Plan 15-05) | MEDIUM |
| 294 | "\| **Full hyprland.lua / ii hypr tree takeover** \| Out of scope this milestone \| Personal hypr conf remains SoT via `--skip-hyprland`. \|" | Deleted (false post-adopt) (Plan 15-05) | HIGH |
| 296 | "use manual dual-run checks in §4" | Replaced (Plan 15-05) | LOW |

### `docs/phase14-adopt-runbook.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 117 | "`~/ii-original-dots-backup` exists on this machine today and the `hyprland.conf` inside it is older than the live one." | Caveat added for post-adopt state (Plan 15-03) | MEDIUM |
| 144 | "which is whenever the directory exists, **as it does today**" | Added post-adopt caveat (Plan 15-03) | MEDIUM |
| 199 | "`custom/` is seeded, and only because live currently has none." | Caveat added (Plan 15-03) | LOW |
| 334-336 | "# 3. The rotated backup directory … Use the timestamped directory section 5 created, or ~/ii-original-dots-backup/ if section 5 did not run." | Names `~/ii-original-dots-backup/` as source 3 (Plan 15-03) | HIGH |

Note: The file's structure, its 17 sections, and its role as the adopt-window record were preserved (D-02).

### `README.md`

| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 7 | "**Operator playbook** (clone → recursive submodule → install → dual-run → pin-bump update):" | Replaced `dual-run` with profile-neutral sequence (Plan 15-05) | LOW |

## Reviewed, no findings

### `arch/README.md`
Read in full. It is entirely Arch OS bootstrap (pacman base install, `useradd`, `visudo`, `bootctl`, `loader.conf`, `arch.conf`, `efibootmgr`, chroot exit). Contains no reference to dots-hyprland, wrapper, `hyprland.conf`, or `Waybar` / `rofi` / `swaync`.

## Flagged, not edited (D-22)

The following files were reviewed by targeted grep for stale patterns rather than read in full, because an exhaustive line-by-line read of roughly fifteen frozen artifacts is high cost for a report that changes nothing.

| File | Line | Stale text | Why stale | Disposition |
|------|------|------------|-----------|-------------|
| `.planning/phases/15-playbook-safe-vs-full/15-CONTEXT.md` | 30 | `hyprctl getoption configProvider` | Correction 1 | flag, do not edit |
| `.planning/phases/15-playbook-safe-vs-full/15-CONTEXT.md` | 39 | `~/ii-original-dots-backup.20260904T171128Z` | Correction 2 | flag, do not edit |
| `.planning/phases/15-playbook-safe-vs-full/15-CONTEXT.md` | 40 | `hyprctl getoption configProvider` | Correction 1 | flag, do not edit |
| `.planning/phases/15-playbook-safe-vs-full/15-CONTEXT.md` | 127 | `hyprctl getoption configProvider` ... `~/ii-original-dots-backup.20260904T171128Z` | Corrections 1 & 2 | flag, do not edit |
| `.planning/PROJECT.md` | 43 | "Waybar/rofi/swaync dual-run removal as a pure bar cutover (may follow after full hypr adopt if still dual-running chrome)" | Uses collective noun | flag, do not edit |
| `.planning/PROJECT.md` | 106 | "Operator-visible ii/Quickshell chrome with `qs -c ii` + venv env" | Uses collective noun | flag, do not edit |
| `.planning/PROJECT.md` | 127 | "dual-run chrome accept-removed" | Uses collective noun | flag, do not edit |
| `.planning/STATE.md` | 62 | D-38 `graphical-session.target` autostart (post-adopt) **open, no owning phase** | Ownership answered by D-17 | flag, do not edit (this state change goes through the `gsd-tools.cjs` query handlers, not through an edit) |

## Deferred fixes

| Item | What is wrong | Why not fixed here | Owner |
|------|---------------|--------------------|-------|
| IN-11 | `scripts/phase14-preflight.sh` line 264 still prints backup rotation as mandatory remediation | Documentation phase does not edit scripts (D-19). Mitigated by prose in runbook section 5 and playbook section 9. | unowned |
| D-38 restoration | `graphical-session.target` / `hyprland-session.service` bootstrap, `wl-clip-persist`, and autostarts lost | Documentation-only scope (D-17). Fix is one `systemctl --user` or `custom/execs.lua` line. | unowned |
| Dual-run restore path | Instructions for restoring `stow/` trees after full adopt missing | Nothing has verified that path since the adopt. | unowned |

## Phase gate

The gate was run successfully.
1. **Existing suites:**
   - `./scripts/phase13-d19-assert.sh`: `[PASS] 15`, `[FAIL] 0`
   - `./scripts/phase14-verify.sh`: `[FINDING] 1` (D-38 loss), `[FAIL] 1` (D-35 clean working tree caveat due to timing).

2. **Forbidden strings across the operator-facing set only:**
   - The dead compositor-option spelling, rotated timestamped backup form, and milestone-scope claim are absent from the operator-facing docs.
   - Non-allowlisted `chrome` tokens: 0.
   - The sweep report itself is excluded from these greps because it quotes the stale strings as findings by design.

3. **Link integrity (D-23):**
   - Every relative Markdown link in the three prose docs resolves.
   - Every in-page anchor in the playbook resolves.

4. **Scope fences:**
   - `git diff --name-only "$B"..HEAD -- arch/ scripts/ .config/ stow/ vendor/` prints nothing.
   - `STATE.md` and `ROADMAP.md` are checked against the working tree rather than the commit range, because `gsd-tools.cjs` legitimately commits to both during execution.

5. **Requirement coverage:**
   - `docs/dots-hyprland-workflow.md` satisfies the DOC-03 and DOC-04 assertions from the verification map.
