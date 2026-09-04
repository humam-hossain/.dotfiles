# Phase 14: Live full adopt & verify - Research

**Researched:** 2026-09-04
**Domain:** Operator-executed live system cutover (Hyprland session config adopt) — runbook authoring, non-mutating preflight/verify shell asserts, rollback design
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Ownership and sequencing

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

#### Process gate (ADOPT-01)

- **D-18:** The ADOPT-01 gate is the runbook's go/no-go checklist. The preflight script's exit code is one input to that checklist, not the gate itself.
- **D-19:** The go decision is recorded in the `script(1)` transcript. No separate signed-off checklist file.
- **D-20:** No-go conditions are hard blockers plus a time and fallback condition — not mechanical blockers alone, and not left to judgment in the moment.
- **D-21:** One gate covers the whole adopt window: install, overlay apply, reboot, first login, verification. No separate mini-gate.
- **D-22:** The no-go list forbids these flags outright: `-f` / `--force` (sets `ask=false`, which defeats the backup — see D-27), `--skip-backup` (the wrapper already refuses it bare per FULL-03), `-F` / `--firstrun` (would flip `install_file__auto_backup` into replacing live `hyprlock.conf` and `hypridle.conf` instead of writing `.new` sidecars, breaking Phase 11 D-24), and `--skip-hyprland-entry` (would skip installing `hyprland.lua`, breaking ADOPT-02).

#### Rollback (ADOPT-04)

- **D-23:** Rollback is **three tiers, escalating**, and never uses upstream `./setup uninstall`.
  1. Config-level restore: `~/.config/hypr/hyprland.conf.old` back to `hyprland.conf`, plus `~/ii-original-dots-backup/` and the repo's D-07 pre-adopt archive.
  2. `arch/dots-hyprland.sh uninstall` with `--configs-only` or `--packages-only` — the wrapper-owned safe uninstall, which removes only `illogical-impulse-*` meta packages with `pacman -R` and never runs `yay -Rns` or an orphan sweep.
  3. `arch/dots-hyprland.sh protect --install-missing`.
- **D-24:** The rollback trigger is: no usable desktop after one honest attempt. Not any failed success criterion, and not open-ended judgment.
- **D-25:** Rollback steps are a section of the runbook, pushed to GitHub — reachable from a phone if the desktop is dead.
- **D-26:** Prove the rollback **inputs** exist, not the restore itself. No dry-run of the restore commands.
- **D-27:** **Preflight rotates `~/ii-original-dots-backup` to a timestamped name.** Upstream's `auto_backup_configs` (`sdata/subcmd-install/3.files.sh:12`) backs up unconditionally only when `ask` is true; when `ask` is false it backs up **only if the backup directory is absent** — and it currently exists, holding a stale Jul 23 copy (480K: `fish`, `fontconfig`, `hypr`, `kitty`, `kdeglobals`, `mpv`, `starship.toml`, `.local/share`) against an Aug 15 live `hyprland.conf`, missing `quickshell` and `dolphinrc` entirely. `ask` flips to false via the greeting's `n`, via `-f`/`--force`, or via typing `yesforall` at any command prompt during stages 2 and 3 — both of which run *before* the backup in stage 4. Rotating the directory aside makes both branches back up regardless of what the operator answers, and preserves the stale copy under its own name. When the backup does run it is `rsync -av` without `--delete`, including `/hypr/` and `/hypr/**`, so the whole pre-adopt hypr tree is captured. — **Reversibility:** reversible — it is a `mv` of 480K.
- **D-28:** Drop `waybar` and `swaync` from `PROTECT_EXPLICIT` (`arch/dots-hyprland.sh:251` and `:263`) as part of the prep commit, so a later tier-3 `protect --install-missing` cannot silently resurrect torn-down chrome. Note this does not demote anything: `protect_explicit_packages` only ever *adds* `--asexplicit`. The packages stay installed, so tier-1 rollback — which restores `hyprland.conf` and with it the `exec-once` line — remains coherent. `rofi` was never in the list. `hyprpaper` stays in the list; it is hypr-stack, not chrome.

#### Verification (ADOPT-03)

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

### Deferred Ideas (OUT OF SCOPE)

- DP-1 scale correction, if the live scale proves wrong after the overlay lands — recorded in `14-02`, fixed in a later phase (D-14).
- `hyprland-session.service` and the `graphical-session.target` bootstrap for `xdg-desktop-portal` ScreenCast — accepted loss for this phase; revisit in Phase 15 if screen share turns out to be wanted (D-38).
- `wl-clip-persist` and the four workspace-pinned autostarts (Chrome ws1, kitty+tmux ws1, btop, Discord) — accepted losses, Phase 15+ `custom/execs.lua` candidates.
- Personal fish and starship as an active live layer — Phase 11 D-28 stands; only kitty gets the re-stow exception (D-17).
- Wrapper `verify` subcommand (POLISH-01) — Phase 14's verify script is phase-scoped and does not become a wrapper subcommand here.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **ADOPT-01** | Live full install is executed only after INV-* and DISP-* are satisfied (process gate) | INV-01..04 and DISP-01..04 are marked Complete in `REQUIREMENTS.md:90-97`; the gate is therefore an *artifact-existence* assert plus a runbook go/no-go checklist (D-18). §Code Examples gives the exact preflight artifact assertions; §Common Pitfalls #1 covers the dirty/unpushed-tree blocker that currently exists |
| **ADOPT-02** | After full hypr adopt, Hyprland session loads via ii Lua entry (`hyprland.lua` / hyprland tree) rather than the pre-adopt personal `hyprland.conf` as primary | Three-way proof (D-33) is fully groundable: the rename is at `3.files-legacy.sh:52`, the `hyprland.lua` install at `:58-63` (gated only by `--skip-hyprland-entry`), and the running-session probe is `hyprctl -j status .configProvider` — **pre-adopt baseline captured verbatim this session** (`"configProvider": "hyprlang"`). See §Code Examples "ADOPT-02 three-way proof" |
| **ADOPT-03** | After adopt, operator-verified: monitors/layout per disposition, shell chrome (`qs -c ii`) runs, and dual-run policy matches DISP-03 | The Phase 13 overlay's `hl.monitor` / `hl.workspace_rule` calls are confirmed present in Hyprland 0.56.2's own API stub, so `hyprctl workspacerules` and `hyprctl -j monitors all` are *behavioral* proof the overlay loaded, not just file-existence proof. **HDMI-A-2 is currently disconnected** — see §Common Pitfalls #3 |
| **ADOPT-04** | Rollback guidance exists that does **not** use upstream `./setup uninstall` | All three tiers already exist as shipped wrapper code — nothing to build. `uninstall --configs-only` / `--packages-only` and `protect --install-missing` are documented in the wrapper's own usage at `arch/dots-hyprland.sh:58-92`. See §Don't Hand-Roll |
</phase_requirements>

## Summary

Phase 14 is a **documentation-and-assertion phase wrapped around a human-executed mutation**. Almost nothing needs to be *built*: the full-install path (`--full`), the safe uninstall, and the `protect` subcommand all shipped in Phase 12 and earlier; the overlays and their `cp -a` apply fence shipped in Phase 13. What Phase 14 produces is (a) a runbook the operator reads at a bare TTY with no browser, (b) a non-mutating preflight script that mechanically proves the go conditions, (c) a post-adopt verify script that turns the four success criteria into exit codes, and (d) the two small prep mutations the agent *is* allowed to make — the D-07 live-to-repo `.config` sync and the `PROTECT_EXPLICIT` list edit.

The single highest-value discovery this session is that **every claim the plan needs to make about the running session is empirically checkable, and the pre-adopt baselines were captured verbatim**. `hyprctl -j status` on this machine right now returns `{"configProvider": "hyprlang", "backend": "drm"}` and `hyprctl eval 'return 1+1'` returns the error `eval is only supported with the lua config manager` — both of which invert after the Lua entry lands, giving D-33's third condition a real probe instead of an inference. Independently, `hl.monitor` and `hl.workspace_rule` — the only two API calls the Phase 13 overlay makes — are both declared in Hyprland 0.56.2's shipped LSP stub at `/usr/share/hypr/stubs/hl.meta.lua`, and every field the overlay passes (`output`, `mode`, `position`, `scale`, `transform`, `workspace`, `monitor`) is a declared field with a matching type. The largest silent-failure risk in the phase — "the overlay is syntactically fine but calls an API this Hyprland doesn't have" — is closed.

Three findings materially change the plan from what CONTEXT assumes. First, **the repo is currently dirty and 2 commits ahead of `origin/main`**, and one of the dirty entries (`.gsd/`) is untracked *and* not gitignored, so D-35's "`git status --porcelain` is empty" assert can never pass until prep resolves it. Second, **HDMI-A-2 is not connected** — `hyprctl monitors all` lists only DP-1 — so any verify assert that demands a two-head layout will fail for a reason unrelated to the adopt; the script must treat HDMI-A-2 as conditional. Third, **D-27's "preflight rotates the backup directory" makes preflight a mutating script**, which collides head-on with the `scripts/phase12-full-smoke.sh` precedent CONTEXT names as the pattern (whose own header reads "Non-mutating only"); the rotation needs to be an explicitly opt-in flag or a separate runbook step, not a side effect of running the checks.

