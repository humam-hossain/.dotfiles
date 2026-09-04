# Phase 14: Live full adopt & verify - Context

**Gathered:** 2026-09-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 14 is the first phase that mutates the live machine. Everything before it was inventory (Phase 10), dispositions (Phase 11), wrapper encoding (Phase 12), and repo-side overlay authoring (Phase 13). This phase delivers the prep artifacts that make the live full adopt safe, the operator-executed adopt itself, and the verification record that closes ADOPT-01 through ADOPT-04.

In scope: a runbook plus a preflight script; the Phase 11 D-07 live-to-repo `.config` sync; the operator's `arch/dots-hyprland.sh install --full` run from a bare TTY; the Phase 13 overlay apply; reboot and first ii login; scripted and human verification; a written rollback path that never calls upstream `./setup uninstall`.

Out of scope: the agent running any mutating install; correcting the DP-1 scale if it proves wrong; porting Waybar custom modules; anything in DOC-03/DOC-04, which is Phase 15.

</domain>

<decisions>
## Implementation Decisions

### Ownership and sequencing

- **D-01:** The operator pulls the trigger on the real `arch/dots-hyprland.sh install --full`. The agent only prepares. No agent invocation ever runs a mutating install. — **Reversibility:** one-way — the run changes live `~/.config`, system packages, and the Hyprland session entry; undoing means the rollback path in D-23, not a re-run.
- **D-02:** The prep deliverable is a runbook document plus a preflight/smoke script. Not one or the other — the script gates the mechanical preconditions, the runbook carries the human sequence and the go/no-go checklist.
- **D-03:** The agent runs the Phase 11 D-07 live-to-repo `.config` sync during prep, as its own commit. **The sync must exclude `.config/hypr/custom/`.** Live has no `hypr/custom/` directory at all, and Phase 13 D-03 makes the repo copy the one-way authoring source of truth for the overlays; a naive live-to-repo sync would either delete `custom/general.lua` or silently do nothing. Everything else under `.config` flows live-to-repo so the repo holds a faithful pre-adopt archive.
- **D-04:** Phase 14 splits into two plans. `14-01` is prep (runbook, preflight script, D-07 sync, PROTECT_EXPLICIT edit) and can complete immediately. `14-02` is verification and completes after the operator's adopt window, which may be days later.
- **D-05:** The executor may run `printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run` during prep. Piping `yes` is required, not optional: `backup_gate` runs at `arch/dots-hyprland.sh:1440`, before the argv is assembled at `:1445` or printed at `:1467`, and on any non-`yes` answer it exits 1 with "Aborted (backup gate). No ./setup invoked." — capturing zero evidence. `--dry-run` is what prevents mutation, not the gate answer. This matches the wrapper's own documented usage on line 108 and the shipped, passing precedent at `scripts/phase12-full-smoke.sh:63`.
- **D-06:** The real install runs from a **bare TTY with Hyprland stopped**, not from inside a live session. Stage 4 of upstream's install ends with `sleep 1; try hyprctl reload` immediately after `hyprland.conf` has been renamed away; with no compositor running that call fails harmlessly, whereas inside a live session it would reload a session whose config file no longer exists.
- **D-07:** If the install dies partway, stop, capture the failure, and re-run the same command. Do not push through by hand and do not roll back on the first failure. Upstream's file operations are idempotent enough to re-run, and a partial run leaves the machine in a state the rollback path cannot cleanly reason about anyway.
- **D-08:** The operator applies the Phase 13 overlay **right after the install, before relogin**. Upstream seeds `hypr/custom/` via `install_dir__ignore_existing`, which only fires because live has no `custom/` directory; the overlay copy must land on top of that seed before the first ii session reads it.
- **D-09:** Waybar/rofi/swaync teardown is **automatic and atomic with the install** — there is no separate teardown step. Their `exec-once` lives in `~/.config/hypr/hyprland.conf:64` (`exec-once = waybar & swaync & hyprpaper &`), and upstream renames that whole file to `hyprland.conf.old` at `3.files-legacy.sh:50`. Hyprland 0.56.2 prefers `.conf` over `.lua` (its own binary warns "You are using the .conf config format, support for which will be removed in Hyprland 0.57"), which is precisely why upstream renames it. This matches Phase 11 D-14. The `PROTECT_EXPLICIT` edit (D-28) moves into the prep commit; the verify script only confirms none of the three is running. — **Reversibility:** costly — re-adding dual-run later is a new decision, per Phase 11 D-11.
- **D-10:** If `pacman -Syu` pulls a new kernel, let it, and reboot before the first ii login. `--full` drops `--skip-sysupdate` by design (Phase 11 D-29).
- **D-11:** The operator records the TTY session with `script(1)`, and the transcript lands in the phase directory. This is how `14-02` learns what actually happened during an install the agent did not run.
- **D-12:** Preflight demands the `vendor/dots-hyprland` submodule pin is recorded, the submodule is clean, and there is no drift. Note that upstream's stage 4 begins with `auto_update_git_submodule`, which will run `git submodule update --init --recursive` inside the vendor tree if nested submodules report dirty — so a clean starting state is what makes the recorded pin meaningful afterwards.
- **D-13:** Preflight asserts the backup directory is writable and reports what it already contains, and additionally rotates it (see D-27).
- **D-14:** If the live DP-1 scale is wrong after the overlay lands, record it in `14-02` and fix it in a later phase. Do not block phase completion on it and do not fix it mid-window.
- **D-15:** The repo working tree must be clean, with prep committed and pushed, before the install runs. The runbook the operator reads at a TTY has to be the version on GitHub.
- **D-16:** The runbook tells the operator to log in at a TTY via `start-hyprland`. This machine has no display manager running; `/usr/share/wayland-sessions/` lists `hyprland`, `hyprland-uwsm`, and `plasma`, but the session is started from a TTY script, so upstream's closing "DO NOT SELECT UWSM" warning does not apply here.
- **D-17:** **Kitty is re-stowed after the install.** This is a narrow, named exception to Phase 11 D-28. Live `~/.config/kitty/` contains only `kitty.conf`, a stow symlink into `stow/kitty/.config/kitty/kitty.conf`; upstream's `install_dir__sync` (`rsync -a --delete`) replaces that symlink with its own 1050-byte file and adds `search.py` and `scroll_mark.py`. The repo file is never touched, so `stow -R kitty` restores the personal config and upstream's two kitten scripts sit inert alongside. `starship.toml` is deliberately **not** protected — upstream's `install_file` uses `cp -f`, which follows the destination symlink and overwrites `stow/zsh/.config/starship.toml`; the operator accepts that loss. Fish stays accept-upstream per D-28.

