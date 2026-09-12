# Stack Research

**Domain:** Personal config capture / reproducible dotfiles layer on an installed dots-hyprland (ii) Arch + Hyprland system
**Researched:** 2026-09-12
**Confidence:** HIGH (most load-bearing claims are empirically verified on this machine; see `## Evidence log`)
**Milestone:** v0.4 Personal config layer

---

## Headline finding — D-41's premise is half wrong, and the dangerous half is the other half

D-41 says: *stow symlinks by default; narrow copy-capture exception for files an application rewrites atomically (temp + rename replaces a symlink with a plain file).*

**The named candidate does not have that problem.** Quickshell's `FileView` atomic write goes through Qt's `QSaveFile`, and `QSaveFile::open()` **resolves the symlink chain before writing and renames onto the resolved target**. The symlink survives; the file inside the repo is what gets replaced. The same is true of KDE's `KConfig` (`dolphinrc`, `kdeglobals`, `kiorc`, …), which also writes through `QSaveFile`. Verified here, twice, with real writes (see Evidence log E1, E2).

**The real capture-killer in this project is the installer, not the applications.** `vendor/dots-hyprland`'s `./setup` installs configs with `rsync -a` and `cp -f`:

| Upstream function | Mechanism | Effect on a stow symlink at the destination |
|---|---|---|
| `install_dir` / `install_dir__sync` | `rsync -a` (`--delete` for `__sync`) | **Replaces the symlink with a plain file.** Capture silently lost; repo keeps the stale copy. `--delete` additionally **removes** stow symlinks that upstream doesn't ship. |
| `install_file`, `install_file__auto_backup` | `cp -f` | **Follows the symlink and overwrites the repo file in place.** Link survives; your repo content is replaced by upstream's (visible as a `git diff`). |
| `install_dir__ignore_existing` | `[ -d $t ] && do nothing` | **Completely safe.** If the target dir exists (a real dir *or* a symlink to one), upstream touches nothing. This is what guards `~/.config/hypr/custom`. |

This is not new knowledge to the repo — it is the same asymmetry already recorded as **D-17** in `docs/phase14-adopt-runbook.md` (kitty's symlink replaced by upstream's real file → re-stow; `starship.toml` followed through the link and overwritten → accepted loss). v0.4 should generalise D-17 into a per-path policy rather than invent a new copy-capture machine for a hazard that the evidence says is rare.

**Consequence for the milestone:** the "copy-capture exception" survives, but it should be re-scoped from *"apps that write atomically"* (empirically: none of ours) to *"paths upstream `./setup` rsyncs"* (empirically: `~/.config/quickshell`, `~/.config/hypr/hyprland`, `~/.config/fontconfig`, `~/.config/fish`, and every misc `dots/.config/*` dir) — and for those the correct answer is usually **"don't stow there at all"** or **"re-stow after install"**, not copy-capture.

---

## Recommended Stack

### Core

| Technology | Version (this host) | Purpose | Why |
|---|---|---|---|
| **GNU Stow** | `stow 2.4.1-1` | Default capture path: live *is* the repo | Already the repo idiom (18 packages, 14 `arch/*.sh` scripts end in `stow -v=5 -t ~ <pkg>`). Verified symlink-safe against every writer that matters here. Migration cost of anything else is unjustified. |
| **Stow flag set: `--no-folding -R -t ~ -d <repo>/stow`** | — | Mandatory invocation shape for v0.4 packages | `--no-folding` prevents stow from turning a whole directory into one symlink (with an empty target, stow makes **`~/.config` itself** a symlink into the package — E5). `-R` makes re-running idempotent and prunes obsolete links. |
| **`stow -n -v` (simulate)** | 2.4.1 | Drift/conflict detection primitive for `verify` | Exit 1 + message on conflict (plain file or foreign symlink at target); exit 0 with `LINK:` lines when a repo file isn't linked yet. Two machine-readable drift signals, no new dependency (E6). |
| **git + `git status --porcelain`** | — | Content-drift detection for symlink-captured files | Because live *is* the repo, every app write is already a working-tree diff. No sync step exists to forget. |
| **`.stow-local-ignore` + `.gitignore`** | stow 2.4.1 | Keep runtime state out of packages | Needed for `illogical-impulse/installed_listfile`, `installed_true`, lockfiles. The repo already does the `.gitignore` half for qBittorrent. |
| **Vendored `./setup` (`arch/dots-hyprland.sh`)** | submodule pin `1a9ffb78` | Still the install SoT | Unchanged from v0.2/v0.3. Ordering vs. stow is the new contract (below). |
| **Bash wrapper subcommands** | — | `verify`, `capture`, `bootstrap` | Matches the existing `arch/dots-hyprland.sh` dispatch style; no runtime to install. |

