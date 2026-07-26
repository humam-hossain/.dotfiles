# Phase 7: Install, Session Hooks & Dual-Run Verify - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Land a **running** illogical-impulse shell beside Waybar using **personal** Hyprland session ownership.

**In scope:**
- Pre-install: stop `qs`, break live `~/.config/quickshell` symlink so the path is absent
- Live install via Phase 6 wrapper: dry-run then one-shot `arch/dots-hyprland.sh install` (safe defaults + backup gate)
- Personal hypr hooks: `ILLOGICAL_IMPULSE_VIRTUAL_ENV` + `exec-once = qs -c ii` in **owned** `hyprland.conf`
- Dual-run verify: Waybar (and existing swaync/rofi session pieces) still start; operator confirms ii chrome
- LIVE-01, LIVE-02, LIVE-03, LIVE-04

**Out of scope this phase:**
- Retiring in-repo `.config/quickshell` product tree or `arch/quickshell.sh` (Phase 8)
- Full operator playbook / update docs (Phase 9)
- Waybar/rofi/swaync cutover; removing dual-run
- Full ii hyprland.lua / hyprland conf takeover (`--skip-hyprland` remains)
- Reimplementing package lists; calling non-allowlisted setup subcommands through the wrapper
- Automated rollback/restore tooling (re-run wrapper only)
- Extra operator pre-backup tarball step (user declined; wrapper gate remains)

**Requirements:** LIVE-01, LIVE-02, LIVE-03, LIVE-04

</domain>

<decisions>
## Implementation Decisions

### Symlink break & pre-install backup
- **D-01:** Before install-files path runs: **unlink** live `~/.config/quickshell` (symlink only) and **leave the path absent** so upstream setup creates a **real directory**. Do **not** follow the symlink or delete the repo target.
- **D-02:** **No extra** operator pre-backup tarball step for Phase 7. Rely on the existing Phase 6 wrapper **interactive backup gate** only. Do **not** encourage or default to `--skip-backup` / `--allow-skip-backup`.
- **D-03:** **Stop running `qs`** before retarget/install so nothing holds the symlink path mid-rsync.
- **D-04:** Leave in-repo `.config/quickshell` **alone** this phase. Product retirement is Phase 8 after LIVE-04.

### Install command sequence
- **D-05:** First adoption uses **one-shot** `arch/dots-hyprland.sh install` (deps + setups + files) with Phase 6 safe defaults injection (`--core --skip-hyprland --skip-sysupdate`).
- **D-06:** Plans **must** include a **dry-run first** pass (`--dry-run`) and confirm argv shows the safe defaults before the live install.
- **D-07:** Install may run **mid-session** (terminal inside Hyprland) after `qs` is stopped; apply session changes afterward via reload/restart (see D-16).
- **D-08:** On failure mid-install: **fix cause and re-run wrapper**. No automated rollback script in Phase 7.

### Session hook placement
- **D-09:** **Keep personal hyprland config** as source of truth. Do **not** install/replace with ii `hyprland.lua` / full hypr tree this phase (consistent with `--skip-hyprland`).
- **D-10:** Add the two hooks **inline** in personal `hyprland.conf` (not a separate sourced snippet).
- **D-11:** **Commit** hooks into `.dotfiles` (`.config/hypr/hyprland.conf`) this phase so LIVE-02 is versioned.
- **D-12:** `ILLOGICAL_IMPULSE_VIRTUAL_ENV` = **`~/.local/state/quickshell/.venv`** (upstream default / `$XDG_STATE_HOME/quickshell/.venv`).
- **D-13:** Session start: **`exec-once = qs -c ii`** (plain; alongside existing waybar exec-once — do not remove waybar).

### Dual-run verify bar policy
- **D-14:** Order: **hooks first, then verify** — commit env + exec-once, apply session changes, then check LIVE-04 (not “manual qs only then maybe hook”).
- **D-15:** Dual-run policy: **both bars OK even if they overlap**. Waybar remains current primary chrome; no layout cutover work this phase.
- **D-16:** LIVE-04 pass requires **all three**: (1) `qs` process running with config `ii`, (2) `ILLOGICAL_IMPULSE_VIRTUAL_ENV` set in the Hyprland session, (3) operator-confirmed **visible** ii shell chrome on screen.
- **D-17:** Apply session changes with **`hyprctl reload` + restart `qs`** when possible (prefer over mandatory full re-login).