**Primary recommendation:** Build two scripts on the `scripts/phase12-full-smoke.sh` shape — `scripts/phase14-preflight.sh` (pure checks, exit 0/1, plus an opt-in `--rotate-backup` mutation guarded by its own flag) and `scripts/phase14-verify.sh` (post-adopt asserts, run after first ii login) — plus `docs/phase14-adopt-runbook.md` as a single linear sequence with the go/no-go checklist and the three-tier rollback inline, pushed to GitHub before the window opens. Capture pre-adopt baselines into a committed fixture file during prep so the verify script can compare against recorded facts rather than re-deriving them from a machine that has already changed.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Process gate (ADOPT-01) | Human procedure (runbook go/no-go) | Repo tooling (preflight exit code) | D-18 explicitly makes the checklist the gate and the script one input; a script cannot assert "the operator has read the dispositions" |
| Mechanical precondition checks | Repo tooling (`scripts/phase14-preflight.sh`) | — | Same tier as `phase10-inventory-assert.sh` / `phase12-full-smoke.sh`; repo-local, no network, no sudo |
| Pre-adopt archive capture (D-03) | Repo git (`.config/` tree) | — | Phase 11 D-08 fixes the repo as archive/bootstrap SoT; live is not a backup location |
| Package install + file install | Upstream `./setup` (vendor submodule) | Wrapper flag composition | Established pattern — the wrapper composes flags, never reimplements install (`arch/dots-hyprland.sh:6-7`) |
| Session config authority post-adopt | Live `~/.config/hypr/hyprland.lua` (ii tree) | Live `~/.config/hypr/custom/` (personal overlay) | ADOPT-02; the require contract at `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua:25-27` is the hand-off point |
| Machine-specific layout | Repo `.config/hypr/custom/` (authoring SoT) | Live `custom/` (applied copy) | Phase 13 D-01/D-03 — one-way repo→live, no sync daemon |
| Package explicit-marking / cascade protection | Wrapper `protect_explicit_packages` | pacman | Already shipped; D-28 only edits the list |
| Rollback tier 1 (config restore) | Live filesystem (`hyprland.conf.old`, `~/ii-original-dots-backup/`) | Repo `.config/hypr/` archive | D-23.1; three independent restore sources |
| Rollback tiers 2–3 (packages) | Wrapper `uninstall` / `protect` subcommands | — | D-23.2/3; upstream `./setup uninstall` is forbidden (ADOPT-04) |
| Post-adopt verification | Repo tooling (`scripts/phase14-verify.sh`) | Human checklist in `14-LIVE-VERIFY.md` | D-29/D-30 — both required, neither alone |
| Adopt-window evidence capture | `script(1)` transcript | Phase directory (committed) | D-11/D-19 — the only record of a run the agent did not perform |

## Standard Stack

Phase 14 installs **no new packages**. Everything it needs is already on the machine and already in `PROTECT_EXPLICIT`. The "stack" here is the set of tools the two scripts and the runbook depend on.

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `bash` | 5.x (`#!/usr/bin/env bash`, `set -euo pipefail`) | Preflight + verify scripts | Every prior phase assert is bash or python; `scripts/phase12-full-smoke.sh:9` sets exactly this [VERIFIED: scripts/phase12-full-smoke.sh:1-9] |
| `hyprctl` | ships with Hyprland 0.56.2 | Running-session assertions (`status`, `monitors`, `workspacerules`, `eval`) | The only IPC into a live Hyprland; `/usr/bin/hyprctl` present [VERIFIED: `command -v hyprctl` → `/usr/bin/hyprctl`] |
| `jq` | present | Parse `hyprctl -j` JSON | Already in `PROTECT_EXPLICIT` (`arch/dots-hyprland.sh:254`); `/usr/bin/jq` present |
| `git` | 2.x | Submodule pin record (D-12), clean-tree assert (D-35) | Already required by the wrapper's own `preflight()` |
| `script` (util-linux) | 2.42.2 | TTY transcript (D-11) | `/usr/bin/script` present; `script from util-linux 2.42.2` [VERIFIED: `script --version`] |
| `rsync` | present | D-03 live→repo sync | Already in `PROTECT_EXPLICIT` (`arch/dots-hyprland.sh:274`) |
| `stow` | GNU Stow 2.4.1 | Post-install `stow -R kitty` (D-17) | `/usr/bin/stow` present [VERIFIED: `stow --version`] |
| `busctl` (systemd) | present | Screen-share portal probe (D-38) | Only non-interactive way to interrogate the ScreenCast portal |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `luac` | present (used by `scripts/phase13-d19-assert.sh`) | Syntax-check the applied `custom/*.lua` before relogin | Optional pre-relogin sanity gate after the D-08 overlay apply |
| `systemctl --user` | systemd | `graphical-session.target` state, `hyprland-session.service` presence | D-38 known-loss verification |
| `pgrep` / `pkill` | procps | Assert Waybar/rofi/swaync are not running (D-09) | Verify script only — never kill during verify |
| `sha256sum` / `cmp` | coreutils | D-36 backup-matches-pre-adopt, D-37 byte-identical hyprlock/hypridle | Compare against the prep-time baseline fixture |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `hyprctl -j status` for D-33 condition 3 | Infer from `test -f hyprland.lua` alone | Rejected — file existence proves the *install*, not that the *running session* loaded it. `--skip-hyprland-entry` and a stale session both defeat it. D-33 asks specifically for "hyprctl agrees" |
| Bash asserts | `bats` / `pytest` test framework | Rejected — no test framework exists in this repo; all six prior phase asserts are standalone scripts (`scripts/phase{02,03,04,07,10,11,12,13}-*`). Introducing one here is scope creep with zero payoff for an operator at a TTY |
| One combined `phase14-assert.sh` | Separate preflight and verify scripts | Recommended split — D-04 puts them in different plans separated by days, and preflight runs against a pre-adopt machine while verify runs against a post-adopt one. A single script would need a mode flag and would blur the go/no-go boundary |
| Recording the window with `asciinema` | `script(1)` | `script` is already installed, is what D-11 names, and produces a plain-text file that commits cleanly. `asciinema` is not installed |

**Installation:**

```bash
# Nothing to install. Confirm presence only:
command -v hyprctl jq git script rsync stow busctl luac
```

**Version verification:** No packages are added by this phase, so there is no registry lookup to perform. Versions above were read off this machine this session.

## Package Legitimacy Audit

**Not applicable — this phase installs no external packages.**

Phase 14's deliverables are two bash scripts, one markdown runbook, one markdown verification record, a `.config` sync commit, and a two-line deletion from an existing bash array. No `npm install`, `pip install`, `cargo add`, or `pacman -S` appears in any deliverable.

The operator-run `arch/dots-hyprland.sh install --full` *does* install packages, but:
- The package set is chosen by upstream `vendor/dots-hyprland`, pinned at submodule commit `1a9ffb78f0c272a45f82342587dc3bec72762233` [VERIFIED: `git -C vendor/dots-hyprland rev-parse HEAD`], not by this research or this plan.
- Upstream `./setup` remains the install SoT by explicit project decision (`REQUIREMENTS.md:77` — "Reimplement ii package install in `arch/` without `./setup`" is Out of Scope).
- The one package-adjacent artifact this phase touches, `PROTECT_EXPLICIT`, is a *deletion* of two already-installed packages (`waybar`, `swaync`) from a protection list. `protect_explicit_packages` "only ever *adds* `--asexplicit`" (D-28), so the edit cannot install or remove anything.

**Packages removed due to [SLOP] verdict:** none — no package recommendations made.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
                        ┌──────────────────────────────────────────┐
   PREP (plan 14-01)    │  agent — non-mutating + 2 allowed writes  │
   agent-executed       └──────────────────────────────────────────┘
                                          │
    ┌─────────────────────────────────────┼─────────────────────────────────────┐
    │                                     │                                     │
    ▼                                     ▼                                     ▼
┌────────────────┐              ┌──────────────────────┐            ┌────────────────────┐
│ D-03 live→repo │              │ D-28 PROTECT_EXPLICIT│            │ author runbook +   │
│ .config sync   │              │ drop waybar, swaync  │            │ preflight + verify │
│ EXCLUDE custom/│              │ (2-line delete)      │            │ scripts + baseline │
└───────┬────────┘              └──────────┬───────────┘            └─────────┬──────────┘
        │                                  │                                  │
        └──────────────┬───────────────────┴──────────────────────────────────┘
                       ▼
              ┌──────────────────┐        ┌───────────────────────────────────┐
              │ commit + PUSH    │───────▶│ GitHub — reachable from a phone   │
              │ (D-15, D-25)     │        │ if the desktop is dead            │
              └────────┬─────────┘        └───────────────────────────────────┘
                       │
═══════════════════════╪══════════ handoff boundary — agent stops here (D-01) ══════════
                       ▼
        ┌──────────────────────────────┐
        │ OPERATOR opens adopt window  │      ADOPT WINDOW (one gate, D-21)
        │ starts script(1) transcript  │
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐   FAIL / no-go
        │ ./scripts/phase14-preflight  │────────────────▶ ABORT, close window
        │ (INV/DISP artifacts, pin,    │                  no mutation occurred
        │  installed_true, backup dir, │
        │  clean+pushed tree, overlays)│
        └──────────────┬───────────────┘
                       │ exit 0  →  one input to the go/no-go checklist (D-18)
                       ▼
        ┌──────────────────────────────┐
        │ optional: --rotate-backup    │  mv ~/ii-original-dots-backup → .<ts>  (D-27)
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐
        │ exit Hyprland → BARE TTY     │  (D-06 — no compositor running)
        └──────────────┬───────────────┘
                       ▼
   ┌───────────────────────────────────────────────────────────────────────────┐
   │  ./arch/dots-hyprland.sh install --full                                    │
   │                                                                            │
   │   wrapper: preflight → refuse bare --skip-backup → backup_gate("yes")      │
   │            → NO SAFE_DEFAULTS injection → array-exec ./setup install       │
   │                                     │                                      │
   │   upstream ./setup stages:          ▼                                      │
   │     0 greeting  ── answer 'y' ──▶ keeps ask=true ──▶ backup is unconditional│
   │     1 deps      ── pacman -Syu may pull a kernel (D-10)                    │
   │     2 setups                                                               │
   │     3 files:  auto_update_git_submodule                                    │
   │               auto_backup_configs ──▶ ~/ii-original-dots-backup/           │
   │               misc  ──▶ dolphinrc, kdeglobals, kitty/, mpv/, starship.toml │
   │               quickshell ──▶ rsync --delete ~/.config/quickshell           │
   │               fish      ──▶ rsync --delete (excl conf.d)                   │
   │               fontconfig──▶ rsync --delete                                 │
   │               hypr:  rsync --delete hypr/hyprland/                         │
   │                      mv hyprland.conf → hyprland.conf.old   ◀── ADOPT-02   │
   │                      hyprlock.conf  ──▶ .new sidecar (not firstrun)        │
   │                      hyprland.lua   ──▶ INSTALLED            ◀── ADOPT-02  │
   │                      hypridle.conf  ──▶ .new sidecar (not firstrun)        │
   │                      custom/ ──▶ ignore_existing seed (7 files)            │
   │     4 post:   try hyprctl reload  ── harmless, no compositor (D-06)        │
   │                                     │                                      │
   │   wrapper post-setup: protect_explicit_packages → enable_hypr_ii_hooks     │
   └───────────────────────────────────┬───────────────────────────────────────┘
                       │ dies partway → capture, re-run same command (D-07)
                       ▼
        ┌──────────────────────────────┐
        │ D-08 overlay apply  cp -a    │  repo .config/hypr/custom/{general,env,execs}.lua
        │ (NEVER rsync --delete)       │  ──▶ live ~/.config/hypr/custom/
        │ BEFORE relogin               │  overwrites the 1-byte ii seeds; keeps
        └──────────────┬───────────────┘  keybinds.lua, rules.lua, variables.lua, scripts/
                       ▼
        ┌──────────────────────────────┐
        │ stow -R kitty  (D-17)        │
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐
        │ reboot (kernel, D-10)        │
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐
        │ TTY login → start-hyprland   │  (D-16 — no display manager on this box)
        └──────────────┬───────────────┘
                       ▼
   ┌───────────────────────────────────────────────────────────────────────────┐
   │  Hyprland reads ~/.config/hypr/hyprland.lua                                │
   │      require hyprland.{lib,services,env,execs,general,rules,colors,keybinds}│
   │      require custom.env → custom.execs → custom.general  ◀── the overlay   │
   │      hl.on("hyprland.start") ──▶ qs -c ii, hypridle, cliphist, easyeffects │
   └───────────────────────────────────┬───────────────────────────────────────┘
                       ▼
   ┌───────────────────────────────────────────────────────────────────────────┐
   │  ./scripts/phase14-verify.sh   (plan 14-02, may be days later)             │
   │    ADOPT-02: .old exists ∧ .lua exists ∧ hyprctl not-hyprlang ∧ eval works │
   │    ADOPT-03: monitors + workspacerules per overlay; qs -c ii running;      │
   │              waybar/rofi/swaync NOT running (DISP-03 → accept-remove)      │
   │    D-36: backup/.config/hypr/hyprland.conf newer + matches pre-adopt       │
   │    D-37: hyprlock 554B / hypridle 359B unchanged; .new sidecars present    │
   │    D-38: screen-share portal probe; known-loss list                        │
   │    D-35: git status --porcelain clean modulo phase artifacts               │
   └───────────────────────────────────┬───────────────────────────────────────┘
                       ▼
        ┌──────────────────────────────┐        no usable desktop after one
        │ 14-LIVE-VERIFY.md  (D-31)    │◀────── honest attempt (D-24)
        │ script output + findings     │            │
        └──────────────────────────────┘            ▼
                                        ┌──────────────────────────────────────┐
                                        │ ROLLBACK (D-23) — three tiers        │
                                        │  1  mv hyprland.conf.old back        │
                                        │     + ~/ii-original-dots-backup/     │
                                        │     + repo .config/hypr archive      │
                                        │  2  wrapper uninstall --configs-only │
                                        │     / --packages-only                │
                                        │  3  wrapper protect --install-missing│
                                        │  NEVER upstream ./setup uninstall    │
                                        └──────────────────────────────────────┘
