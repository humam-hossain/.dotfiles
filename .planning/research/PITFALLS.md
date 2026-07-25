# Pitfalls Research

**Domain:** Personal Arch Hyprland `.dotfiles` adopting end-4/dots-hyprland (illogical-impulse) as a managed fork+submodule while retiring a local Quickshell product tree
**Researched:** 2026-07-25
**Confidence:** HIGH (primary evidence from live machine state, `arch/quickshell.sh`, `issues/2026-07-16_*` post-mortem, and sibling clone `~/github_repo/dots-hyprland` setup sources)

## Critical Pitfalls

### Pitfall 1: Running `./setup` against a live customized session without a pre-backup

**What goes wrong:**
Upstream `./setup install` (files step) rsyncs with `--delete` into clashing config dirs, renames an existing `~/.config/hypr/hyprland.conf` → `hyprland.conf.old`, installs `hyprland.lua` as the new entry, and overwrites `~/.config/quickshell` wholesale. Personal Waybar/rofi/swaync/hypr keybinds/monitors can be displaced or orphaned in one pass. Interactive backup defaults to `~/ii-original-dots-backup` only if the user answers yes (or non-interactive first run creates it); `--skip-backup` is easy to pass by accident.

**Why it happens:**
dots-hyprland is designed as a full rice installer, not a non-destructive overlay. The existing machine already has a mature Catppuccin Hyprland + Waybar stack. Muscle memory from "just install the shell" underestimates how much `3.files-legacy.sh` touches.

**How to avoid:**
1. **Manual backup first** (before any wrapper runs setup):
   ```bash
   stamp=$(date +%Y%m%d-%H%M%S)
   mkdir -p ~/dots-pre-ii-backup-$stamp
   cp -a ~/.config/hypr ~/.config/waybar ~/.config/rofi ~/.config/swaync \
     ~/.config/quickshell ~/dots-pre-ii-backup-$stamp/ 2>/dev/null || true
   # also snapshot the .dotfiles-tracked trees
   cp -a /home/pera/github_repo/.dotfiles/.config/hypr \
     /home/pera/github_repo/.dotfiles/.config/waybar \
     ~/dots-pre-ii-backup-$stamp/repo-config/ 2>/dev/null || true
   ```
2. Prefer staged install: `./setup install-deps` → `install-setups` → `install-files` with explicit flags:
   - `--skip-hyprland` / `--skip-hyprland-entry` until personal session merge is designed
   - Never pass `--skip-backup` on first adoption
3. Thin `arch/` wrapper must default to **backup-on**, interactive or forced.

**Warning signs:**
- `hyprland.conf` suddenly becomes `hyprland.conf.old` and session boots a different entry
- Monitors/keybinds/workspace rules missing after `hyprctl reload`
- `~/ii-original-dots-backup` missing or empty after install
- Personal Catppuccin theme replaced by Material/Bibata stack without consent

**Phase to address:**
**Phase: Safe install wrapper + backup gate** (before any files install). Block files-step until backup path is verified non-empty.

---

### Pitfall 2: Deleting `.config/quickshell` while the live symlink still points at it

**What goes wrong:**
Live state today:
```
~/.config/quickshell → /home/pera/github_repo/.dotfiles/.config/quickshell
```
`arch/quickshell.sh` intentionally uses a **directory symlink** (`rm -rf "$QS_DST"; ln -s "$QS_SRC" "$QS_DST"`). If the repo tree is deleted first:
- Running Quickshell (`qs`) loads a dangling path → crash loop / empty shell
- Accidental `rm -rf ~/.config/quickshell` **follows or removes the symlink target** depending on flags — can wipe the repo product *or* leave a broken link
- Upstream `install_dir__sync` rsyncs into `$XDG_CONFIG_HOME/quickshell`. If that path is still a symlink into the repo, rsync **writes into the git tree** (or fights the delete-after-verify plan)

**Why it happens:**
v0.1 delivery model = symlink into repo. v0.2 delivery model = upstream install owns `~/.config/quickshell` as a real directory. The two models cannot coexist; order of operations is easy to invert under "delete the old product" pressure.

**How to avoid — delete-after-verify sequence (mandatory):**
1. **Stop** live Quickshell: `pkill -x qs || true; pkill -x quickshell || true`
2. **Break the symlink without deleting the repo tree:**
   ```bash
   if [ -L ~/.config/quickshell ]; then rm ~/.config/quickshell; fi
   # if it is a real dir from a prior partial install, rename aside
   if [ -d ~/.config/quickshell ]; then mv ~/.config/quickshell ~/.config/quickshell.pre-ii; fi
   ```
