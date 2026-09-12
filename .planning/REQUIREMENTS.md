# Requirements: .dotfiles — v0.4 Personal config layer

**Defined:** 2026-09-12
**Core Value:** A fresh machine reproduces this exact desktop from a clone and one command, and everything configured afterward is captured without a manual sync step.
**Research:** `.planning/research/SUMMARY.md` (2026-09-12, confidence HIGH)

## v0.4 Requirements

Requirements for this milestone. Each maps to a roadmap phase.

### Blocker Fixes

Currently-live defects. Nothing else in the milestone works until these land.

- [ ] **FIX-01**: Every `stow` call site uses a valid verbosity flag — `stow -v=5` exits 1 on GNU Stow 2.4.1 at all 15 call sites across 14 `arch/*.sh` files
- [ ] **FIX-02**: `arch/hyprland.sh` no longer restores the pre-adopt `hyprland.conf` over the ii Lua session — lines 25-26 (`cp -rf .config/hypr/*`) are deleted and replaced with a stow invocation
- [ ] **FIX-03**: Repo-root `.config/` is retired as a second authoring tree — contents are redistributed to `stow/`, `restow/`, or `docs/archive/`, or deleted where generated
- [ ] **FIX-04**: `safe_rm_path` refuses any path inside the repo, so destructive `uninstall` paths cannot reach captured configs
- [ ] **FIX-05**: `verify` and `capture` are first-class subcommands in `arch/dots-hyprland.sh` — registered in `ALLOWLIST` and dispatched in `main`, with `verify` able to run without an initialised submodule
- [ ] **FIX-06**: Repo has `.gitattributes` (`* text=auto eol=lf`), `.gitignore` entries for generated and machine-state paths, and a secret scan over the capture trees

### Capture Mechanism

- [ ] **CAP-01**: A file's capture mechanism is knowable from its location alone — three trees with distinct semantics: `stow/` (installer never collides), `restow/` (installer overwrites; re-stow or `git checkout` after install), `capture/` (writer renames over the link; copy only)
- [ ] **CAP-02**: The installer collision map is checked into the repo as data — `path → installer primitive → symlink outcome → repo outcome` — derived from the vendored install scripts at the pinned SHA
- [ ] **CAP-03**: An assert script fails when a path's declared mechanism contradicts the collision map, so the map cannot silently rot against a submodule bump
- [ ] **CAP-04**: Every stow invocation in the repo uses `--no-folding`, so no destination directory ever becomes a symlink into the working tree
- [ ] **CAP-05**: `capture` copies live to repo for `capture/` paths only, never stages or commits, and skips any path whose repo mirror is already dirty against HEAD
- [ ] **CAP-06**: `capture` runs unattended on a systemd user timer, so `capture/` paths need no manual sync
- [ ] **CAP-07**: `stow --adopt` appears in no script — it silently replaces repo content with live content at exit 0

### Hypr Custom Overlays

- [ ] **HYPR-01**: `~/.config/hypr/custom/{env,execs,general,rules,keybinds,variables}.lua` are stow-managed, with live and repo the same inode
- [ ] **HYPR-02**: Personal keybinds are authored in `custom/keybinds.lua` using `hl.unbind` for upstream binds being replaced and `"Category: Label"` descriptions, and the ii cheatsheet groups them correctly
- [ ] **HYPR-03**: App-launcher and terminal choices are set in `custom/variables.lua` rather than by forking upstream files

### Startup Applications

- [ ] **START-01**: The `exec-once` entries lost at the Phase 14 adopt are restored in `custom/execs.lua` — polkit agent, `wl-clip-persist`, cursor, and the workspace-pinned applications
- [ ] **START-02**: `graphical-session.target` is active in a live session (D-38) — `hyprland-session.service` is started from `custom/execs.lua`
- [ ] **START-03**: The `systemctl --user disable` footgun is documented — it deletes the stow symlink for a unit in state `linked`

### Quickshell ii Bar Config

- [ ] **BAR-01**: `~/.config/illogical-impulse/config.json` is captured through `capture/`, and capture survives a wallpaper change (`switchwall.sh` renames over the path)
- [ ] **BAR-02**: Personal bar settings reachable through `config.json` — position, style, auto-hide, utility buttons, workspaces, weather — are set deliberately and reproduce from the repo

### Dolphin, KDE and GTK

- [ ] **KDE-01**: `kiorc`, `ktrashrc`, `kservicemenurc` are stow-managed — ii ships none of them, so there is no collision
- [ ] **KDE-02**: `gtk-3.0/settings.ini`, `gtk-3.0/bookmarks`, `gtk-4.0/settings.ini` are captured per file, and the generated `gtk.css` siblings are gitignored rather than captured
- [ ] **KDE-03**: `dolphinrc` and `chrome-flags.conf` live in `restow/` with a documented recovery step, because the installer writes through the link and overwrites the repo copy

