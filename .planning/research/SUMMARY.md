# Project Research Summary

**Project:** `.dotfiles` — personal config layer over an installed illogical-impulse (ii) shell
**Domain:** Config capture / reproducible dotfiles on Arch + Hyprland, layered on `vendor/dots-hyprland` @ `1a9ffb78`
**Researched:** 2026-09-12
**Confidence:** HIGH (nearly every load-bearing claim is empirically reproduced on this host or read from vendored/upstream source; the few MEDIUM/UNVERIFIED items are named in §8)
**Milestone:** v0.4 Personal config layer

---

## 1. Executive Summary

**The research changed the shape of this milestone.** v0.4 was framed as "build a copy-capture mechanism because apps rewrite their configs atomically and that eats symlinks." That framing is wrong in its premise, wrong about its named villain, and points the engineering effort at the wrong threat. All four researchers independently reproduced the same result: Qt's `QSaveFile` — which is what Quickshell's `FileView` and every KDE `KConfig` write goes through — **resolves the symlink chain before writing and renames onto the resolved target**. The symlink survives; the repo file is correctly updated. Atomic writing is not the enemy of symlink capture; for the Qt writers on this machine it is the *best* case, because live genuinely is the repo with zero sync step.

The actual threats are two, and neither is what D-41 names. **First: the ii installer.** `./setup install-files` places configs with `rsync -a --delete` (destroys a stow symlink, replaces it with a plain file, leaves the repo copy orphaned and `git status` clean), `cp -f` (preserves the link, overwrites the *repo* file through it), and `install_dir__ignore_existing` (a total no-op once the directory exists). This is not a hypothesis — it is the already-recorded D-17 kitty/starship asymmetry, now mechanism-explained, and its blast radius covers most of the milestone's named capture targets. **Second: shell scripts inside ii that write config with plain `mv`.** `switchwall.sh` rewrites `~/.config/illogical-impulse/config.json` with `jq … > "$F.tmp" && mv "$F.tmp" "$F"` on every wallpaper change. A `mv` is a same-directory `rename(2)` onto the *link path* — it does not resolve. So `config.json` really does need a non-symlink mechanism, but for a completely different reason than D-41 states.

The consequences are: (a) the capture design must be organised around **installer collision class and write primitive**, not around "atomic vs not"; (b) `verify` must assert **link-ness before content**, because both destroying primitives leave the repo file untouched and a content-only check reports green in exactly the case that matters; (c) the milestone's named capture list shrinks — `kdeglobals`, `Kvantum`, and both `gtk.css` files turn out to be generated theme output or pure vendor content, not personal config; and (d) two real, currently-live defects (`stow -v=5` exiting 1 at 15 call sites, and `arch/hyprland.sh:25-26` restoring the pre-adopt `hyprland.conf` over the ii Lua session) must be fixed before any bootstrap can run at all. The good news is that the personal surface is *tiny* — a full `diff -rq` of every ii-shipped `dots/.config` entry against live returns **five drifted files** — so "capture as I touch" is not a compromise, it is the correct strategy, and the pin itself is the inventory.

---

## 2. Decision Corrections

### D-41 — restated correctly

> **Current text:** "Stow symlinks are the default capture path… Exception is any file an app rewrites atomically (temp + rename replaces the symlink with a plain file, silently losing capture); those get copy-capture instead. `~/.config/illogical-impulse/config.json` is the known candidate."

**Correct text should be:** Stow symlinks (`--no-folding`, always) are the default capture path — live *is* the repo, no manual sync. The exception is **not** "atomic writes"; atomicity is not a single behaviour. The exception is **any path whose writer performs a bare `rename(2)`/`mv` onto the link path, or that the ii installer overwrites with `rsync`**. Concretely:

| Write primitive | Symlink | Repo file | Evidence |
|---|---|---|---|
| Qt `QSaveFile` (Quickshell `FileView`, KDE `KConfig`) | **preserved** | correctly updated | `qtbase/src/corelib/io/qsavefile.cpp:194-206` (`// Resolve symlinks`, 128-level chase) + `commit()` → `renameOverwrite(finalFileName)`. Reproduced ×3 independently on this host against `qt6-base 6.11.2` (compiled C++ writer, PySide6, and `kwriteconfig6` from `kconfig 6.29.0-1`). Symlink intact, repo content updated, repo inode replaced (`16404027 → 16404029`), mode `0600` preserved. |
| GLib `g_file_set_contents` (dconf, GTK/GNOME) | **DESTROYED** | untouched, orphaned | [GLib `GFileSetContentsFlags`](https://docs.gtk.org/glib/flags.FileSetContentsFlags.html); reproduced locally |
| shell `mv` / Python `os.replace` | **DESTROYED** | untouched, orphaned | reproduced locally (this synthesis re-ran it: `mv` over a symlinked path → `stat -c %F` = `regular file`, repo still `REPO`) |
| `rsync -a [--delete]` | **DESTROYED** (+ `--delete` removes extras) | untouched, orphaned | reproduced with rsync 3.5.0; already happened for real (kitty, `docs/phase14-adopt-runbook.md:253`) |
| `cp -f` | preserved | **OVERWRITTEN through the link** | reproduced; already happened for real (`starship.toml`, commit `2539238`, D-17) |
| `vim`/`nvim` | safe here | — | `backupcopy=auto`, `writebackup=0` on this machine |

**So: `config.json` still needs the exception. The stated reason is factually wrong and must be amended.**

### The `config.json` adjudication — FEATURES is right, and this synthesis confirmed it from source

STACK and ARCHITECTURE concluded the copy-capture exception could likely be dropped entirely; PITFALLS agreed and added GLib as a second killer class; FEATURES dissented, claiming `switchwall.sh` uses `jq … > "$F.tmp" && mv` on `config.json`. **FEATURES' claim holds up against the vendored source. Verdict: the exception survives.**

Confirmed at pin `1a9ffb78`:

- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh:11` — `SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"`
- `switchwall.sh:147` — `jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"`
- `switchwall.sh:154` — same pattern for `.background.thumbnailPath`
- `switchwall.sh:335` — same pattern for `.appearance.palette.accentColor`
- `scripts/ai/gemini-translate.sh:64` — same pattern for `.language.ui`
- `switchwall.sh:120-141` — `cat > "$RESTORE_SCRIPT.tmp"` + `mv` for `custom/scripts/__restore_video_wallpaper.sh` (a third instance, in the otherwise-safest directory)

The `.tmp` is created next to the **unresolved** link path, so the `mv` is a same-directory rename onto the link. Empirically re-verified in this synthesis. STACK/ARCHITECTURE/PITFALLS all missed these call sites because they analysed the *application* writer (`FileView`) and not the *shell scripts shipped alongside it*.

**Net effect on scope:** every wallpaper change (`CTRL+SUPER+T`), every accent-colour change, and every UI-language change destroys a stow symlink at `config.json`. Toggling a bar setting in the Super+I settings panel does *not* — that path is `FileView`/`QSaveFile` and is symlink-safe. The exception is triggered by wallpaper/translate, not by the settings GUI.

### Other PROJECT.md claims the research invalidated

| Claim | Verdict | Evidence |
|---|---|---|
| "Hypr custom overlays… (live already drifted past repo)" for `keybinds.lua`, `rules.lua`, `variables.lua`, `custom/scripts/` | **FALSE — they are installer stubs, not drift.** Re-verified in this synthesis: `keybinds.lua` (135 B), `rules.lua`, `variables.lua`, `env.lua`, `execs.lua` are all **byte-identical to `vendor/dots-hyprland/dots/.config/hypr/custom/`**, mtime `Jul 25 19:12` = the submodule checkout mtime preserved by `rsync -a`. Only `general.lua` (1004 B) is personal, and it is already tracked at repo-root `.config/hypr/custom/general.lua`. | ARCHITECTURE §1.5, FEATURES Surface 1; `cmp` re-run 2026-09-12 |
| "`custom/variables.lua` … `custom/scripts/`" as capture targets — PITFALLS B-4 claims neither is sourced | **PITFALLS IS WRONG about `variables.lua`; RIGHT about `scripts/`.** `hyprland.lua` requires only `custom.{env,execs,general,rules,keybinds}` — PITFALLS read that correctly. But `variables.lua` is required one level deeper: `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua:3-4` does `if is_file_exists(HOME.."/.config/hypr/custom/variables.lua") then require("custom.variables")`, *before* the 194 upstream binds are defined. It is a real, upstream-recommended override point (`hyprland/variables.lua:2`: "Copy these to ~/.config/hypr/custom/variables.lua"). **Keep it as a target.** `custom/scripts/` is genuinely not sourced — it is a plain directory, referenced only by `hyprland/execs.lua:7`, and `switchwall.sh` writes generated content into it. **Demote it from "capture target" to "capture your own scripts only; exclude `__restore_video_wallpaper.sh` and `mpvpaper_thumbnails/`."** | source read 2026-09-12 |
| "`kdeglobals` … `Kvantum` … gtk-3.0/4.0" as capture targets | **Three of these are generated output or pure vendor content, not personal config.** `kdeglobals` is a full Material You colour dump rewritten by `kde-material-you-colors-wrapper.sh` (`switchwall.sh:34`) *and* reordered by KConfig on every save → permanent phantom churn. `Kvantum/` is byte-identical to the pin (`Colloid`, `MaterialAdw`) and is an `install_dir__sync` target — maximum risk, zero value. `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` are declared matugen outputs (`~/.config/matugen/config.toml`), and `gtk-4.0/gtk.css` is *additionally* currently a symlink into `/usr/share/themes/catppuccin-mocha-teal-standard+default/` — an unresolved conflict. **Capture `gtk-{3,4}.0/settings.ini` and `gtk-3.0/bookmarks` per-file; guard everything else.** | ARCHITECTURE §8, FEATURES §5, PITFALLS C-1 |
| "`~/.config/autostart` … startup applications restored" | **Nothing reads XDG autostart in this session.** Hyprland does not; ii runs no `dex`/`xdg-autostart`; a grep of the whole vendored tree for `uwsm`/`graphical-session`/`systemctl --user` hits only `2.setups.sh` (ydotool + bluetooth). `~/.config/autostart/FDM.desktop` is dead weight. **Startup restoration belongs in `custom/execs.lua`, not `autostart/`.** | FEATURES §4 |
| "one command yields the exact setup" | **Honest contract is one command, run twice, with a relogin between.** `./setup` renames `hyprland.conf` → `.old` and installs `hyprland.lua`, so the session after install is not the session before it; `ILLOGICAL_IMPULSE_VIRTUAL_ENV` is only set by `hyprland/env.lua` after relogin; `verify`'s shell checks need a live `qs`. Say this in the requirement rather than discovering it in a phase. | ARCHITECTURE §5.2, PITFALLS F-4 |

---

## 3. The Capture Model

### Mechanisms

| # | Mechanism | Repo location | Contract |
|---|---|---|---|
| 1 | **stow symlink** (`stow -R --no-folding -t ~`) | `stow/<pkg>/` | Live *is* the repo. The app's write lands in git as an unstaged diff. Nothing upstream touches these paths. |
| 2 | **stow symlink, installer-hostile** | `restow/<pkg>/` | Stowed identically, but `./setup install-files` breaks it every time in a *class-specific* way. Bootstrap re-stows after setup; `verify` knows a broken link here means "run restow", not "something is wrong". |
| 3 | **copy-capture** | `capture/<pkg>/` | A one-directional live→repo mirror for paths whose writer destroys links. Driven by a systemd user timer, never a watcher daemon, never a git hook. Never `git add`. Skips any path whose repo mirror is dirty vs `HEAD`. |

`restow/` exists as its own tree because the two installer primitives need *different* recovery commands and `verify` must be able to tell them apart:

- **rsync-replace class** (link broken, repo clean) → fix: `stow -R --no-folding <pkg>`
- **cp-through class** (link intact, repo dirty and matching the vendor file byte-for-byte) → fix: `git checkout -- restow/<pkg>`

This is the single most subtle thing in the design. It is also already hand-maintained as prose at `docs/phase14-adopt-runbook.md:243-255`; `restow/` turns that prose into a directory the filesystem cannot lie about.

### The decision rule — "how do I know which mechanism this file needs?"

Apply in order. Each step is a lookup, not a judgement call.

```
For a path P under $HOME:

1. Is P generated?  (matugen output, material-you colour dump, shell state)
   -> gtk-3.0/gtk.css, gtk-4.0/gtk.css, fuzzel/fuzzel_theme.ini,
      hypr/hyprland/colors.lua, hypr/hyprlock/colors.conf, kdeglobals,
      ~/.local/state/quickshell/**, ~/.config/dconf/user
   => GUARD. Never capture. verify FAILs if it ever appears in a tree.
      If a personal subset matters, capture the matugen *template* instead.

2. Is P wholly produced by ./setup with no personal edit?
   -> Kvantum/, quickshell/, hypr/hyprland/, fontconfig/, wlogout/, matugen/,
      xdg-desktop-portal/, mpv/, foot/, fuzzel/, zshrc.d/, darklyrc,
      konsolerc, code-flags.conf, thorium-flags.conf  (all byte-identical to pin today)
   => UNMANAGED. The pin reproduces it. Leave it alone.

3. Does a writer perform a bare rename(2)/mv onto P's own path?
   -> config.json (switchwall.sh:147,154,335; gemini-translate.sh:64)
   -> custom/scripts/__restore_video_wallpaper.sh (switchwall.sh:120-141)
   -> any GLib/GTK app that persists its own settings (per-app UNVERIFIED)
   => capture/  (mechanism 3)

4. Does ./setup write P?  (grep the destination table in §4)
      no  => stow/<pkg>/        (mechanism 1)
     yes  => restow/<pkg>/      (mechanism 2), tagged rsync-replace | cp-through

5. Did verify observe P clobbered despite being stowed, twice?
   => promote to capture/. Nothing enters capture/ on suspicion, only on evidence.
```

Two invariants that sit above the rule:

- **`--no-folding` unconditionally, on every stow invocation in this repo.** Stow folds whenever the target directory does not yet exist — which on a fresh machine is *every* directory. Reproduced: stowing a package containing `.config/…` into an empty target made **`~/.config` itself** a symlink into the package. Compose that with `rsync -a --delete ~/.config/quickshell` and the installer writes the entire ii tree *into the git working tree* and `--delete`-prunes it. Two packages are already folded today (`~/.config/qBittorrent`, `~/.config/smartmontools`); neither is an installer destination, so they are currently harmless — but `verify` check L0 exists to surface them.
- **Capture is allowlist-only, at file granularity, never whole-directory.** `~/.config` is 12 GB on this machine (Chrome 7.1 GB, Discord 2.0 GB) and holds live secrets (`rustdesk/*.toml`, `obs-websocket/config.json`, `roboflow/config.json`, `gh/hosts.yml`, `configstore/`). `~/.config/illogical-impulse/` alone mixes shell config, user `actions/`, and a 77 KB installer `installed_listfile`. Reuse the wrapper's existing `is_allowlisted` (`arch/dots-hyprland.sh:106`) / `safe_rm_path` (`:428`) shape rather than inventing a second pattern.

### `verify` — the non-negotiable property

Both destroying primitives leave the repo file **untouched**, so `git status` stays clean while live silently forks. **A content-only drift check reports green in exactly the case that matters.** `verify` must assert, per managed path, in this order: (1) `test -L`, (2) `readlink -f` equals the expected repo path, (3) no ancestor is a symlink into the repo (folding check), (4) `-xtype l` sweep for dangling links, and only *then* (5) content. Build it on the existing `scripts/phase14-verify.sh` output contract (`[PASS]`/`[FAIL]`/`[FINDING]`/`[INFO]`, trailing `=== done: FAIL=n FINDINGS=n ===`, exit 0/1, plus exit 2 for precondition errors); do not invent a new one. Its acceptance test must be **adversarial**: stow a file, `rsync -a --delete` over it to simulate the installer, confirm `verify` FAILs.

One thing `verify` must *not* call drift: a stowed file whose repo content differs from `HEAD`. That is capture working. It is INFO, not FAIL. Likewise an unclaimed upstream stub sitting next to a managed file is INFO until claimed — otherwise `verify` is red from day one (today's `keybinds.lua` case).

---

## 4. Installer Collision Map

Consolidated from three overlapping versions (STACK, ARCHITECTURE §1.1-1.2, PITFALLS D-1). Read from `vendor/dots-hyprland/sdata/subcmd-install/` at pin `1a9ffb78`. Every row is source-read and the primitives are empirically reproduced.

### Primitives

| Helper | Source | Primitive | Symlink outcome | Repo outcome |
|---|---|---|---|---|
| `install_dir__ignore_existing` | `3.files.sh:150-160` | `[ -d "$t" ]` → echo and **return** | **untouched** | untouched |
| `install_file` → `cp_file` | `3.files.sh:46-52, 93-101` | `cp -f` | **preserved** | **OVERWRITTEN through the link** (loud — shows in `git status`) |
| `install_file__auto_backup` | `3.files.sh:102-120` | firstrun: `mv $t $t.old` + copy · else: writes `$t.new`, leaves `$t` | firstrun: **link renamed away** · else: untouched | else: untouched |
| `install_dir__sync` → `rsync_dir__sync` | `3.files.sh:67-76, 130-138` | `rsync -a --delete` | **DESTROYED**, replaced by plain file; extras **deleted** | untouched, **silently orphaned** |
| `install_dir__sync_exclude` | `3.files.sh` | `rsync -a --delete --exclude <x>` | destroyed except inside the excluded subtree | as above |
| `install_dir` | `3.files.sh:121-149` | `rsync -a` | **DESTROYED** | untouched, orphaned |

> **Correction to the milestone premise:** `install_dir__ignore_existing` is *named* for per-file ignore-existing but its body never reaches the rsync when the directory exists — it returns after an echo. Real semantics: **skip-if-directory-exists**, which is *stronger*. `[ -d ]` is also true for a symlink-to-directory, so even a folded `~/.config/hypr/custom` is respected.

### Per-path map

| Live path | Line (`3.files-legacy.sh`) | Helper | Symlink outcome | Repo outcome | Mechanism |
|---|---|---|---|---|---|
| `hypr/custom/` | `:75` | `install_dir__ignore_existing` | **untouched** | untouched | **`stow/`** — the one structurally safe surface |
| `hypr/hyprland/**` | `:50` | `install_dir__sync` | destroyed + pruned | orphaned | **never capture** (also holds matugen `colors.lua`) |
| `hypr/hyprland.conf` | `:51-54` | inline `mv` → `.old` | link renamed away | — | already fired at Phase 14 |
| `hypr/hyprland.lua` | `:61` | `install_file` | preserved | overwritten | **never capture** — personalise via `custom/` |
| `hypr/hyprlock.conf`, `hypridle.conf` | `:56`, `:68` | `install_file__auto_backup` | untouched (non-firstrun) | untouched; `.new` sibling appears | optional `restow/` |
| `quickshell/**` (whole tree) | `:26` | `install_dir__sync` | destroyed + pruned | orphaned | **never capture** ([issue #2294](https://github.com/end-4/dots-hyprland/issues/2294) is why it widened from `ii/`) |
| `fish/` (except `conf.d`) | `:33` | `install_dir__sync_exclude` | destroyed outside `conf.d` | orphaned | `restow/` (already stowed) |
| `fontconfig/` | `:41` | `install_dir__sync` | destroyed | orphaned | leave (identical to pin) |
| misc loop — **directories**: `Kvantum`, `matugen`, `mpv`, `kitty`, `foot`, `fuzzel`, `wlogout`, `xdg-desktop-portal`, `kde-material-you-colors`, `zshrc.d` | `:14` | `install_dir__sync` | destroyed + pruned | orphaned | `kitty` → `restow/`; rest → leave (identical to pin) |
| misc loop — **files**: `chrome-flags.conf`, `code-flags.conf`, `darklyrc`, `dolphinrc`, `kdeglobals`, `konsolerc`, `starship.toml`, `thorium-flags.conf` | `:15` | `install_file` (`cp -f`) | preserved | **overwritten** | `dolphinrc`, `chrome-flags.conf`, `starship.toml` → `restow/` cp-through; `kdeglobals` → GUARD; rest → leave |
| `~/.local/share/konsole`, `~/.local/share/icons/illogical-impulse.svg` | `:18`, `:79` | `install_dir` / `install_file` | destroyed / preserved | orphaned / overwritten | leave |
| `~/.config/illogical-impulse/` | — | **not shipped at all**; created by `gen_firstrun` (`3.files.sh:40-45`) | — | — | `capture/` for `config.json`; **never** `installed_listfile` / `installed_true` |
| `kiorc`, `ktrashrc`, `kservicemenurc`, `gtk-3.0/settings.ini`, `gtk-3.0/bookmarks`, `gtk-4.0/settings.ini`, `~/.config/autostart/*`, `~/.config/systemd/user/*` | — | **not shipped at all** | — | — | **`stow/`** — zero collision risk |

**Two standing consequences.** (1) With `--core`/`SAFE_DEFAULTS` retired at Phase 16, the misc loop now runs on **every** install, and its target set overlaps heavily with this milestone's capture list — the collision is not hypothetical, it is most of the milestone. (2) The update path (`git -C vendor pull` → re-run `./setup install`) fires every row again, on a machine that by then has far more stowed paths than Phase 14 did. **Post-install re-stow must be a mandatory, automated step, and `verify` must run after every install.**

---

## 5. Scope: In and Out

### In

| Item | Reason |
|---|---|
| `hypr/custom/{env,execs,general,rules,keybinds,variables}.lua` → `stow/` | The one directory the installer provably never touches; `variables.lua` confirmed sourced via `hyprland/keybinds.lua:3-4` |
| Personal keybinds with `hl.unbind` + `"Category: Label"` descriptions | `hl.unbind` confirmed in `/usr/share/hypr/stubs/hl.meta.lua`; cheatsheet regroups live off `hyprctl binds -j` |
| App-launcher choices in `custom/variables.lua` | Upstream's own recommended, update-friendly override path |
| Startup restoration in `custom/execs.lua` (polkit agent, `wl-clip-persist`, four workspace-pinned apps, cursor) | Seven `exec-once` entries died at the Phase 14 adopt; `custom/execs.lua` is the safe surface |
| **D-38** — `systemctl --user start hyprland-session.service` from `custom/execs.lua` | One line; the unit is already stow-symlinked and intact; `graphical-session.target` is **inactive right now** |
| `~/.config/illogical-impulse/config.json` → `capture/` | `switchwall.sh`/`gemini-translate.sh` `mv` over it — confirmed from source |
| `kiorc`, `ktrashrc`, `kservicemenurc` → `stow/kde/` | Not shipped by ii at all; zero collision |
| `gtk-3.0/settings.ini`, `gtk-3.0/bookmarks`, `gtk-4.0/settings.ini` → `stow/gtk/` (per **file**) | Personal, portable, not shipped; the directory also holds generated `gtk.css` |
| `dolphinrc`, `chrome-flags.conf` → `restow/` (cp-through class) | Genuinely drifted (9 lines / 1 line), `install_file` → recoverable via `git checkout` |
| `kitty`, `fish`, `starship.toml` → `restow/` | Already stowed; already collided once; formalise the re-stow |
| The installer collision map, checked in and lint-asserted | Turns "is this path safe to stow?" from research into a lookup, permanently |
| `verify` (POLISH-01), link-aware, adversarially tested | The milestone's headline claim is false without it |
| One-command (twice-run) bootstrap, resumable, idempotent | Explicit requirement; nothing like it exists — 34 independent `arch/*.sh` today |
| Package list snapshot (`pacman -Qqen` / `-Qqem`) **as data** | Cheap, high recovery value, 261 explicit / 56 AUR |

### Out

| Item | Reason |
|---|---|
| Bar widget composition / adding, removing, reordering widgets | `modules/ii/bar/BarContent.qml` is a hardcoded 343-line composition — no widget list, model, ordering key or plugin point exists in the config schema. Requires QML editing. |
| Forking / capturing `~/.config/quickshell/ii/**` | `rsync -a --delete` over the whole tree destroys it every install, and it duplicates the vendored submodule. Durable QML changes are **fork commits on `humam-hossain/dots-hyprland`** carried by rebase. Defer to CUST-*. Live tree has **zero** drift from pin today — a clean starting point. |
| Waybar customs port (ping/weather/earthquake) | Requires exactly the QML fork above. CUST-01..03. |
| `kdeglobals`, `Kvantum/`, `gtk-{3,4}.0/gtk.css`, `fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, `hyprlock/colors.conf` | Generated theme output or pure vendor content — capturing them means a diff on every wallpaper change |
| `~/.local/state/quickshell/`, `installed_listfile`, `installed_true`, `~/.local/share/dolphin/view_properties/`, `dconf/user`, caches | Pure machine state; restoring it is useless at best, wrong at worst |
| Forking `hyprland.lua` and commenting out upstream requires | Needs permanent `--skip-hyprland-entry`; two coupled forks to reconcile at every update. `hl.unbind` + `custom/variables.lua` + `hl.config` cover the real cases. |
| Switching the session to `uwsm` | Architecturally nicer, but it replaces the session entry point and invalidates the Phase 14 adopt verification, to fix what one `exec_cmd` line fixes |
| A reproducible package *installer* (AUR ordering, helper bootstrap, ii meta interleaving) | A milestone of its own. `./setup` stays the SoT for ii's deps. |
| Upfront inventory of everything dots-hyprland installs | Rejected by the user, and unnecessary: `diff -rq vendor/…/dots/.config ~/.config` returns **5 files**. The pin *is* the inventory, computed on demand. |
| Theme/icon/cursor **packages**, the wallpaper image | AUR, versions, `/usr/share` contents, a binary in `~/Pictures`. Document the names as a prerequisite list; capture the path convention, not the image. |
| A file-watcher / auto-commit daemon; a git `pre-commit` capture hook; a shell `precmd` hook | "Simplest and without crashing stuff" was the stated constraint. `inotifywait` is not installed; `.git/hooks` is not version-controlled so a fresh clone has none; a bad `precmd` in a stowed `.zshrc` is instantly everywhere. A systemd user timer is the only mechanism whose failures are visible and whose blast radius excludes the session. |
| `stow --adopt` inside any script | Reproduced: `--adopt` silently replaced repo content with live content, exit 0, no prompt. On a fresh machine it would adopt **upstream's stubs** over your files with the tree looking correct afterward. Interactive-only, one path at a time, gated on a clean work tree, `git diff` immediately after. |
| `~/.config/autostart/*.desktop` as a startup mechanism | Nothing reads XDG autostart in this session |
| Ever running `./setup uninstall` | v0.3 Pitfall 11 still stands; `installed_listfile`-driven `rm` without confirmation, and folding gives it a new way to bite |

---

## 6. Known Blockers to Fix

Concrete, currently-live defects. The milestone cannot work until these are fixed.

| # | Defect | Location | Why it blocks | Severity |
|---|---|---|---|---|
| B1 | **`stow -v=5` exits 1 on GNU Stow 2.4.1** — `Unknown option: =` / `Unknown option: 5`, usage dumped. Correct forms are `--verbose=5` or `-v 5`. **15 call sites across 14 files.** | `arch/alacritty.sh:9`, `arch/btop.sh:8`, `arch/define.sh:7`, `arch/fish.sh:26`, `arch/hyprland.sh:29`, `arch/hyprland.sh:33`, `arch/kitty.sh:10`, `arch/nvim.sh:20`, `arch/rofi.sh:10`, `arch/tmux.sh:17`, `arch/wezterm.sh:10`, `arch/xterm.sh:10`, `arch/yazi.sh:10`, `arch/zsh.sh:43`, `arch/zsh_powerlevel.sh:61` | Every stow in the repo's own install scripts is a hard failure today. `arch/hyprland.sh` has `set -euo pipefail` (line 2), so line 29 aborts the script and line 33 (swaync stow) **never runs**. Verified: `stow -v=5` → `rc=1`. | **BLOCKER** |
| B2 | **`arch/hyprland.sh:25-26` restores the pre-adopt `hyprland.conf` over the ii Lua session**, undoing Phase 14. Also uses a cwd-relative path with no `cd`, so it only works from the repo root. | `arch/hyprland.sh:25-26` — `mkdir -p ~/.config/hypr` / `cp -rf .config/hypr/* ~/.config/hypr/` | Any bootstrap that calls `arch/hyprland.sh` reverts the milestone-defining change of the previous milestone. Must be **deleted** and replaced with `stow -R --no-folding --verbose=5 -t ~ hypr`. | **BLOCKER** |
| B3 | No stow invocation anywhere uses `--no-folding`. | all 15 sites above | On a fresh machine this makes `~/.config` (or `~/.config/illogical-impulse`, or `~/.config/hypr`) a symlink into the repo, and the installer's `rsync -a --delete` then writes into and prunes the git working tree. | **BLOCKER** |
| B4 | Repo-root `.config/` is a stale second copy tree. `.config/dolphinrc` and `.config/kdeglobals` both **differ from live** — exactly the failure D-41 exists to eliminate. Its only consumer is B2. | repo-root `.config/` | Two authoring sources of truth. Must be retired: `hypr/custom/*.lua` → `stow/hypr/`; `dolphinrc` → `restow/kde-upstream/`; `kdeglobals` → **deleted** (generated); pre-adopt hypr confs → `docs/archive/pre-adopt-hypr/`. | HIGH |
| B5 | `safe_rm_path` guards only `$HOME/*` and `*/.config/hypr*`. The repo lives at `$HOME/github_repo/.dotfiles`, so a **repo path passes the guard**. Once configs are symlinked, `uninstall` targeting `$II_CONFDIR` becomes materially riskier. | `arch/dots-hyprland.sh:428-450`; targets at `:162-187` | Hardening, but cheap and directly created by this milestone's design. Add a `REPO_ROOT` refusal. | HIGH |
| B6 | `arch/dots-hyprland.sh` `ALLOWLIST` (`:14`) and `main` (`:771-805`) must gain `verify` and `capture` as **own handlers**, not routed into `run_install_family` — `./setup` would reject them. `preflight` (`:115-120`) `exit 1`s on an uninitialised submodule, but `verify` must run without one. | `arch/dots-hyprland.sh` | Required plumbing for the milestone's two new subcommands. | required |
| B7 | No `.gitattributes`; no secret scan; `.gitignore` lacks the generated/state patterns this milestone will produce. | repo root | Cheap insurance before bulk capture. Add `* text=auto eol=lf`; add `installed_listfile`, `installed_true`, `*.target.wants/`, `*/colors.lua`, `gtk-{3,4}.0/gtk.css`, `fuzzel_theme.ini`, `*.lock`, `*-socket`, `*.sqlite*`, `*/Cache/`, `*/GPUCache/`, `*.pma`, `*/thumbnails/`; add a `gitleaks`/`git-secrets` pass over `stow/`. | MODERATE |
| B8 | `systemctl --user disable hyprland-session.service` **deletes the stow symlink** — the unit reports state `linked`, not `enabled`, and `disable` removes *all* symlinks to matching unit files including manually created ones. Verified live. | `~/.config/systemd/user/hyprland-session.service` | A recovery footgun the D-38 work will walk straight into. Document; `verify` asserts the unit is `linked` and active. | MODERATE |

---

## 7. De-risk First

Ranked. All of these must be empirically settled in an early phase, **before any bulk capture**, because every later phase inherits them.

1. **Fix B1/B2/B3.** Nothing can be bootstrapped or verified while stow exits 1 at every call site and `arch/hyprland.sh` reverts Phase 14. This is a prerequisite, not a risk.
2. **Build the installer collision map and make it machine-checkable.** Derive `path → primitive → symlink outcome → repo outcome` from `3.files-legacy.sh` + `3.files.sh` at the pin; check it in; assert it with a script in the `scripts/phase10-inventory-assert.sh` style. Every candidate path is classified against it *before* it is stowed. Without this, capture is guessing about the one actor guaranteed to attack it.
3. **Make `verify` link-aware and prove it adversarially.** `! -L` → FAIL; `readlink -f` mismatch → FAIL; folded ancestor → FAIL; `-xtype l` → FAIL; *then* content. Acceptance test: stow a file, `rsync -a --delete` over it, confirm `verify` FAILs. A `verify` that does not pass this test is a false green, and this is the risk that makes the milestone's headline claim false.
4. **Run the `config.json` experiment — both halves.** (a) Toggle one bar setting in the Super+I panel, then `ls -l ~/.config/illogical-impulse/config.json` — predicted: symlink survives (`FileView`/`QSaveFile`). (b) Change the wallpaper (`CTRL+SUPER+T`), then check again — predicted: **symlink destroyed** (`switchwall.sh:147`). (b) is the one that fixes the mechanism. Do it against a scratch path (`qs -p /tmp/fvtest/shell.qml`, distinct `instance.lock`) before touching the live config.
5. **Full fresh-machine dry run in a throwaway XDG.** `XDG_CONFIG_HOME=/tmp/xdgtest XDG_DATA_HOME=/tmp/xdgtest-data ./vendor/dots-hyprland/setup install-files --skip-backup`, then diff against the §4 table. Validates the whole map at once and produces the fixture the `verify` collision-class array is linted against. Follow it with `stow -n --no-folding --verbose=5` for every package to collect the real conflict list — that is the input to the bootstrap's de-stub rule.
6. **Decide the `kdeglobals` and GTK4 questions before capturing anything in those directories.** `kdeglobals` → narrow-to-keys, archive-only, or nothing. `gtk-4.0/gtk.css` → catppuccin symlink or matugen output, not both.
7. **Land the safety properties before the first bulk stow.** `cp -a` backup of live paths to a timestamped dir; `stow -n` dry-run first; allowlist gate; a tested one-line documented undo per package (`stow -D -t ~ <pkg> && cp -a <backup>/<pkg>/. ~/`); capture one package at a time, commit per package.

---

## 8. Open Questions

Merged and deduplicated across all four documents, each with the test that settles it.

| # | Question | Confidence today | Test that settles it |
|---|---|---|---|
| Q1 | Does a stow symlink at `config.json` survive an ii settings-UI write end-to-end? | MEDIUM (source-proven, three independent `QSaveFile` reproductions, but not executed against the running `qs`) | `qs -p /tmp/fvtest/shell.qml` with a `FileView`+`JsonAdapter` over a symlinked scratch file; toggle a property; `stat -c %F` the link and `cat` the target. Predicted: link survives, repo updated, no leftover `c.json.XXXXXX`. |
| Q2 | Does a wallpaper change destroy the symlink at `config.json`? | HIGH (source confirmed at `switchwall.sh:147,154,335`; `mv`-over-symlink reproduced) | `CTRL+SUPER+T`, then `ls -l ~/.config/illogical-impulse/config.json`. Predicted: plain file. This is the test that *justifies* the exception. |
| Q3 | Does the `QSaveFile` temp file ever become visible to git? It is created in the **resolved** directory — i.e. inside the repo. | UNVERIFIED | Tight `git status --porcelain` loop while toggling a config option repeatedly (ii debounces at 50 ms and can write in bursts). If ever observed → `.gitignore` rule + keep `verify` check X2. |
| Q4 | What is the `hl.exec_cmd` rules-table key spelling for workspace-pinned autostart? The meta declares `rules?: table<string, string\|number\|boolean>` but upstream never uses it. | UNVERIFIED | Try `hl.exec_cmd("kitty", { workspace = "1" })`; fall back to `hl.exec_cmd("hyprctl dispatch exec '[workspace 1 silent] …'")`. |
| Q5 | Does `install_dir__ignore_existing` really skip a *folded symlink* `custom/` end-to-end? (`[ -d symlink-to-dir ]` is true in isolation — verified.) | MEDIUM | `./arch/dots-hyprland.sh install-files` in a throwaway `XDG_CONFIG_HOME` with `custom/` pre-folded. Also confirms the fresh-machine stub-population path. |
| Q6 | Which specific GTK/GNOME apps in this user's set use `g_file_set_contents`? The primitive is verified; the per-app inventory is not. | UNVERIFIED | Symlink a scratch config for each candidate, drive one settings change, `test -L`. Until then, treat the GTK/GNOME half of `~/.config` as copy-capture territory by default. |
| Q7 | Is `kde-material-you-colors` even installed and firing? `which` → not found; live `[Colors:*]` blocks are byte-identical to the pin; `~/.config/gtk-3.0/gtk.css` is **absent** despite matugen declaring it as an output. If the pipeline is inert, the `kdeglobals` churn hazard is latent, not active. | UNVERIFIED — and this is the discrepancy behind the whole `kdeglobals` debate | One deliberate `CTRL+SUPER+T`, then `git status` / `stat` on `kdeglobals` and `gtk.css`. Settles the narrowing question. |
| Q8 | Does matugen write *through* or *replace* `~/.config/gtk-4.0/gtk.css`? That path is currently a symlink into `/usr/share/themes` — writing through it means silently editing a root-owned system theme (or failing). | UNVERIFIED | Same wallpaper change as Q7; inspect the link and the system file. Worth knowing even though the path is a GUARD. |
| Q9 | What does Hyprland do with a `workspace_rule` naming an absent monitor? `custom/general.lua` pins workspaces 6–10 to `HDMI-A-2`. | UNVERIFIED (the display itself is safe — `hyprland/general.lua:2-7` has a catch-all `hl.monitor` loaded *before* `custom.general`, so an unmatched rule degrades to "no custom scale/pinning", not a black screen) | Boot with one head and try to reach workspace 7. Motivates a `custom/machine/$(hostname).lua` layer. |
| Q10 | Do KDE apps (Dolphin, `kwriteconfig6`) write through a symlink under real cascade/locking, not just via `QSaveFile` in isolation? | MEDIUM — `kwriteconfig6` reproduced successfully; KConfig also does cascading and locking that `QSaveFile` alone does not | Scratch `kiorc`; open Dolphin, change a setting, close; `test -L`. Do this before committing `stow/kde/`. |
| Q11 | Do file modes survive? `dolphinrc`, `kdeglobals`, `kiorc`, `kservicemenurc`, `ktrashrc` are `0600` live; git stores only the exec bit, so a fresh clone yields `0644`. Conversely, KConfig's `setPermissions` follows symlinks and will **chmod your repo file to 0600** on every write. | MEDIUM | Check whether KConfig's non-owner direct-write branch triggers on mode or ownership (source says ownership). Decide whether bootstrap `chmod 600`s an explicit list after stow. |
| Q12 | Does VS Code / Code-OSS replace symlinked settings files on save? Widely reported, not reproduced here. | UNVERIFIED — nvim is safe (`backupcopy=auto`) | Only matters if the user edits captured configs in VS Code. Test before relying on symlink capture for those files. |
| Q13 | Does `qt6ct.conf` have any effect given ii sets `QT_QPA_PLATFORMTHEME=kde`? | UNVERIFIED | Change a `qt6ct` setting, restart a Qt app, observe. If inert, drop it from scope. |
| Q14 | Does `systemctl --user enable` work from a TTY with no graphical session and no lingering? | MEDIUM | Run it on the scratch bootstrap; confirm only `--now` on the timer needs the post-relogin phase. |
| Q15 | `3.files-exp.sh` behaviour is entirely unread. It is only reachable via `--exp-files`, which the wrapper never passes — but the wrapper forwards user flags verbatim, so an operator *could*. | **UNVERIFIED — and if anyone passes `--exp-files`, every row in §4 is void.** | Read it, or make the wrapper refuse the flag. |
| Q16 | What exactly produced `kitty.conf.upstream` (mtime Jul 25, which `rsync --delete` should have removed at the Sep 4 install)? | UNVERIFIED | Not worth chasing — the collision *class* is proven independently. Noted so it is not mistaken for a new signal. |

---

## 9. Roadmap Implications

### Suggested phase shape

| Phase | Delivers | Rationale | Research? |
|---|---|---|---|
| **P17 — Unblock + D-38** | Fix B1 (15 `stow -v=5` sites), B2 (`arch/hyprland.sh:25-26`), B3 (`--no-folding` everywhere); land the one-line `systemctl --user start hyprland-session.service` in `custom/execs.lua`; add `.gitattributes` + `.gitignore` patterns (B7). | Every stow in the repo fails today and `arch/hyprland.sh` reverts Phase 14 — nothing downstream can be trusted until this lands. **D-38 is a one-line fix, independent of the capture mechanism, in the one directory the installer provably never touches, and `graphical-session.target` has been inactive since Sep 4. Ship it here.** | **No** — defects are located and the mechanism is confirmed |
| **P18 — Collision map + link-aware `verify`** | The checked-in `path → primitive → symlink outcome → repo outcome` table with an assert script; `verify` built on the `phase14-verify.sh` output contract, link-ness before content, adversarially tested; wrapper plumbing (B6) and `safe_rm_path` hardening (B5). | De-risk items 2 and 3. Every capture decision downstream is a lookup against this table, and the milestone's headline claim is unfalsifiable without `verify`. | **Light** — Q5, Q14 |
| **P19 — `hypr/custom/` capture + startup restore** | `stow/hypr/` with all six `*.lua` (`--no-folding`); retire repo-root `.config/hypr/custom/` (B4); restore the seven lost `exec-once` entries; keybinds with `hl.unbind` + `"Category: Label"`; launcher choices in `variables.lua`. | The safest surface in the project (`install_dir__ignore_existing` is a whole-directory no-op) and the user's first-named want. Note the untracked files there are **upstream stubs, not drift** — the work is authoring, not rescuing. | **No** — override contract fully mapped; only Q4 outstanding, with a documented fallback |
| **P20 — `config.json`** | Run Q1 and Q2; on the (expected) Q2 result, land `capture/ii/` + the `dotfiles-capture` systemd user timer with the skip-if-dirty rule, JSON validation, and the defaults-clobber guard. | The exception is real but narrow, and the *mechanism* must be chosen from the test result, not from D-41's text. Depends on P18's `verify` to prove it works. | **Light** — the two tests are specified |
| **P21 — KDE / GTK capture** | `stow/kde/` (`kiorc`, `ktrashrc`, `kservicemenurc`), `stow/gtk/` (per-file `settings.ini` + `bookmarks`), `restow/kde-upstream/` (`dolphinrc`, `chrome-flags.conf`) with the cp-through recovery documented; GUARD list for `kdeglobals`/`Kvantum`/`gtk.css`. | Five drifted files total — genuinely small once the generated output is excluded. | **Yes, narrowly** — Q7, Q8 + the GTK4 conflict, Q10, Q11 |
| **P22 — Bootstrap** | Resumable, idempotent `./bootstrap` with per-phase state at `$XDG_STATE_HOME/dotfiles/bootstrap.state`, `--from`/`--only`/`--dry-run`, a clone-path assertion, one `sudo -v` keepalive, and `verify --strict` as the final gate and the exit code. | No precedent in this repo — 34 independent scripts today. Depends on everything above; `verify` must exist before "one command reproduces the exact setup" means anything. | **Yes** — ordering, idempotence (Q5, Q14) and the de-stub rule are unexplored; run the full throwaway-XDG dry run here or in P18 |

### Ordering rationale

- **The blockers gate everything**, and D-38 rides along free in P17 because it touches only `custom/execs.lua`.
- **The collision map and `verify` precede all capture.** Planning P19/P21 before P18 means guessing which paths are symlink-safe — and the research's central finding is that guessing is exactly how this fails silently.
- **P20 depends on P18** because the `config.json` decision is only trustworthy if `verify` can prove the link state afterwards.
- **P21 is the only phase with genuinely open design questions** (`kdeglobals` narrowing, GTK4 conflict). Keep them out of the critical path.
- **Bootstrap is last, and its requirement text must say "one command, run twice, with a relogin between."** A fresh machine has no compositor for the install phases and needs one for the verify phases; `./setup` replaces the session entry point mid-run. This is unavoidable and should be stated, not discovered.

### Confidence

| Area | Confidence | Basis |
|---|---|---|
| Write-primitive behaviour (`QSaveFile`, `mv`, `rsync`, `cp -f`, GLib) | **HIGH** | Reproduced independently by 3–4 agents on this host; upstream source cited line-for-line |
| Installer collision map | **HIGH** | Read from vendored source at the pin by three agents, in agreement |
| Stow 2.4.1 behaviour (folding, conflicts, `--adopt`, `-v=5`) | **HIGH** | Empirically reproduced; `stow -v=5` → `rc=1` re-verified in this synthesis |
| ii override surface (`custom/`, `hl.unbind`, load order) | **HIGH** | Source-read and confirmed against the live session (Hyprland 0.56.2, `configProvider: lua`, 195 binds) |
| `config.json` exception justification | **HIGH** | `switchwall.sh:147,154,335` + `gemini-translate.sh:64` read at the pin in this synthesis; `mv`-over-symlink re-reproduced |
| End-to-end live `qs` write through a symlink | **MEDIUM** | Q1 — source-proven, not executed against the running shell |
| `kdeglobals` / theming-pipeline churn rate | **LOW-MEDIUM** | Q7 — `kde-material-you-colors` appears not to be installed; the whole hazard may be latent |
| GTK/GNOME per-app write primitives | **LOW** | Q6 — the primitive is verified, the app inventory is not |
| `3.files-exp.sh` | **UNVERIFIED** | Q15 — entirely unread |

---

## Sources

Full citations, with file paths and line numbers, live in the four research documents. Load-bearing primary sources:

**Vendored installer (`vendor/dots-hyprland` @ `1a9ffb78`):**
`sdata/subcmd-install/3.files.sh:12-39, 40-45, 46-52, 53-92, 93-172, 196-238` · `3.files-legacy.sh:6-79` (the destination table) · `options.sh:48-105` · `2.setups.sh` · `setup:10, 48-63, 68-130` · `sdata/lib/environment-variables.sh:2-6, 27-30` · `sdata/lib/functions.sh:346-390` · `sdata/subcmd-uninstall/*.sh:39-115`

**Vendored ii shell:**
`dots/.config/hypr/hyprland.lua:11,23,26,29,32` · `dots/.config/hypr/hyprland/keybinds.lua:3-4` (the `custom.variables` require) · `hyprland/variables.lua:2` · `hyprland/execs.lua` · `hyprland/general.lua:2-7` · `dots/.config/quickshell/ii/scripts/colors/switchwall.sh:11,34,120-141,147,154,335` · `scripts/ai/gemini-translate.sh:64` · `modules/common/Config.qml:14,55-77` · `modules/ii/bar/BarContent.qml` · `services/HyprlandKeybinds.qml` · `services/KeyringStorage.qml` · `dots/.config/matugen/config.toml`

**Upstream source (fetched / on-host debug sources):**
`qtbase/src/corelib/io/qsavefile.cpp:194-206` (symlink resolution) + `commit()` · `kconfig/src/core/kconfiginibackendreader_p.h:225-300` · `quickshell/src/io/fileview.cpp:218-290`, `fileview.hpp:207,423`, `src/io/jsonadapter.cpp:24-99` · [GLib `GFileSetContentsFlags`](https://docs.gtk.org/glib/flags.FileSetContentsFlags.html) · [`QSaveFile` docs](https://doc.qt.io/qt-6/qsavefile.html) · [GNU Stow manual](https://www.gnu.org/software/stow/manual/stow.html) · `/usr/share/hypr/stubs/hl.meta.lua` · [ii configuration docs](https://ii.clsty.link/en/ii-qs/03config/) · [end-4/dots-hyprland#2294](https://github.com/end-4/dots-hyprland/issues/2294)

**Repo:**
`arch/dots-hyprland.sh:14, 22-104, 106, 115-120, 162-187, 428-450, 697-805` · `arch/hyprland.sh:25-26, 29, 33` + 13 further `stow -v=5` sites · `scripts/phase14-verify.sh:4-18, 24-29, 33-46` (the `verify` output contract) · `docs/phase14-adopt-runbook.md:243-255` (D-17) · `docs/dots-hyprland-workflow.md:11, 218, 328, 339-344` · `.planning/PROJECT.md` (D-02/D-17/D-18/D-38/D-41, POLISH-01) · `.planning/research/v0.3/{ARCHITECTURE,PITFALLS}.md` · commit `2539238`

**Live system (2026-09-12):** GNU Stow 2.4.1-1 · qt6-base 6.11.2-3 · kconfig 6.29.0-1 · illogical-impulse-quickshell-git 0.1.0.r1-8 (Quickshell 0.2.1, rev `7511545e`) · matugen 4.2.0-1 · rsync 3.5.0 · Hyprland 0.56.2 (`configProvider: lua`) · 78 live symlinks into the repo · `graphical-session.target` **inactive** · `~/.config` = 12 GB

---
*Research synthesis for v0.4 — 2026-09-12*