3. Run upstream install-files (or full install) so `~/.config/quickshell` becomes a **real directory** populated from `vendor/dots-hyprland/dots/.config/quickshell`
4. **Verify** `qs` / ii shell starts and bar is usable
5. **Only then** delete the in-repo product tree and retire `arch/quickshell.sh`
6. Commit the removal as its own change after session proof

**Warning signs:**
- `test -L ~/.config/quickshell` still true after "install"
- `readlink -f ~/.config/quickshell` still under `.dotfiles/.config/`
- `qs` errors about missing `shell.qml` / config path
- git status shows mass deletions in `.config/quickshell` while the session is still using that path

**Phase to address:**
**Phase: Session cutover / product retirement** — explicitly after install verification. Roadmap must sequence **retarget → install → verify → delete**, never delete-first.

---

### Pitfall 3: Re-enabling ddcutil / DDC/CI brightness traffic (historical iGPU crash)

**What goes wrong:**
Documented incident (`issues/2026-07-16_igpu-flickering-hang-no-display.md`): Waybar `ddcutil getvcp 10` polling ~every 6s produced **10,764 failed DDC/CI log lines in ~3 hours**, saturating DP I2C and contributing to display instability / hang on Intel UHD 770 + ASUS ROG PG348Q.

Upstream adoption re-introduces the same tooling path:
- Metapackage `illogical-impulse-backlight` depends on `ddcutil` + `brightnessctl`
- `2.setups.sh` creates `i2c` group, `usermod -aG video,i2c,input`, writes `i2c-dev` modules-load
- `Brightness.qml` runs `ddcutil detect --brief` on monitor list changes and `ddcutil -b … getvcp 10` during init; `setvcp` on user brightness changes

This is **not** the old 6s poll loop, but it is still DDC/CI on a monitor known to return `DDCRC_READ_ALL_ZERO` / retries. Combined with any future aggressive polling overlay = crash class reopened.

**Why it happens:**
setup installs the full dependency surface. Project Out of Scope already forbids brightness/backlight widgets using DDC/CI, but stock ii enables Brightness service by default. `arch/quickshell.sh` and even `arch/hyprland.sh` also install ddcutil today — inertia to leave it.

**How to avoid:**
1. Treat **no DDC/CI polling** as a hard acceptance criterion for v0.2
2. After install, **disable** ii brightness UI paths (sidebar quick slider / OSD bindings that call Brightness) via config overlay or fork patch — do not "try brightness once to see"
3. Prefer `brightnessctl` only for laptop-class backlight if ever needed; on this desktop (external DP monitor), leave brightness control out
4. Do not re-enable Waybar `custom/backlight` / ddcutil modules
5. Guard in wrapper docs: "Installing ii packages may pull ddcutil; package presence ≠ enable polling"
6. Optional: post-install check `pgrep -a ddcutil` and `journalctl --user -b | grep -c ddcutil` should stay ~0 during idle

**Warning signs:**
- `journalctl -b | grep ddcutil` growing rapidly
- `ddcutil detect` / `getvcp` failures with `DDCRC_RETRIES` / `READ_ALL_ZERO`
- Flicker, DP blanking, rising interrupt latency after shell start
- Sidebar brightness slider enabled in ii settings

**Phase to address:**
**Phase: Post-install hardening / ddcutil guard** (same milestone as first successful install). Also flag in install-wrapper phase so deps install does not get celebrated as "brightness works."

---

### Pitfall 4: Sibling clone → fork + submodule conversion done wrong

**What goes wrong:**
Existing clone at `~/github_repo/dots-hyprland` currently has:
- `origin` = `https://github.com/end-4/dots-hyprland.git` (upstream, not a personal fork)
- Nested submodule `shapes` already present at a pinned SHA

Common failure modes:
1. `git submodule add` pointing at **end-4** directly → no push target for personal commits
2. `git submodule add` of the **local path** without a published fork URL → unreproducible for future clones; remotes stay messy
3. Fork created but submodule still tracks end-4; local commits go nowhere useful
4. Moving the sibling directory into `vendor/dots-hyprland` with `mv` instead of `git submodule add` → parent never records gitlink; clone of `.dotfiles` lacks the dependency
5. Forgetting to set `upstream` remote on the fork → painful update workflow later
6. Submodule left on detached HEAD with uncommitted local edits (if any)