```

### Recommended Project Structure

```
docs/
└── phase14-adopt-runbook.md          # operator-facing; pushed to GitHub (D-25)

scripts/
├── phase14-preflight.sh              # pre-adopt gate inputs; pure checks + opt-in --rotate-backup
└── phase14-verify.sh                 # post-adopt asserts; run after first ii login

.planning/phases/14-live-full-adopt-verify/
├── 14-PRE-ADOPT-BASELINE.md          # or .json — recorded facts verify compares against
├── 14-ADOPT-TRANSCRIPT.txt           # script(1) output (D-11), committed after the window
└── 14-LIVE-VERIFY.md                 # D-31 — script output + written findings

.config/hypr/                          # D-03 sync target (custom/ EXCLUDED)
arch/dots-hyprland.sh                  # D-28 two-line delete only
```

### Pattern 1: Non-mutating assert script with hard/soft split

**What:** A standalone bash script that emits `[PASS]`/`[FAIL]` lines, counts failures in a `FAIL` accumulator, and exits non-zero only on hard failures. Soft observations print `[INFO]`/`[WARN]` and never move the exit code.

**When to use:** Both Phase 14 scripts. It is the established repo pattern across six prior phases.

**Example:**

```bash
# Source: scripts/phase12-full-smoke.sh:9-17 (shipped, passing 2026-08-18)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
```

Phase 14 should extend this with a third level, because D-14 and D-38 both explicitly say a failure becomes a *recorded finding* rather than a phase blocker:

```bash
FINDINGS=0
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
```

The DP-1 scale (D-14) and screen share (D-38) route to `finding()`. Everything ADOPT-02 asserts routes to `fail()`.

### Pattern 2: Gate-fed dry-run capture

**What:** `printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run` — the pipe is mandatory, not decorative.

**Why:** `backup_gate` reads on stdin and `exit 1`s on anything but the exact token `yes`, *before* argv is assembled or printed. Without the pipe you capture nothing.

**Example:**

```bash
# Source: scripts/phase12-full-smoke.sh:63 (shipped precedent)
if printf 'yes\n' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1; then
  grep -q 'would exec' "$FULL_OUT" || fail "dry-run missing would-exec"