### Process gate (ADOPT-01)

- **D-18:** The ADOPT-01 gate is the runbook's go/no-go checklist. The preflight script's exit code is one input to that checklist, not the gate itself.
- **D-19:** The go decision is recorded in the `script(1)` transcript. No separate signed-off checklist file.
- **D-20:** No-go conditions are hard blockers plus a time and fallback condition — not mechanical blockers alone, and not left to judgment in the moment.
- **D-21:** One gate covers the whole adopt window: install, overlay apply, reboot, first login, verification. No separate mini-gate.
- **D-22:** The no-go list forbids these flags outright: `-f` / `--force` (sets `ask=false`, which defeats the backup — see D-27), `--skip-backup` (the wrapper already refuses it bare per FULL-03), `-F` / `--firstrun` (would flip `install_file__auto_backup` into replacing live `hyprlock.conf` and `hypridle.conf` instead of writing `.new` sidecars, breaking Phase 11 D-24), and `--skip-hyprland-entry` (would skip installing `hyprland.lua`, breaking ADOPT-02).

### Rollback (ADOPT-04)

- **D-23:** Rollback is **three tiers, escalating**, and never uses upstream `./setup uninstall`.
  1. Config-level restore: `~/.config/hypr/hyprland.conf.old` back to `hyprland.conf`, plus `~/ii-original-dots-backup/` and the repo's D-07 pre-adopt archive.
  2. `arch/dots-hyprland.sh uninstall` with `--configs-only` or `--packages-only` — the wrapper-owned safe uninstall, which removes only `illogical-impulse-*` meta packages with `pacman -R` and never runs `yay -Rns` or an orphan sweep.
  3. `arch/dots-hyprland.sh protect --install-missing`.