### Supporting tools (all already present on Arch)

| Tool | Version | Purpose | When |
|---|---|---|---|
| `readlink -f` / `stat -c %i` | coreutils | Assert a live path resolves into `stow/<pkg>/…` | The second half of `verify` — catches "link exists but points somewhere else" and "link replaced by a copy of the right content" |
| `diff -q` / `diff -ru` | diffutils | Drift for copy-captured files only | Only for the (hopefully empty) copy-capture set |
| `cp -a` | coreutils | The copy-capture write itself | Same mechanism D-18 already blessed in Phase 13 |
| `rsync` | `3.5.0` | Upstream's installer mechanism (not ours) | Understand it; do not adopt it for capture |
| `kwriteconfig6` / `kreadconfig6` | `kconfig 6.29.0-1` | Seed/read KDE keys deterministically on a fresh machine | Alternative to capturing churn-prone `kdeglobals` wholesale |
| `luac -p` | lua | Syntax-gate `custom/*.lua` before they reach a live session | Phase 13 precedent (D-19) |

### Per-path capture policy (the actual deliverable of this research)

| Live path | Who else writes it | Policy | Rationale |
|---|---|---|---|
| `~/.config/hypr/custom/*.lua`, `custom/scripts/` | upstream via `install_dir__ignore_existing` → **nothing when dir exists** | **stow, `--no-folding`** | The one directory upstream explicitly refuses to touch. Safest surface in the whole system. |
| `~/.config/illogical-impulse/config.json` | ii shell via `FileView`/`JsonAdapter` (`QSaveFile`, `atomicWrites: true` default) | **stow, `--no-folding`, file-level only** | QSaveFile resolves the symlink (E1). Must be file-level: the same dir holds `installed_listfile` / `installed_true` state. |
| `~/.config/dolphinrc`, `kiorc`, `ktrashrc`, `kservicemenurc`, `darklyrc` | Dolphin/KDE via `KConfig` (`QSaveFile`) | **stow** (individual files at `~/.config` level — no folding risk) | E2. Note these are `0600`; stow preserves the repo file's mode, so commit them with 600 in-repo or accept 644. |
| `~/.config/kdeglobals` | **`kde-material-you-colors-wrapper.sh` rewrites colour sections on every wallpaper change** (`switchwall.sh:34`) | **Do NOT stow.** Seed personal non-colour keys with `kwriteconfig6` in bootstrap | Stowing it makes every wallpaper switch dirty the repo. Mechanically safe, operationally miserable. |
| `~/.config/gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, `fuzzel/fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, `hypr/hyprlock/colors.conf` | **matugen 4.2.0 generated outputs** (`matugen/config.toml`) | **Never capture** (generated) | Derived from the wallpaper; capturing them captures noise. `gtk-3.0/settings.ini` (not a matugen output) *is* capturable. |
| `~/.config/quickshell/**` | `install_dir__sync` = `rsync -a --delete` | **Never stow** | `--delete` will remove your links and rsync will replace them (E3, E4). Already the standing rule since v0.2 ("live path: real `~/.config/quickshell`, not symlink into git"). |
| `~/.config/hypr/hyprland/**`, `hyprland.lua`, `hyprlock.conf`, `hypridle.conf` | `install_dir__sync` / `install_file*` | **Never stow** — personalise via `custom/` overlays only | Upstream-owned; the Lua entry already sources `custom/`. |
| `~/.config/fish`, `fontconfig`, and misc `dots/.config/*` | `install_dir__sync` / `install_dir__sync_exclude` | **Accept-upstream** (current D-28 default) or **re-stow after install** (the kitty D-17 pattern) | Decide per app; the mechanism is the same one already documented. |
| `~/.config/systemd/user/*.service`, `~/.config/autostart/*` | nobody | **stow** | Already stowed and already survived the Phase 14 adopt. Natural home for the D-38 `graphical-session.target` autostart fix. |
| `~/.config/qBittorrent/` | qBittorrent via `QSettings`→`QSaveFile` | **stow, folded dir** (status quo; works) | Live proof in this repo: `~/.config/qBittorrent` is a folded dir symlink and the atomic-writing app has been updating the repo file in place for weeks (same inode both sides). Keep, but know that the folded-dir form also captures state files → `.gitignore` entries, which the repo already has. |