**Why it happens:**
"We already have a clone" tempts path reuse. Submodule mechanics require a **URL + recorded SHA** in the parent, not just a folder on disk.

**How to avoid:**
1. Create personal GitHub fork of end-4/dots-hyprland first
2. Either:
   - Re-clone fork into a temp path and `git submodule add <fork-url> vendor/dots-hyprland`, **or**
   - Retarget the sibling: set `origin` → fork, add `upstream` → end-4, push any needed refs, then add as submodule from the **fork URL**
3. Inside submodule verify:
   ```bash
   git remote -v   # origin=fork, upstream=end-4
   git submodule update --init --recursive   # shapes present
   ```
4. Parent commit must include `.gitmodules` **and** the gitlink for `vendor/dots-hyprland`
5. Document: never develop only in the sibling path after submodule exists — develop inside `vendor/dots-hyprland` (or keep one canonical path)

**Warning signs:**
- `git submodule status` empty or path not listed
- `origin` still end-4 after "we forked"
- `vendor/dots-hyprland` is a normal directory without `.git` gitfile
- Fresh `git clone --recurse-submodules` of `.dotfiles` leaves empty vendor

**Phase to address:**
**Phase: Fork + submodule foundation** (first phase of v0.2). No install wrapper until remotes and recursive submodules verify.

---

### Pitfall 5: Nested submodule (`shapes`) not initialized

**What goes wrong:**
dots-hyprland embeds:
```
dots/.config/quickshell/ii/modules/common/widgets/shapes
  → https://github.com/end-4/rounded-polygon-qmljs.git
```
Parent `.dotfiles` only records the **outer** submodule SHA. Nested `shapes` requires `--recursive`. Missing shapes → QML import/widget failures (rounded polygon widgets broken or shell fail to load modules).

Upstream `auto_update_git_submodule` in `3.files.sh` runs `git submodule update --init --recursive` **when install runs from a proper git checkout**. That does **not** help:
- A broken/partial submodule add
- A tarball / sparse copy without `.gitmodules`
- Parent clone without recurse where `vendor/dots-hyprland` itself is empty

**Why it happens:**
`git submodule update --init` without `--recursive` is the default habit; nested modules are invisible until QML breaks.

**How to avoid:**
1. Always: `git submodule update --init --recursive` from `.dotfiles` root after clone/pull
2. Wrapper install step must assert shapes path non-empty before calling `./setup`
3. Verification:
   ```bash
   test -f vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/shapes/LICENSE
   git -C vendor/dots-hyprland submodule status --recursive
   ```
4. Document clone: `git clone --recurse-submodules <dotfiles-url>`

**Warning signs:**
- `shapes` directory empty or missing `.git`
- `git submodule status --recursive` shows `-` (not initialized) or `+` unexpectedly
- QML errors referencing shapes / rounded polygon modules

**Phase to address:**
**Phase: Fork + submodule foundation** (verify gate) and re-check in install phase.

---

### Pitfall 6: Dual-running Waybar + ii bar without intentional control

**What goes wrong:**
Current session already dual-runs:
- `hyprland.conf`: `exec-once = waybar & swaync & hyprpaper &`
- Live processes: both `waybar` and `qs -d` observed
- ii `hyprland/execs.lua` also does `qs -c $qsConfig` on `hyprland.start`

If install activates ii hypr entry **and** personal conf still starts Waybar:
- Two bars stack (vertical space loss, overlapping layers)
- System tray claimed by two hosts (icons missing/duplicated; v0.1 already noted dual-host tray noise)
- Double notification stacks if swaync + ii notifications both live
- Confusing keybinds (SUPER+w restarts waybar; ii has its own)

v0.2 scope explicitly allows dual-run until later cutover — but **uncontrolled** dual-run (both autostarted from conflicting hypr entries) is different from **intentional** dual-run.

**Why it happens:**
Partial install (qs config only) vs full hypr lua entry vs personal conf left intact — three combinations, only some are sane.

**How to avoid:**
1. Pick one session model for v0.2:
   - **A (recommended for v0.2):** Keep personal `hyprland.conf` as source of truth; install ii **quickshell only** (`--skip-hyprland` / carefully skip entry); start `qs` via a single explicit `exec-once` or manual launch; leave Waybar as primary until later milestone
   - **B:** Adopt ii `hyprland.lua` + `custom/` overlays for personal execs; migrate Waybar out of autostart deliberately