fi
```

### Pattern 3: Baseline-fixture comparison instead of live re-derivation

**What:** Prep records the pre-adopt facts into a committed file; verify compares against that file rather than trying to re-observe a machine that has already changed.

**Why:** D-36 ("backup matches the pre-adopt live conf") and D-37 ("byte-identical to their pre-install state") are both *impossible to check after the fact* unless the pre-install state was recorded first. After the install, live `hyprland.conf` no longer exists — it is `hyprland.conf.old` — and the only other copy is inside the backup you are trying to validate. Circular.

**Example:**

```bash
# In prep (14-01), before any mutation:
{
  printf 'hyprland_conf_sha256=%s\n' "$(sha256sum ~/.config/hypr/hyprland.conf | cut -d' ' -f1)"
  printf 'hyprlock_conf_sha256=%s\n' "$(sha256sum ~/.config/hypr/hyprlock.conf | cut -d' ' -f1)"
  printf 'hypridle_conf_sha256=%s\n' "$(sha256sum ~/.config/hypr/hypridle.conf | cut -d' ' -f1)"
  printf 'hyprlock_conf_bytes=%s\n'  "$(stat -c%s ~/.config/hypr/hyprlock.conf)"
  printf 'hypridle_conf_bytes=%s\n'  "$(stat -c%s ~/.config/hypr/hypridle.conf)"
  printf 'submodule_pin=%s\n'        "$(git -C vendor/dots-hyprland rev-parse HEAD)"
  printf 'configProvider_pre=%s\n'   "$(hyprctl -j status | jq -r .configProvider)"
} > .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt
```

### Pattern 4: One-way named-file overlay apply

**What:** `cp -a` of exactly `general.lua`, `env.lua`, `execs.lua`. Never `rsync --delete`.

**Why:** the ii seed at `install_dir__ignore_existing` also lands `keybinds.lua` (135 bytes), `rules.lua`, `variables.lua`, and `scripts/__restore_video_wallpaper.sh` (107 bytes). That last file is referenced from ii's own `execs.lua:7`, so a delete-sync would break ii's startup, not just lose a file.

The exact fence is already written and verified in `13-SOT-APPLY.md` — the plan must reference it, not rewrite it.

### Anti-Patterns to Avoid

- **Running the install from inside a live Hyprland session.** Stage 4 ends with `try hyprctl reload` after `hyprland.conf` was renamed away. With no compositor the call fails harmlessly; inside a session it reloads a config that no longer exists (D-06).
- **Answering `n` at the greeting or typing `yesforall` mid-install.** Both set `ask=false` (`0.greeting.sh:44`, `functions.sh:24`) *before* the backup runs in stage 4, which flips `auto_backup_configs` into the "only back up if the directory is absent" branch (`3.files.sh:15`). Since the directory exists, the backup silently does not happen. D-27's rotation is the countermeasure; answering `y`/`Y` at every prompt is the belt.
- **Using the word "chrome" anywhere in the runbook.** Live `hyprland.conf:96` autostarts `google-chrome-stable`. Write `Waybar/rofi/swaync` (D-39).
- **Asserting `test -f ~/.config/hypr/hyprland.lua` and calling ADOPT-02 done.** That proves the file installed, not that the session loaded it. See §Code Examples.
- **Making the preflight script mutate as a side effect.** See §Common Pitfalls #2.
- **Writing rollback tier 1 as "restore from `~/ii-original-dots-backup`" alone.** The backup is exactly what D-36 exists to distrust. Tier 1 has three independent sources for a reason; the runbook should order them `hyprland.conf.old` → repo archive → backup dir, cheapest and most-certain first.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Safe ii uninstall for rollback | A new uninstall script, or upstream `./setup uninstall` | `./arch/dots-hyprland.sh uninstall [--configs-only\|--packages-only]` | Already shipped. Removes only `illogical-impulse-*` with `pacman -R`, no `-s` cascade, no `yay -Rns`, no orphan sweep, and re-marks the protect list. Upstream's version uses `yay -Rns` on meta packages including `illogical-impulse-hyprland` and will cascade-delete `hyprland` itself [VERIFIED: arch/dots-hyprland.sh:58-70] |
| Restoring packages a bad orphan sweep deleted | A reinstall list | `./arch/dots-hyprland.sh protect --install-missing` | Already shipped; `pacman -S --needed` for every missing protect-list package, then re-marks explicit |
| Full-profile flag composition | Hand-typing `./setup install` with the right flags | `./arch/dots-hyprland.sh install --full` | Phase 12 encoded FULL-01..05 including the backup gate, the bare-`--skip-backup` refusal, and post-install protect + hook enable. Bypassing the wrapper loses all five |
| Backing up clashing configs | A custom pre-install `cp -a` sweep | Upstream `auto_backup_configs` + the D-27 rotation | Upstream's `backup_clashing_targets` already computes the clash set against `dots/.config` and uses `rsync -av` without `--delete`. Rotating the stale directory aside is a one-line `mv`; reimplementing the clash computation is not |
| Overlay apply | A fresh `cp`/`rsync` invocation | The fence already written at `13-SOT-APPLY.md` §"Apply command (D-18)" | It is version-controlled, D-19-verified, and its failure modes (missing `general.lua` → abort; missing slot → warn) are already decided |
| Proving the session came from Lua | Parsing `hyprland.lua` or grepping process args | `hyprctl -j status` + `hyprctl eval` | The compositor knows which config manager it loaded; ask it |
| TTY session recording | `tee` into a file plus manual timestamps | `script(1)` | Captures the interleaved prompt/response of upstream's `v()` confirmations, which `tee` on stdout alone would miss |
| Restoring the personal kitty config | Copying `stow/kitty/.config/kitty/kitty.conf` by hand | `stow -R kitty` | The repo file is never touched by upstream (`rsync -a --delete` replaces the symlink, not its target); re-stow is the whole fix |

**Key insight:** every mutating capability Phase 14 needs already exists as reviewed, shipped wrapper code. The phase's job is to *sequence and prove*, not to build. Any plan task that writes new mutation logic is almost certainly duplicating `arch/dots-hyprland.sh` and should be challenged.

## Runtime State Inventory

This is a migration/cutover phase. All five categories were probed on the live machine this session.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | `~/.config/illogical-impulse/installed_true` — 0 bytes, dated Aug 3 [VERIFIED: `ls -la ~/.config/illogical-impulse/`]. This is `FIRSTRUN_FILE` [VERIFIED: vendor/dots-hyprland/sdata/lib/environment-variables.sh:28-30 — `DOTS_CORE_CONFDIR="${XDG_CONFIG_HOME}/illogical-impulse"`, `FIRSTRUN_FILE="${DOTS_CORE_CONFDIR}/installed_true"`]. Its presence sets `INSTALL_FIRSTRUN=false` [VERIFIED: 3.files.sh:210-215]. • `~/.config/illogical-impulse/installed_listfile` — 73 758 bytes, Aug 3; upstream appends every installed path to it • `~/.config/quickshell/` — 6.1 M real tree, will be `rsync -a --delete`d [VERIFIED: 3.files-legacy.sh:26] | **No data migration.** Preflight hard-asserts `installed_true` exists (D-34) — this is the sole mechanism holding Phase 11 D-24. `installed_listfile` grows; not a concern. Do **not** sync `~/.config/quickshell` back to the repo — Phase 11 D-08 forbids it |
| **Live service config** | `hyprland-session.service` — a personal stow unit, currently `active` [VERIFIED: `systemctl --user is-active hyprland-session.service` → `active`], symlinked at `~/.config/systemd/user/hyprland-session.service → ../../../github_repo/.dotfiles/stow/systemd/.config/systemd/user/hyprland-session.service`. Started **only** from `hyprland.conf:57` (`exec-once = systemctl --user start hyprland-session.service`), which dies at the rename | **Code edit only — the unit file survives.** It lives under `stow/`, outside upstream's write set, and the symlink in `~/.config/systemd/user/` is untouched by the install. Only its *autostart* is lost. Recovery is one `systemctl --user start` or one line in `custom/execs.lua` (Phase 15, per D-38). The runbook's known-loss entry should say this explicitly so the operator does not think the unit was deleted |
| **OS-registered state** | `/usr/share/wayland-sessions/` holds `hyprland.desktop`, `hyprland-uwsm.desktop`, `plasma.desktop` [VERIFIED: `ls /usr/share/wayland-sessions/`], but **no display manager is in use** — the session starts from `/usr/bin/start-hyprland` at a TTY [VERIFIED: `command -v start-hyprland` → `/usr/bin/start-hyprland`]. No systemd timers, no cron, no `pm2` | **None.** Confirms D-16: upstream's "DO NOT SELECT UWSM" closing warning is inapplicable here. The runbook says "log in at a TTY and run `start-hyprland`" |
| **Secrets / env vars** | No SOPS, no `.env` under the affected trees. `ILLOGICAL_IMPULSE_VIRTUAL_ENV` is a hypr `env =` line, not a secret; present in the repo archive at `.config/hypr/hyprland.conf:111` [VERIFIED: grep] and in live `hyprland.conf`. Live also sets `QT_QPA_PLATFORMTHEME` (ii replaces `qt6ct` with `kde` per D-38) | **None.** `enable_hypr_ii_hooks` writes the env line into whichever `hyprland.conf` files exist; after the rename the live one is gone and the repo one already carries it (D-35) |
| **Build artifacts / installed packages** | `scripts/__pycache__/` holds three stale `.pyc` files for phase02/03/04 asserts [VERIFIED: `ls scripts/__pycache__`] — irrelevant to this phase and already gitignored via `__pycache__/`. Packages: `waybar`, `swaync`, `rofi`, `hyprpaper` all remain **installed**; only their autostart is removed. `linux 7.1.11.arch1-1` matches running kernel `7.1.11-arch1-1` [VERIFIED: `uname -r`, `pacman -Q linux`] | **None for artifacts.** For packages: D-28 removes `waybar` and `swaync` from `PROTECT_EXPLICIT` (they stay installed, just unprotected). `pacman -Syu` runs during `--full`; the local db currently reports 0 pending upgrades, but `--full` syncs first so a kernel may still land — D-10's reboot instruction stands regardless |

### Additional runtime facts that change the plan

**Upstream's write set against *this* machine's live `~/.config`.** Upstream's misc block iterates `dots/.config/` excluding `quickshell`, `fish`, `hypr`, `fontconfig` [VERIFIED: 3.files-legacy.sh:11]. Cross-referencing upstream's 18 misc entries against live, exactly **five collide**:

| Live path | Upstream op | Effect |
|-----------|-------------|--------|
| `~/.config/dolphinrc` (177 B, real file) | `install_file` → `cp -f` | overwritten |
| `~/.config/kdeglobals` (59 B, real file) | `install_file` → `cp -f` | overwritten |
| `~/.config/kitty/` (contains one stow symlink) | `install_dir__sync` → `rsync -a --delete` | symlink replaced; repo file safe; `stow -R kitty` restores (D-17) |
| `~/.config/mpv/` (**directory is empty**) | `install_dir__sync` | nothing personal to lose |
| `~/.config/starship.toml` (symlink → `stow/zsh/.config/starship.toml`) | `install_file` → `cp -f` | **follows the symlink and overwrites the repo file** — accepted loss (D-17) |

The other 13 upstream misc targets (`chrome-flags.conf`, `code-flags.conf`, `darklyrc`, `foot`, `fuzzel`, `kde-material-you-colors`, `konsolerc`, `Kvantum`, `matugen`, `thorium-flags.conf`, `wlogout`, `xdg-desktop-portal`, `zshrc.d`) are **absent** on live and land greenfield.

**The existing backup is provably stale and provably incomplete.** `~/ii-original-dots-backup/.config/` holds `fish`, `fontconfig`, `hypr`, `kdeglobals`, `kitty`, `mpv`, `starship.toml` [VERIFIED: `ls -la ~/ii-original-dots-backup/.config/`]. `quickshell` and `dolphinrc` are absent — exactly the two collisions that appeared after the backup was taken. Its `hypr/hyprland.conf` is 14 908 bytes dated Jul 23 20:58; live's is 15 301 bytes dated Aug 15 11:02. D-27's premise is confirmed on disk.

**The D-03 sync is much smaller than "sync all of `~/.config`".** Repo `.config/` contains only `hypr/` [VERIFIED: `find .config -maxdepth 3`]; every other personal config lives under `stow/`. Diffing repo `.config/hypr` against live yields exactly three deltas [VERIFIED: `diff -rq .config/hypr ~/.config/hypr`]:

```
Files .config/hypr/hyprland.conf and /home/pera/.config/hypr/hyprland.conf differ
Only in /home/pera/.config/hypr: hyprland.conf.bak
Only in /home/pera/.config/hypr: hyprland-gui.conf
```

Plus the live-only, repo-absent collisions worth archiving under D-07's intent: `dolphinrc` (177 B) and `kdeglobals` (59 B). `fontconfig/fonts.conf` is a single file; `mpv/` is empty. `quickshell/` must be excluded (Phase 11 D-08). The planner should scope D-03 to a concrete, enumerable file list rather than an open-ended `rsync ~/.config .config/`.

## Common Pitfalls

### Pitfall 1: D-35's clean-tree assert cannot pass today

**What goes wrong:** The verify script asserts `git status --porcelain` is empty apart from phase artifacts. Right now the tree has two modified tracked files and five untracked entries [VERIFIED: `git status --porcelain`]:

```
 M .planning/PROJECT.md
 M stow/zsh/.zshrc