### The one-command bootstrap

Minimal robust shape — a new top-level entry (`./bootstrap.sh` or `arch/bootstrap.sh`), idempotent, re-runnable:

```bash
#!/usr/bin/env bash
set -euo pipefail
# 0. prerequisites (idempotent)
sudo pacman -S --needed --noconfirm git stow rsync
# 1. submodules BEFORE the installer (setup lives inside the submodule)
git submodule update --init --recursive
# 2. upstream install — writes with rsync/cp, so it MUST run before stow
./arch/dots-hyprland.sh install
# 3. personal layer — stow last, always --no-folding, always restow
cd stow && for p in hypr-custom illogical-impulse kde systemd "${EXISTING[@]}"; do
  stow -R --no-folding -v -t ~ "$p"
done
# 4. seed the non-capturable keys (kdeglobals etc.)
./scripts/seed-kde-keys.sh
# 5. prove it
cd .. && ./arch/dots-hyprland.sh verify
```

**Ordering rules that matter, and why:**

1. **Submodule init first** — `arch/dots-hyprland.sh` execs `vendor/dots-hyprland/setup`; an uninitialised submodule is an empty dir. `--recursive` is required (nested `shapes` submodule, OWN-03).
2. **`./setup` before `stow`** — non-negotiable. Upstream's `rsync -a` overwrites symlinks (E3) and `rsync -a --delete` deletes them (E4); running stow first means the install silently eats the personal layer. Running stow second means the only file upstream could later clobber is one you restow.
3. **`--no-folding` always** — on a *fresh* machine many of these directories don't exist yet, which is exactly the condition that triggers folding. With an empty `$HOME`, `stow` will make `~/.config` a symlink into one package (E5) — catastrophic, and it also changes upstream's behaviour (`install_dir__ignore_existing` does `[ -d $t ]`, which is **true for a symlink-to-dir** (E7), so a folded `~/.config/hypr/custom` is still respected — but a folded `~/.config/illogical-impulse` would make the installer write `installed_listfile` *into the repo*).
4. **`-R` (restow), not bare `stow`** — makes step 3 idempotent and prunes links for files deleted from the package. Bare `stow` over an existing correct tree is also fine (exit 0), but `-R` additionally repairs a partially-clobbered tree… **except** when the clobber left a plain file, which is a hard conflict and aborts (E6 case 4) — hence step 5.
5. **`verify` at the end, and its exit code is the bootstrap's exit code** — "one command yields the exact setup" is only true if the command asserts it.

### The `verify` subcommand (drift check, POLISH-01)

Three checks, all shell, no new dependencies:

```bash
# A. structural drift — conflicts and unlinked repo files
out=$(stow -n -v --no-folding -d "$REPO/stow" -t "$HOME" "$pkg" 2>&1); rc=$?
[ $rc -ne 0 ] && drift "conflict: $out"                 # plain file / foreign link at target
grep -qE '^(LINK|UNLINK):' <<<"$out" && drift "unlinked: $out"   # repo file not live yet

# B. ownership drift — link exists but resolves outside the repo
[ "$(readlink -f "$HOME/$rel")" = "$REPO/stow/$pkg/$rel" ] || drift "foreign target"

# C. content drift — copy-captured set only
diff -q "$REPO/stow/$pkg/$rel" "$HOME/$rel" >/dev/null || drift "content"
# D. and for the symlink set, content drift is just:
git -C "$REPO" status --porcelain -- stow/
```

Check A alone catches the entire "atomic write ate my symlink" failure mode *and* the "upstream rsync replaced my link" failure mode, loudly, with exit 1. That is the assertion D-41 asks for.

---

## Alternatives Considered — and rejected

Evaluated against the four criteria the milestone actually cares about: **(a)** apps that rewrite configs atomically, **(b)** directories `./setup` also writes into, **(c)** one-command fresh-machine bootstrap, **(d)** partial-directory capture.

| Tool | (a) atomic rewrites | (b) installer co-writes | (c) bootstrap | (d) partial dir | Verdict |
|---|---|---|---|---|---|
| **GNU Stow 2.4.1** *(recommended)* | **Safe** for QSaveFile writers (verified); naive temp+rename writers would clobber the link, and `stow -n` detects it with exit 1 | Neutral — no opinion, but `--no-folding` + per-path policy makes coexistence explicit; conflicts are loud, never silent | Needs ~6 lines of wrapper (already exists in style) | **Yes**, natively — `--no-folding` symlinks individual files inside a shared dir | **Keep.** Zero migration cost, 18 packages already, every hazard now measured. |
| **chezmoi** | Copy mode **loses** app writes on the next `apply`; chezmoi's own FAQ says the fix is *"replace the config file with a symlink back to the source dir"* — i.e. reinvent stow. Symlink mode excludes templates, private, executable and **whole directories** | Better story via `.chezmoiexternal`/scripts, but nothing that beats "don't stow there" | Best-in-class: `chezmoi init --apply <repo>` | Yes | **Reject.** Its own recommended answer for our central problem is symlinks; adopting it converts 18 working packages into a two-state model (source state + target state) whose main feature — templating across machines — this single-machine repo does not need. |
| **yadm** (bare repo + alt/encrypt) | Live *is* the repo (files are real files in `$HOME`) — atomic rewrites are fine | **Bad.** `$HOME` is the work tree, so upstream's `rsync --delete` into `~/.config/quickshell` interacts with a repo that tracks all of `$HOME`; you manage it with a large ignore surface | `yadm clone --bootstrap <repo>` — very good | Yes (per-file tracking) | **Reject.** Track-everything-in-`$HOME` is the opposite of "capture as touched" (the milestone's scope note) and would have to be reconciled against a 30-file `.gitignore` from day one. |
| **Bare git repo** (`git --git-dir=$HOME/.dotfiles.git`) | Fine (real files) | Same problem as yadm, without yadm's ergonomics | 3 lines, but fiddly (`showUntrackedFiles=no`, alias in shell rc before the shell rc is cloned) | Yes | **Reject.** Would orphan `stow/`, `arch/`, `docs/`, `vendor/` — this repo is a *project*, not just a home-dir snapshot. |
| **dotbot** | Symlinks, same as stow, but declared in `install.conf.yaml` | Same as stow | Good (`./install`) | Yes | **Reject (narrowly).** Functionally equivalent to stow + a wrapper; adds a Python dependency and a second submodule to gain a config file this repo can express in 6 lines of bash. |
| **home-manager / Nix** | Read-only store symlinks — **actively hostile**: an app that rewrites its config fails or the change is wiped on rebuild | Would fight `./setup` for ownership of the whole tree | Excellent once bootstrapped | Yes | **Reject.** Hard-incompatible with "app writes the config and the repo captures it", which is the milestone's core value. Also a total rewrite of `arch/*.sh`. |
| **rcm** (`rcup`) | Symlinks, same class as stow | Same as stow | `rcup -d` | Weaker (host/tag-oriented) | **Reject.** Strictly less common than stow with no advantage here. |
| **inotify/systemd-path watcher + auto-commit** | Would make copy-capture "automatic" | — | — | — | **Reject.** A daemon that commits to git on file change is exactly the "crashing stuff" the user asked to avoid, and it is unnecessary once symlink capture is proven for the writers in play. |
| **Bind mounts / hardlinks for the "atomic" case** | Bind mount survives rename-over? **No** — a file bind mount is broken by a rename over the mountpoint; hardlinks are broken by *any* temp+rename (the new inode replaces the name) — confirmed by the inode change in E1 | — | Needs root + fstab/systemd units | — | **Reject.** More moving parts, worse failure modes, and unnecessary given E1/E2. |