- **D-24:** The rollback trigger is: no usable desktop after one honest attempt. Not any failed success criterion, and not open-ended judgment.
- **D-25:** Rollback steps are a section of the runbook, pushed to GitHub — reachable from a phone if the desktop is dead.
- **D-26:** Prove the rollback **inputs** exist, not the restore itself. No dry-run of the restore commands.
- **D-27:** **Preflight rotates `~/ii-original-dots-backup` to a timestamped name.** Upstream's `auto_backup_configs` (`sdata/subcmd-install/3.files.sh:12`) backs up unconditionally only when `ask` is true; when `ask` is false it backs up **only if the backup directory is absent** — and it currently exists, holding a stale Jul 23 copy (480K: `fish`, `fontconfig`, `hypr`, `kitty`, `kdeglobals`, `mpv`, `starship.toml`, `.local/share`) against an Aug 15 live `hyprland.conf`, missing `quickshell` and `dolphinrc` entirely. `ask` flips to false via the greeting's `n`, via `-f`/`--force`, or via typing `yesforall` at any command prompt during stages 2 and 3 — both of which run *before* the backup in stage 4. Rotating the directory aside makes both branches back up regardless of what the operator answers, and preserves the stale copy under its own name. When the backup does run it is `rsync -av` without `--delete`, including `/hypr/` and `/hypr/**`, so the whole pre-adopt hypr tree is captured. — **Reversibility:** reversible — it is a `mv` of 480K.
- **D-28:** Drop `waybar` and `swaync` from `PROTECT_EXPLICIT` (`arch/dots-hyprland.sh:251` and `:263`) as part of the prep commit, so a later tier-3 `protect --install-missing` cannot silently resurrect torn-down chrome. Note this does not demote anything: `protect_explicit_packages` only ever *adds* `--asexplicit`. The packages stay installed, so tier-1 rollback — which restores `hyprland.conf` and with it the `exec-once` line — remains coherent. `rofi` was never in the list. `hyprpaper` stays in the list; it is hypr-stack, not chrome.

### Verification (ADOPT-03)

- **D-29:** Verification is scripted checks plus a short human checklist. Neither alone.
- **D-30:** Monitors, shell chrome, and dual-run policy are all checked by the same script, with human confirmation alongside.
- **D-31:** Results land in `14-LIVE-VERIFY.md` — script output plus written findings.
- **D-32:** The success bar for Phase 14: a usable ii desktop, the Phase 13 overlay applied, Waybar/rofi/swaync gone, and findings logged. Not "everything perfect".
- **D-33:** ADOPT-02 is proven three ways, all three required: `~/.config/hypr/hyprland.conf.old` exists, `~/.config/hypr/hyprland.lua` exists, and `hyprctl` agrees the running session came from the Lua entry.
- **D-34:** Preflight hard-fails if `~/.config/illogical-impulse/installed_true` is missing, and the runbook forbids `--firstrun`/`-F` (D-22). The not-firstrun marker is the entire mechanism by which Phase 11 D-24 holds.
- **D-35:** The repo working tree is expected to be **clean** after the install; a dirty tree is a stop-worthy finding. `list_hypr_ii_hook_target_files` skips absent files (`arch/dots-hyprland.sh:660`), so after the rename the live target is gone; the repo copy already carries both hooks at `.config/hypr/hyprland.conf:67` and `:111`, so `enable_hypr_ii_hooks` reports "already active" and writes nothing. If the tree *is* dirty, review the diff and commit it, but treat the fact as a finding. The verify script asserts `git status --porcelain` is empty apart from the phase-directory transcript and verify artifacts.
- **D-36:** After the install, the verify script asserts `~/ii-original-dots-backup/.config/hypr/hyprland.conf` is newer than the install start and matches the pre-adopt live conf. This is the check that catches a silently skipped backup (D-27) and turns rollback tier 1 from assumed-good into checked-good.
- **D-37:** The verify script asserts Phase 11 D-24 held: live `hyprlock.conf` (554 bytes) and `hypridle.conf` (359 bytes) are byte-identical to their pre-install state, and `hyprlock.conf.new` / `hypridle.conf.new` sidecars exist unpromoted.
- **D-38:** The verify checklist carries a **named known-loss list**, so the operator reads these as expected rather than as breakage. Verified as replaced by ii and therefore *not* losses: polkit (`dots/.config/quickshell/ii/services/PolkitService.qml` uses `Quickshell.Services.Polkit` with a `PolkitAgent` — Quickshell is the auth agent), cliphist text and image, wallpaper, cursor theme (Bibata-Modern-Classic 24 replaces catppuccin-mocha-dark 30), and `QT_QPA_PLATFORMTHEME` (ii sets `kde`, replacing `qt6ct`). Actual losses, all accepted: `hyprland-session.service` (a personal stow unit at `stow/systemd/.config/systemd/user/hyprland-session.service` that bootstraps `graphical-session.target` and, per its own header, fixes `xdg-desktop-portal` screen share; started only from the conf line that dies at the rename, with no ii equivalent), `wl-clip-persist`, and the four workspace-pinned autostarts (Chrome on ws1, kitty+tmux on ws1, btop, Discord). **The verify script explicitly tests screen share**; if it is broken that becomes a recorded finding and a Phase 15 item, the same treatment as the DP-1 scale in D-14.
- **D-39:** Phase 14 documents write **`Waybar/rofi/swaync`** literally and never the word "chrome". Live `hyprland.conf:96` autostarts `google-chrome-stable`, so a runbook instruction about "chrome" is genuinely ambiguous to an operator reading it at a TTY.