2. Never leave **both** personal conf and ii lua active as competing entries
3. Document which bar is authoritative this milestone
4. Tray UAT: dual-host log noise alone ≠ failure (per v0.1); stacked bars covering content **is** failure

**Warning signs:**
- Two bars visible after login
- `pgrep -a waybar; pgrep -a qs` both non-empty unexpectedly after "qs-only" install
- Tray icons only on one bar / missing entirely
- `hyprland.conf` and `hyprland.lua` both present and both "active" without a clear entry

**Phase to address:**
**Phase: Session integration** (after install-files). Explicit dual-run policy written into success criteria. Full Waybar cutover stays **out of v0.2**.

---

### Pitfall 7: Overwriting personal Hyprland entry / losing hyprlock and machine-specific config

**What goes wrong:**
`3.files-legacy.sh` when Hyprland install is not skipped:
- `install_dir__sync` on `hypr/hyprland` (**--delete** — extra personal files in that dir vanish)
- Renames `hyprland.conf` → `.old` so lua config loads
- `install_file` for `hyprland.lua` (overwrite)
- `install_file__auto_backup` for `hyprlock.conf` / `hypridle.conf` (firstrun moves to `.old`, else writes `.new`)
- `custom/` is `install_dir__ignore_existing` — only created if missing; **does not** auto-port personal keybinds

Personal monitors (`DP-1`, etc.), Catppuccin, `hyprland-session.service` bootstrap, workspace-pinned apps, and **hyprlock** (explicitly kept per PROJECT) can be displaced. ii may pull a different lock path/config.

**Why it happens:**
Assuming "install the shell" is QML-only. The rice treats Hyprland config as part of the product.

**How to avoid:**
1. First adoption: **`--skip-hyprland` and/or `--skip-hyprland-entry`** unless a deliberate migration plan exists
2. Keep hyprlock as the lock screen; do not enable ii LockScreen as replacement (PROJECT Out of Scope)
3. If adopting lua later: port personal bits into `~/.config/hypr/custom/{execs,keybinds,general,env}.lua` — that is the upstream-supported overlay surface
4. Preserve `hyprland-session.service` graphical-session bootstrap (screen share / portals)

**Warning signs:**
- Login session missing personal autostart apps
- hyprlock config replaced; lock look/behavior changed unintentionally
- Portal/screen-share regressions after hypr conf churn
- `hyprland.conf.old` exists and you did not expect a lua migration

**Phase to address:**
**Phase: Safe install wrapper** (flags) + **Session integration** (if/when hypr is touched). Default skip-hyprland until a later milestone.

---

### Pitfall 8: Deleting the local product before the managed install is proven

**What goes wrong:**
v0.1 tree is large (~57k LOC, hundreds of QML files) and is the only known-good Quickshell config path on this machine. Deleting it (or committing the CONCERNS-noted mass deletions) before:
- fork/submodule is solid
- `./setup` install-files succeeds
- ii shell runs in session

…leaves no rollback except git history / backups — and if the live symlink still pointed at the tree, the session breaks immediately.

**Why it happens:**
Milestone goal "remove local Quickshell product" is easy to treat as step 1 instead of the last step.

**How to avoid:**
**Delete-after-verify** is a hard rule:
1. Submodule + remotes OK
2. Install deps/setups/files OK
3. Live `~/.config/quickshell` is real dir from upstream
4. Human UAT: bar visible, session stable, no ddcutil storm
5. Then delete `.config/quickshell` from repo, retire `arch/quickshell.sh`, update docs
6. Separate commit for deletion

**Warning signs:**
- Roadmap/plan tasks ordered "delete tree" before "verify qs"
- git shows product deleted while `qs` still depends on it
- No backup tarball / branch tag before deletion

**Phase to address:**
**Phase: Product retirement** — last implementation phase of v0.2, never first.

---

### Pitfall 9: Thin wrapper that reimplements setup (or silently skips critical steps)

**What goes wrong:**
PROJECT requires thin `arch/` wrapper around upstream `./setup`. Temptation: copy-paste package lists from `illogical-impulse-*` PKGBUILDs into a new `arch/ii.sh` and "just rsync dots" — then drift from upstream forever. Opposite failure: wrapper calls only `install-files` without deps/venv → shell starts but Python tools / `ILLOGICAL_IMPULSE_VIRTUAL_ENV` missing.