?? .gsd/
?? .planning/phases/13-personal-hypr-custom-overlays/13-EDGE-COVERAGE.json
?? .planning/phases/13-personal-hypr-custom-overlays/13-PATTERNS.md
?? .planning/phases/13-personal-hypr-custom-overlays/13-RESEARCH.md
?? .planning/phases/13-personal-hypr-custom-overlays/COVERAGE.md
```

`.gsd/` is untracked **and not matched by any `.gitignore` rule** [VERIFIED: `cat .gitignore` — patterns are `.config/system_monitor/ping/data/`, `.config/system_monitor/ping/.env`, `.planning/tmp/`, `.claude/`, `.commandcode/`, `__pycache__/`, and five `stow/qbittorrent/…` paths]. It will show as dirty on every run forever.

**Why it happens:** D-35 was written against an assumed-clean tree.

**How to avoid:** Prep (14-01) must either add `.gsd/` to `.gitignore` or commit it, and must commit or discard the other six entries. Additionally the tree is **2 commits ahead of `origin/main`** [VERIFIED: `git rev-list --left-right --count origin/main...HEAD` → `0	2`], so D-15's "committed **and pushed**" needs an explicit `git push` task — a commit alone does not satisfy it, and D-25 depends on GitHub being current for phone-readable rollback.

**Warning signs:** preflight passing locally while the runbook on GitHub is a version behind.

### Pitfall 2: D-27 makes "preflight" a mutating script, contradicting the pattern it is modelled on

**What goes wrong:** D-13/D-27 say preflight rotates `~/ii-original-dots-backup` to a timestamped name. `scripts/phase12-full-smoke.sh`, which CONTEXT names as the pattern, opens with "Non-mutating only: help / `--dry-run` / refuse / syntax" [VERIFIED: scripts/phase12-full-smoke.sh:2]. A script that silently `mv`s 480 K of the operator's home directory is not that.

**Why it happens:** two decisions written at different moments, both individually sound.

**How to avoid:** split the concerns. `./scripts/phase14-preflight.sh` performs checks only and *reports* the backup directory's staleness as a `[FAIL]` with the exact remediation command. The rotation is either an explicit `--rotate-backup` flag on the same script or a numbered step in the runbook the operator runs by hand. Either satisfies D-13's "reports what it already contains" and D-27's rotation, without an agent-runnable script that mutates `$HOME` as a side effect of being run. This also keeps the script safe to run repeatedly during planning.

**Warning signs:** a plan task that runs the preflight script "to verify it works" and thereby rotates the backup days before the window.

### Pitfall 3: HDMI-A-2 is not connected — dual-head verification will fail for the wrong reason

**What goes wrong:** the Phase 13 overlay declares two monitors, but `hyprctl -j monitors all` right now returns exactly one entry [VERIFIED: `hyprctl -j monitors all`]:

```
DP-1 | Ancor Communications Inc ROG PG348Q #ASMQZZkZbYPd | 3440x1440@59.97300 scale=1 transform=0 at 0,0 disabled=false
```

`monitors all` lists active *and* inactive outputs, so HDMI-A-2 is not merely disabled — it is absent from the compositor's view entirely.

**Why it happens:** the second display is physically disconnected or powered off.

**How to avoid:** the verify script must treat HDMI-A-2 conditionally. Assert DP-1 unconditionally; for HDMI-A-2, emit `[INFO] HDMI-A-2 not present — dual-head assertion skipped` rather than `[FAIL]`. Separately, assert the *workspace rules* unconditionally — `hyprctl workspacerules` reports rules for monitors that are not attached (it already reports `monitor: DP-1` rules today), so all eleven rules are checkable regardless of what is plugged in. That makes the overlay's `hl.workspace_rule` calls provable even single-headed. The runbook should ask the operator to connect HDMI-A-2 before the verify step if they want the full check.

**Warning signs:** a verify run that reports a monitor failure the operator cannot reproduce by looking at the screen.

### Pitfall 4: The DP-1 scale question is narrower than it looks

**What goes wrong:** D-14 anticipates a wrong DP-1 scale after the overlay lands.

**Why it likely will not happen:** live `hyprland.conf:29` is `monitor=DP-1,preferred,auto,auto` and the current result is `scale=1` [VERIFIED: `hyprctl -j monitors`]. The overlay declares the identical intent [VERIFIED: .config/hypr/custom/general.lua:3-8 — `output = "DP-1"`, `mode = "preferred"`, `position = "auto"`, `scale = "auto"`]. Same inputs, same compositor version, so `scale=1` is the expected outcome.

**How to avoid:** record `scale=1` in the pre-adopt baseline fixture and have the verify script compare, routing any difference to `finding()` (not `fail()`) per D-14. Do not spend planning effort on a scale-correction path.

### Pitfall 5: `hyprpaper`'s autostart dies with the same line as Waybar and swaync

**What goes wrong:** `hyprland.conf:64` is a single line starting three daemons: `exec-once = waybar & swaync & hyprpaper &` [VERIFIED: `grep -n exec-once ~/.config/hypr/hyprland.conf`]. The rename removes all three, not two. `hyprpaper` stays in `PROTECT_EXPLICIT` per D-28, and `~/.config/hypr/hyprpaper.conf` (187 B) survives the install untouched — but nothing starts it.

**Why it matters:** ii's `execs.lua` starts no wallpaper daemon. It runs `$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh` and `qs -c $qsConfig` [VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua:5-7], so wallpaper becomes Quickshell's responsibility. D-38 already classifies wallpaper as "replaced by ii, not a loss" — that is correct, but the runbook should name `hyprpaper` in the known-loss list as *stopped-but-installed*, otherwise an operator who sees no `hyprpaper` process will read it as breakage.

**Warning signs:** operator reports "wallpaper daemon is gone" as a bug during verify.

### Pitfall 6: `rofi` has no `exec-once` at all

**What goes wrong:** D-09 frames Waybar/rofi/swaync teardown as one atomic event driven by the `exec-once` line. But `rofi` is not on that line — it is referenced at `hyprland.conf:41` as `$menu = rofi -show drun` and at `:278` in a cliphist keybind [VERIFIED: `grep -n rofi ~/.config/hypr/hyprland.conf`]. It has no autostart to remove.

**Why it matters:** the verify script's "none of the three is running" assert (D-09) is trivially true for `rofi` — it was never a daemon. The real change is that its *keybinds* vanish with the conf, and Phase 11 D-13 already decided to "rely on dots-hyprland defaults after chrome removal". The verify checklist should assert the *launcher keybind works* (human check) rather than the *rofi process is absent* (vacuous). D-28 already notes `rofi` was never in `PROTECT_EXPLICIT`.

### Pitfall 7: `~/.config/hypr/hyprland/scripts/launch_first_available.sh` is deleted by the hypr sync

**What goes wrong:** `install_dir__sync dots/.config/hypr/hyprland "$XDG_CONFIG_HOME"/hypr/hyprland` is `rsync -a --delete` [VERIFIED: 3.files-legacy.sh:50 and 3.files.sh:67-76]. Live `~/.config/hypr/hyprland/` contains exactly one personal file, `scripts/launch_first_available.sh` [VERIFIED: `find ~/.config/hypr/hyprland`], which will be deleted.

**Why it is fine:** the identical file is already tracked in the repo at `.config/hypr/hyprland/scripts/launch_first_available.sh` (353 B) and `diff -rq` reports no difference [VERIFIED]. Phase 11 D-18 already dispositioned this `accept-upstream` on the strength of that. No action needed — but the runbook's known-loss list should name it so it is not rediscovered as a surprise during verify.

### Pitfall 8: `hyprctl reload` after the install would be actively harmful, and CONTEXT's line reference for the rename is off by two

**What goes wrong:** two small accuracy issues that the plan will inherit if copied verbatim.

- D-06's reasoning is sound but the rename is at `3.files-legacy.sh:52`, not `:50`. Line 50 is `install_dir__sync dots/.config/hypr/hyprland …`; line 52 is `mv "${XDG_CONFIG_HOME}/hypr/hyprland.conf" "${XDG_CONFIG_HOME}/hypr/hyprland.conf.old"` [VERIFIED: `cat -n vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh`]. Same for D-09's citation.
- Both `3.files.sh:12` (`function auto_backup_configs(){`) and `3.files.sh:219` (`if [[ ! "${SKIP_BACKUP}" == true ]]; then auto_backup_configs; fi`) are correct as cited [VERIFIED: grep -n].

**How to avoid:** the plan should cite `3.files-legacy.sh:52` for the rename. Any grep-based source-grounding check the plan-reviewer runs will otherwise flag it.

## Code Examples

### ADOPT-02 three-way proof (D-33)

Conditions 1 and 2 are file existence. Condition 3 — "hyprctl agrees the running session came from the Lua entry" — has two independent probes, both with a pre-adopt baseline captured verbatim this session.

```bash
# --- Condition 1 & 2 -------------------------------------------------------
test -f "$HOME/.config/hypr/hyprland.conf.old" \
  || fail "ADOPT-02: hyprland.conf.old missing (rename did not happen)"
test -f "$HOME/.config/hypr/hyprland.lua" \
  || fail "ADOPT-02: hyprland.lua missing (--skip-hyprland-entry leaked?)"
test ! -f "$HOME/.config/hypr/hyprland.conf" \
  || fail "ADOPT-02: hyprland.conf still present — .conf would win over .lua"

# --- Condition 3a: the compositor names its own config provider -------------
# PRE-ADOPT BASELINE captured 2026-09-04 on this machine, verbatim:
#   $ hyprctl -j status
#   {
#       "configProvider": "hyprlang",
#       "backend": "drm"
#   }
provider="$(hyprctl -j status | jq -r '.configProvider')"
if [[ "$provider" == "hyprlang" ]]; then
  fail "ADOPT-02: configProvider is still 'hyprlang' — session did not load the Lua entry"
else
  pass "ADOPT-02: configProvider is '$provider' (not hyprlang)"
fi

# --- Condition 3b: the Lua REPL is only available under the Lua manager -----
# PRE-ADOPT BASELINE captured 2026-09-04, verbatim:
#   $ hyprctl eval 'return 1+1'
#   eval is only supported with the lua config manager
eval_out="$(hyprctl eval 'return 1+1' 2>&1)"
if [[ "$eval_out" == *"only supported with the lua config manager"* ]]; then
  fail "ADOPT-02: hyprctl eval refused — session is not under the Lua config manager"
else
  pass "ADOPT-02: hyprctl eval accepted ('$eval_out')"
fi
```

The `!= "hyprlang"` form is deliberate: the *pre-adopt* value is a directly observed fact, whereas the post-adopt token is not observable from a pre-adopt machine. Asserting the absence of the known-bad value is fully grounded; asserting the presence of a guessed-good value is not. Probe 3b is a second, independent signal that does not depend on any token at all.

### ADOPT-03: prove the overlay actually loaded, not just that it was copied

```bash
# Monitors — DP-1 unconditional; HDMI-A-2 conditional (see Pitfall 3).
hyprctl -j monitors all | jq -e '.[] | select(.name=="DP-1")' >/dev/null \
  && pass "ADOPT-03: DP-1 present" || fail "ADOPT-03: DP-1 missing"

if hyprctl -j monitors all | jq -e '.[] | select(.name=="HDMI-A-2")' >/dev/null; then
  hyprctl -j monitors all \
    | jq -e '.[] | select(.name=="HDMI-A-2") | (.scale==1.5 and .transform==1)' >/dev/null \
    && pass "ADOPT-03: HDMI-A-2 scale 1.5 transform 1 per overlay" \
    || finding "ADOPT-03: HDMI-A-2 present but scale/transform differ from overlay"
else
  printf '[INFO] HDMI-A-2 not attached — dual-head assertion skipped\n'
fi

# DP-1 scale: D-14 says record, do not block.
dp1_scale="$(hyprctl -j monitors all | jq -r '.[] | select(.name=="DP-1") | .scale')"
# Pre-adopt baseline captured 2026-09-04: DP-1 3440x1440@59.973 scale=1 transform=0 at 0,0
[[ "$dp1_scale" == "1" || "$dp1_scale" == "1.0" ]] \
  && pass "ADOPT-03: DP-1 scale unchanged at $dp1_scale" \
  || finding "ADOPT-03: DP-1 scale is $dp1_scale (pre-adopt was 1) — D-14, record and defer"

# Workspace rules — checkable even single-headed. Eleven rules, verbatim from the overlay.
rules="$(hyprctl workspacerules)"
for ws in 1 2 3 4 5 special:social; do
  grep -q "Workspace rule ${ws}:" <<<"$rules" || fail "ADOPT-03: workspace rule $ws missing"
done
for ws in 6 7 8 9 10; do
  grep -q "Workspace rule ${ws}:" <<<"$rules" || fail "ADOPT-03: workspace rule $ws missing"
done

# Shell chrome runs; dual-run policy is accept-remove (DISP-03 overridden by Phase 11 D-11).
pgrep -f 'qs -c ii' >/dev/null && pass "ADOPT-03: qs -c ii running" \
                               || fail "ADOPT-03: qs -c ii not running"
for p in waybar swaync; do
  pgrep -x "$p" >/dev/null && fail "ADOPT-03: $p still running (dual-run policy is accept-remove)" \
                           || pass "ADOPT-03: $p not running"
done
# rofi was never a daemon (Pitfall 6) — assert absence for completeness only.
pgrep -x rofi >/dev/null && finding "rofi process found (unexpected — it has no exec-once)" \
                         || pass "ADOPT-03: rofi not running"
```

### D-37: hyprlock / hypridle untouched, sidecars unpromoted

```bash
# Pre-adopt sizes VERIFIED on disk 2026-09-04:
#   -rw-r--r-- 1 pera pera 554 Aug  5 02:07 /home/pera/.config/hypr/hyprlock.conf
#   -rw-r--r-- 1 pera pera 359 Aug  5 02:07 /home/pera/.config/hypr/hypridle.conf
[[ "$(stat -c%s "$HOME/.config/hypr/hyprlock.conf")" == 554 ]] \
  || fail "D-37: hyprlock.conf is no longer 554 bytes — firstrun path fired?"
[[ "$(stat -c%s "$HOME/.config/hypr/hypridle.conf")" == 359 ]] \
  || fail "D-37: hypridle.conf is no longer 359 bytes — firstrun path fired?"
# ...and compare sha256 against 14-PRE-ADOPT-BASELINE.txt for byte-identity.
test -f "$HOME/.config/hypr/hyprlock.conf.new" || fail "D-37: hyprlock.conf.new sidecar missing"
test -f "$HOME/.config/hypr/hypridle.conf.new" || fail "D-37: hypridle.conf.new sidecar missing"
```

Why sidecars rather than replacement: `install_file__auto_backup` branches on `INSTALL_FIRSTRUN`; the not-firstrun branch is `v cp_file $s $t.new` [VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:102-121]. `INSTALL_FIRSTRUN` is false because `FIRSTRUN_FILE` exists [VERIFIED: 3.files.sh:210-215]. `-F`/`--firstrun` forces it true [VERIFIED: options.sh:75] — hence D-22's ban.

### D-38: non-interactive screen-share probe

Baselines captured pre-adopt this session, verbatim:

```bash
#   $ systemctl --user is-active graphical-session.target
#   active
#   $ busctl --user get-property org.freedesktop.portal.Desktop \
#       /org/freedesktop/portal/desktop org.freedesktop.portal.ScreenCast version
#   u 6
#   $ busctl --user get-property org.freedesktop.portal.Desktop \
#       /org/freedesktop/portal/desktop org.freedesktop.portal.ScreenCast AvailableSourceTypes
#   u 7

systemctl --user is-active graphical-session.target >/dev/null \
  && pass "D-38: graphical-session.target active" \
  || finding "D-38: graphical-session.target inactive — hyprland-session.service autostart lost (expected); screen share likely broken. Phase 15 item."

if busctl --user get-property org.freedesktop.portal.Desktop \
     /org/freedesktop/portal/desktop org.freedesktop.portal.ScreenCast \
     AvailableSourceTypes 2>/dev/null | grep -q '^u '; then
  pass "D-38: ScreenCast portal answers AvailableSourceTypes"
else
  finding "D-38: ScreenCast portal not answering — screen share broken. Record, defer to Phase 15."
fi
```

Both route to `finding()`, never `fail()` — D-38 says a broken screen share "becomes a recorded finding and a Phase 15 item, the same treatment as the DP-1 scale in D-14".

### D-05: the gate-fed dry-run, verified working

```bash
printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run
```

This is the shipped, passing form at `scripts/phase12-full-smoke.sh:63`. Without the pipe, `backup_gate` (`arch/dots-hyprland.sh:166-192`) reads on stdin, sees a non-`yes` answer, prints `[FAIL] Aborted (backup gate). No ./setup invoked.` and exits 1 before any argv is assembled.

### The D-08 overlay apply — reference, do not rewrite

The exact fence lives at `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` §"Apply command (D-18)": `cp -a` of `general.lua` (abort if missing), then `env.lua` and `execs.lua` (warn and continue if missing). Never `rsync --delete`.

Post-apply sanity gate before relogin, worth adding to the runbook:

```bash
luac -p ~/.config/hypr/custom/*.lua && echo "custom/*.lua parse OK"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `hyprland.conf` (hyprlang) as the only session config | `hyprland.lua` with a typed `hl` API | Hyprland 0.55 [CITED: https://wiki.hypr.land/Configuring/Start/] | This whole phase. `hl.monitor` / `hl.workspace_rule` are the Phase 13 overlay's entire surface |
| hyprlang supported indefinitely | Hyprland's own binary emits `You are using the .conf config format, support for which will be removed in Hyprland 0.57.` | 0.56 [VERIFIED: `strings /usr/bin/Hyprland`] | The adopt is not merely a preference change — the `.conf` format has a stated removal version one minor release away |
| Guessing the Lua API surface | A generated LSP stub ships at `/usr/share/hypr/stubs/hl.meta.lua` (67 113 bytes) | 0.55+ [CITED: https://wiki.hypr.land/Configuring/Start/; VERIFIED: `ls -la /usr/share/hypr/stubs/`] | Every overlay field is checkable against the installed compositor's own type declarations, offline |
| Config-format detection by inspection | `hyprctl status` reports `configProvider`, and `hyprctl eval`/`repl` exist only under the Lua manager | 0.55+ | Gives ADOPT-02 a real runtime probe |

**Deprecated / outdated:**
- **hyprlang `.conf` format**: slated for removal in Hyprland 0.57 per the binary's own warning. Live is on 0.56.2 [VERIFIED: `hyprctl -j version` → `"version": "0.56.2"`, `"tag": "v0.56.2"`], so the runway is short. This strengthens the case for adopting now rather than deferring.
- **Personal `hyprland.conf` as session entry**: after this phase it is an archive and a rollback source only. Phase 11 D-15 and the CONTEXT integration note both say its `qs -c ii` and `ILLOGICAL_IMPULSE_VIRTUAL_ENV` hook lines become vestigial — feeding OVL-03/DOC-04 in Phase 15.

### The Phase 13 overlay validates against Hyprland 0.56.2's own type declarations

This is the strongest single de-risking result of this research. Every call and field the overlay uses is declared in the installed stub.

`HL.MonitorSpec` [VERIFIED: /usr/share/hypr/stubs/hl.meta.lua:571-595] declares, verbatim:

```
---@class HL.MonitorSpec
---@field mode? string
---@field output string
---@field position? string
---@field scale? string|number
---@field transform? integer|boolean
```

`HL.WorkspaceRuleSpec` [VERIFIED: /usr/share/hypr/stubs/hl.meta.lua:603-622] declares, verbatim:

```
---@class HL.WorkspaceRuleSpec
---@field monitor? string
---@field workspace string
```

And the two functions themselves [VERIFIED: /usr/share/hypr/stubs/hl.meta.lua:856,863], verbatim:

```
---@field monitor fun(spec: HL.MonitorSpec): nil
---@field workspace_rule fun(spec: HL.WorkspaceRuleSpec): HL.WorkspaceRule
```

Against the overlay [VERIFIED: .config/hypr/custom/general.lua:3-15,17-27], which uses `output = "DP-1"` / `mode = "preferred"` / `position = "auto"` / `scale = "auto"` for DP-1, `output = "HDMI-A-2"` / `scale = 1.5` / `transform = 1` for HDMI-A-2, and `hl.workspace_rule({ workspace = "1", monitor = "DP-1" })` through `workspace = "10"` plus `workspace = "special:social"`: every field name matches, `scale` accepts both the string `"auto"` and the number `1.5` per `string|number`, and `transform = 1` matches `integer|boolean`. Required fields (`output`, `workspace`) are always supplied.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The post-adopt value of `hyprctl -j status .configProvider` is `"lua"` | Code Examples | Low — this is precisely why the recommended assert is `!= "hyprlang"` plus the independent `hyprctl eval` probe, neither of which depends on the token. If a plan hard-codes `== "lua"` and the real token differs, the verify script fails spuriously. **The planner should not hard-code the positive token.** |
| A2 | Hyprland 0.56.2 prefers `.conf` over `.lua` when both exist (CONTEXT D-09's stated mechanism) | Open Questions | Low operationally — upstream renames the conf regardless, so the outcome is identical either way. But the runbook should not assert the preference direction as fact. See Open Question 1 |
| A3 | `pacman -Syu` during the deps stage will not pull a kernel | Runtime State Inventory | Low — the local db shows 0 pending upgrades right now, but `--full` syncs the db first, so a kernel can still land. D-10's "reboot before first ii login" instruction makes this moot; the plan should keep the reboot unconditional rather than conditioning it on a kernel upgrade |
| A4 | `install_dir__sync` on `~/.config/kitty/` leaves upstream a 1050-byte `kitty.conf` plus `search.py` and `scroll_mark.py` (D-17's byte count) | User Constraints (D-17) | Very low — the byte count is not load-bearing; `stow -R kitty` restores regardless of what upstream wrote. Not re-verified this session |
| A5 | The operator has physical access to a TTY and can reach GitHub from a phone during the window (D-25's premise) | Architecture | Medium — if the desktop dies and GitHub is unreachable, the rollback steps are unreadable. Mitigation the planner may want: have the runbook also written to a plain file on disk outside `~/.config`, e.g. `~/phase14-rollback.txt`, as a belt to D-25's braces |
| A6 | `~/.config/mpv/` being empty means nothing personal is lost there | Runtime State Inventory | Very low — `find ~/.config/mpv -type f` returned nothing this session |

## Open Questions

1. **Does Hyprland 0.56.2 prefer `hyprland.conf` or `hyprland.lua` when both are present?**
   - What we know: CONTEXT D-09 asserts `.conf` wins, which is why upstream renames it. Upstream's own code agrees — the rename is commented `# disable old config` and echoes `hyprland.conf has been renamed to hyprland.conf.old. This is to allow the new lua config to load.` [VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh:52-53]. The official wiki states the opposite: "If you don't have a `hyprland.lua` config file, your old `hyprland.conf` will be loaded, but if you do have one, `hyprland.lua` will be loaded instead" [CITED: https://wiki.hypr.land/Configuring/Start/].
   - What's unclear: which is true on 0.56.2 specifically. This machine has a `.conf` and no `.lua`, so the ambiguity is not resolvable here without mutating live — which D-01/D-17 forbid.
   - Recommendation: **it does not matter operationally.** Upstream renames the conf either way, so the Lua entry becomes authoritative under both readings. The plan should (a) not state a preference direction in the runbook, and (b) keep the verify assert `test ! -f ~/.config/hypr/hyprland.conf` — which is correct under both readings and catches a failed rename directly.

2. **Should the D-03 sync capture `dolphinrc` and `kdeglobals`, or only the hypr tree?**
   - What we know: Phase 11 D-07 says "sync live `~/.config` PRESENT personal configs into repo `.config/` so nothing personal exists only on live". Repo `.config/` currently holds only `hypr/`. `dolphinrc` (177 B) and `kdeglobals` (59 B) are live-only, are in upstream's write set, and will be overwritten [VERIFIED: `ls -la ~/.config/dolphinrc ~/.config/kdeglobals`; 3.files-legacy.sh:11-16]. Both are trivially small and their contents were read this session.
   - What's unclear: whether they count as "personal config" worth archiving, or as machine cruft. `kdeglobals` is `[KDE] widgetStyle=Breeze` / `[General] ColorScheme=BreezeDark`; `dolphinrc` is view-state plus `MenuBar=Disabled`.
   - Recommendation: capture both. They are 236 bytes combined, they satisfy D-07's literal wording, and D-38 already flags `QT_QPA_PLATFORMTHEME` theming as changing — having the pre-adopt theme settings archived costs nothing and makes tier-1 rollback more complete.

3. **How much of the `script(1)` transcript should be committed?**
   - What we know: D-11 says the transcript lands in the phase directory; D-19 says the go decision is recorded in it. A full `--full` install transcript with `ask=true` (every `v()` prompt confirmed individually) will be large and full of ANSI escapes.
   - What's unclear: raw or filtered.
   - Recommendation: commit the raw file, and have `14-LIVE-VERIFY.md` quote the load-bearing excerpts (the go decision, the backup confirmation, the rename echo, any failure). Do not use `--log-in`/`--log-io` — the man page warns those "may record security-sensitive information as the log file contains all terminal session input (e.g., passwords)" and the install runs `sudo pacman` [CITED: `man script`, util-linux 2.42.2]. Output-only is both smaller and safer.

4. **Does the operator want HDMI-A-2 connected for the verify step?**
   - What we know: it is currently not attached (Pitfall 3), so the dual-head half of ADOPT-03 is unverifiable as things stand.
   - Recommendation: the runbook asks the operator to connect it before verify; the script degrades gracefully if they do not, and `14-LIVE-VERIFY.md` records which mode the verification ran in. Do not block D-32's success bar on it.

## Environment Availability

All probes run on the live machine 2026-09-04.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `hyprctl` | ADOPT-02/03 asserts | ✓ | `/usr/bin/hyprctl`, Hyprland 0.56.2 | — |
| `Hyprland` | the session itself | ✓ | 0.56.2, tag `v0.56.2`, commit `efb5099…` | — |
| `qs` / `quickshell` | ADOPT-03 shell chrome | ✓ | `/usr/bin/qs`, `/usr/bin/quickshell` | — |
| `jq` | JSON asserts | ✓ | `/usr/bin/jq` | fall back to `grep` on non-`-j` output |
| `git` | D-12 pin, D-35 clean tree | ✓ | `/usr/bin/git` | — |
| `script` | D-11 transcript | ✓ | util-linux 2.42.2 | `tee` (loses prompt interleaving) |
| `stow` | D-17 kitty re-stow | ✓ | GNU Stow 2.4.1 | manual `ln -s` |
| `rsync` | D-03 sync, upstream install | ✓ | `/usr/bin/rsync` | — |
| `busctl` | D-38 screen-share probe | ✓ | systemd | `systemctl --user is-active graphical-session.target` alone |
| `luac` | optional post-apply Lua syntax gate | ✓ | used by `scripts/phase13-d19-assert.sh` | skip the gate |
| `pacman` / `yay` | upstream deps stage | ✓ | `/usr/bin/pacman`, `/usr/bin/yay` | — |
| `start-hyprland` | D-16 TTY login | ✓ | `/usr/bin/start-hyprland` (289 072 B) | a `wayland-sessions` entry via a DM — not in use here |
| `vendor/dots-hyprland` submodule | the install | ✓ clean | pin `1a9ffb78f0c272a45f82342587dc3bec72762233`; nested `shapes` submodule at `e31ec4c…`, clean | — |
| `~/.config/illogical-impulse/installed_true` | D-34 not-firstrun gate | ✓ | 0 bytes, Aug 3 | **none — this is a hard preflight failure if absent** |
| `~/ii-original-dots-backup/` | D-13/D-27 | ✓ present, **stale** | 480 K; `.config/{fish,fontconfig,hypr,kdeglobals,kitty,mpv,starship.toml}` + `.local/share`; missing `quickshell`, `dolphinrc` | rotate aside (D-27) |
| HDMI-A-2 display | ADOPT-03 dual-head | ✗ | not listed by `hyprctl monitors all` | verify single-headed; record the mode |
| Clean+pushed git tree | D-15, D-25, D-35 | ✗ | 2 modified, 5 untracked; 2 commits ahead of `origin/main` | **none — prep must fix before the window** |

**Missing dependencies with no fallback:**
- Clean, pushed working tree (D-15/D-25/D-35). `.gsd/` is untracked and unignored; prep must gitignore or commit it, then `git push`.

**Missing dependencies with fallback:**
- HDMI-A-2 — verify degrades to single-head with an `[INFO]` line and the workspace-rule assertions still run in full.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Inline bash asserts — no `bats`/`pytest` suite in this repo (Phase 6/12/13 pattern) |
| Config file | none — plan-task `<verify><automated>` blocks plus two standalone scripts |
| Quick run command | `bash -n scripts/phase14-preflight.sh && bash -n scripts/phase14-verify.sh && bash -n arch/dots-hyprland.sh` |
| Full suite command (14-01, pre-adopt) | `./scripts/phase14-preflight.sh` |
| Full suite command (14-02, post-adopt) | `./scripts/phase14-verify.sh` |
| Regression guard | `./scripts/phase12-full-smoke.sh` — must stay `FAIL=0` after the D-28 `PROTECT_EXPLICIT` edit |
| Estimated runtime | preflight ~2–5 s; verify ~3–8 s |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-01 | INV-*/DISP-* artifacts present; submodule pin recorded and clean; `installed_true` present; tree clean and pushed; overlays present | smoke | `./scripts/phase14-preflight.sh` | ❌ Wave 0 |
| ADOPT-01 | Runbook exists with a single unambiguous go/no-go sequence and the four banned flags named | smoke | `grep -c . docs/phase14-adopt-runbook.md` + greps for `--force`, `--skip-backup`, `--firstrun`, `--skip-hyprland-entry` | ❌ Wave 0 |
| ADOPT-02 | `hyprland.conf.old` exists ∧ `hyprland.lua` exists ∧ `hyprland.conf` gone ∧ `configProvider != hyprlang` ∧ `hyprctl eval` accepted | smoke | `./scripts/phase14-verify.sh` (ADOPT-02 block) | ❌ Wave 0 |
| ADOPT-03 | DP-1 present at pre-adopt scale; 11 workspace rules per overlay; `qs -c ii` running; `waybar`/`swaync` not running | smoke | `./scripts/phase14-verify.sh` (ADOPT-03 block) | ❌ Wave 0 |
| ADOPT-03 | Monitors/layout look right on screen; launcher keybind works | manual-only | human checklist in `14-LIVE-VERIFY.md` — no non-visual proxy for "the layout looks right" | ❌ Wave 0 |
| ADOPT-04 | Rollback section exists, names all three tiers, and contains **no** `setup uninstall` string | smoke | `grep -q 'uninstall --configs-only' docs/phase14-adopt-runbook.md && ! grep -qE '(\./)?setup uninstall' docs/phase14-adopt-runbook.md` | ❌ Wave 0 |
| ADOPT-04 | Rollback **inputs** exist (D-26 — inputs, not a restore dry-run) | smoke | `./scripts/phase14-verify.sh`: `test -f ~/.config/hypr/hyprland.conf.old`; backup dir non-empty and newer than install start (D-36); repo `.config/hypr/hyprland.conf` present; wrapper `uninstall --dry-run` and `protect --dry-run` both exit 0 | ❌ Wave 0 |
| D-28 regression | `waybar`/`swaync` gone from `PROTECT_EXPLICIT`; `hyprpaper` retained; Phase 12 smoke still green | smoke | `! grep -qE '^  (waybar\|swaync)$' arch/dots-hyprland.sh && grep -qE '^  hyprpaper$' arch/dots-hyprland.sh && ./scripts/phase12-full-smoke.sh` | ✅ (smoke exists) |
| D-03 regression | Sync did not touch `.config/hypr/custom/` | smoke | `git diff --name-only HEAD~1 -- .config/hypr/custom` returns empty, plus the `13-SOT-APPLY.md` D-19 fence via `./scripts/phase13-d19-assert.sh` | ✅ (D-19 assert exists) |

### Sampling Rate

- **Per task commit (14-01):** `bash -n` on every script touched, plus that task's `<verify><automated>` block.
- **Per wave merge (14-01):** `./scripts/phase14-preflight.sh` in check-only mode **and** `./scripts/phase12-full-smoke.sh` (guards the D-28 edit) **and** `./scripts/phase13-d19-assert.sh` (guards the D-03 sync).
- **Adopt window:** the preflight exit code is one input to the human go/no-go (D-18); the window itself produces the `script(1)` transcript, not test output.
- **Per task commit (14-02):** re-run `./scripts/phase14-verify.sh` and append output to `14-LIVE-VERIFY.md`.
- **Phase gate:** `phase14-verify.sh` exits 0 (findings allowed, hard failures not) before `/gsd-verify-work`.
- **Max feedback latency:** under 10 seconds for every automated command.

### Wave 0 Gaps

- [ ] `scripts/phase14-preflight.sh` — covers ADOPT-01, ADOPT-04 (input existence)
- [ ] `scripts/phase14-verify.sh` — covers ADOPT-02, ADOPT-03, ADOPT-04 (D-26/D-36), D-35, D-37, D-38
- [ ] `docs/phase14-adopt-runbook.md` — covers ADOPT-01 (the gate itself), ADOPT-04 (D-23/D-25)
- [ ] `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` — **must be written before any mutation**; without it D-36 and D-37 are unprovable (see Pattern 3)
- [ ] `.gitignore` entry for `.gsd/` (or a commit of it) — without this, D-35's clean-tree assert can never pass
- [ ] No framework install needed

## Security Domain

ASVS L1, `security_block_on: high`, grep-depth — matching the Phase 13 precedent.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface. Note only: after adopt, Quickshell becomes the polkit agent via `Quickshell.Services.Polkit` + `PolkitAgent` [VERIFIED: vendor/dots-hyprland/dots/.config/quickshell/ii/services/PolkitService.qml:6,43], replacing `/usr/lib/polkit-kde-authentication-agent-1` from `hyprland.conf:61`. If it fails, `sudo` at a TTY still works — not a lockout |
| V3 Session Management | no | Desktop session, not a web session |
| V4 Access Control | yes (narrow) | The agent must not run mutating installs (D-01). Enforced by plan structure, not code: every mutating command lives in the runbook as an operator step |
| V5 Input Validation | yes | Both scripts take no untrusted input. `set -euo pipefail`, quote every expansion, no `eval`, no unquoted `$(…)` in a destructive position |
| V6 Cryptography | no | `sha256sum` is used for file-identity comparison only, not as a security control |
| V12 File & Resource | yes | The D-27 rotation and the D-03 sync both touch real paths under `$HOME` and the repo. Absolute, literal paths only; never a computed path in an `rm`/`--delete` position |
| V14 Configuration | yes | The D-28 edit changes a security-relevant list (cascade protection). Guarded by `./scripts/phase12-full-smoke.sh` staying green |

### Known Threat Patterns for bash + live-system cutover

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Preflight rotates the backup as a side effect, days before the window, leaving no backup when the install runs | Denial of service | Pitfall 2 — rotation behind an explicit `--rotate-backup` flag or a runbook step; never implicit |
| `rsync --delete` or `rm -rf` on a computed path that expands empty | Denial of service | Literal absolute paths; `set -u`; the D-08 apply stays `cp -a` on named files (Phase 13 `T-rsync-delete`, already closed) |
| Agent invocation runs the real `install --full` | Tampering | D-01/D-05 — only the `--dry-run` form appears in any agent-runnable artifact. Assert: no plan task's command contains `install --full` without `--dry-run` |
| Runbook rollback text drifts to upstream `./setup uninstall`, which cascades via `yay -Rns` and can delete `hyprland` itself | Denial of service | ADOPT-04 + a literal negative grep in the verify suite: `! grep -qE '(\./)?setup uninstall' docs/phase14-adopt-runbook.md` |
| `ask=false` (greeting `n`, `-f`, or `yesforall`) silently skips the backup because the directory already exists | Denial of service | D-27 rotation makes both branches back up; D-22 bans `-f`; the runbook instructs `y` at the greeting and forbids `yesforall` |
| `-F`/`--firstrun` replaces live `hyprlock.conf`/`hypridle.conf` instead of writing `.new` sidecars | Tampering | D-22 ban + D-34 `installed_true` preflight assert + the D-37 byte-size assert as the detector |
| `--skip-hyprland-entry` skips `hyprland.lua`, silently defeating ADOPT-02 | Tampering | D-22 ban + the ADOPT-02 three-way proof catches it after the fact |
| `script(1)` transcript captures a sudo password | Information disclosure | Output-only logging; never `--log-in`/`--log-io` [CITED: `man script`] |
| Committed transcript leaks host paths or tokens | Information disclosure | Review the transcript before committing; it is a `~`-scoped install log, but the review step belongs in the plan |
| Supply chain (npm/pip/cargo) | Tampering | Not applicable — no package installs in this phase's deliverables (see §Package Legitimacy Audit) |

## Project Constraints (from CLAUDE.md)

**No `CLAUDE.md` exists in this repository.** `.planning/config.json` sets `"claude_md_path": "./.claude/CLAUDE.md"`, but that file is absent, and a `find . -maxdepth 3 -name CLAUDE.md` outside `vendor/` returns nothing [VERIFIED: filesystem search this session]. `.claude/` is gitignored.

**No project skills directory.** Neither `.claude/skills/` nor `.agents/skills/` exists [VERIFIED: `ls .claude/` → `agents commands gsd-core gsd-file-manifest.json gsd-install-state.json gsd-migration-journal hooks scripts settings.local.json worktrees`].

The binding constraints for this phase therefore come from CONTEXT.md (reproduced verbatim in `<user_constraints>`), `REQUIREMENTS.md` §Out of Scope, and the wrapper's own header comment [VERIFIED: arch/dots-hyprland.sh:6-7], verbatim:

```
# Pattern: arch/waybar.sh / arch/*.sh (REPO_ROOT, main dispatcher, [LABEL] echos).
# Divergence: no package arrays; delegates install logic to upstream setup.
# Uninstall/protect are wrapper-owned (safe) — do NOT call upstream ./setup uninstall.
```

## Sources

### Primary (HIGH confidence — read on disk this session)

- `arch/dots-hyprland.sh` — `SAFE_DEFAULTS` (:14), usage/`--full`/uninstall/protect docs (:40-130), `preflight()` (:149-160), `backup_gate()` (:166-192), `PROTECT_EXPLICIT` (:230-295, `hyprpaper` :234, `waybar` :251, `swaync` :263), `list_hypr_ii_hook_target_files()` (:653-667), `enable_hypr_ii_hooks()` (:791+), `--full` scope refusal (:1422-1427), gate call (:1440), argv build (:1445-1456), dry-run branch (:1461-1473), post-setup protect+hooks (:1484-1493)
- `scripts/phase12-full-smoke.sh` — assert-script pattern (:9-17), gate-fed dry-run precedent (:63)
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` — `auto_backup_configs()` (:12-38) and its `ask` branches (:14-15), `cp_file` → `cp -f` (:46-52), `rsync_dir__sync` → `rsync -a --delete` (:67-76), `install_file` (:93-101), `install_file__auto_backup` (:102-121), `install_dir__sync` (:130-138), `install_dir__ignore_existing` (:150-160), `INSTALL_FIRSTRUN` derivation (:201-216), `auto_update_git_submodule` (:215-216), backup call site (:219)
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — misc block (:8-20), quickshell (:22-28), fish (:30-35), fontconfig (:37-44), hypr block (:46-77): `hyprland/` sync (:50), **conf → `.old` rename (:52-53)**, `hyprlock.conf` auto-backup (:55-57), `hyprland.lua` entry gated by `SKIP_HYPRLAND_ENTRY` (:58-63), `hypridle.conf` (:64-70), `custom/` ignore-existing seed (:75)
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — `-f/--force → ask=false` (:74), `-F/--firstrun` (:75), `--skip-hyprland` (:84), `--skip-hyprland-entry` (:85), `--core` expansion (:90)
- `vendor/dots-hyprland/sdata/subcmd-install/0.greeting.sh` — the `n → ask=false` prompt (:32-50)
- `vendor/dots-hyprland/sdata/lib/functions.sh` — `v()` and its `yesforall → ask=false` branch (:7-32), `backup_clashing_targets()` (:346+), `auto_update_git_submodule` submodule-dirty branch
- `vendor/dots-hyprland/sdata/lib/environment-variables.sh:27-30` — `BACKUP_DIR`, `DOTS_CORE_CONFDIR`, `INSTALLED_LISTFILE`, `FIRSTRUN_FILE`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua:1-44` — the require contract; `custom.env` (:10-12), `custom.execs` (:22-24), `custom.general` (:25-27)
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua:1-25` — what ii starts; no wallpaper daemon, no polkit agent (non-fedora)
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/PolkitService.qml:6,43` — `Quickshell.Services.Polkit`, `PolkitAgent`
- `/usr/share/hypr/stubs/hl.meta.lua:571-595,603-622,856,863` — `HL.MonitorSpec`, `HL.WorkspaceRuleSpec`, `hl.monitor`, `hl.workspace_rule`
- `.config/hypr/custom/general.lua:1-27` — the Phase 13 overlay
- `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` — apply command (D-18) and in-repo verify fence (D-19)
- `.planning/phases/11-disposition-decisions/11-CONTEXT.md:43-58` — D-07, D-08, D-11..D-15, D-18
- `.planning/REQUIREMENTS.md:41-44,77,83,90-109` — ADOPT-01..04, Out of Scope, traceability
- Live machine probes: `hyprctl -j status`, `hyprctl -j version`, `hyprctl -j monitors all`, `hyprctl workspacerules`, `hyprctl eval`, `strings /usr/bin/Hyprland`, `git status --porcelain`, `git rev-list --left-right --count origin/main...HEAD`, `git -C vendor/dots-hyprland rev-parse HEAD`, `diff -rq .config/hypr ~/.config/hypr`, `ls -la` on `~/.config/hypr`, `~/.config/illogical-impulse`, `~/ii-original-dots-backup/.config`, `~/.config/kitty`, `~/.config/fish`, `systemctl --user is-active`, `busctl --user get-property … ScreenCast`, `command -v`, `pacman -Q`, `uname -r`

### Secondary (MEDIUM confidence — official documentation)

- https://wiki.hypr.land/Configuring/Start/ — Lua config location, load precedence, `/usr/share/hypr/stubs/` LSP stub, `hyprctl` Lua REPL
- https://hypr.land/news/26_lua/ — the 0.55 Lua-ification announcement
- `man script` (util-linux 2.42.2) — `-a/--append`, `-c/--command`, and the `--log-in`/`--log-io` password-capture warning

### Tertiary (LOW confidence)

- None. Every claim in this document is either read from disk this session or cited to official documentation. The two web-search digests were cached to the research store under keys `0b2e5b84…` and `7e4de5a3…`.

## Metadata

**Confidence breakdown:**

- Standard stack: **HIGH** — no packages are added; every tool was probed on the live machine with its version recorded.
- Architecture: **HIGH** — the full install path was read end to end in upstream source with line numbers, and every wrapper function the plan depends on was read in `arch/dots-hyprland.sh`.
- Pitfalls: **HIGH** — all eight are grounded in observed live state or read source, not inference. Pitfalls 1, 3, and 7 in particular were discovered by probing, not by reasoning, and each invalidates an assumption CONTEXT makes.
- Overlay/API compatibility: **HIGH** — validated field by field against the installed compositor's own type stub.
- Post-adopt `configProvider` token: **LOW** — see A1; the recommended asserts are deliberately constructed not to depend on it.
- Config-format precedence on 0.56.2: **LOW** — see Open Question 1; operationally irrelevant.

**Research date:** 2026-09-04
**Valid until:** 2026-10-04 for the repo/upstream facts (the submodule is pinned, so they cannot drift without an explicit bump). **Volatile immediately** for the live-machine observations — the dirty git tree, the disconnected HDMI-A-2, the stale backup directory, and the running-process list can all change before the adopt window opens. The preflight script is what re-establishes them at go time; that is precisely its job.