### Claude's Discretion

- Exact preflight script structure, check ordering, and output format.
- Exact `hyprctl` assertions used to satisfy D-33, provided all three conditions are covered.
- Runbook section ordering and prose, provided the D-21 single-gate sequence appears once as one unambiguous order.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Prior phase decisions
- `.planning/phases/11-disposition-decisions/11-CONTEXT.md` — D-05 (full profile drops all three SAFE_DEFAULTS residuals); D-07 (pre-flight live-to-repo `.config` sync); D-11/D-14 (Waybar/rofi/swaync accept-remove, same adopt window); D-15 (`hyprland.conf` → `.old`); D-18 (`hyprland/` rsync accept-upstream); D-20 (`hypr/custom/` absent, allow ii seed); D-24 (hyprlock/hypridle no-touch, do not promote `.new`); D-27–D-31 (misc and package accept-upstream); D-28 is narrowed by D-17 above
- `.planning/phases/12-wrapper-full-profile/12-CONTEXT.md` — FULL-01..FULL-05 encoding of the `--full` meta-flag and the backup gate
- `.planning/phases/13-personal-hypr-custom-overlays/13-CONTEXT.md` — D-02 (Phase 14 runs the apply); D-03 (one-way repo-to-live for `custom/`); D-13 (wrong DP-1 scale recorded in Phase 14); D-18 (apply is a `cp -a` of `general.lua`/`env.lua`/`execs.lua`, failing if `general.lua` is missing); D-21 (must-migrate is monitors and workspace pins only)
- `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` — the apply command and source-of-truth policy the overlay files reference in their own header comment

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` §Live adopt & verify — ADOPT-01..ADOPT-04, lines 41–44; ADOPT-04 forbids upstream `./setup uninstall`
- `.planning/ROADMAP.md` — Phase 14 goal, dependencies on Phases 10–13, four success criteria

### Wrapper and upstream code
- `arch/dots-hyprland.sh` — `SAFE_DEFAULTS` (:12); `PROTECT_EXPLICIT` (:230–295, with `waybar` at :251 and `swaync` at :263); `list_hypr_ii_hook_target_files` (:653); `enable_hypr_ii_hooks` (:791); backup gate ordering (:1440–1467); post-install protect and hook enable (:1487–1492); wrapper-owned safe `uninstall` and `protect` subcommands
- `scripts/phase12-full-smoke.sh:63` — shipped precedent for `printf 'yes\n' | … install --full --dry-run`
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` — `auto_backup_configs` (:12) and its `ask`-dependent branches; `install_file` → `cp_file` → `cp -f`; `rsync_dir__sync` (`rsync -a --delete`, :75); `install_file__auto_backup` firstrun behaviour; backup call site (:219)
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh:8–90` — the misc, quickshell, fish, fontconfig, and hyprland install blocks in execution order, including the `hyprland.conf` → `.old` rename at :50
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh:70–92` — flag semantics, including `-f`/`--force` setting `ask=false` and `--core` expanding to four skips
- `vendor/dots-hyprland/sdata/subcmd-install/0.greeting.sh:33–50` — the greeting prompt whose `n` answer sets `ask=false`
- `vendor/dots-hyprland/sdata/lib/functions.sh:10–31` — the `v()` prompt and its `yesforall` branch; `backup_clashing_targets` (:346), which uses `rsync -av` without `--delete`
- `vendor/dots-hyprland/sdata/lib/environment-variables.sh:27–30` — `BACKUP_DIR`, `INSTALLED_LISTFILE`, `FIRSTRUN_FILE`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` — the require contract the Phase 13 overlays satisfy
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` — what ii starts, and therefore what is and is not a real loss under D-38

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- `scripts/phase12-full-smoke.sh` is the pattern for the Phase 14 preflight/smoke script: non-mutating only, help/`--dry-run`/refuse/syntax, and it already demonstrates the `printf 'yes\n' |` gate-feed idiom.
- The wrapper's `protect` subcommand and `protect_explicit_packages` already exist and need no new code for rollback tier 3 — only the `PROTECT_EXPLICIT` list edit in D-28.
- `arch/dots-hyprland.sh uninstall` already implements the safe, non-cascading removal ADOPT-04 requires. No new rollback tooling needs writing, only documenting.