**Why it happens:**
`.dotfiles` house style is self-contained `arch/*.sh`. Upstream installer is interactive, multi-step, and opinionated — feels foreign.

**How to avoid:**
1. Wrapper only: resolve `REPO_ROOT`, `cd vendor/dots-hyprland`, invoke `./setup <subcommand> "$@"` with labeled echos
2. Do not fork the dependency graph into pacman one-liners except documented escapes
3. Ensure env note: `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` default `~/.local/state/quickshell/.venv` must be set for the session (ii ships this in `hyprland/env` — if hypr install is skipped, wrapper/docs must set it another way)
4. Match `arch/*.sh` UX (labels) without replacing setup semantics

**Warning signs:**
- Wrapper contains long package arrays duplicated from metapkgs
- Install "succeeds" but `echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV` empty in Hyprland
- Files present but `uv`/venv missing under state dir

**Phase to address:**
**Phase: Install wrapper** (after submodule foundation).

---

### Pitfall 10: Incomplete retirement of `arch/quickshell.sh` and ddcutil/i2c provisioning

**What goes wrong:**
Even after deleting the QML tree, leaving `arch/quickshell.sh` callable re-symlinks `~/.config/quickshell` → empty/missing repo path and re-runs ddcutil/i2c setup. Fresh machine bootstrap docs that still list `quickshell.sh` reintroduce the old product path.

**Why it happens:**
Retiring a product is multi-surface: script, README provisioning order, INTEGRATIONS.md, symlink, packages.

**How to avoid:**
Retirement checklist:
- [ ] Remove or stub `arch/quickshell.sh` with a fatal message pointing at the new wrapper
- [ ] Update `arch/README.md` / provisioning order
- [ ] Update `.planning` docs that reference local tree as live product
- [ ] Confirm no exec-once still assumes repo symlink layout
- [ ] Decide whether to leave system packages `ddcutil`/`i2c-tools` installed (harmless if unused) vs remove; **must not** re-enable polling either way

**Warning signs:**
- New machine runbook still says `./arch/quickshell.sh`
- Symlink reappears after "cleanup"
- Two install paths documented as current

**Phase to address:**
**Phase: Product retirement + documentation** (end of milestone).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep sibling clone + submodule as two checkouts | No re-clone time | Edits in wrong tree; pin drift | Never for day-to-day — pick one canonical path |
| `--skip-backup` on setup | Faster install | No restore after overwrite | Never on first adoption |
| Full hypr lua adopt in same phase as submodule | "Complete" rice | Session breakage; hard rollback | Later milestone only |
| Leave ddcutil installed but "we won't use it" | No package surgery | Any widget/keybind can re-trigger DDC | Acceptable if UI/bindings disabled and monitored |
| Dual-run Waybar + qs indefinitely | Safety during port | Tray noise; theme split; double maintenance | Acceptable for v0.2; not forever |
| Vendor without personal fork (submodule → end-4 only) | Fewer GitHub steps | Cannot push custom commits cleanly | Never if customizations expected |
| Delete local QML early to "reduce confusion" | Cleaner tree | No fallback if ii install fails | Never — delete-after-verify only |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `~/.config/quickshell` | Leave v0.1 symlink, run setup rsync into it | Remove symlink first; let setup create real directory |
| `./setup install-files` | Assume it only touches Quickshell | It syncs many `dots/.config/*` dirs unless skipped; hypr specially handled |
| Nested `shapes` submodule | `git submodule update --init` only | Always `--recursive`; assert files exist |
| Personal fork remotes | `origin` left as end-4 | `origin`=fork, `upstream`=end-4 |
| Hyprland entry | Run full hypr install over personal conf | Prefer `--skip-hyprland*` until overlay plan exists |
| `ILLOGICAL_IMPULSE_VIRTUAL_ENV` | Skip hypr env include and forget env | Set in session env or custom env.lua / wrapper docs |
| ddcutil / i2c | Treat as required for "complete" shell | Out of scope for brightness; do not poll |
| Waybar customs (ping :8765) | Expect them in stock ii | Deferred; keep Waybar until ports exist |
| hyprlock | Allow ii lock config to replace workflow | Keep hyprlock; auto_backup/review hyprlock.conf |
| `arch/quickshell.sh` | Leave as parallel installer | Retire/stub after verify |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| DDC/CI retry storms | journal flooded with ddcutil; flicker | Disable brightness DDC paths; no poll modules | Minutes–hours on this hardware (see 2026-07-16) |
| Dual bars + dual notifiers | Compositor lag; layer thrash | One intentional bar stack | Immediately visible UX pain |
| Full rsync --delete of large trees mid-session | hyprctl reload mid-edit; partial state | Install from TTY or accept reload; backup first | First install if session hot |
| Uninitialized nested submodule | QML load failures, missing widgets | Recursive init gate | First qs launch |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Running setup steps as root / with sudo shell | Upstream explicitly `prevent_sudo_or_root`; broken perms on `~/.config` | Run as user; let setup escalate only where it asks |
| Blind `yesforall` on setup prompts | Overwrites without review | Answer per-step on first adoption |
| Copying secrets into vendor submodule | Secrets pushed to fork | Keep machine secrets in personal overlays outside submodule |
| LAN-exposed services unchanged | Unrelated but co-session | Out of scope for v0.2; do not widen during rice install |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Unexpected Material vs Catppuccin clash | Visual inconsistency across bar/launcher | Accept dual aesthetic in v0.2 or theme later; don't force full cutover |
| Stacked bars after install | Lost screen real estate | Control autostart; one primary bar |
| Lost keybinds after hypr overwrite | Feels like "broken machine" | Skip hypr install; or port to `custom/` first |
| Firstrun / welcome flows unwanted | Noise, AI/onboarding surfaces | PROJECT out-of-scope features — disable, don't invest |
| Brightness OSD appears and hits ddcutil | Risk of display instability | Disable brightness UI |