### Drift Verification

- [ ] **VER-01**: `verify` asserts link identity before content for `stow/` and `restow/` paths — a destroyed symlink is the failure a content-only check cannot see
- [ ] **VER-02**: `verify` diffs content for `capture/` paths and reports drift
- [ ] **VER-03**: `verify` has defined exit codes — 0 clean, 1 drift, 2 precondition failure — and a `--strict` mode
- [ ] **VER-04**: `verify` is proven adversarially — stow a file, run `rsync -a --delete` over it, and confirm `verify` fails

### One-Command Bootstrap

- [ ] **BOOT-01**: A single command bootstraps a fresh machine, is resumable after failure, and is idempotent on re-run
- [ ] **BOOT-02**: Bootstrap ordering is submodule init, then ii `./setup`, then stow, then capture seed, then verify — stow must follow the installer
- [ ] **BOOT-03**: Bootstrap reports where it stops and what the operator must do, since the session entry point changes mid-run and a relogin is unavoidable
- [ ] **BOOT-04**: Bootstrap ends in a `verify` pass, so "reproduces the exact setup" is asserted rather than assumed
- [ ] **BOOT-05**: Explicitly installed package lists (`pacman -Qqen`, `pacman -Qqem`) are snapshotted into the repo as data

## v2 Requirements

Deferred. Tracked, not in this roadmap.

### Shell Customisation (fork-carried)

- **CUST-01**: Waybar ping module ported to a ii bar widget
- **CUST-02**: Waybar weather module ported to a ii bar widget
- **CUST-03**: Waybar earthquake module ported to a ii bar widget
- **CUST-04**: Bar widget composition — adding, removing, reordering — which requires editing `modules/ii/bar/BarContent.qml`

### Reproducibility Beyond Configs

- **PKG-01**: Package installation is reproducible end to end, including AUR helper bootstrap and dependency ordering

## Out of Scope

| Feature | Reason |
|---------|--------|
| Bar widget composition in v0.4 | `BarContent.qml` is a hardcoded 343-line composition — no widget list, model, ordering key, or plugin point exists in the config schema |
| Capturing `~/.config/quickshell/ii/**` | The installer runs `rsync -a --delete` over the whole tree every install, and it duplicates the vendored submodule. Durable QML changes belong on the fork as commits |
| `kdeglobals`, `Kvantum/`, `gtk-{3,4}.0/gtk.css`, `fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, `hyprlock/colors.conf` | Generated theme output or pure vendor content — capturing them means a diff on every wallpaper change |
| `~/.local/state/quickshell/`, `installed_listfile`, `installed_true`, dolphin `view_properties/`, `dconf/user`, caches | Machine state, not configuration — restoring it is useless at best and wrong at worst |
| Forking `hyprland.lua` to comment out upstream requires | Needs a permanent `--skip-hyprland-entry` and leaves two coupled forks to reconcile at every update; `hl.unbind` plus `custom/variables.lua` covers the real cases |
| Switching the session to `uwsm` | Replaces the session entry point and invalidates the Phase 14 adopt verification, to fix what one `exec_cmd` line fixes |
| A reproducible package installer | A milestone of its own; `./setup` remains the source of truth for ii's dependencies |
| Upfront inventory of everything dots-hyprland installs | Rejected by the operator, and unnecessary — `diff -rq vendor/…/dots/.config ~/.config` returns five drifted files. The pin is the inventory, computed on demand |
| Theme, icon, cursor packages and the wallpaper image | AUR packages, `/usr/share` contents, and a binary in `~/Pictures`. Capture the names and the path convention, not the payload |
| A file-watcher or auto-commit daemon, a git `pre-commit` capture hook, a shell `precmd` hook | "Simplest and without crashing stuff" was the stated constraint. `inotifywait` is absent, `.git/hooks` is not version-controlled so a fresh clone has none, and a bad `precmd` in a stowed shell rc is instantly everywhere |
| `~/.config/autostart/*.desktop` as a startup mechanism | Nothing reads XDG autostart in this session |
| `./setup uninstall` | v0.3 Pitfall 11 stands — `installed_listfile`-driven removal without confirmation |

## Traceability

Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| (pending roadmap) | | |

**Coverage:**
- v0.4 requirements: 33 total
- Mapped to phases: 0
- Unmapped: 33 ⚠️

---
*Requirements defined: 2026-09-12*
*Last updated: 2026-09-12 after v0.4 research synthesis*
