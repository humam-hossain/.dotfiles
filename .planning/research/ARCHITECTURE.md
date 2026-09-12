# Architecture Research

**Domain:** Personal config capture layer over an installed illogical-impulse (ii) shell, on Arch + Hyprland
**Researched:** 2026-09-12
**Confidence:** HIGH for installer/stow/symlink mechanics (empirically tested on this machine, source cited); MEDIUM for the Quickshell `config.json` write path (source-verified in Qt + Quickshell, not yet executed against the live shell)
**Milestone:** v0.4 Personal config layer

---

## 0. Executive verdict on D-41

D-41 is **directionally right and factually wrong in its stated exception.**

> "Exception is any file an app rewrites atomically (temp + rename replaces the symlink with a plain file, silently losing capture); `~/.config/illogical-impulse/config.json` is the known candidate."

That failure mode **does not apply to `config.json`.** ii writes it through Quickshell's `FileView` → Qt's `QSaveFile`, and `QSaveFile::open()` explicitly resolves the symlink chain (up to 128 levels) to a `finalFileName` *before* creating its temp file. The temp file is therefore created **inside the repo, next to the resolved target**, and `renameOverwrite()` replaces **the repo file**. The symlink in `~/.config` is never touched. Atomic write is not the enemy of symlink capture; it is the best case for it.

The real enemy — empirically confirmed on this machine today — is **the ii installer**, which breaks symlink capture in three distinct ways depending on which upstream helper function touches the path. The milestone's capture design must be organised around *installer collision class*, not around *atomic write*.

Three further findings change the shape of the milestone:

1. **`stow -v=5` exits 1 on GNU Stow 2.4.1.** All twelve `arch/*.sh` stow call sites use exactly that form. Stow is currently broken in this repo's own install scripts.
2. **Stow's default folding is catastrophic here.** Tested: stowing a package whose target dir does not yet exist makes `~/.config` itself a symlink into the repo; a subsequent `rsync -a --delete` from the installer then **deletes repo files**. `--no-folding` is mandatory, and is accepted by 2.4.1 despite being absent from `--help`.
3. **The "real drift" in `~/.config/hypr/custom/` is not personal content.** `keybinds.lua`, `rules.lua`, `variables.lua` and `scripts/__restore_video_wallpaper.sh` are **byte-identical to `vendor/dots-hyprland/dots/.config/hypr/custom/`**. They are installer stubs, not lost work. What the repo is missing is not your edits — it is *ownership of the slots*.

---

## 1. Verified facts (the empirical base for everything below)

All rows tested on this machine, 2026-09-12, or read from cited source. Nothing here is inferred from general principle.

### 1.1 Upstream installer → symlink interaction

Upstream has exactly two file-placement primitives, and they behave **oppositely** toward a stow symlink.

| Upstream helper | Source | Mechanism | Effect on a stow symlink at the destination |
|---|---|---|---|
| `cp_file()` → `cp -f "$1" "$2"` | `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:46-52` | `cp -f` follows the dest symlink and writes through it | **Symlink SURVIVES. Repo content is silently overwritten with upstream's.** |
| `rsync_dir*()` → `rsync -a [--delete]` | `3.files.sh:53-92` | rsync writes a temp in the dest dir then renames over the name | **Symlink is REPLACED by a plain file. Repo untouched; capture silently lost.** |
| `rsync_dir__sync()` where the *destination directory itself* is a folded stow symlink | `3.files.sh:67-76` | rsync follows the dir symlink, `--delete` applies inside it | **Writes INTO the repo and DELETES repo files not present upstream.** |

Empirical proof (scratch dirs, this machine):

```
### cp -f onto a symlink
live/f.conf is: symbolic link        <- link survived
repo/f.conf now: UPSTREAM            <- repo clobbered

### rsync -a --delete into a dir containing a symlink
lived/g.conf is: regular file        <- link destroyed
repo/g.conf still: REPO              <- repo untouched, capture lost

### rsync -a --delete where DEST ITSELF is a symlink-to-dir
repod2 now contains: h.conf          <- "mine.conf" was DELETED from the repo
lived2 is: symbolic link
```

This exactly explains and generalises the two losses already recorded in `docs/phase14-adopt-runbook.md:253-255`:

- kitty: `dots/.config/kitty` is a **directory** → MISC loop (`3.files-legacy.sh:14`) → `install_dir__sync` → rsync → *"upstream's kitty sync replaces the stow symlink with its own real file"*. Confirmed.
- starship: `dots/.config/starship.toml` is a **top-level file** → `3.files-legacy.sh:15` → `install_file` → `cp -f` → *"it is a symlink into the repo, upstream's copy follows it, and your repo copy is overwritten in place"*. Confirmed, and D-17 accepted that loss without knowing the mechanism.

### 1.2 Per-destination behaviour of `./setup install-files`

Read from `3.files-legacy.sh` (the default path; `3.files-exp.sh` runs only under `--exp-files`, which the wrapper never passes).

| Destination under `~/.config` | Line | Helper | Behaviour when the path already exists |
|---|---|---|---|
| every top-level entry of `dots/.config/` except quickshell/fish/hypr/fontconfig, **directories** | `3.files-legacy.sh:14` | `install_dir__sync` | **rsync -a --delete — OVERWRITES and PRUNES** |
| same loop, **files** (`chrome-flags.conf`, `code-flags.conf`, `darklyrc`, `dolphinrc`, `kdeglobals`, `konsolerc`, `starship.toml`, `thorium-flags.conf`) | `3.files-legacy.sh:15` | `install_file` → `cp -f` | **OVERWRITES (through a symlink)** |
| `quickshell/` | `:26` | `install_dir__sync` | **OVERWRITES and PRUNES the whole tree** |
| `fish/` (except `conf.d`) | `:33` | `install_dir__sync_exclude` | OVERWRITES and PRUNES |
| `fontconfig/` | `:41` | `install_dir__sync` | OVERWRITES and PRUNES |
| `hypr/hyprland/` | `:50` | `install_dir__sync` | OVERWRITES and PRUNES |
| `hypr/hyprland.conf` | `:51-54` | inline `mv` | renamed to `hyprland.conf.old` |
| `hypr/hyprlock.conf`, `hypr/hypridle.conf` | `:56`,`:68` | `install_file__auto_backup` | firstrun → `mv $t $t.old` then copy; **not firstrun → writes `$t.new`, leaves `$t` alone** |
| `hypr/hyprland.lua` | `:61` | `install_file` → `cp -f` | **OVERWRITES (through a symlink)** |
| **`hypr/custom/`** | **`:75`** | **`install_dir__ignore_existing`** | **`[ -d $t ]` → prints "already exists, will not do anything" and SKIPS ENTIRELY** |
| `~/.local/share/konsole`, `~/.local/share/icons/illogical-impulse.svg` | `:18`,`:79` | `install_dir` / `install_file` | overwrite |

**Correction to the milestone premise.** The prompt says upstream *"reportedly uses `ignore_existing` semantics for `custom/`"*. The function is *named* `install_dir__ignore_existing` but its body (`3.files.sh:150-160`) never reaches the `--ignore-existing` rsync when the directory exists — it returns after an echo. The real semantics are **skip-if-directory-exists**, which is *stronger* protection than per-file ignore-existing. Verified further: `[ -d ]` returns true for a **symlink to a directory**, so even a folded `~/.config/hypr/custom` symlink causes upstream to skip. `custom/` is the one destination that is genuinely safe under any stow arrangement.

