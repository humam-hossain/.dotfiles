# Pitfalls Research

**Domain:** Automated personal-config capture (stow symlinks + copy-capture) layered on an installed illogical-impulse / Quickshell shell, Arch + Hyprland
**Researched:** 2026-09-12
**Confidence:** HIGH (most findings verified against primary source or reproduced empirically on this machine; UNVERIFIED items are marked inline)
**Milestone:** v0.4 Personal config layer

---

## 0. The one finding that changes the milestone design

**D-41's stated premise is wrong for the file it was written about.**

D-41 says: *"Exception is any file an app rewrites atomically (temp + rename replaces the symlink with a plain file, silently losing capture); `~/.config/illogical-impulse/config.json` is the known candidate."*

Atomic-rewrite is **not** a single behaviour. Whether a temp+rename destroys a symlink depends entirely on *which* atomic primitive the app uses:

| Write primitive | Symlink outcome | Repo file outcome | Evidence |
|---|---|---|---|
| **Qt `QSaveFile`** (Quickshell `FileView`, all KDE `KConfig`) | **Preserved** — resolves the link chain first, renames onto the *resolved target* | Correctly updated | `qtbase/src/corelib/io/qsavefile.cpp:194-206` (`// Resolve symlinks`); reproduced with PySide6 on the live Qt 6.11.2 — symlink survived, target updated, mode `0600` preserved |
| **GLib `g_file_set_contents`** (dconf, GTK/GNOME apps) | **DESTROYED** — `rename(2)` over the link path replaces the link | Untouched, silently orphaned | `G_FILE_SET_CONTENTS_CONSISTENT` = "fsync() … and use of an atomic rename() of the new version over the old" ([GLib docs](https://docs.gtk.org/glib/flags.FileSetContentsFlags.html)); reproduced locally — link became a plain file, repo copy still held the old content |
| **`rsync -a [--delete]`** (dots-hyprland `install_dir__sync`) | **DESTROYED** — dest type mismatch, replaced with a plain file | Untouched, silently orphaned | Reproduced locally with rsync 3.5.0; matches the kitty behaviour already recorded in `docs/phase14-adopt-runbook.md:253` |
| **`cp -f`** (dots-hyprland `install_file` → `cp_file`, `3.files.sh:49`) | Preserved | **OVERWRITTEN through the link** | Reproduced locally; already happened for real — commit `2539238` "accept upstream's starship.toml overwrite as a known loss (D-17)" |
| **`vim`/`nvim` write** | `backupcopy=no` breaks it; `yes`/`auto` preserve it | — | `:h 'backupcopy'` — *"When the file is a link the new file will not be a link"*; this machine is `backupcopy=auto`, `writebackup=0` → **safe** |

**Consequences for the milestone:**

1. `config.json` almost certainly **does not need the copy-capture exception**. Quickshell's `FileView` defaults `atomicWrites` to `true` (`fileview.hpp:423`) and therefore uses `QSaveFile` (`fileview.cpp:251-253`), which writes *through* the symlink. The D-41 empirical test should still be run, but expect it to come back "symlink is fine."
2. The **real** symlink killers on this system are the **dots-hyprland installer** and **GLib-based apps**, not the shell. The exception list should be rebuilt around write primitive, not around a vague notion of "atomic".
3. Both of the destroying primitives leave the repo file **untouched**, so `git status` stays clean while live silently drifts. **A content-only `verify` will report "no drift" in exactly the case that matters.** The drift check MUST assert link-ness (`test -L` + `readlink -f` equality), not just byte equality. This is the single most important design constraint in this document.

---

## A. Symlinked config files — the failure catalogue

### A-1. Installer `cp -f` overwrites the repo file through the symlink
**Severity: CRITICAL** (already happened once)

**What goes wrong:** `install_file` → `cp_file` (`vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:46-52`) runs `cp -f "$src" "$dest"`. `cp` follows the destination symlink and truncates/rewrites the *target*. Your repo file now contains upstream's content. The symlink survives, so nothing looks broken.

**Why:** `cp` without `--no-dereference`/`--remove-destination` opens the destination for writing, which traverses the final symlink.

**Detection signal:** `git status` in `.dotfiles` shows a modified file you did not edit, immediately after an install/update run.

**Affected paths today:** `starship.toml`, `hyprland.lua`, `hyprlock.conf`, `hypridle.conf`, `.local/share/icons/illogical-impulse.svg`, and every top-level *file* under `dots/.config/` (`chrome-flags.conf`, `code-flags.conf`, `darklyrc`, `dolphinrc`, `kdeglobals`, `konsolerc`) via the misc loop at `3.files-legacy.sh:11-17`.

**Mitigation:** Never stow a path that upstream `install_file`s, unless you re-stow after every install. The repo already made this choice explicitly (D-17 accepts the loss for `starship.toml`, protects `kitty` by re-stowing). Extend that into a machine-checkable collision list rather than prose.

---

### A-2. Installer `rsync -a --delete` replaces the symlink with a plain file
**Severity: CRITICAL**

**What goes wrong:** `install_dir__sync` → `rsync_dir__sync` (`3.files.sh:67-76`) runs `rsync -a --delete src/ dest/`. A symlinked entry in `dest` is a type mismatch against a regular source file, so rsync writes a temp file and renames over it. The symlink is gone; the repo file is untouched. Live and repo silently fork from that moment on, and **git shows nothing**.

**Why:** rsync's default transfer is temp-file + rename in the destination directory; the rename lands on the link path.

**Detection signal:** `find ~/.config -maxdepth 3 -path '<captured path>' ! -type l` returns a hit. Content diff will NOT catch it.

**Affected paths:** `~/.config/quickshell` (whole tree, `3.files-legacy.sh:26`), `~/.config/hypr/hyprland` (`:50`), `~/.config/fish` (`:33`), `~/.config/fontconfig` (`:41`), and every *directory* under `dots/.config/` via the misc loop (`Kvantum`, `matugen`, `mpv`, `kitty`, `foot`, `fuzzel`, `wlogout`, `xdg-desktop-portal`, `kde-material-you-colors`, `zshrc.d`, `hypr` subpaths). `--delete` additionally removes anything in those directories that upstream does not ship.

**Mitigation:** Same collision list as A-1, plus: never place stowed content *inside* an `install_dir__sync` target — `--delete` will remove it outright, not merely replace it.

---

### A-3. GLib-based applications destroy the symlink on every save
**Severity: HIGH**

**What goes wrong:** Any app writing config with `g_file_set_contents` / `g_file_set_contents_full` renames a temp file over the destination path. `rename(2)` does not follow the final symlink, so the link is replaced by a regular file.

**Detection signal:** Same as A-2 — link-ness check only.

**Affected:** `~/.config/dconf/user` (also binary machine state — never capture it), GTK apps that persist their own settings, `gsettings` backends. Not exhaustively enumerated for this machine. **UNVERIFIED** which specific GTK apps in this user's set do this; the primitive is verified, the per-app inventory is not.

**Mitigation:** Treat the GTK/GNOME half of `~/.config` as copy-capture territory by default and symlink only after proving link survival for that specific app.

---

### A-4. A content-only drift check cannot see A-2 or A-3
**Severity: CRITICAL (design-level)**

**What goes wrong:** `verify` diffs repo content against live content. When a symlink has been replaced by a plain file, the repo copy still holds the last-known-good content, so the diff is empty at first — and it stays empty for whatever the repo says while live diverges. The check reports green while capture is dead.

**Mitigation:** `verify` must assert, for every managed path, in this order: (1) `test -L "$live"`, (2) `readlink -f "$live"` equals the expected repo path, (3) only then content. Failing (1) or (2) is a *louder* failure than failing (3), because it means capture has been silently detached.

---

### A-5. Permission and ownership drift on 0600 files
**Severity: MODERATE**

**What goes wrong:** `~/.config/dolphinrc`, `kdeglobals`, `gh/config.yml`, `gh/hosts.yml`, `~/.config/hypr/hyprland.conf.bak`, `hyprland-gui.conf` are all `0600` live. Git records only the executable bit, so a fresh-machine restore recreates them at `0644 & ~umask` — world-readable.

Additionally, KConfig actively re-`chmod`s: `writeToDevice` (`kconfiginibackendreader_p.h:226-289`) preserves the existing mode if the file is user-owned, otherwise creates at `QFile::ReadUser|WriteUser` (0600), and calls `QFile::setPermissions(filePath(), fileMode)` after `commit()`. Because that runs on the *link path* and `setPermissions` follows symlinks, **KConfig will chmod your repo file to 0600 on every write.**

**Detection signal:** `find stow/ -type f -perm -o+r` on files that should be private; or `ls -l` inside the repo showing `-rw-------` on tracked files after a KDE app runs.

**Mitigation:** Do not put genuinely secret files under capture at all (see E-1). For merely-private ones, have the bootstrap `chmod 600` an explicit list after stow; do not rely on git.

---

### A-6. Repo unavailable at login → dangling symlinks
**Severity: HIGH**

**What goes wrong:** If `~/github_repo/.dotfiles` is missing (fresh machine, pre-clone, moved clone, unmounted volume), every stowed path in `~/.config` is a dangling symlink. Behaviour then splits by app:

- Target's **parent directory also missing**: `QSaveFile::open()` returns **false**. Verified — Quickshell logs `Write of … failed: Unknown error when opening file`, sets `FileViewError::Unknown`, and **does not crash**. The shell runs on the QML-declared defaults in `Config.qml`; the bar starts, but with default appearance.
- Target's **parent directory exists, file missing**: `QSaveFile` **creates the target** through the link at default umask (0644). Verified. So the shell will happily write a defaults-populated `config.json` into your repo.

On this machine `/home` and the repo are the same ext4 filesystem (`stat -c %d` both `66311`), so cross-filesystem rename failures are not a live concern — but they would be if the repo ever moved to a separate mount, because `QSaveFile`/`rsync` temp files are created next to the *resolved* target.

**Detection signal:** `find ~/.config -xtype l` (broken symlinks).

**Mitigation:** Bootstrap must clone before it stows, and `verify` must include a `-xtype l` sweep. Also see F-3 on the hard-coded clone path.

---

### A-7. Editors breaking links on save
**Severity: LOW here, but worth pinning down**

- `vim`/`nvim`: `backupcopy=no` renames and breaks the link (`:h 'backupcopy'`: *"When the file is a link the new file will not be a link"*); `yes` and `auto` preserve it, and `auto` explicitly avoids renaming when the file is a link. **This machine: `backupcopy=auto`, `backup=0`, `writebackup=0` → safe.** No action needed unless the nvim config changes.
- VS Code / Code-OSS: widely reported to replace symlinked settings files on save. **UNVERIFIED** — not reproduced here. If the user edits captured configs in VS Code, test it before relying on symlink capture for those files.

**Mitigation:** Add `backupcopy=auto` (or `yes`) as an asserted invariant in `verify` if nvim config is ever changed; do not just assume it.

---

## B. Quickshell / illogical-impulse specific hazards

### B-1. The shell overwrites the repo copy with *defaults* after any failed parse
**Severity: CRITICAL**

**What goes wrong:** `JsonAdapter::deserializeAdapter` (`jsonadapter.cpp:24-39`) on a parse error emits `qmlWarning("Failed to deserialize json: …")` and **returns** — the in-memory adapter keeps the compiled-in defaults. It does not crash and it does not refuse to write. Then `Config.qml:70` (`onAdapterUpdated: fileWriteTimer.restart()`) means the *next* settings change of any kind serialises the **defaults** and `QSaveFile`s them over your file, through the symlink, into the repo.

Trigger paths that are very realistic in a git-managed setup:
- A git **merge/rebase conflict** leaves `<<<<<<<` markers in `config.json` → unparseable → first bar interaction writes defaults over the conflict *and* over all personalisation.
- A hand-edit with a trailing comma or a `//` comment (the format is strict JSON, `QJsonDocument::fromJson`).
- A truncated read during a `git checkout`/`git stash` window.

Worse: `Config.qml:72-76` — `onLoadFailed`, if the error is `FileNotFound`, calls `writeAdapter()` **immediately**. So a momentarily-absent file (mid-checkout, mid-stow) provokes an instant defaults write.

**Detection signal:** A `git diff` on `config.json` that deletes most customisation at once; `qs` log lines containing `Failed to deserialize json`.

**Mitigation:**
- Never let git operations run against a live-symlinked `config.json` without stopping the shell first, or set `blockWrites` (`Config.qml:14`, `FileView.blockWrites`) for the duration. A documented "pause capture" is cheaper than a recovery.
- Treat `config.json` as **shell-owned**: the repo copy is a mirror; hand-edits go through the shell's settings UI, not a text editor.
- `verify` should flag "config.json is byte-identical to a fresh-defaults serialisation" as a suspected defaults-clobber.

---

### B-2. Normalisation churn — reordered keys, injected defaults, no comments
**Severity: MODERATE**

**What goes wrong:** `serializeAdapter()` (`jsonadapter.cpp:96-99`) is `QJsonDocument(...).toJson(Indented)` over **every** readable property. That means:
- Keys come out **alphabetically sorted** (QJsonObject is a sorted map) regardless of declaration order in `Config.qml`. Confirmed against the live file: `Config.qml` declares `enable, automatic, backgroundTransparency, contentTransparency`; the file has them alphabetised.
- **Every** default is materialised, including the 1.4 KB `ai.systemPrompt` blob and the whole `extraModels` sample entry, whether or not the user cares.
- JSON has no comments; any annotation you add is destroyed on next write.

Good news: this is **deterministic**, so if you only ever commit the shell-written form there is no ping-pong. And reload does **not** re-trigger a write — `deserializeAdapter` sets `changesBlocked = true` around the property assignment (`jsonadapter.cpp:41,52`), so there is no infinite write loop. Verified from source.

**Real churn source:** every submodule pin-bump that adds a config key upstream will add that key (with its default) to your file on first run → a diff you did not author, on a file that also holds your real settings.

**Mitigation:** Accept the normalised form as canonical. Commit `config.json` only in its shell-written shape. Expect and pre-approve a "schema drift" diff after every pin bump; make that an explicit step in the update playbook rather than a surprise.

---

### B-3. `~/.config/illogical-impulse/` is not a capture-safe directory
**Severity: HIGH**

**What goes wrong:** That directory holds four things with three different owners:

| Path | Owner | Capture? |
|---|---|---|
| `config.json` (17 KB) | the shell | yes (the milestone's target) |
| `actions/` | the user | yes |
| `installed_listfile` (77 KB, `0600`, 1049 lines) | the **installer** | **never** |
| `installed_true` (0 B) | the **installer** | **never** |

If you stow the **directory** rather than individual files, stow folds `~/.config/illogical-impulse` into a symlink to the repo, and then `cp_file` writes 77 KB of machine-specific absolute paths (`INSTALLED_LISTFILE`, `environment-variables.sh:29`) straight into the repo on every install run.

Worse: upstream `uninstall` (`sdata/subcmd-uninstall/…:39-77`) reads that listfile and `rm`s every path under `$HOME` **without confirmation**. With a folded directory symlink those paths resolve into the repo working tree. (For *file*-level stow this is benign: `cp_file` records `realpath -se` — `-s` means **no** symlink expansion — so the listfile stores `/home/pera/.config/starship.toml`, and `rm` removes only the link. Confirmed: line 998 of the live listfile is the link path, not the repo path.)

**Detection signal:** `installed_listfile` appearing in `git status`; `~/.config/illogical-impulse` being a symlink.

**Mitigation:** File-level stow only for this directory, or `stow --no-folding`. Add `installed_listfile` and `installed_true` to `.gitignore` as belt-and-braces.

---

### B-4. `custom/variables.lua` and `custom/scripts/` are never sourced
**Severity: MODERATE — this falsifies part of the milestone's feature list**

**What goes wrong:** The milestone targets *"`keybinds.lua`, `rules.lua`, `variables.lua`, `custom/scripts/` joining the existing `general/env/execs.lua`"*. But `~/.config/hypr/hyprland.lua` requires exactly five custom modules:

```
custom.env, custom.execs, custom.general, custom.rules, custom.keybinds
```

There is **no `require("custom.variables")`** and nothing sources `custom/scripts/`. Capturing `variables.lua` produces a file that has zero effect; capturing `custom/scripts/` only works if something in `execs.lua`/`keybinds.lua` references those scripts by path.

**Detection signal:** Setting something in `custom/variables.lua` and observing no change after `hyprctl reload`.

**Mitigation:** Either drop `variables.lua` from the requirement, or override `hyprland/variables.lua` values from `custom/general.lua` (which *is* sourced, after the defaults). Decide this before writing the phase, not during.

---

### B-5. `~/.config/hypr/hyprland/` is a `--delete` sync target and holds generated files
**Severity: HIGH**

**What goes wrong:** `install_dir__sync dots/.config/hypr/hyprland` (`3.files-legacy.sh:50`) is `rsync -a --delete`. Anything you stow into that directory is *deleted* on the next install, not merely overwritten. And `~/.config/hypr/hyprland/colors.lua` is **matugen-generated** (`~/.config/matugen/config.toml` → `output_path = '~/.config/hypr/hyprland/colors.lua'`) — it is rewritten on every wallpaper change.

**Mitigation:** Personal Hyprland content goes in `custom/` only. `custom/` is safe from the installer: `install_dir__ignore_existing` (`3.files-legacy.sh:75`) short-circuits on `[ -d "$t" ]`, and `test -d` follows symlinks, so an existing stow link or folded directory is left alone. Verified from source. **`custom/` is the one hypr path where symlink capture is structurally safe.**

---

### B-6. Bar behaviour when `config.json` is unreadable
**Severity: HIGH — answered, and the answer is "it degrades, it does not die"**

Verified by reading `Config.qml` + `fileview.cpp` + `jsonadapter.cpp` and by exercising `QSaveFile` against dangling links on the exact Qt build `qs` links (`libQt6Core.so.6`, qt6-base 6.11.2):

- **Dangling link, target parent missing** → open fails, `qmlWarning`, no crash, **shell starts with compiled-in defaults**. Bar appears; theming/settings are default.
- **Dangling link, target parent present** → shell creates `config.json` with defaults through the link.
- **Malformed JSON** → `qmlWarning`, defaults retained, no crash; next change writes defaults back (B-1).
- **No write loop** in any of these cases (`changesBlocked` guard).

So the worst case is *silent loss of personalisation*, not *no desktop*. That is good news for the "without crashing stuff" constraint — but it also means **the failure is invisible until you notice your bar looks wrong**, which is exactly the class of failure `verify` exists to catch.

---

## C. KDE / KConfig and the generated-theme trap

### C-1. Half the milestone's "KDE app configs" list is machine-generated theme output, not personal config
**Severity: HIGH — this reshapes the requirement**

The milestone lists `dolphinrc, kdeglobals, kiorc, ktrashrc, kservicemenurc, Kvantum, darklyrc, gtk-3.0/4.0`. Several of those are **derived state regenerated from the current wallpaper**:

- `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` — matugen template outputs, per `~/.config/matugen/config.toml`.
- `~/.config/fuzzel/fuzzel_theme.ini`, `~/.config/hypr/hyprland/colors.lua`, `~/.config/hypr/hyprlock/colors.conf` — same.
- `kdeglobals`, `Kvantum`, `darklyrc`, `konsolerc` — targets of ii's Qt-theming path (`switchwall.sh:34` → `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh`). Live `kdeglobals` is a full Material colour dump (`Colors:Button`, `ColorEffects:*` …) with today's mtime, not hand-authored settings.

Capturing these means a git diff **on every wallpaper change**.

Note a live inconsistency worth checking in the phase: `kde-material-you-colors` is **not currently installed** on this machine (`which` → not found; not a pacman-owned binary), so that wrapper is presently inert. If a later `./setup install` pulls it in, the churn starts. **UNVERIFIED:** which process wrote the current `kdeglobals` at today's login.

**Mitigation:** Capture the **matugen templates** (`~/.config/matugen/templates/`, `~/.config/matugen/config.toml`) — those are the real source of truth — and `.gitignore` the generated outputs. For `kdeglobals`, capture at most a hand-curated non-colour subset, or nothing.

---

### C-2. KConfig writes are symlink-safe but cascade-relative
**Severity: MODERATE**

**Save strategy (primary source, `kconfiginibackendreader_p.h:225-300`):** `QSaveFile` when the file is absent or user-owned (atomic, symlink-resolving, mode preserved or 0600); plain `QFile` with `Truncate|ExistingOnly` when the file exists but is **not** owned by the user. Both write *through* a symlink. **So symlink capture of KDE configs is mechanically fine.**

**The cascade problem:** KConfig merges `$XDG_CONFIG_DIRS` (`/etc/xdg/...`) under `$XDG_CONFIG_HOME`, and only persists entries that are dirty or differ from the merged default (`kconfig.cpp` `bDirty`/`bGlobal` handling). A captured `kdeglobals`/`dolphinrc` is therefore a **delta against this machine's system defaults**. Restored onto a machine with a different `/etc/xdg` (different KF6 version, different distro packaging), the merged result differs — the file is simultaneously *incomplete* (relies on system defaults you no longer have) and *over-complete* (pins values that are now redundant).

**Machine-specific keys observed live:**
- `ktrashrc` — the group name itself is an absolute path: `[/home/pera/.local/share/Trash]`. Wrong `$HOME` → the whole group is inert.
- `dolphinrc` — `[PreviewSettings] Plugins=` is an enumeration of **installed thumbnailer plugins** (32 entries here); restoring it onto a machine with a different plugin set pins names that don't exist. `Version=202` is a schema marker that triggers KConfig update scripts (`kconf_updaterc`).
- `kdeglobals` — entirely colour values derived from the wallpaper (C-1).
- Not present here but standard offenders in KDE configs generally: window geometry/`State`/`Size` keys, `ViewPropsTimestamp`, `RecentFiles`/`RecentDirs`, per-device UUIDs, screen-resolution-dependent sizes.

**Standard practice for version-controlling KDE configs:** the community norm is **filtered, not whole-file** — commit only the groups/keys you deliberately set, and leave geometry/recent/state/timestamp keys out. **Confidence: MEDIUM** (this is convention aggregated from dotfile-management practice, not a KDE-published policy).

**Detection signal:** noisy diffs on keys you never touched; `kconf_updaterc` changing.

**Mitigation:** For KDE configs, prefer **copy-capture with a key filter** over whole-file symlink. A small `capture-kde` step that greps out an allowlist of groups is more robust than symlinking the file and then fighting the churn.

---

### C-3. KConfig deletes the file — and therefore the symlink — when a config empties out
**Severity: LOW, but it silently detaches capture**

`writeToDevice` has an explicit branch: if the serialised file is empty and the mode is the default 0600, it calls `file.cancelWriting()` and `QFile::remove(filePath())` (`kconfiginibackendreader_p.h:269-279`). `QFile::remove` on a symlink path removes the **link**, not the target. So resetting an app's settings to all-defaults can quietly unstow that file.

**Detection signal:** the `-xtype l` / `test -L` sweep in A-4.

---

## D. Installer-vs-capture collisions

Ground truth read from `vendor/dots-hyprland/sdata/subcmd-install/` at the pinned SHA `1a9ffb78`.

### D-1. What `./setup install` does to captured state, by mechanism

| Installer function | Source line | Primitive | Effect on a stowed target |
|---|---|---|---|
| `install_file` → `cp_file` | `3.files.sh:46-52, 93-101` | `cp -f` | Writes **through** the link, corrupting the repo file (A-1) |
| `install_file__auto_backup` | `3.files.sh:102-120` | `mv $t $t.old` then `cp -f`, **or** `cp` to `$t.new` on non-firstrun | On firstrun: **`mv` renames your symlink away** and drops a plain file. On re-run: writes `$t.new` and leaves you alone |
| `install_dir__sync` → `rsync_dir__sync` | `3.files.sh:67-76, 130-138` | `rsync -a --delete` | **Destroys the link**; `--delete` also removes anything extra you stowed there (A-2) |
| `install_dir` → `rsync_dir` *(Phase 18 split)* | `3.files.sh:121-129`; `3.files-legacy.sh:18` | `rsync -a` | **Destroys the link**; replaces symlink with a regular directory while leaving repo copy untouched (rsync-replace). Differs from sync only in not deleting extras |
| `install_dir__ignore_existing` | `3.files.sh:139-160`; `3.files-legacy.sh:75` | `rsync -a --ignore-existing`, gated on `[ -d $t ]` | Short-circuits on the whole destination directory; **no-op** when target directory exists (incl. as a symlink) — this is why `hypr/custom/` is safe |
| `auto_backup_configs` → `backup_clashing_targets` | `3.files.sh:12-39`; `lib/functions.sh:346-390` | `rsync -av` into `~/ii-original-dots-backup` | Copies your live clashing entries out first. This is the pre-existing safety net and it is **prompted, not automatic**, unless `-f/--force` |
| `hyprland.conf` rename | `3.files-legacy.sh:51-54` | `mv` | Renames `hyprland.conf` → `.old`. Already happened (Phase 14) |
| `gen_firstrun` | `3.files.sh:40-45` | `touch` + `>>` | Writes into `~/.config/illogical-impulse/` (B-3) |
| `hyprctl reload` | `3.files.sh:238` | — | Reloads the live session at the end of every install |

**Note on the `--core` retirement (Phase 16):** with `SAFE_DEFAULTS` gone, the misc loop (`3.files-legacy.sh:8-20`) now runs on every install. That loop `install_dir__sync`s / `install_file`s **every** top-level entry in `dots/.config/` except quickshell/fish/hypr/fontconfig — i.e. `darklyrc`, `dolphinrc`, `kdeglobals`, `konsolerc`, `Kvantum`, `matugen`, `mpv`, `kitty`, `foot`, `fuzzel`, `wlogout`, `xdg-desktop-portal`, `kde-material-you-colors`, `starship.toml`, `zshrc.d`, `chrome-flags.conf`, `code-flags.conf`, `thorium-flags.conf`. **That set overlaps heavily with this milestone's capture targets.** The collision list is not hypothetical; it is most of the milestone.

---

### D-1a. Experimental file installation (`3.files-exp.sh` / `--exp-files`) — Deliberately Unmodelled

*(Added Phase 18 / 2026-09-14 per D-30, D-35 and Q15 resolution)*

Upstream `dots-hyprland` provides an alternative file installation route via `--exp-files` (implemented in `sdata/subcmd-install/3.files-exp.sh`, configured via `3.files-exp.yaml`).

This path is complete and functional, but uses an entirely disjoint set of write primitives and destinations from the legacy path:

| Mode | Command executed | Effect on stowed symlink |
|---|---|---|
| `sync` | `rsync -av --delete` | Destroys the symlink; deletes unmodelled contents |
| `soft` | `rsync -av` | Destroys the symlink; replaces with real directory |
| `hard` | `cp -r` | Writes through or destroys symlink |
| `hard-backup` | `mv` to `.old.N` then `cp -r` | Destroys the symlink via `mv` |
| `soft-backup` | `cp -r` to `.new` sidecar | Creates unmanaged sidecar |
| `skip-if-exists` | `cp -r` (if destination absent) | No-op if target exists, writes regular copy if absent |

Key architectural differences:
- Reads destinations from `3.files-exp.yaml` rather than `3.files-legacy.sh`.
- Runs an interactive preference wizard unless upstream `$ask` is false.
- Two upstream TODOs (`symlink: true` and `--exp-file-reset-symlink`) are present in comments but completely unimplemented at this pin (`1a9ffb78`).
- **Conclusion:** Every row in `collision-map.tsv` would be void under `--exp-files`, and every primitive either destroys or writes through symlinks. The wrapper (`arch/dots-hyprland.sh`) refuses `--exp-files` with exit 2 at the `main()` prologue (D-31, D-33 / CAP-08). This path is deliberately unmodelled.

---

### D-2. Stow tree-folding lets the installer write *into the repo*
**Severity: CRITICAL**

**What goes wrong:** GNU Stow 2.4.1 folds: *"Rather than creating the directory … and populating it with symlinks … Stow will create a single symlink … This is called 'tree folding'."* If `~/.config/hypr/` does not already exist when you stow a package containing `.config/hypr/custom/*`, stow folds at the highest empty level — `~/.config/hypr` itself becomes a symlink into the repo. Then:

- `install_dir__sync dots/.config/hypr/hyprland "$XDG_CONFIG_HOME"/hypr/hyprland` writes ii's **entire** hyprland Lua tree into your repo working tree,
- the `hyprland.conf` → `.old` rename happens **inside the repo**,
- `hyprland.lua`, `hyprlock.conf`, `hypridle.conf` land in the repo,
- `--delete` operates on repo content.

Same hazard for `~/.config/illogical-impulse` (B-3) and any other folded directory.

**Detection signal:** `find ~/.config -maxdepth 2 -type l -exec test -d {} \; -print` → any *directory* symlink into the repo is a folding site; cross-check it against the D-1 table.

**Mitigation:** `stow --no-folding` for every package whose target directory the installer touches, and/or `mkdir -p` the real directories before the first stow. Prefer `--no-folding` globally — the cost is more symlinks, the benefit is that folding can never surprise you.

---

### D-3. `stow --adopt` moves live files into the repo — including installer output
**Severity: HIGH**

The manual is blunt: *"Warning! This behaviour is specifically intended to alter the contents of your stow directory. If you do not want that, this option is not for you."* `--adopt` is the obvious tool for "capture as I touch" — point stow at an existing live file and it moves into the repo. But an unattended/scripted `--adopt` will just as happily adopt upstream's installed content, or generated theme output, with no diff review.

**Mitigation:** `--adopt` only ever interactively, one path at a time, with `git diff` reviewed *immediately after* (the file arrives with its live content, so the diff is the whole point). Never in a loop, never in the bootstrap.

---

### D-4. The update path re-runs everything
**Severity: HIGH**

The update contract is `git -C vendor/dots-hyprland pull` (pin bump) then re-run `./setup install`. That means **every** row in the D-1 table fires again, on a machine that by then has more stowed paths than it did at Phase 14. Upstream's own help even says *"To update to the latest, manually run `git stash && git pull` first"* — a `git stash` inside the submodule, which the parent repo's pin discipline does not expect.

Also: on re-run `INSTALL_FIRSTRUN` is false (because `~/.config/illogical-impulse/installed_true` exists), so `install_file__auto_backup` switches from "rename yours to `.old` and install mine" to "drop mine at `.new` and leave yours". That is why `hypridle.conf.new` and `hyprlock.conf.new` are sitting in `~/.config/hypr/` right now. Deleting `installed_true` — or capturing it and restoring a stale copy — flips that behaviour back to destructive.

**Mitigation:** Make "re-stow the protected set" a mandatory post-install step in the playbook, driven by the same machine-readable collision list, and have `verify` run automatically after every install/update. Never capture `installed_true`.

---

## E. Git and content hazards

### E-1. Secrets in `~/.config` that a "capture as I touch" workflow will reach
**Severity: CRITICAL**

Present on this machine, and exactly the kind of thing a broad capture sweeps up:

| Path | Risk |
|---|---|
| `~/.config/rustdesk/RustDesk.toml`, `rustdesk/peers/*.toml` | Remote-access credentials / permanent password |
| `~/.config/obs-studio/plugin_config/obs-websocket/config.json` | WebSocket server password |
| `~/.config/roboflow/config.json` | API key |
| `~/.config/gh/hosts.yml`, `gh/config.yml` | GitHub auth (0600; on **this** machine `hosts.yml` is 95 B with **no** `oauth_token` key, so currently clean — but that depends on the auth method) |
| `~/.config/configstore/` | npm/yeoman-style tokens |
| `~/.config/discord/`, browser profile dirs | Session cookies and tokens |
| `~/.config/wireshark/preferences`, `extcap.cfg` | Capture credentials |

**Good news, verified:** ii does **not** put AI API keys in `config.json`. `KeyringStorage.qml` routes them to the system secret service (`"application": "illogical-impulse"`), so `config.json` is safe to commit on that axis. `~/.config/kwalletrc` holds settings only; wallet material lives in `~/.local/share/kwalletd/`, outside `.config`.

**Mitigation (concrete):**
- Capture is **allowlist-only**. Never `stow` a whole-`.config` package. The allowlist lives in the repo and `verify` refuses paths outside it — the wrapper already has this shape (`arch/dots-hyprland.sh:106` `is_allowlisted`, `:428` `safe_rm_path`); reuse it.
- A pre-commit secret scan (`gitleaks` or `git-secrets`) over `stow/` and `.config/`. Add a deny-list of filenames: `hosts.yml`, `*.toml` under `rustdesk/`, `credentials*`, `*token*`, `*secret*`, `*.pem`, `*.key`, `id_*`.
- Explicit `.gitignore` negative patterns as a second layer, since `.gitignore` alone does not protect an already-tracked file.

---

### E-2. `~/.config` is 12 GB — size and binary churn
**Severity: HIGH**

Measured: `~/.config` = **12 GB**, of which `google-chrome` 7.1 GB and `discord` 2.0 GB. Multi-hundred-MB caches, `GPUCache/data_*`, `ShaderCache`, `History`/`Favicons` SQLite DBs, `.pma` metrics blobs.

The repo already has scar tissue from a milder version of this: `.gitignore` carries explicit entries for `stow/qbittorrent/.config/qBittorrent/lockfile`, `ipc-socket`, `rss/storage.lock`, `qBittorrent-data.conf` — runtime state that arrived because a whole directory was captured.

**Mitigation:** Allowlist at the **file** level for anything in an app directory that also holds state. `.gitignore` patterns to add up front: `*.lock`, `*-socket`, `*.sqlite*`, `*/Cache/`, `*/GPUCache/`, `*/ShaderCache/`, `*.pma`, `*/thumbnails/`, `*.png`/`*.jpg` under config paths, `installed_listfile`, `installed_true`, `dconf/user`, `*/colors.lua`, `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, `fuzzel_theme.ini`.

---

### E-3. Machine-specific values baked into the captured Hyprland config
**Severity: HIGH — this is the direct threat to "exact setup instantly"**

`.config/hypr/custom/general.lua` hard-codes:
- output names `DP-1` and `HDMI-A-2`,
- `scale = 1.5` and `transform = 1` on the second head,
- eleven `workspace_rule` pins binding workspaces 1–5 + `special:social` to `DP-1` and 6–10 to `HDMI-A-2`.

On a fresh machine with `eDP-1` (laptop) or a different port, none of this matches.

**Mitigating fact, verified:** ii's own `~/.config/hypr/hyprland/general.lua:2-7` declares a catch-all `hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })`, and `hyprland.lua` sources `hyprland.general` **before** `custom.general`. So an unmatched personal monitor rule degrades to "no custom scale/transform/pinning", **not** to a black screen. The fresh machine will have a working display.

**Not mitigated:** workspaces 6–10 pinned to a nonexistent `HDMI-A-2`. **UNVERIFIED** what Hyprland does with a `workspace_rule` naming an absent monitor — plausibly falls back to the focused monitor, plausibly makes those workspaces awkward to reach. Test it before declaring the fresh-machine bootstrap successful.

Other machine-specific content to expect: `ktrashrc`'s `[/home/pera/...]` group header, `dolphinrc`'s installed-thumbnailer enumeration, absolute paths in `custom/execs.lua`, and the timezone/ping-host/conda paths already called out in PROJECT.md Constraints.

**Mitigation:** A **per-machine override layer** — `custom/general.lua` sources a `custom/machine/$(hostname).lua` if present, and the repo ships the hostname files. That keeps monitor/workspace topology out of the shared layer entirely and makes "exact setup instantly" honest about what "exact" means across different hardware.

---

### E-4. Mode-bit and line-ending churn
**Severity: LOW**

Git tracks only the exec bit, so the 0600↔0644 dance in A-5 produces no diff but also no protection. No `.gitattributes` exists in the repo; all captured files here are LF, so CRLF churn is not a live risk — but `core.autocrlf` on a future machine could introduce it. KConfig sets `setTextModeEnabled(true)` for EOL translation, which is a no-op on Linux.

**Mitigation:** Add a `.gitattributes` with `* text=auto eol=lf` before bulk capture. Cheap insurance.

---

## F. "One command on a fresh machine" failure modes

### F-1. Ordering: stow before the target directory exists → folding (or conflict)
**Severity: CRITICAL**

Two opposite failures depending on order:
- **Stow first, install second:** stow folds empty parents (D-2), the installer then writes into the repo.
- **Install first, stow second:** the installer creates `~/.config/hypr/custom/` as a real directory of upstream stubs, so stow hits *"a target is encountered which already exists but is a plain file … Stow will register this as a conflict and refuse to proceed"* and aborts — safely, but the bootstrap stops.

**Guard:** Pin the order explicitly — install → *delete the upstream stubs the capture owns* → `stow --no-folding`. And run `stow -n` (`--simulate`) first so conflicts are reported before anything is written.

---

### F-2. AUR build failures and `-git` package non-reproducibility
**Severity: HIGH**

`sdata/dist-arch/` contains 14 meta-packages, two of which build from upstream HEAD: `illogical-impulse-quickshell-git` and `illogical-impulse-microtex-git`. The live machine runs `illogical-impulse-quickshell-git 0.1.0.r1-8` reporting `Quickshell 0.2.1 (revision 7511545e…)`. A fresh build months later gets a **different Quickshell revision**, against which the pinned ii QML may not compile. The submodule pin gives *config* reproducibility, not *binary* reproducibility.

Also from the v0.3 research and still live: the ii install marks shared packages `asdeps`, so a later `yay -Yc` can remove `hyprland`/`kitty`; and dropping `--skip-sysupdate` runs an unattended `pacman -Syu` mid-bootstrap.

**Guard:** Bootstrap must be **resumable and idempotent** — each step checks its own postcondition and is safe to re-run. Record the working Quickshell revision in the repo and, if the fresh build fails, pin/patch rather than debug live. Run the protect/re-mark step after every dep install. Keep sysupdate in its own window.

---

### F-3. The clone path is baked into every symlink
**Severity: HIGH**

Live links are relative: `~/.config/starship.toml -> ../github_repo/.dotfiles/stow/zsh/.config/starship.toml`. Relative means `$HOME`-independent (good) but **directory-layout-dependent**: the clone must land at exactly `$HOME/github_repo/.dotfiles`. Clone to `~/.dotfiles` or `~/src/dotfiles` and every link dangles (A-6).

**Guard:** The bootstrap's first action is asserting its own location: `[ "$(pwd -P)" = "$HOME/github_repo/.dotfiles" ]` or fail with the exact `git clone` command to run. Do not attempt to be clever and relocate.

---

### F-4. Needing a graphical session mid-bootstrap, and needing a relogin
**Severity: MODERATE**

`3.files.sh:236-238` ends with `sleep 1; try hyprctl reload` — meaningless outside a Hyprland session, harmless because it is wrapped in `try`. But `ILLOGICAL_IMPULSE_VIRTUAL_ENV` must be set for Quickshell to work at all (`3.files.sh:256-258`), and it is set by `hyprland/env.lua` — i.e. **only after a Hyprland relogin**. Verification of the shell cannot happen in the same non-graphical bootstrap run that installed it.

Related and currently true: `graphical-session.target` and `hyprland-session.service` are both **inactive** right now (verified). D-38 is live, not theoretical.

**Guard:** Split the bootstrap into `phase-1 (no session required)` and `phase-2 (run after relogin, verifies)`. The single command orchestrates both with an explicit "log out and re-run" checkpoint. Do not claim success from phase 1.

---

### F-5. Wrong user / sudo
**Severity: MODERATE**

Upstream `setup` calls `prevent_sudo_or_root` on line 10 and refuses to run as root — good. But it also runs `sudo_init_keepalive` and needs a sudo password mid-run, so the bootstrap is not unattended. Running any *capture* step as root would create root-owned files in `~/.config` and in the repo; KConfig's `writeToDevice` explicitly detects a not-user-owned file and silently switches to non-atomic direct write.

**Guard:** Bootstrap asserts `[ "$(id -u)" -ne 0 ]` and `[ -O "$HOME" ]` up front, and a `find ~/.config stow/ ! -user "$(id -un)"` check in `verify`.

---

### F-6. systemd units are symlinks and `disable` deletes them
**Severity: MODERATE**

`~/.config/systemd/user/hyprland-session.service` is a stow symlink into the repo. `systemctl --user list-unit-files` reports its state as **`linked`**, not `enabled`/`disabled` — verified live. Per `systemctl(1)`: *"disable … removes all symlinks to matching unit files, including manually created symlinks, and not just those actually created by enable or link."* So `systemctl --user disable hyprland-session.service` **deletes the stow symlink**.

Separately, `~/.config/systemd/user/default.target.wants/` holds enablement symlinks into `/usr/lib/systemd/user/` (`pipewire`, `pipewire-pulse`, `ydotool`). Capturing those is wrong — they should be recreated by `systemctl --user enable`, not restored as files, or they will point at units for packages that may not be installed.

**Guard:** Bootstrap does `stow systemd` then `systemctl --user daemon-reload && systemctl --user enable --now hyprland-session.service`. `.gitignore` `*.target.wants/`. `verify` checks the unit is `linked` and the service is active.

---

## G. Recovery and blast radius

### G-1. How the user gets their desktop back

The recovery story is better than it looks, and should be written down before capture starts, not after:

| Failure | Recovery |
|---|---|
| Shell shows defaults (B-1/B-6) | `git -C ~/github_repo/.dotfiles checkout -- <config.json path>` with the shell stopped, then restart `qs -c ii` |
| Symlink destroyed by installer (A-2) | `cd stow && stow -R -v=5 -t ~ <pkg>` — the repo copy was never touched. This is already the documented `kitty` procedure (`docs/phase14-adopt-runbook.md:243-253`) |
| Repo file corrupted through the link (A-1) | `git checkout` / `git show <ref>:<path> >` — the D-17 `starship.toml` precedent, and the reason atomic per-file commits matter |
| Everything wrong, session unusable | `~/ii-original-dots-backup` (installer's own backup), plus `docs/phase14-adopt-runbook.md` §14 three-tier rollback. **Never** upstream `./setup uninstall` (v0.3 Pitfall 11 still stands, and B-3 gives it a new way to bite) |

### G-2. Required safety properties of the capture mechanism

Non-negotiable, given "simplest and without crashing stuff":

1. **Dry-run by default for anything bulk.** `stow -n` before `stow`; a `capture --dry-run` that prints the plan and exits.
2. **Automatic backup before the first stow of any package** — `cp -a` the live paths to a timestamped directory, not just a trust in git.
3. **Allowlist-gated.** The mechanism refuses any path not in an in-repo allowlist. Reuse `arch/dots-hyprland.sh:106 is_allowlisted` / `:428 safe_rm_path` rather than inventing a second pattern.
4. **A one-line documented undo per package**, in the README, tested: `cd stow && stow -D -t ~ <pkg> && cp -a <backup>/<pkg>/. ~/`.
5. **Never destructive without confirmation**, and never destructive at all while the shell holds the file open — stop `qs` or set `blockWrites` first.
6. **`verify` asserts link-ness before content** (A-4), and runs automatically after every `./setup install` and after every reboot.
7. **Capture one package at a time, commit per package.** Bulk capture is how a bad allowlist entry becomes a 7 GB commit.

### G-3. Risk ranking (likelihood × blast radius)

| # | Risk | Likelihood | Blast radius | Score |
|---|---|---|---|---|
| 1 | Installer destroys/corrupts stowed configs on the next `./setup install` (A-1, A-2, D-1, D-4) | **Certain** — it already happened twice (`starship.toml`, `kitty`) | Silent, repo-wide, repeats on every update | **Highest** |
| 2 | Content-only `verify` reports green while capture is detached (A-4) | High — follows automatically from #1 | Defeats the milestone's core claim ("no manual sync" asserted, not assumed) | **Highest** |
| 3 | Stow folding lets the installer write into the repo working tree (D-2) | High if `--no-folding` is not the default | Repo gains hundreds of upstream files; `--delete` operates on repo content | **Highest** |
| 4 | Shell writes defaults over `config.json` after a parse failure (B-1) | Medium — needs a malformed file, which git conflicts produce | Total loss of shell personalisation, silently | High |
| 5 | Secrets committed by a broad capture (E-1) | Medium | Irreversible once pushed | High |
| 6 | Generated theme output captured → churn on every wallpaper change (C-1) | High | Noise, not damage; erodes trust in `verify` | Medium |
| 7 | Fresh machine: wrong monitor names / wrong clone path (E-3, F-3) | High | Degraded, not broken (catch-all monitor rule verified) | Medium |
| 8 | `--adopt` silently pulling upstream content into the repo (D-3) | Medium | Recoverable via git, but confusing | Medium |
| 9 | 12 GB `.config` partially captured (E-2) | Low with an allowlist | Repo bloat, painful to undo | Medium |
| 10 | `systemctl disable` deleting the unit symlink (F-6) | Low | One re-stow | Low |

---

## De-risk first

These three must be closed in an early phase, **before any bulk capture**, because every later phase inherits them:

**1. Build the installer-collision map and make it machine-checkable.**
Derive, from `3.files-legacy.sh` + `3.files.sh` at the pinned SHA, a table of `path → installer primitive → symlink outcome`. Every candidate capture path is classified against it *before* it is stowed. Deliverable: a checked-in list plus an assert script in the style of `scripts/phase1*-assert.sh`. Without this, capture is guessing about the one actor guaranteed to attack it. (Closes risks 1, 3, 8.)

**2. Make `verify` link-aware, and prove it catches a destroyed symlink.**
`verify` must fail on `! -L`, on a `readlink -f` mismatch, and on `-xtype l`, *before* it looks at content. The acceptance test is adversarial: stow a file, run `rsync -a --delete` over it to simulate the installer, and confirm `verify` fails. A `verify` that passes that test is worth building on; one that doesn't is a false green. (Closes risk 2 — and risk 2 is the one that makes the milestone's headline claim false.)

**3. Run the D-41 `config.json` experiment — and expect it to overturn the decision.**
Stop `qs`, stow `config.json` alone, restart, toggle one setting, then check `test -L` and the repo diff. The source says the symlink will survive (`QSaveFile` resolves symlinks; `atomicWrites` defaults true) and the PySide6 reproduction on the same Qt 6.11.2 agrees. If it survives, **drop the copy-capture exception for `config.json`** and re-scope the exception list around GLib/GTK apps and installer-owned paths instead. Pair it with the B-1 guard (never run git operations against a live-symlinked `config.json` without stopping the shell). (Closes risk 4, and simplifies the mechanism — which is what the user actually asked for.)

---

## Sources

**Primary — read directly on this machine:**
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` (lines 12-39, 40-45, 46-52, 53-92, 93-172, 219, 236-238)
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` (lines 8-20, 22-28, 30-44, 46-77)
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh`; `vendor/dots-hyprland/setup`
- `vendor/dots-hyprland/sdata/lib/environment-variables.sh` (lines 27-30); `sdata/lib/functions.sh` (lines 346-390)
- `vendor/dots-hyprland/sdata/subcmd-uninstall/*.sh` (lines 39-115)
- `~/.config/quickshell/ii/modules/common/Config.qml`; `.../Directories.qml`; `~/.config/quickshell/ii/services/KeyringStorage.qml`
- `~/.config/hypr/hyprland.lua`; `~/.config/hypr/hyprland/general.lua`; `~/.config/hypr/custom/*.lua`; `~/.config/matugen/config.toml`
- `/usr/src/debug/illogical-impulse-quickshell-git/quickshell/src/io/fileview.cpp` (218-290, 427), `fileview.hpp:207,423`, `src/io/jsonadapter.cpp` (24-99)
- `arch/dots-hyprland.sh` (106-135, 428, 452); `docs/phase14-adopt-runbook.md` (243-255, 307); `.gitignore`; commit `2539238`
- `man stow` (GNU Stow 2.4.1) — `--adopt`, `--no-folding`, `--dotfiles`, tree folding, conflicts
- `man systemctl` — `disable` semantics; `systemctl --user list-unit-files` output

**Primary — fetched:**
- Qt `qtbase/src/corelib/io/qsavefile.cpp:194-206` (symlink resolution) — https://raw.githubusercontent.com/qt/qtbase/6.11/src/corelib/io/qsavefile.cpp
- KDE KConfig `src/core/kconfiginibackendreader_p.h:225-300` — https://invent.kde.org/frameworks/kconfig/-/raw/master/src/core/kconfiginibackendreader_p.h
- KDE KConfig `src/core/kconfigini.cpp`, `src/core/kconfig.cpp` — https://invent.kde.org/frameworks/kconfig/
- GLib `GFileSetContentsFlags` — https://docs.gtk.org/glib/flags.FileSetContentsFlags.html
- Qt `QSaveFile` class docs — https://doc.qt.io/qt-6/qsavefile.html
- Vim `'backupcopy'` — https://vimhelp.org/options.txt.html#%27backupcopy%27

**Empirical — reproduced in a scratch directory on this machine (2026-09-12):**
- `cp -f` through a symlink → target overwritten, link preserved
- `rsync -a --delete` (rsync 3.5.0) onto a symlinked dest → link replaced by a plain file, repo copy untouched
- `QSaveFile` (PySide6 / Qt 6.11.2, the same `libQt6Core.so.6` that `qs` links) → symlink resolved and preserved, target updated, `0600` preserved; dangling link with missing parent → `open()` false; dangling link with present parent → target created
- `GLib.file_set_contents` → symlink destroyed, replaced by a plain file, repo copy orphaned
- `realpath -se` returns the unresolved path (so the installer's listfile records link paths, not repo paths)

**Carried forward:** `.planning/research/v0.3/PITFALLS.md` — pitfalls 8 (asdeps/orphan cleanup), 10 (ddcutil standing ban), 11 (never `./setup uninstall`) remain in force and are not repeated here except where v0.4 gives them a new failure path.

---
*PITFALLS research for v0.4 — 2026-09-12*