## "Looks Done But Isn't" Checklist

- [ ] **Fork remotes:** `origin` is personal fork, `upstream` is end-4 — not both end-4
- [ ] **Parent gitlink:** `.gitmodules` + `vendor/dots-hyprland` committed; `git submodule status` clean
- [ ] **Nested shapes:** recursive status clean; shapes files on disk
- [ ] **Backup exists:** non-empty `~/dots-pre-ii-backup-*` (and/or `~/ii-original-dots-backup`) before files install
- [ ] **Symlink retired:** `~/.config/quickshell` is **not** a symlink into `.dotfiles`
- [ ] **Install source:** live config matches vendor/upstream install, not deleted local tree
- [ ] **qs runs:** bar visible after login or manual start; no crash loop
- [ ] **Env:** `ILLOGICAL_IMPULSE_VIRTUAL_ENV` set when qs needs Python tooling
- [ ] **ddcutil idle:** no polling; journal quiet for ddcutil during normal use
- [ ] **Hypr entry intentional:** either personal conf kept or lua+custom fully owned — not accidental rename to `.old`
- [ ] **Dual-run policy:** documented which of Waybar/qs is primary this milestone
- [ ] **Local product deleted only after verify:** repo tree removal is last, with session still healthy
- [ ] **`arch/quickshell.sh` retired:** cannot re-symlink the old path
- [ ] **Docs:** provisioning order points at new wrapper, not v0.1 path
- [ ] **hyprlock still lock screen:** not replaced by Quickshell lock

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| setup overwrote hypr/waybar | MEDIUM | Restore from `~/dots-pre-ii-backup-*` or `~/ii-original-dots-backup`; `hyprctl reload`; re-copy from `.dotfiles` if repo still clean |
| Symlink/target delete broke qs | MEDIUM | Stop qs; restore tree from git; recreate symlink **or** re-run install-files into real dir |
| Nested submodule empty | LOW | `git submodule update --init --recursive` from parent and inside vendor |
| Wrong remote / no fork | LOW–MEDIUM | Create fork; `git remote set-url origin <fork>`; push; fix `.gitmodules` url + `git submodule sync` |
| ddcutil storm / flicker | HIGH (session stability) | Kill qs/waybar modules using ddcutil; disable brightness UI; check journal; avoid force reboots if possible; see post-mortem power/DP notes |
| Dual bars chaos | LOW | `pkill waybar` or `pkill qs`; fix exec-once / execs.lua; reload |
| Deleted product pre-verify | MEDIUM | `git checkout` / `git restore` the tree from last good commit; re-establish symlink only as emergency fallback |
| Partial submodule (empty vendor) | LOW | Re-add submodule; ensure commit has gitlink |