Corollary: on a **fresh** machine, `custom/` does *not* exist when `./setup` runs, so upstream **does** populate it with its seven stub files. Bootstrap ordering must account for that (§5).

### 1.3 Quickshell `config.json` write path

- ii: `~/.config/quickshell/ii/modules/common/Config.qml:64-77` — a `FileView` with `watchChanges: true`, `onAdapterUpdated: fileWriteTimer.restart()` (50 ms debounce, `:55-61`), calling `writeAdapter()` (`:60`). `atomicWrite` is **not set**, so the Quickshell default applies.
- Quickshell `src/io/fileview.cpp`: `if (doAtomicWrite) file.reset(new QSaveFile(state.path)); else file.reset(new QFile(state.path));` then `QSaveFile::commit()`.
- Confirmed present in the installed binary: `strings /usr/bin/quickshell` contains `_ZN9QSaveFileC1ERK7QStringP7QObject` and `_ZN9QSaveFile6commitEv` (`illogical-impulse-quickshell-git 0.1.0.r1-8`, Quickshell 0.2.1, rev `7511545e`).
- Qt 6.11.2 installed. `qtbase/src/corelib/io/qsavefile.cpp`, `QSaveFile::open()`:

```cpp
// Resolve symlinks. Don't use QFileInfo::canonicalFilePath so it still give the expected
// target even if the file does not exist
d->finalFileName = d->fileName;
if (existingFile.isSymLink()) {
    int maxDepth = 128;
    while (--maxDepth && existingFile.isSymLink())
        existingFile.setFile(existingFile.symLinkTarget());
    if (maxDepth > 0)
        d->finalFileName = existingFile.filePath();
}
```

**Conclusion: a stow symlink at `~/.config/illogical-impulse/config.json` survives ii's writes, and the content lands in the repo.** Marked MEDIUM confidence only because it has not been executed live (§9, test E-1).

Bonus consequence, and a genuine argument for symlinks over copy: `watchChanges: true` means a `git checkout`/`git pull` that changes the repo file causes ii to **reload the config live**. Copy-capture cannot give you that.

### 1.4 GNU Stow 2.4.1 on this machine

| Test | Result |
|---|---|
| `stow -v=5 -t T pkg` | **exit 1**, `Unknown option: =` / `Unknown option: 5`, usage dumped |
| `stow --verbose=5 -t T pkg` | exit 0 |
| `stow -v 5 -t T pkg` | exit 0 |
| default stow, target `.config` absent | `T/.config -> ../stow/pkg/.config` — **whole directory folded** |
| `stow --no-folding` | accepted (exit 0) though **absent from `--help`**; creates real dirs, per-file symlinks all the way down |
| stow over an existing plain file | exit 1, `All operations aborted` — **atomic, nothing partially applied** |
| `stow --adopt` over that conflict | exit 0; **live content moved into the repo package**, target becomes a symlink |

`stow -v=5` is used at `arch/alacritty.sh:9`, `arch/btop.sh:8`, `arch/define.sh:7`, `arch/fish.sh:26`, `arch/hyprland.sh:29`, `arch/hyprland.sh:33`, `arch/kitty.sh:10`, `arch/nvim.sh:20`, `arch/rofi.sh:10`, `arch/tmux.sh:17`, `arch/wezterm.sh:10`, `arch/xterm.sh:10`, `arch/yazi.sh:10`, `arch/zsh.sh:43`, `arch/zsh_powerlevel.sh:61`. **Every one is currently a hard failure.** `arch/hyprland.sh` has `set -euo pipefail` (line 2), so line 29 aborts the script and line 33 (swaync stow) never runs. This is a bootstrap blocker, not a cosmetic issue.

### 1.5 Current live/repo state (corrections to the brief)

- **Symlinks into the repo already exist — 78 of them.** The brief's claim that "no symlinks into the repo exist anywhere" is wrong; `stat` `links=1` is the *hard-link* count, which is 1 for a symlink too. Confirmed live: `~/.zshrc`, `~/.tmux.conf`, `~/.Xresources`, `~/.p10k.zsh`, `~/.zprofile`, `~/define.sh`, `~/.config/starship.toml`, `~/.config/qBittorrent` (folded dir), `~/.config/smartmontools` (folded dir), and per-file links under `nvim`, `waybar`, `swaync`, `rofi`, `btop`, `yazi`, `alacritty`, `wezterm`, `kitty`, `system_monitor`, `systemd/user`.
- Two packages are **already folded at directory level** — `~/.config/qBittorrent` and `~/.config/smartmontools`. Neither is an upstream destination, so they are currently harmless, but they are live proof that the default folding happens.
- `~/.config/hypr/custom/`: `general.lua` = repo (1004 B, personal, dual-head + workspace pins); `env.lua`/`execs.lua` = 1 B, identical to both repo and upstream stub; `keybinds.lua`/`rules.lua`/`variables.lua`/`scripts/__restore_video_wallpaper.sh` = **byte-identical to the vendored upstream stubs**, mtime `Jul 25 19:12` (the submodule checkout mtime, preserved by `rsync -a`).
- Repo tracks a second, parallel copy tree at repo root `.config/` — `dolphinrc`, `kdeglobals`, `hypr/custom/{env,execs,general}.lua`, plus the **pre-adopt** `hypr/hyprland.conf`, `hyprland.conf.bak`, `hyprland-gui.conf`, `hyprlock.conf`, `hypridle.conf`, `hyprpaper.conf`.
- `.config/dolphinrc` and `.config/kdeglobals` both **differ from live** — the copy tree is stale, which is exactly the failure D-41 is trying to eliminate.
- **`arch/hyprland.sh:25-26` is a live landmine:**
  ```bash
  mkdir -p ~/.config/hypr
  cp -rf .config/hypr/* ~/.config/hypr/
  ```
  This restores the **pre-adopt `hyprland.conf`** over the ii Lua session, undoing Phase 14. It also uses a cwd-relative path with no `cd`, so it only works when invoked from the repo root. It must be deleted before any bootstrap runs it.
- **Generated, not personal.** `~/.config/matugen/config.toml` declares templates writing `~/.config/gtk-3.0/gtk.css`, `~/.config/gtk-4.0/gtk.css`, `~/.config/hypr/hyprland/colors.lua`, `~/.config/hypr/hyprlock/colors.conf`, `~/.config/fuzzel/fuzzel_theme.ini`. `~/.config/kdeglobals` is material-you colour output (`[ColorEffects:Disabled] Color=#211f24`, mtime today 06:00). `~/.config/Kvantum/` is pure upstream (`Colloid`, `MaterialAdw`, mtime = submodule checkout). **None of these belong in the repo.** The milestone's target list ("`kdeglobals`, `Kvantum`, gtk-3.0/4.0") must be narrowed — see §8.
- `~/.config/gtk-3.0/` contains **both** personal (`settings.ini`, `bookmarks`) and generated (`gtk.css`) content. `~/.config/gtk-4.0/gtk.css` is a symlink to `/usr/share/themes/catppuccin-mocha-.../gtk-4.0/gtk.css`. **Capture granularity must therefore be per-file, never per-directory.**
- `~/.config/{kiorc,ktrashrc,kservicemenurc}` and `~/.config/autostart/FDM.desktop` are **not** shipped by upstream at all → zero collision risk → pure symlink candidates.
- No git hooks installed (`.git/hooks/` contains only samples — actually empty of non-samples). No `inotifywait` installed. No systemd user path units or timers.
- `verify` scaffolding that exists: `scripts/phase14-verify.sh` — a 500+ line read-only checker with the exact output contract to reuse (`:24-29`, `:38-41`): `[PASS]` / `[FAIL]` (moves exit) / `[FINDING]` (never moves exit) / `[INFO]` (unobservable, named not skipped), trailing `=== done: FAIL=n FINDINGS=n ===`, exit 0/1. `docs/dots-hyprland-workflow.md:328` documents the expected output. **Build `verify` on this contract; do not invent a new one.**