### Agent's Discretion
- Exact `pkill`/`qs` stop command and whether to warn if qs was not running
- Exact hypr `env =` line syntax/spacing for the venv path (must resolve to upstream default path)
- Placement of the new lines within `hyprland.conf` (near existing exec-once block preferred)
- Exact dry-run / live install command order in plans and UAT checklist wording
- How to assert “real directory not symlink” (e.g. `test ! -L && test -d` plus presence of `ii` tree)
- Whether to also sync live `~/.config/hypr/hyprland.conf` from repo in the same plan step (D-11 commits repo; live must match for session)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning (v0.2)
- `.planning/PROJECT.md` — live session uses installed ii; dual-run; delete local product later
- `.planning/REQUIREMENTS.md` — **LIVE-01**, **LIVE-02**, **LIVE-03**, **LIVE-04**
- `.planning/ROADMAP.md` — Phase 7 goal, success criteria, plans 07-01…07-03
- `.planning/STATE.md` — Current position Phase 7
- `.planning/phases/06-thin-setup-wrapper-safe-defaults/06-CONTEXT.md` — Wrapper D-05…D-13 safe defaults, backup gate, allowlist (must not re-open)
- `.planning/phases/05-fork-submodule-pin/05-CONTEXT.md` — Canonical path `vendor/dots-hyprland` only

### Research (install / session safety)
- `.planning/research/SUMMARY.md` — Phase 7 delivers deps/setups/files + env + `qs -c ii` + dual-run verify
- `.planning/research/ARCHITECTURE.md` — Phase 7 session coexistence; personal conf hooks; avoid full ii hypr entry
- `.planning/research/PITFALLS.md` — **Pitfall 1** (backup/files overwrite), **Pitfall 2** (symlink → rsync into git tree), dual-run policy, `ILLOGICAL_IMPULSE_VIRTUAL_ENV` when hypr install skipped
- `.planning/research/STACK.md` — Recommended `./setup` flags; qs runtime

### Repo / live integration
- `.planning/codebase/INTEGRATIONS.md` — `arch/quickshell.sh` symlink model; hypr `exec-once` (waybar/swaync/hyprpaper)
- `.planning/codebase/ARCHITECTURE.md` — Provisioning layer; config deployment mechanisms
- `arch/dots-hyprland.sh` — Phase 6 wrapper (allowlist, safe defaults, backup gate, `--dry-run`)
- `arch/quickshell.sh` — Current symlink installer (do not re-run for adoption path)
- `.config/hypr/hyprland.conf` — Personal hypr SoT for inline hooks
- `vendor/dots-hyprland/setup` — Upstream install entry
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` — Files install + venv env warning
- `vendor/dots-hyprland/sdata/uv/README.md` — Default `ILLOGICAL_IMPULSE_VIRTUAL_ENV` path

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/dots-hyprland.sh` — ready wrapper: safe defaults, backup gate, `--dry-run`, allowlisted `install`
- `vendor/dots-hyprland/setup` — executable SoT for live install
- `.config/hypr/hyprland.conf` — personal conf with existing `exec-once = waybar & swaync & hyprpaper &` (add env + `qs -c ii` here)
- `qs` already on PATH (Quickshell 0.3.0 Arch package)

### Established Patterns
- Phase 6: never auto-inject `--force` / `--skip-backup`; full `--skip-hyprland` (not entry-only)
- Live QS today: `~/.config/quickshell` → symlink into `.dotfiles/.config/quickshell` (must unlink before files install)
- No `source =` includes in personal hypr today — inline hooks match style
- Upstream default venv: `~/.local/state/quickshell/.venv` (set in hypr when `--skip-hyprland` skips ii env conf)

### Integration Points
- Pre: stop qs → unlink `~/.config/quickshell` (path absent)
- Install: `./arch/dots-hyprland.sh install --dry-run` then live `install` (operator types yes at gate)
- Session: commit hooks to `.config/hypr/hyprland.conf`; ensure live conf matches; `hyprctl reload` + restart qs
- Verify LIVE-01…04: real dir tree, env set, waybar still up, qs -c ii process + visible chrome
- Downstream Phase 8 deletes in-repo product only after LIVE-04 green

</code_context>

<specifics>
## Specific Ideas

- User: **keep own hyprland config** — only additive env + exec-once; no ii hypr takeover
- User: **no need for backup** beyond existing wrapper gate (interpreted as no extra pre-backup tarball; Phase 6 gate still runs)
- Success criteria from ROADMAP remain authoritative for “done”
- Roadmap sketch still valid as plan skeleton: 07-01 pre-install symlink, 07-02 wrapper install, 07-03 hypr hooks + dual-run verify

</specifics>

<deferred>
## Deferred Ideas

- Retire `.config/quickshell` product tree + `arch/quickshell.sh` — Phase 8
- Full clone/install/update playbook — Phase 9
- Document restore from `~/ii-original-dots-backup` as primary recovery narrative — Phase 9 (Phase 7 recovery is re-run only)
- Waybar/rofi/swaync cutover — later milestone
- Full Lua hypr cutover — later milestone
- Wrapper `verify` subcommand — POLISH-01 / future

None beyond phase-boundary deferrals — discussion stayed within Phase 7 scope.

</deferred>

---

*Phase: 7-Install Session Hooks Dual-Run Verify*
*Context gathered: 2026-07-26*