## Pitfall-to-Phase Mapping

Suggested v0.2 phase order (for roadmap). Names are recommendations — orchestrator may renumber.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Sibling→fork/submodule mistakes | **P1 Fork + submodule foundation** | `git remote -v`, `git submodule status --recursive`, shapes files exist |
| Nested shapes missing | **P1** (+ recheck in P2) | Non-empty shapes path; qs imports |
| setup overwrite without backup | **P2 Safe install wrapper + backup gate** | Backup dir non-empty; wrapper refuses files-step without backup |
| Hypr entry / hyprlock clobber | **P2** (default skip-hyprland*) | Personal hyprland.conf still authoritative unless opt-in |
| Wrapper reimplements setup | **P2** | Wrapper only execs `./setup`; no duplicated metapkg arrays |
| Symlink vs rsync fight | **P3 Session install / path retarget** | `! test -L ~/.config/quickshell`; real dir from install |
| Dual Waybar + ii uncontrolled | **P3** | Documented policy; pgrep matches policy; no stacked-bar UAT fail |
| ddcutil re-enable | **P3 hardening** (same window as first live qs) | No brightness poll; journal quiet; settings slider off |
| Delete-before-verify | **P4 Product retirement** only after P3 UAT | qs healthy on upstream path; then delete tree |
| `arch/quickshell.sh` zombie | **P4** | Script stubbed/removed; docs updated |
| Full Waybar/rofi/swaync cutover | **Later milestone** (not v0.2) | N/A this milestone |

### Recommended phase ordering rationale

```
P1 Fork+submodule+recursive shapes
    → P2 Wrapper + mandatory backup + conservative setup flags
        → P3 Retarget symlink, install, verify session, dual-run policy, ddcutil guard
            → P4 Delete local Quickshell tree, retire arch/quickshell.sh, docs
```

**Hard sequencing rules for the roadmap:**
1. **Backup before setup files**
2. **Retarget/remove symlink before install-files into `~/.config/quickshell`**
3. **Verify live ii shell before deleting repo `.config/quickshell`**
4. **Do not adopt full hypr lua in the same breath as first install** unless explicitly scoped later
5. **Never re-enable DDC/CI brightness polling**

## Sources

| Source | Type | Confidence | Use |
|--------|------|------------|-----|
| `.planning/PROJECT.md` (v0.2 goals, constraints, out-of-scope) | Project canon | HIGH | Scope, no-ddcutil, hyprlock keep, dual-run later |
| `issues/2026-07-16_igpu-flickering-hang-no-display.md` | Post-mortem | HIGH | ddcutil/I2C crash class |
| `arch/quickshell.sh` | Local installer | HIGH | Symlink model, ddcutil/i2c provisioning |
| `arch/hyprland.sh` | Local installer | HIGH | Also installs ddcutil; personal conf copy model |
| Live FS: `~/.config/quickshell` symlink; `pgrep` waybar+qs | Machine state | HIGH | Dual-run + symlink reality |
| `~/github_repo/dots-hyprland/setup` + `sdata/subcmd-install/{3.files.sh,3.files-legacy.sh,2.setups.sh,options.sh}` | Upstream installer | HIGH | Overwrite, backup dir, skip flags, hypr rename, qs sync |
| `sdata/dist-arch/illogical-impulse-backlight/PKGBUILD` | Upstream deps | HIGH | ddcutil package pull-in |
| `dots/.../services/Brightness.qml` | Upstream shell | HIGH | ddcutil detect/getvcp/setvcp behavior |
| `.gitmodules` shapes → rounded-polygon-qmljs | Upstream nested submodule | HIGH | Recursive requirement |
| `.planning/codebase/CONCERNS.md` | Prior risk map | HIGH | Uncommitted deletions; ddcutil risk |
| `.planning/codebase/INTEGRATIONS.md` | Architecture map | HIGH | exec-once, symlink, provisioning order |
| v0.1 `04-RESEARCH.md` dual-host tray notes | Prior milestone | MEDIUM–HIGH | Dual-run tray expectations |
| General git submodule nested practices | Community / docs | MEDIUM | Recursive init patterns (cross-checked with upstream `auto_update_git_submodule`) |

---
*Pitfalls research for: adopting dots-hyprland into personal Arch Hyprland .dotfiles (v0.2)*
*Researched: 2026-07-25*
*Mode: ecosystem / integration pitfalls for subsequent milestone*