---

## 2. Recommended architecture

### 2.1 The one-sentence model

> **Three mechanisms, distinguished by repo location, chosen by *installer collision class*, enumerated by walking the trees, and asserted by one `verify`.**

### 2.2 Repo tree

```
.dotfiles/
├── bootstrap                      # NEW — resumable one-command entry (§5)
├── arch/
│   ├── dots-hyprland.sh           # MODIFY — gains `verify` + `capture` subcommands (§4, §6)
│   ├── hyprland.sh                # MODIFY — DELETE the `cp -rf .config/hypr/*` line (§6)
│   └── *.sh                       # MODIFY — `-v=5` → `--verbose=5`; add `--no-folding`
│
├── stow/                          # MECHANISM 1: symlink. live IS the repo.
│   ├── <18 existing packages>/
│   ├── hypr/                      # NEW  ~/.config/hypr/custom/*.lua + custom/scripts/
│   │   └── .config/hypr/custom/{general,env,execs,keybinds,rules,variables}.lua
│   │                               └── scripts/
│   ├── ii/                        # NEW  ~/.config/illogical-impulse/config.json
│   ├── kde/                       # NEW  kiorc, ktrashrc, kservicemenurc  (no upstream collision)
│   ├── gtk/                       # NEW  gtk-3.0/settings.ini, gtk-3.0/bookmarks,
│   │                               #      gtk-4.0/settings.ini  (NOT gtk.css — generated)
│   └── autostart/                 # NEW  ~/.config/autostart/*.desktop
│
├── restow/                        # MECHANISM 2: symlink, but installer-hostile.
│   │                              # Same layout as stow/. Stowed identically, but the
│   │                              # bootstrap/verify contract requires a RE-STOW after
│   │                              # every `./setup install-files`, because upstream
│   │                              # rsync replaces the link (dirs) or cp -f writes
│   │                              # through it (top-level files).
│   ├── kitty/  .config/kitty/kitty.conf          (rsync-replace class)
│   ├── zsh-starship/ .config/starship.toml       (cp-through class — see §2.4)
│   └── kde-upstream/ .config/{dolphinrc,darklyrc,konsolerc}
│
├── capture/                       # MECHANISM 3: copy. Defined, DELIBERATELY EMPTY at
│   │                              # milestone start. Populated only when `verify` proves
│   │                              # a path is clobbered despite being in stow/ or restow/.
│   └── README.md                  # the admission criteria + how to promote a path here
│
├── docs/
│   ├── capture-model.md           # NEW — the human-readable mechanism table
│   └── archive/pre-adopt-hypr/    # MOVED — repo-root .config/hypr/* pre-adopt confs
│
└── vendor/dots-hyprland/          # unchanged: product only, never a capture target
```

**Repo-root `.config/` is retired.** Its `hypr/custom/*.lua` move to `stow/hypr/`; `dolphinrc` moves to `restow/kde-upstream/`; `kdeglobals` is **deleted** (generated); the pre-adopt hypr confs move to `docs/archive/pre-adopt-hypr/` (they are also in git history). Its only consumer today is the `cp -rf` line being deleted from `arch/hyprland.sh`.

### 2.3 Why three trees and not two

The brief asked for two mechanisms. The evidence says there are three *operational contracts*, and collapsing the middle one into either neighbour loses information the bootstrap and `verify` both need:

- `stow/` — stow once, never think about it again. Nothing upstream touches these paths.
- `restow/` — stow the same way, but **`./setup install-files` breaks it every time**, in a mechanism-specific way. The bootstrap must re-stow *after* setup; `verify` must know that a broken link here is "expected after a pin bump, run restow" rather than "something went wrong". `docs/phase14-adopt-runbook.md:243-255` already hand-maintains exactly this knowledge for kitty as prose; `restow/` turns that prose into a directory.
- `capture/` — the copy fallback. Empty by construction.

If you put kitty in `stow/`, `verify` cannot tell a routine post-install re-stow from a genuine hijack. If you put it in `capture/`, you lose live-is-repo for a file that is perfectly happy as a symlink 99% of the time.

### 2.4 The `cp -f` class needs one extra rule

For `restow/zsh-starship` and `restow/kde-upstream`, upstream's `cp -f` **writes through the surviving symlink into the repo** (§1.1). So after `./setup install-files` the link is intact but the *repo file now contains upstream's content* — `verify` sees a valid symlink and a dirty git tree. The recovery is not `stow -R`; it is `git checkout -- restow/<pkg>`.

`verify` must therefore distinguish, for `restow/` paths only:

- link broken + repo clean → rsync class → fix: `stow -R --no-folding <pkg>`
- link intact + repo dirty right after an install → cp-through class → fix: `git checkout -- restow/<pkg>`

This is the single most subtle thing in the design and the reason `restow/` exists as its own tree.

### 2.5 Mechanism selection rule (the decision procedure)

```
For a path P under $HOME:

  Is P generated by matugen / material-you / the shell itself?        -> UNMANAGED. Record in
     (gtk.css, kdeglobals, hypr/hyprland/colors.lua, hyprlock/colors.conf,   docs/capture-model.md
      fuzzel_theme.ini, ~/.local/state/quickshell/**)                        as a GUARD path.

  Is P produced wholly by `./setup` with no personal edit?            -> UNMANAGED (vendor owns it).
     (Kvantum/, quickshell/, hypr/hyprland/, fontconfig/, wlogout/,          Restored by re-running
      matugen/, xdg-desktop-portal/, mpv/, foot/, fuzzel/, zshrc.d/)         the installer.

  Does `./setup` write P?   (grep the destination tables in §1.2)
       no  -> stow/<pkg>/
      yes  -> restow/<pkg>/         [note its class: rsync-replace | cp-through]

  Did `verify` observe P clobbered despite being stowed, >=2 times?   -> promote to capture/<pkg>/
```

Nothing is admitted to `capture/` on suspicion. Only on evidence.

### 2.6 Component responsibilities

| Component | Responsibility | Never does |
|---|---|---|
| `stow/` tree | Authoring surface for collision-free personal config | — |
| `restow/` tree | Same, for paths `./setup` overwrites | — |
| `capture/` tree | Mirror of live for paths proven un-symlinkable | Be the authoring surface |
| `bootstrap` | Order the fresh-machine phases; persist resume state; report partial completion | Run `./setup` twice; auto-`--adopt`; assume a graphical session |
| `arch/dots-hyprland.sh verify` | Read-only drift assertion across all three trees + GUARD paths | Mutate anything |
| `arch/dots-hyprland.sh capture` | Idempotent live→`capture/` mirror | `git add`, `git commit`, or touch `stow/`/`restow/` |
| `dotfiles-capture.timer` | Call `capture` on a schedule | Anything else |
| `vendor/dots-hyprland` | Product + installer, source of truth for install steps | Ever be a capture destination |
| `docs/capture-model.md` | The human-readable mechanism + collision-class table | Be parsed by code |

---

## 3. Control and data flow

### 3.1 Capture (steady state)

```
                  you edit a config, or an app rewrites it
                                   |
        +--------------------------+---------------------------+
        |                          |                           |
   stow/ or restow/ path       capture/ path             GUARD / vendor path
        |                          |                           |
   write lands in the          write lands in            write lands in $HOME
   REPO through the            $HOME only                only; repo never sees it
   symlink (QSaveFile                |                           |
   resolves it; ordinary             | dotfiles-capture.timer    | (by design)
   editors follow it)                | (15 min + OnBootSec)      |
        |                            v                           v
        |                     `dots-hyprland.sh capture`      nothing
        |                     rsync live -> capture/
        |                     SKIPS any path whose repo
        |                     copy is dirty vs HEAD
        |                            |
        +------------+---------------+
                     v
            `git status` shows the change as an unstaged diff.
            You review and commit. Nothing auto-commits, ever.
```

**No manual sync** is satisfied structurally for `stow/` + `restow/` (the write *is* the capture) and by the timer for `capture/`. The only manual act left is `git commit`, which is review, not sync.

### 3.2 Bootstrap (fresh machine) — see §5 for the full phase table

```
clone --recurse-submodules
        v
./bootstrap  ---> [1 preflight] [2 submodules] [3 base pkgs*] [4 hypr stack*]
                  [5 ./setup install*  <- INTERACTIVE, writes custom/ stubs]
                  [6 de-stub: delete custom/* files byte-identical to vendor]
                  [7 stow -R --no-folding  stow/ + restow/]
                  [8 restore capture/ -> $HOME]
                  [9 systemctl --user enable (not --now)]
        v
   ==== STOP: reboot / log into Hyprland ====        (* = needs root)
        v
./bootstrap  ---> [9b systemctl --user start] [10 verify]
        v
   `=== done: FAIL=0 ===`
```

### 3.3 Verify

```
enumerate stow/**  -> LINK set      (target = $HOME + path after stow/<pkg>/)
enumerate restow/**-> LINK set      (same, tagged restow + collision class)
enumerate capture/**-> COPY set
hardcoded          -> GUARD set     (generated + vendor-owned paths)

for each LINK target:   symlink? -> points into repo? -> right package? -> no folded ancestor?
for each COPY target:   exists?  -> not a symlink?    -> content equal?
for each GUARD path:    absent from all trees? not a symlink into the repo?
cross-cutting:          uncaptured neighbours; stray QSaveFile temp files; submodule SHA;
                        qs binary + ii/shell.qml + running qs -c ii   (POLISH-01)
```

---

## 4. `verify` — algorithm, exit codes, output

Lives as `arch/dots-hyprland.sh verify`, implemented in a sourced helper or a `scripts/` library shared with `bootstrap`. Reuses the `phase14-verify.sh` output contract verbatim.

### 4.1 Enumeration

```
REPO=$(git rev-parse --show-toplevel)
LINK_TARGETS  = for T in stow restow: for F in $(find $REPO/$T/<pkg> -type f -o -type l):
                  rel = ${F#$REPO/$T/<pkg>/}
                  target = $HOME/$rel        # repo layout mirrors $HOME exactly
COPY_TARGETS  = same over capture/
GUARD_PATHS   = fixed list in docs/capture-model.md, mirrored as an array in the script,
                asserted equal by a lint (same pattern as scripts/phase10-inventory-assert.sh)
```

Enumeration is **purely structural** — no manifest to drift. That is the main reason for Layout A (§7).

### 4.2 Per-target checks

**LINK target T (repo source R, package P):**

| # | Condition | Level | Message / fix |
|---|---|---|---|
| L0 | any ancestor of T under `$HOME` is a symlink into the repo | **FAIL** | `folded directory: <A> -> repo. An installer rsync --delete here will delete repo files. Fix: stow -D <P> && stow --no-folding <P>` |
| L1 | T does not exist | **FAIL** | `not stowed. Fix: cd stow && stow -R --no-folding <P>` |
| L2 | T exists, not a symlink, `cmp -s T R` | **FAIL** (tree=`stow`) / **FINDING** (tree=`restow`) | `clobbered by a copy, content identical. Fix: rm T && stow -R --no-folding <P>` |
| L3 | T exists, not a symlink, content differs | **FAIL** | `REPLACED — live content is not in the repo. Diff follows. Decide before restowing.` + `diff -u R T \| head -40` |
| L4 | T is a symlink resolving outside `$REPO` | **FAIL** | `hijacked -> <resolved>` |
| L5 | T is a symlink into `$REPO` but not to R | **FAIL** | `wrong package: -> <resolved>, expected <R>` |
| L6 | T is the correct symlink, R differs from `git show HEAD:<R>` | **INFO** | `captured, uncommitted` — **this is success, not drift** |
| L7 | T is the correct symlink, R == HEAD | **PASS** | — |
| L8 | tree=`restow`, class=`cp-through`, R differs from HEAD **and** R matches `vendor/dots-hyprland/dots/<rel>` byte-for-byte | **FAIL** | `upstream wrote through the symlink into the repo. Fix: git checkout -- <R>` |

L8 is the discriminator described in §2.4 and is the only check that consults the vendor tree.

**COPY target T (repo mirror R):**

| # | Condition | Level | Message |
|---|---|---|---|
| C1 | T missing | **FAIL** | `not restored. Fix: dots-hyprland.sh capture --restore` |
| C2 | T is a symlink into the repo | **FAIL** | `mechanism mismatch — a capture/ path is symlinked. Either demote the link or promote the path to stow/.` |
| C3 | `cmp -s T R` fails, R clean vs HEAD | **FINDING** | `capture stale by <N>s — the timer will pick this up` |
| C4 | `cmp -s T R` fails, R dirty vs HEAD | **FAIL** | `capture BLOCKED: repo mirror has uncommitted edits that live does not have. capture skips this path. Commit or discard <R>.` |
| C5 | equal | **PASS** | — |

**GUARD path G:**

| # | Condition | Level |
|---|---|---|
| G1 | G appears under `stow/`, `restow/` or `capture/` | **FAIL** — `generated/vendor-owned path was captured; it will churn every wallpaper switch` |
| G2 | G is a symlink into the repo | **FAIL** |
| G3 | otherwise | **PASS** |

**Cross-cutting:**

| # | Check | Level |
|---|---|---|
| X1 | a live file sits next to a managed file, in the same directory, with no repo counterpart — **and** is not byte-identical to the vendor stub | **FINDING** `uncaptured neighbour: <T>` |
| X1b | same, but **is** byte-identical to `vendor/dots-hyprland/dots/<rel>` | **INFO** `unclaimed upstream stub: <T>` (this is today's `keybinds.lua` case — correctly *not* drift) |
| X2 | files matching `*.??????` under the three trees | **FINDING** `stray atomic-write temp file` |
| X3 | `git ls-tree HEAD vendor/dots-hyprland` SHA == checked-out submodule SHA | PASS/FAIL (POLISH-01) |
| X4 | `command -v qs`, `~/.config/quickshell/ii/shell.qml` exists, a `qs`/`quickshell` process is running | PASS / FINDING (POLISH-01; **INFO** when there is no graphical session — never a FAIL, per `phase14-verify.sh:10-14`) |
| X5 | `stow --version` >= 2.3.0 and `stow --no-folding -n` returns 0 | PASS/FAIL (§1.4 landmine) |
| X6 | summary: `N files captured since last commit` | INFO |

### 4.3 Contract

- **Exit 0** — zero FAIL. FINDINGS may be non-zero.
- **Exit 1** — one or more FAIL.
- **Exit 2** — precondition error (not a git repo, stow missing, `$HOME` unreadable). Distinct from 1 so the bootstrap can tell "config drifted" from "cannot check".
- `--strict` promotes every FINDING to FAIL (for `bootstrap`'s final gate and any future CI).
- `--tree stow|restow|capture` scopes the run.
- Final line: `=== done: FAIL=<n> FINDINGS=<n> ===` — same shape as `docs/dots-hyprland-workflow.md:328`.
- **Read-only, absolutely.** Same prohibition block as `scripts/phase14-verify.sh:4-18`. `verify` prints fixes; it never applies them.

### 4.4 What counts as drift vs. expected difference

| Observation | Verdict |
|---|---|
| stowed file's repo content differs from HEAD | **Expected.** This is capture working. INFO. |
| live file is a plain copy where a symlink belongs | **Drift.** |
| upstream stub sitting un-owned next to a managed file | **Expected until claimed.** INFO, not FAIL — otherwise `verify` is red from day one. |
| `capture/` mirror lagging live | **Expected within the timer window.** FINDING. |
| generated file (`gtk.css`, `kdeglobals`) differing from anything | **Not drift.** Not managed. |
| `hypr/hyprland.conf.old` present | **Expected.** Phase 14 artefact. |

---

## 5. One-command bootstrap

### 5.1 Phase table

| # | Phase | Root? | Graphical session? | Idempotent? | Notes |
|---|---|---|---|---|---|
| 0 | `git clone --recurse-submodules` | no | no | yes | **Outside the command** (chicken/egg). One documented line in README. |
| 1 | preflight | no | no | yes | arch? stow >= 2.3 + `--no-folding` works? submodule initialised? not root (`setup:10` `prevent_sudo_or_root`)? `$HOME` writable? Exit 2 on failure. |
| 2 | `git submodule update --init --recursive` | no | no | yes | |
| 3 | base packages (`arch/necessary.sh`, `tools.sh`, `fonts.sh`, …) | **yes** | no | yes (`pacman --needed`) | |
| 4 | Hyprland stack (`arch/hyprland.sh`, **reworked**) | **yes** | no | yes | must **not** `cp -rf .config/hypr/*`; must stow with `--no-folding --verbose=5` |
| 5 | `arch/dots-hyprland.sh install` | **yes** | no | **NO — see 5.3** | **INTERACTIVE**: `setup:73` `pause`, `0.greeting.sh`. Calls `try hyprctl reload` (`3.files.sh:238`) — `try` so it is non-fatal without a compositor. |
| 6 | de-stub `~/.config/hypr/custom/` | no | no | yes | delete only files byte-identical to `vendor/…/dots/.config/hypr/custom/<f>`; anything else → abort and report |
| 7 | `stow -R --no-folding --verbose=5` over `stow/` + `restow/` | no | no | yes | abort on conflict; **never auto-`--adopt`** |
| 8 | restore `capture/` → `$HOME` (`rsync -a`) | no | no | yes | no-op while `capture/` is empty |
| 9a | `systemctl --user daemon-reload` + `enable` (no `--now`) | no | no | yes | `enable` works without an active session |
| — | **STOP #1 — reboot or log into Hyprland** | | | | unavoidable: phase 5 replaced the session entry with `hyprland.lua`, and nothing graphical exists yet on a fresh machine |
| 9b | `systemctl --user start dotfiles-capture.timer`, confirm `graphical-session.target` (D-38) | no | **yes** | yes | |
| 10 | `verify --strict` | no | **yes** | yes | X4 needs a running `qs`; `hyprctl` needs `HYPRLAND_INSTANCE_SIGNATURE` |

### 5.2 Where the single command necessarily stops

**Exactly once, between 9a and 9b.** On a fresh machine phases 1–9a run from a TTY with no compositor; phases 9b–10 need a live Hyprland session. `./setup` itself renames `hyprland.conf` → `.old` and installs `hyprland.lua`, so the session in effect *after* phase 5 is not the session in effect *before* it, and no amount of ordering removes the relogin.

So the honest contract is:

> `./bootstrap` → reboot → `./bootstrap` → `=== done: FAIL=0 ===`

Not one invocation. **One command, run twice, with a reboot between.** The milestone requirement "one command yields the exact setup, verified" is met by *the same command being correct to re-run*, not by a single process. Say this plainly in the requirement rather than discovering it in phase 5.

A second, softer stop is phase 5's upstream `pause` and greeting — the operator presses Enter at least once. `arch/dots-hyprland.sh` deliberately never injects `--force`/`--skip-allgreeting` (`usage()` at `arch/dots-hyprland.sh:57-61`). Keep it that way; an unattended full install of a destructive installer is not a feature.

### 5.3 Idempotence caveat on phase 5

`./setup install` is *safe* to re-run but **not identical** on re-run:

- `install_file__auto_backup` (`3.files.sh:102-120`) branches on `INSTALL_FIRSTRUN`, which is derived from the existence of `~/.config/illogical-impulse/installed_true` (`3.files.sh:206-210`). Firstrun: `mv $t $t.old` + copy. Not firstrun: writes `$t.new` and leaves `$t` alone. So `hyprlock.conf`/`hypridle.conf` are replaced on the first run and merely shadowed thereafter.
- `hyprland.conf` → `.old` only fires when `hyprland.conf` exists (`3.files-legacy.sh:51`), so it fires once.
- `install_dir__ignore_existing` for `custom/` fires once (first run), never again.
- The wrapper passes `--skip-backup` by default (`arch/dots-hyprland.sh:704,183-185`), so there is no snapshot. `--keep-backup` is the escape hatch.

Therefore: `bootstrap` **must** record phase-5 completion in state and skip it on resume. Re-running the whole bootstrap after a successful install must not re-enter phase 5 silently.

### 5.4 Resume state and partial-completion reporting

State file: `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/bootstrap.state`, one `phase=<n> status=<ok|failed> at=<iso8601>` line per phase. Chosen over a repo-local file so a `git clean` cannot resurrect a destructive phase.

Report shape (printed at start and end of every run):

```
  [x] 1  preflight                       ok    2026-09-12T15:02:11Z
  [x] 2  submodules                      ok    2026-09-12T15:02:19Z
  [x] 5  ii ./setup install              ok    2026-09-12T15:18:44Z
  [>] 9b systemd user units              PENDING — needs a graphical session
  [ ] 10 verify --strict                 blocked by 9b
  ==== reboot into Hyprland, then re-run ./bootstrap ====
```

`--from <n>` / `--only <n>` for recovery; `--dry-run` printing the phase plan without executing, matching the wrapper's existing `--dry-run` convention (`arch/dots-hyprland.sh:704`).

One `sudo -v` at the top of phase 3 with a keepalive, so the operator types a password once; upstream runs its own keepalive inside phase 5 (`setup:75-77`).

---

## 6. Supersession analysis (D-02 / D-17 / D-18)

### 6.1 What is superseded

| Superseded | By | Scope |
|---|---|---|
| **D-02 / D-17 "repo = authoring source of truth, live = applied copy, with an explicit apply step"** — for `stow/` and `restow/` paths | D-41 symlink capture | For these paths, **live and repo are the same inode**. There is no apply step and no copy to go stale. Authoring happens wherever you open the file. |
| **D-18** (`cp -a` of `general.lua`, `env.lua`, `execs.lua` from repo `.config/hypr/custom/` into live) | `stow -R --no-folding hypr` | The three-file `cp -a` is retired. Phase 13's authoring SoT moves from repo-root `.config/hypr/custom/` to `stow/hypr/.config/hypr/custom/`. |
| Repo-root `.config/` as a deploy tree | `stow/` + `restow/` + `docs/archive/` | Its only executor is `arch/hyprland.sh:26`. |

### 6.2 What stays true

| Still true | Why |
|---|---|
| **The repo is the durable source of truth.** | Git history is the undo for every mechanism, including symlink capture. What changed is *where you type*, not *what you trust*. |
| **`vendor/dots-hyprland` is product-only and is never a capture destination.** | Phase 13's fence. The one new use is *read-only*: `verify` compares against vendor stubs (X1b, L8). |
| **`~/.config/quickshell` is a real directory, never a symlink into the repo.** | `docs/dots-hyprland-workflow.md:11,218`, LIVE-01. Now *proven* rather than asserted: `3.files-legacy.sh:26` is `install_dir__sync` = `rsync -a --delete`; §1.1 test 3 shows that through a folded dir symlink it **deletes repo files**. |
| **D-17's starship.toml loss is real and unchanged.** | Mechanism now identified: `cp -f` through a symlink (`3.files.sh:49`). Generalised into the `restow/` cp-through class rather than accepted as a one-off. |
| **The safe profile stays retired (Phase 16).** | Nothing here reintroduces install profiles. |
| **Rollback is the repo runbook, never `./setup uninstall`.** | Unchanged. `--upstream-dangerous` remains token-gated. |

### 6.3 Concrete rework list

| File / function | Line(s) | Change | Severity |
|---|---|---|---|
| `arch/hyprland.sh` | 25-26 | **DELETE** `mkdir -p ~/.config/hypr; cp -rf .config/hypr/* ~/.config/hypr/`. Restores the pre-adopt `hyprland.conf` over the Lua session and undoes Phase 14. Replace with `stow -R --no-folding --verbose=5 -t ~ hypr`. | **BLOCKER** |
| `arch/hyprland.sh` | 29, 33 | `-v=5` → `--verbose=5`; add `--no-folding` | **BLOCKER** (exit 1 today) |
| `arch/{alacritty,btop,define,fish,kitty,nvim,rofi,tmux,wezterm,xterm,yazi,zsh,zsh_powerlevel}.sh` | the `stow -v=5` line in each | same fix | **BLOCKER** |
| `arch/dots-hyprland.sh` | 14 | `ALLOWLIST` gains `verify` and `capture` | required |
| `arch/dots-hyprland.sh` | 771-805 (`main`) | route `verify`/`capture` like `uninstall` (own handler), **not** into `run_install_family` — they are not upstream subcommands and `./setup` would reject them | required |
| `arch/dots-hyprland.sh` | 22-104 (`usage`) | document the two new subcommands; the docstring is the flag SoT per DOC-01 | required |
| `arch/dots-hyprland.sh` | 115-120 (`preflight`) | `verify` must run **without** an initialised submodule for the stow/capture half, and degrade to INFO for the X3 submodule-SHA check. Do not reuse `preflight` unchanged — it `exit 1`s. | required |
| `arch/dots-hyprland.sh` | 162-187 (`collect_ii_config_targets`) | `uninstall` targets `$II_CONFDIR` = `~/.config/illogical-impulse`. Once `config.json` is a stow symlink, `rm -rf` on the *directory* removes the link, not the repo file — safe. **But** add a guard: refuse any path inside `REPO_ROOT`. Today `safe_rm_path` (`:428-450`) only guards `$HOME/*` and `*/.config/hypr*`, and the repo lives at `$HOME/github_repo/.dotfiles`, so a repo path would pass. | hardening |
| `arch/dots-hyprland.sh` | 428-450 (`safe_rm_path`) | add the `REPO_ROOT` refusal above | hardening |
| `.config/` (repo root) | all | migrate per §2.2; delete `kdeglobals` (generated); archive pre-adopt hypr confs | required |
| `docs/dots-hyprland-workflow.md` | §7 (~line 328) | add the capture model and the new `verify` expected output | required |
| `docs/phase14-adopt-runbook.md` | 243-255 | the hand-maintained kitty/starship asymmetry is now encoded in `restow/`; point the prose at `docs/capture-model.md` | required |
| `scripts/phase14-verify.sh` | — | **keep as-is.** It is a Phase 14 historical assertion against a recorded baseline (`:44,:57-63`). The new `verify` borrows its output contract; it does not replace it. | no change |

---

## 7. Alternatives considered and rejected

### 7.1 Layout: manifest-driven single tree (rejected)

`stow/` for everything plus a `capture.tsv` declaring `path<TAB>mechanism<TAB>collision-class`.

| | Layout A — mechanism by directory (**chosen**) | Layout B — single tree + manifest |
|---|---|---|
| How a human knows the mechanism | `ls` the path | open and grep a TSV |
| Enumeration | `find` the tree — cannot disagree with itself | parse TSV, then reconcile with the tree; two sources that **will** drift |
| Adding a file | drop it in the right tree, `stow -R` | edit the tree *and* the manifest; forget one and it is silently unmanaged |
| Per-file granularity | yes (only files present are managed) | yes |
| Extra metadata (collision class) | encoded as `restow/` membership; richer notes live in `docs/capture-model.md`, which code does not parse | native |
| Failure mode | a file in the wrong tree — `verify` L2/C2 catches it | a manifest row with no file, or a file with no row — needs its own lint |
| Fits existing repo | yes — `stow/<pkg>/.config/...` is already the convention for 18 packages | no — new concept |

Rejected because the manifest is a second source of truth for something the filesystem already states unambiguously, and the repo has a documented allergy to prose-as-evidence (D-20). A tree cannot lie about which tree it is in.

The collision-class metadata that *would* have justified a manifest is only needed for the `restow/` tree and only to choose a fix message. Two subdirectories (`restow/<pkg>` + a class note in `docs/capture-model.md`, lint-asserted against the script's array in the `scripts/phase10-inventory-assert.sh` style) cover it without a parser.

### 7.2 Stow folding (rejected — use `--no-folding`)

The brief asks whether a folded `~/.config/hypr/custom` symlink-to-directory, into which the installer then writes, is desirable auto-capture or dangerous.

**Neither — for `custom/` specifically it is a no-op**, because `install_dir__ignore_existing` tests `[ -d $t ]`, which is true for a symlink-to-directory, so upstream skips entirely (§1.2, verified). Folding `custom/` is harmless.

**But folding anywhere else is catastrophic**, and stow folds by default whenever the target directory does not yet exist — which on a fresh machine is *every* target directory. Empirically (§1.4): stowing a package with `.config/app/...` into an empty target produced `target/.config -> ../stow/pkg/.config`. **The whole of `~/.config` became a symlink into the repo.** Then (§1.1 test 3) `rsync -a --delete` into a folded destination deleted a repo file. Composing those two: on a fresh machine, `stow` before `./setup` would cause `install_dir__sync dots/.config/quickshell ~/.config/quickshell` to write the entire ii tree **into the git repo** and `--delete`-prune whatever was there.

Two live packages are already folded at directory level today (`~/.config/qBittorrent`, `~/.config/smartmontools`). Neither is an upstream destination, so they are currently safe — but they are an existing instance of the hazard, and `verify` check L0 exists to surface them.

**Recommendation: `--no-folding` unconditionally, on every stow invocation in the repo.** Cost: more symlinks. Benefit: no directory under `$HOME` is ever a door into the repo, so no third-party tool can write into git by accident. Given that the one tool guaranteed to run over these exact directories uses `rsync --delete`, this is not a close call.

Auto-capture of installer output is not a goal anyway — vendor content belongs in `vendor/`, where it already is, pinned.

### 7.3 Copy-capture trigger mechanism

| Mechanism | Reliability | Crash risk | Surprise | Can capture a half-written file? | Verdict |
|---|---|---|---|---|---|
| (a) manual `capture` subcommand | total | none | none | only if you run it mid-write | **keep — same code path, invoked by (d)** |
| (b) git `pre-commit` hook pulling live→repo | poor — only fires if you commit, never fires for `commit --no-verify`, and `.git/hooks` is **not** version-controlled, so a fresh clone has no hook at all | low | **high** — silently changes the tree you are committing; `git commit -a` semantics break; the diff you reviewed is not the diff you commit | yes | **reject** |
| (c) inotify watcher copying on change | `inotifywait` is **not installed**; a long-lived shell daemon that must be babysat; mutates the repo working tree under your editor → mid-rebase surprises; QSaveFile's rename fires `IN_MOVED_TO` which is safe, but plain-write apps fire `IN_MODIFY` repeatedly | medium — the watcher dies silently and capture stops with no signal | high | yes, for `IN_MODIFY` writers | **reject** |
| (d) systemd user timer | high — systemd restarts it, failures land in the journal, `systemctl --user status` answers "is it working?" | **none for the session** — a failing timer unit cannot take down Hyprland | low — scheduled, visible, disableable | only by bad luck at rest; content-validate before writing (JSON parse for `*.json`) | **RECOMMEND** |
| (e) shell `precmd` / exit hook | fires only when you happen to open a shell; nondeterministic | **high** — a bug makes every prompt slow or every shell unusable; `.zshrc` is itself stowed, so a bad hook is instantly everywhere | high | yes | **reject hard** |

**Recommended: (d) `dotfiles-capture.timer` → `dotfiles-capture.service` → `arch/dots-hyprland.sh capture`.**

```ini
# stow/systemd/.config/systemd/user/dotfiles-capture.timer
[Timer]
OnBootSec=3min
OnUnitActiveSec=15min
Persistent=true
```

`Type=oneshot`, `Nice=10`, no `Restart=`. Ships in the existing `stow/systemd` package alongside `hyprland-session.service`, which is already stowed and already symlinked live (`~/.config/systemd/user/hyprland-session.service -> …/stow/systemd/…`).

**`capture` rules — the whole safety argument:**

1. Writes **only** into `capture/`. Never `stow/`, never `restow/`, never `$HOME`.
2. **Never** runs `git add` or `git commit`. Every capture appears as an unstaged diff you can `git checkout` away. Git is the review gate and the undo.
3. **Skips any path whose repo mirror is dirty vs `HEAD`** (`git diff --quiet -- <R>`), emitting a warning. This is the entire conflict policy, and it is checkable in one command.
4. Content-validates before writing where a format exists (`jq -e . <file>` for JSON). A truncated read is dropped, not mirrored.
5. Refuses to run when git is mid-operation (`.git/rebase-merge`, `.git/MERGE_HEAD`, `.git/CHERRY_PICK_HEAD` present).
6. Uses `rsync -a --checksum` so an unchanged file does not churn mtimes.

**Conflict resolution when live and repo both changed:** `capture` skips and warns (rule 3); `verify` reports it as **C4 FAIL**. The human resolves by committing or discarding the repo-side edit. Copy-capture is a one-directional mirror; the moment you author in the mirror you have made an error the tooling should stop on, not silently arbitrate. Auto-merging two versions of a config file is the failure mode that loses data quietly, which is precisely what this milestone exists to prevent.

### 7.4 Rejected: put personal overlays on the fork (`vendor/dots-hyprland/dots/.config/hypr/custom/`)

Already rejected in v0.3 (`.planning/research/v0.3/ARCHITECTURE.md:150`). Still right: pin-bumps would fight personal edits, and it puts personal config behind a submodule boundary where `verify` and `git status` in the parent cannot see it.

### 7.5 Rejected: `stow --adopt` inside `bootstrap`

`--adopt` is the correct *interactive* primitive for the initial capture of today's live files (§1.4 test F: it moves live content into the package and leaves a symlink). It is the wrong *automatic* primitive: on a fresh machine after phase 5, `--adopt` would move **upstream's stub `keybinds.lua`** into the repo and overwrite your version, silently, with the tree looking perfectly correct afterward. `bootstrap` aborts on conflict and prints the `--adopt` command for a human to run after reading the diff.

---

## 8. Narrowing the milestone's capture list

The milestone names "Dolphin + KDE app configs captured — `dolphinrc`, `kdeglobals`, `kiorc`, `ktrashrc`, `kservicemenurc`, `Kvantum`, `darklyrc`, gtk-3.0/4.0". The evidence splits that list four ways:

| Path | Upstream ships it? | Verdict |
|---|---|---|
| `kiorc`, `ktrashrc`, `kservicemenurc` | **no** | `stow/kde/` — clean, zero collision |
| `~/.config/autostart/FDM.desktop` | no | `stow/autostart/` |
| `gtk-3.0/settings.ini`, `gtk-3.0/bookmarks`, `gtk-4.0/settings.ini` | no | `stow/gtk/` — **per file**, not the directory |
| `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` | no, but **matugen generates them** (`~/.config/matugen/config.toml:20-26`); gtk-4.0's is a symlink to `/usr/share/themes/catppuccin-mocha-…` | **GUARD — do not capture** |
| `dolphinrc`, `darklyrc`, `konsolerc` | yes, top-level file → `cp -f` | `restow/kde-upstream/`, cp-through class |
| `kdeglobals` | yes, **and** rewritten by material-you colour generation (mtime today 06:00; `[ColorEffects:*]` blocks) | **GUARD — do not capture.** Would churn on every wallpaper change. If a personal subset matters, extract those keys into a small file the theme generator does not own. |
| `Kvantum/` | yes, `install_dir__sync`, contents are pure upstream (`Colloid`, `MaterialAdw`, mtime = submodule checkout) | **UNMANAGED — vendor owns it.** Reinstalled by `./setup`. |
| `chrome-flags.conf` (not in the milestone list, but personally edited: mtime 2026-09-08 vs install 2026-09-04) | yes, `cp -f` | `restow/`, cp-through class — **currently at risk of silent loss on the next pin bump** |

Two of the six named KDE items and both gtk trees should **not** be captured. That is a scope reduction worth landing before the roadmap fixes phases.

---

## 9. Open questions requiring empirical test

Ordered by how much of the design they can invalidate.

**E-1 (BLOCKING — validates or breaks D-41's core exception). Does ii's `config.json` write survive a symlink?**
Do not test on the live config. Recipe:
```bash
mkdir -p /tmp/fvtest/{repo,live}
printf '{"a":1}\n' > /tmp/fvtest/repo/c.json
ln -s /tmp/fvtest/repo/c.json /tmp/fvtest/live/c.json
# minimal shell.qml: FileView { path: "/tmp/fvtest/live/c.json"; JsonAdapter { property int a: 1 } }
# toggle `a` so onAdapterUpdated fires, then:
stat -c '%F' /tmp/fvtest/live/c.json    # EXPECT: symbolic link
cat /tmp/fvtest/repo/c.json            # EXPECT: the new value
ls -a /tmp/fvtest/repo/                # EXPECT: no leftover c.json.XXXXXX
```
Run with `qs -p /tmp/fvtest/shell.qml` (distinct config path ⇒ distinct `instance.lock` ⇒ the running `qs -c ii` is untouched). **Predicted: symlink survives, repo file updated.** If it fails, `stow/ii/` becomes `capture/ii/` and §7.3's timer becomes load-bearing rather than a backstop.

**E-2. Does the QSaveFile temp file ever become visible to git?**
`QSaveFile` creates `<final>.XXXXXX` in the *resolved* directory — i.e. inside the repo. The rename window is sub-millisecond, but ii debounces writes at 50 ms (`Config.qml:57`) and can write in bursts. Test: tight `git status --porcelain` loop while toggling a config option repeatedly. If temps are ever observed, add a `.gitignore` rule and keep `verify` X2.

**E-3. Does `install_dir__ignore_existing` really skip a *folded symlink* `custom/` in situ?**
§1.2 proves `[ -d symlink-to-dir ]` is true in isolation. Confirm end-to-end with `./arch/dots-hyprland.sh install-files` in a throwaway `XDG_CONFIG_HOME` (upstream honours `XDG_CONFIG_HOME`, `sdata/lib/environment-variables.sh:4`), with `custom/` pre-folded. Also confirms the fresh-machine stub-population path for bootstrap phase 6.

**E-4. Full fresh-machine dry run in a throwaway `XDG_CONFIG_HOME`.**
`XDG_CONFIG_HOME=/tmp/xdgtest XDG_DATA_HOME=/tmp/xdgtest-data ./vendor/dots-hyprland/setup install-files --skip-backup` then diff `/tmp/xdgtest` against the destination table in §1.2. Validates the whole table at once and produces the fixture the future `verify` collision-class array should be linted against. Note `install_google_sans_flex` does network I/O and `hyprctl reload` runs at the end (both `try`-wrapped).

**E-5. Which stow packages conflict after a real `./setup` on a clean `$HOME`?**
Under E-4's throwaway XDG, run `stow -n --no-folding --verbose=5 -t /tmp/xdgtest-home <every package>` and collect the conflict list. This is the input to bootstrap phase 6's de-stub rule and tells you whether "delete only byte-identical vendor stubs" is sufficient or whether a second rule is needed.

**E-6. Do KDE apps (Dolphin, `kwriteconfig6`) write through a symlink?**
KConfig uses `QSaveFile` too, so the prediction is yes — but KConfig also does cascading/locking that `QSaveFile` alone does not. Test on a scratch `kiorc` before committing `stow/kde/`.

**E-7. Does matugen write through or replace `~/.config/gtk-4.0/gtk.css`?**
Currently that path is a symlink into `/usr/share/themes`. If matugen writes *through* it, a wallpaper change is silently editing a root-owned system theme (or failing). Worth knowing even though the path is a GUARD.

**E-8. `systemctl --user enable` from a TTY with no graphical session.**
Confirm phase 9a works without lingering enabled, and that `--now` on the timer is the only part needing 9b.

**E-9 (UNVERIFIED, flagged not tested). `3.files-exp.sh` behaviour.**
Only reachable via `--exp-files`, which the wrapper never passes (`arch/dots-hyprland.sh:704-733` forwards user flags verbatim, so an operator *could*). Its destination table was not read. If anyone ever passes `--exp-files`, every claim in §1.2 is void.

---

## 10. Sources

**Repo (read directly, this commit):**
- `arch/dots-hyprland.sh` — `:14` ALLOWLIST, `:22-104` usage, `:115-120` preflight, `:162-187` ii config targets, `:428-450` `safe_rm_path`, `:697-702` `touches_files`, `:704-769` `run_install_family`, `:771-805` `main`
- `arch/hyprland.sh:25-26, 29, 33`; twelve further `stow -v=5` call sites (§1.4)
- `scripts/phase14-verify.sh:4-18, 24-29, 33-46` — the verify output contract to reuse
- `docs/phase14-adopt-runbook.md:243-255` — the kitty/starship asymmetry, now mechanism-explained
- `docs/dots-hyprland-workflow.md:11, 218, 328, 339-344` — quickshell-is-real-dir, verify output shape, D-38 autostart loss
- `.planning/PROJECT.md` — D-02/D-17/D-18, POLISH-01, v0.4 targets
- `.planning/research/v0.3/ARCHITECTURE.md:85-96, 150` — the three unanswered repo↔live options; this document answers them (B, with stow, `--no-folding`)

**Vendored installer (`vendor/dots-hyprland` @ `1a9ffb78`):**
- `setup:10, 48-63, 68-130`
- `sdata/subcmd-install/3.files.sh:12-39` (backup), `:46-92` (cp/rsync primitives), `:93-172` (install_* wrappers), `:196-238` (firstrun detection, backup gate, hyprctl reload)
- `sdata/subcmd-install/3.files-legacy.sh:6-79` (the full destination table)
- `sdata/subcmd-install/options.sh:48-105` (flags; `--core` expansion at `:90`)
- `sdata/lib/environment-variables.sh:2-6, 27-30`

**Upstream sources (fetched):**
- `quickshell/src/io/fileview.cpp` — `doAtomicWrite` → `QSaveFile` + `commit()`
- `qtbase/6.8/src/corelib/io/qsavefile.cpp` — `QSaveFile::open()` symlink resolution to `finalFileName`; `commit()` via `renameOverwrite()`; `directWriteFallback`

**Live system (observed 2026-09-12):** GNU Stow 2.4.1; Qt 6.11.2; Quickshell 0.2.1 rev `7511545e` (`illogical-impulse-quickshell-git 0.1.0.r1-8`); `~/.config/quickshell/ii/modules/common/{Config,Directories}.qml`; `~/.config/matugen/config.toml`; 78 live symlinks into the repo; scratch-dir experiments for `cp -f`/`rsync`/stow folding/`--adopt`/`-v=5`.

---
*ARCHITECTURE research for v0.4 — 2026-09-12*