---

## Stow specifics that matter here (all verified on 2.4.1)

- **`--adopt` is a loaded gun and should never appear in an automated path.** It moves the *live* file's content into the package, **overwriting the repo's version** (E8: repo content `MINE` → `LIVE`, no prompt, exit 0). It is only safe as an interactive, documented ritual: clean work tree → `stow --adopt` → `git diff` → keep or `git checkout HEAD --`. That is precisely the workflow the stow manual describes ("particularly useful when the stow package is under the control of a version control system"). Put it behind a subcommand that refuses to run on a dirty tree.
- **Tree folding is the fresh-machine footgun.** Stow "only descends as far as necessary into the target tree when it can create a tree-folding symlink". Empty target ⇒ `~/.config` becomes a symlink into one package (E5). Two live examples of folding already exist in this repo (`~/.config/qBittorrent`, `~/.config/smartmontools`) — harmless there, but not something to let happen to a directory the ii installer writes into.
- **Tree unfolding** (splitting a folded symlink into a real dir when a second package needs it) is automatic, and stow "will never delete anything that it doesn't own" — so unfolding is safe; it is the *folded* state that is hazardous, because non-stow writers (installer, app state files) then land inside the repo.
- **Conflicts abort everything, atomically-ish.** Since 2.0 stow does a two-phase scan: conflicts are collected, displayed, and **nothing is stowed or unstowed** (exit 1). Same exit code under `--simulate` (E6) — which is what makes it a usable `verify` primitive.
- **`--dotfiles` (the `dot-` prefix rewrite) is not applicable.** This repo stores real `.config/…` paths inside packages; enabling `--dotfiles` would change nothing and risks surprising interactions with the ignore list. Do not adopt.
- **`.stow-local-ignore`** (per-package, top-level) overrides the built-in ignore list and is the right place to exclude runtime state from a captured directory. Note the default ignore list already drops `.gitignore`, CVS/emacs lock patterns, etc.
- **`-R/--restow` vs `-D` + `stow`**: `-R` is the documented way to prune obsolete symlinks after the package changes; prefer it in scripts. `-p/--compat` scans the whole target tree when unstowing (catches orphans from files you deleted from a package long ago) — useful for a one-off cleanup, too slow/broad for routine use.
- **Version currency:** 2.4.1 is what Arch ships (`stow 2.4.1-1`) and is the current GNU release line; 2.4.x added `--dotfiles` ignore-list refinements and the default "don't scan the whole tree on unstow" behaviour that `--compat` reverses. No behaviour change in 2.4.x affects the design above. *(Release-note detail: MEDIUM confidence — verified behaviours are from the installed 2.4.1 manual and live runs, not from reading the 2.4.x NEWS file.)*

---

## The atomic-write hazard, concretely

**What `rename(2)` over a symlink does:** `rename(newpath=link)` replaces the *link itself* — the directory entry is overwritten, so the symlink is gone and a plain file takes its place. Capture is lost silently and the repo keeps the last-known content. Verified (E9: Python `os.replace` → live file becomes plain, repo still says `ORIGINAL`).

**Why our apps don't do that:** Qt's `QSaveFile` explicitly defeats it. From `qtbase/src/corelib/io/qsavefile.cpp`, `QSaveFilePrivate::open()`:

```cpp
finalFileName = fileName;
if (priorFile.isSymLink()) {
    int maxDepth = 128;
    for (QString target; maxDepth; --maxDepth) {
        target = priorFile.symLinkTarget();
        if (target.isEmpty()) break;
        priorFile.setFile(target);
    }
    if (maxDepth > 0) finalFileName = priorFile.filePath();
}
```

and `commit()` does `fe->renameOverwrite(d->finalFileName)`. The temp file is created next to — and renamed onto — **the resolved target**, i.e. the file inside `stow/`. Side effect worth knowing: the repo file's **inode changes on every save** (E1: `16404027 → 16404029`), which is why hardlink-based capture schemes are not an option.

**Who writes what, in this system:**

| Writer | Mechanism | Source | Symlink-safe? |
|---|---|---|---|
| Quickshell `FileView` (ii `Config.qml`, `Persistent.qml` → `writeAdapter()`) | `QSaveFile` when `atomicWrites` is true, which is **the default** (`Q_OBJECT_BINDABLE_PROPERTY_WITH_ARGS(..., bAtomicWrites, true, ...)`); ii never sets it false | `/usr/src/debug/illogical-impulse-quickshell-git/quickshell/src/io/fileview.{cpp,hpp}` (pinned build, on this host) | **Yes** |
| KDE `KConfig` (`dolphinrc`, `kdeglobals`, …) | `QSaveFile file(filePath())`; falls back to direct in-place write when the file is not owned by the user | `kconfig/src/core/kconfiginibackendreader_p.h` | **Yes** |
| qBittorrent (`QSettings`) | Qt atomic save | live evidence in this repo | **Yes** (folded dir, same inode both sides) |
| btop | in-place truncate on exit | live evidence: `~/.config/btop/btop.conf` is still a symlink after months | **Yes** |
| upstream `./setup` `rsync -a` | temp + rename **per file** | `sdata/subcmd-install/3.files.sh` | **NO — replaces link with plain file** |
| upstream `./setup` `cp -f` | write through the link | same | Link survives, **repo content overwritten** |
| matugen 4.2.0 template output | UNVERIFIED (likely in-place truncate) | — | Irrelevant — never capture generated outputs |
| Firefox `prefs.js`, VS Code `settings.json` | temp + rename (non-Qt) — the classic symlink-eaters other dotfile setups complain about | not in scope for this repo | Would need copy-capture; **none are in the v0.4 target list** |

**What other dotfile setups do about it:** chezmoi's documented answer is to make the target a symlink back into the source dir (i.e. what stow does); yadm/bare-repo sidestep it by making `$HOME` the work tree; home-manager cannot solve it at all (read-only store). Nobody recommends a watcher daemon.

---

## Evidence log (empirical, this host, 2026-09-12)

| ID | Test | Result |
|---|---|---|
| E1 | Compiled a `QSaveFile` writer against `qt6-base 6.11.2-3`; wrote to `home/config.json` → `../repo/config.json` | `commit=1`; **symlink intact**; repo content replaced; repo inode `16404027 → 16404029` |
| E2 | `kwriteconfig6 --file <symlinked dolphinrc>` (`kconfig 6.29.0-1`) | **Symlink intact**; repo `dolphinrc` updated; inode replaced |
| E3 | `rsync -a src/ home/` where `home/f` is a symlink into repo | **Symlink replaced by a plain file**; repo still holds the old content |
| E4 | `rsync -a --delete src/ home/` with an extra stow symlink present | **Symlink deleted**; repo file survives, capture silently broken |
| E4b | `rsync -a --ignore-existing src/ home/` | Symlink preserved, content untouched |
| E4c | `cp -f src/f home/f` (symlink) | Link survives; **repo content overwritten with upstream's** |
| E5 | `stow` into an empty target, package containing `.config/hypr/custom/…` | `home/.config` **itself became a symlink** into the package; `--no-folding` produced real dirs + one file symlink |
| E6 | `stow -n -v` against: consistent tree / new repo file / deleted live link / foreign symlink / plain file | exit 0 silent · exit 0 + `LINK:` · exit 0 + `LINK:` · **exit 1 conflict** · **exit 1 conflict** |
| E7 | `[ -d ]` on a symlink-to-dir | TRUE → upstream's `install_dir__ignore_existing` guard respects a stowed dir |
| E8 | `stow --adopt` over a live plain file | exit 0; **repo content silently replaced by the live content** |
| E9 | Python `os.replace(tmp, link)` | Link replaced by a plain file; repo untouched — the generic hazard, confirmed |