### Established patterns
- The wrapper never runs a mutating install on an agent's behalf; every mutating path is operator-initiated and gated. Phase 14 preserves this.
- Machine overlays are never committed into `vendor/dots-hyprland` or the fork. The Phase 13 overlays live in the parent repo and are copied onto live.
- Upstream `./setup` is the source of truth for installation; the wrapper composes flags around it rather than reimplementing it.

### Integration points
- **The stow layer is the non-obvious one.** Only three live paths that upstream writes resolve into the repo: `~/.config/starship.toml` (a symlink to `stow/zsh/`, written *through* by `cp -f`), `~/.config/kitty/kitty.conf`, and `~/.config/fish/{config,auto-Hypr}.fish` (both replaced, not followed, by `rsync -a --delete`, so the repo files survive and only the stow links break). Everything else under `~/.config` that is stow-linked — alacritty, btop, nvim, qBittorrent, rofi, smartmontools, swaync, systemd, system_monitor, waybar, wezterm, yazi — is outside upstream's write set and is untouched.
- `~/.config/hypr` is a real directory, not a symlink, so there is no repo-through-symlink hazard on the hypr tree specifically.
- After the adopt, the repo's `.config/hypr/hyprland.conf` stops being any session's entry point and becomes the pre-adopt archive and rollback tier-1 source. Its `qs -c ii` and `ILLOGICAL_IMPULSE_VIRTUAL_ENV` hook lines become vestigial. This role change feeds OVL-03 and DOC-04 in Phase 15.
- The Phase 13 overlay apply must remain a **named-file `cp -a`** and must never become an `rsync --delete`. Upstream's `custom/` seed also ships `keybinds.lua` (135 bytes) and `scripts/__restore_video_wallpaper.sh` (107 bytes, referenced from ii's own `execs.lua`), which a delete-sync would destroy. The repo's `env.lua` and `execs.lua` are 1 byte, as are upstream's, so copying them is a no-op; only `general.lua` carries content.

</code_context>

<specifics>
## Specific Ideas

- The operator asked for the install to be walked through step by step rather than defended option by option; the runbook should be written in that same order — wrapper gate, greeting, deps, setups, files (backup, misc, quickshell, fish, fontconfig, hypr), post-install protect and hook enable, overlay apply, reboot, TTY login, verify.
- The operator's stated position on the dual-run bar stack: "I really don't need waybar rofi swaync". The runbook should not treat their removal as a risk to be managed.
- The operator's stated position on the stow collisions: starship is not worth protecting, kitty is.

</specifics>

<deferred>
## Deferred Ideas

- DP-1 scale correction, if the live scale proves wrong after the overlay lands — recorded in `14-02`, fixed in a later phase (D-14).
- `hyprland-session.service` and the `graphical-session.target` bootstrap for `xdg-desktop-portal` ScreenCast — accepted loss for this phase; revisit in Phase 15 if screen share turns out to be wanted (D-38).
- `wl-clip-persist` and the four workspace-pinned autostarts (Chrome ws1, kitty+tmux ws1, btop, Discord) — accepted losses, Phase 15+ `custom/execs.lua` candidates.
- Personal fish and starship as an active live layer — Phase 11 D-28 stands; only kitty gets the re-stow exception (D-17).
- Wrapper `verify` subcommand (POLISH-01) — Phase 14's verify script is phase-scoped and does not become a wrapper subcommand here.

</deferred>

---

*Phase: 14-live-full-adopt-verify*
*Context gathered: 2026-09-04*