Corroboration from the repo's own history: `docs/phase14-adopt-runbook.md` §9 / D-17 already records E3 (kitty) and E4c (`starship.toml`) as observed live behaviour.

---

## What NOT to use

| Avoid | Why | Use instead |
|---|---|---|
| A copy-capture mechanism for `illogical-impulse/config.json` | The premise is disproven — `FileView` writes through the symlink (E1) | Plain stow with `--no-folding` |
| A file watcher / auto-commit daemon | Complexity and surprise; "simplest, without crashing stuff" was the stated constraint | Live-is-the-repo symlinks + `verify` |
| `stow` without `--no-folding` for any new v0.4 package | Folds `~/.config` (or `~/.config/illogical-impulse`) into the repo and lets the installer write state files into git | `--no-folding` always |
| Stowing `~/.config/quickshell`, `~/.config/hypr/hyprland`, `hyprland.lua` | `rsync -a --delete` territory | `hypr/custom/` overlays; upstream owns the rest |
| Stowing `~/.config/kdeglobals` wholesale | Regenerated on every wallpaper change by `kde-material-you-colors-wrapper.sh` → permanent repo churn | Seed personal keys via `kwriteconfig6` in bootstrap; leave the file uncaptured |
| Capturing matugen outputs (`gtk-3.0/gtk.css`, `fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, `hyprlock/colors.conf`) | Machine-generated from the wallpaper | Capture the *inputs* (matugen templates) if anything |
| `stow --adopt` inside any script | Silently overwrites repo content (E8) | Interactive subcommand gated on a clean work tree, followed by `git diff` |
| Switching to chezmoi / yadm / home-manager | Migration cost on 18 working packages, and none solves a problem stow has here | Stay on stow |
| Hardlinks or bind mounts as an atomic-write workaround | QSaveFile replaces the inode every save (E1); bind mounts break on rename-over | Not needed |
| Running `stow` before `./setup` on a fresh machine | Installer eats the personal layer (E3/E4) | `./setup` → `stow -R --no-folding` → `verify` |

---

## Open questions requiring empirical test

1. **[HIGH] Does ii write `config.json` while the shell is running, often enough to matter?** E1 proves the *mechanism* is safe; it does not prove the repo won't churn. Test: change one bar setting in the ii settings UI, then `git status` — confirm exactly one file changes and the symlink is still a symlink afterwards (`ls -l ~/.config/illogical-impulse/config.json`). This is the single UAT that retires D-41's uncertainty.
2. **[HIGH] Does the ii shell ever *delete and recreate* `~/.config/illogical-impulse/`** (e.g. a first-run/migration path) rather than just writing the file? `FileView` write creates parent dirs via `mkpath` but never unlinks the dir; UNVERIFIED for the surrounding ii QML. Test: remove the file, restart `qs -c ii`, observe whether a fresh plain file appears where the symlink was.
3. **[MEDIUM] `kdeglobals` churn rate.** Confirm `kde-material-you-colors-wrapper.sh` is what rewrites it (`switchwall.sh:34`) and how much of the file is colour-generated vs. personal. If the personal surface is 3 keys, the seed-script approach wins; if it's 30, reconsider.
4. **[MEDIUM] File modes through stow.** `dolphinrc`, `kdeglobals`, `kiorc`, `kservicemenurc`, `ktrashrc` are `0600` live. Git stores only the exec bit, so a fresh clone yields `0644` in the repo and the symlink exposes that mode. Test whether KConfig cares (E2's `createNew=false` branch triggers on *ownership*, not mode, so it probably doesn't) — and decide whether bootstrap should `chmod 600` after stow.
5. **[MEDIUM] Re-run of `./setup` after the personal layer is stowed.** The policy table predicts: `hypr/custom` untouched, kitty-style clobber on any misc dir, `cp -f` write-through on named files. Test with a real `install-files` run on a scratch `XDG_CONFIG_HOME` before trusting the ordering rule in the bootstrap script.
6. **[LOW] matugen 4.2.0 write mechanism** (in-place vs temp+rename) — only matters if a decision is later made to capture a matugen *output*, which this research recommends against.
7. **[LOW] `~/.config/autostart` semantics under Hyprland** — whether XDG autostart `.desktop` files are honoured in this session at all, or whether the D-38 fix must be `custom/execs.lua` + `systemctl --user start hyprland-session.service`. Affects which package the startup requirement lands in, not the capture mechanism.

---

## Sources

**Primary — source read on this host (HIGH):**
- `/usr/src/debug/illogical-impulse-quickshell-git/quickshell/src/io/fileview.cpp` §`FileViewWriter::write` — `QSaveFile` vs `QFile` branch on `doAtomicWrite`
- `/usr/src/debug/illogical-impulse-quickshell-git/quickshell/src/io/fileview.hpp` — `atomicWrites` default `true`, documented as "creating another file … and renaming it over the existing file"
- `~/.config/quickshell/ii/modules/common/Config.qml`, `Persistent.qml` — `FileView` + `JsonAdapter` + `writeAdapter()`, `atomicWrites` never overridden
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` — `cp_file`, `rsync_dir`, `rsync_dir__sync`, `rsync_dir__ignore_existing`, `install_dir*`, `install_file*`
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — per-path install map (quickshell/fish/fontconfig/hypr/custom)
- `vendor/dots-hyprland/dots/.config/matugen/config.toml` — generated-output list
- `~/.config/quickshell/ii/scripts/colors/{switchwall.sh,applycolor.sh}` — `kde-material-you-colors-wrapper.sh` invocation
- `info stow` (GNU Stow 2.4.1 manual, installed): *Invoking Stow* (`--adopt`, `--no-folding`, `--dotfiles`, `--simulate`, `--compat`), §5.1 Tree folding, §5.2 Tree unfolding, §5.3 Ownership, §6.1 Refolding, *Conflicts*
- `docs/phase14-adopt-runbook.md` §9 / D-17 — prior live observation of the same rsync/cp asymmetry

**Primary — upstream source (HIGH):**
- https://raw.githubusercontent.com/qt/qtbase/dev/src/corelib/io/qsavefile.cpp — `QSaveFilePrivate::open()` symlink resolution (128-level chase), `commit()` `renameOverwrite(finalFileName)`
- https://invent.kde.org/frameworks/kconfig/-/raw/master/src/core/kconfiginibackendreader_p.h — `QSaveFile file(filePath());`, `setDirectWriteFallback` (Android only), non-owner direct-write fallback
- https://doc.qt.io/qt-6/qsavefile.html — "contents will be written to a temporary file, and if no error happened, commit() will move it to the final file"
- https://www.gnu.org/software/stow/manual/stow.html — GNU Stow manual

**Secondary (HIGH/MEDIUM):**
- chezmoi docs via Context7 (`/twpayne/chezmoi`): symlink-mode restrictions, "handle configuration files which are externally modified" → symlink back to source dir, `chezmoi init --apply`, `chezmoi diff`
- Package versions on this host: `stow 2.4.1-1`, `qt6-base 6.11.2-3`, `kconfig 6.29.0-1`, `illogical-impulse-quickshell-git 0.1.0.r1-8`, `matugen 4.2.0-1`, `rsync 3.5.0`

---
*STACK research for v0.4 — 2026-09-12*
