# Configuration Redistribution Registry (FIX-03)

This document is the canonical operator-facing record for the migration and redistribution of all configuration files formerly located under repo-root `.config/`.

## Purpose & Commit Granularity (D-28)

Repo-root `.config/` was an artifact of earlier development phases prior to adopting the three-tree model (`stow/`, `restow/`, `capture/`). Under requirement FIX-03, all 12 tracked files under `.config/` are relocated according to the collision classifications established in `collision-map.tsv`.

Per decision **D-28**, this removal is split into discrete, independently revertible commits by disposition:
1. **Archive:** `.config/hypr/hyprland.conf` and `hyprland.conf.bak` into `docs/archive/` (Plan 18-04).
2. **KDE restow:** `.config/dolphinrc` and `.config/kdeglobals` into `restow/` with live-content adoption (Plan 18-04).
3. **Hypr split:** Hyprland configurations split between `stow/hypr/` and `restow/hypr/` (Plan 18-06).
4. **Script retargeting:** Updating scripts that reference the old `.config/` paths (Plan 18-09).
5. **Tree retirement:** Final removal of the emptied repo-root `.config/` directory (Plan 18-09).

> **Important:** No file leaving repo-root `.config/` is disposed of as generated or silently deleted. Every file is preserved in `stow/`, `restow/`, or `docs/archive/`.

---

## Reconciliation against `collision-map.tsv`

Every destination path below is derived mechanically from `collision-map.tsv` using prefix matching (D-13):
- A path belongs in `stow/` if every matching prefix row in `collision-map.tsv` preserves the symlink and leaves repo content untouched.
- A path belongs in `restow/` if any matching prefix row in `collision-map.tsv` has a DESTROYED symlink outcome or OVERWRITTEN repo outcome.

### Note on `hyprland.lua` (RESEARCH F-13)
The collision map includes `$XDG_CONFIG_HOME/hypr/hyprland.lua` (`3.files-legacy.sh:61`), which was not enumerated in initial planning discussions. Because `hyprland.lua` is generated and managed live by `dots-hyprland` and has no counterpart in repo-root `.config/`, it represents a valid collision map row that produces **no move** in this redistribution.

---

## Redistribution Table

| Source Path | Disposition | Destination | Content Decision (D-22) | Justification / Map Row |
|---|---|---|---|---|
| `.config/dolphinrc` | Move | `restow/dolphinrc/.config/dolphinrc` | **Live wins** | MISC loop (`3.files-legacy.sh:15`, `install_file` → `cp-through`). Repo copy was stale; live has genuine KDE settings. |
| `.config/kdeglobals` | Archive | `docs/archive/kdeglobals` | N/A (Archive) | Retired in Phase 22 (D-20) due to wallpaper churn (Q7). Live unlinked, guarded by `guard-paths.tsv`. |
| `.config/hypr/custom/env.lua` | Move | `stow/hypr/.config/hypr/custom/env.lua` | **Repo wins** (identical) | `$XDG_CONFIG_HOME/hypr/custom` (`install_dir__ignore_existing`, preserved). Live and repo match. |
| `.config/hypr/custom/execs.lua` | Move | `stow/hypr/.config/hypr/custom/execs.lua` | **Repo wins** (identical) | Mandated by Phase 17 D-18. `install_dir__ignore_existing`. Live and repo match. |
| `.config/hypr/custom/general.lua` | Move | `stow/hypr/.config/hypr/custom/general.lua` | **Repo wins** (identical) | `$XDG_CONFIG_HOME/hypr/custom` (`install_dir__ignore_existing`, preserved). Live and repo match. |
| `.config/hypr/hypridle.conf` | Move | `restow/hypr/.config/hypr/hypridle.conf` | **Repo wins** (identical) | `install_file__auto_backup` (`3.files-legacy.sh:56`). Firstrun renames link away (`mv`), so outcome is DESTROYED (`rsync-replace`). Disarmed on host via `installed_true`, but map models firstrun. |
| `.config/hypr/hyprlock.conf` | Move | `restow/hypr/.config/hypr/hyprlock.conf` | **Repo wins** (identical) | `install_file__auto_backup` (`3.files-legacy.sh:56`). Firstrun renames link away (`mv`), so outcome is DESTROYED (`rsync-replace`). Disarmed on host via `installed_true`. |
| `.config/hypr/hyprland-gui.conf` | Move | `stow/hypr/.config/hypr/hyprland-gui.conf` | **Repo wins** (identical) | Not present in `collision-map.tsv`. Upstream installer never writes to this filename; safe in `stow/`. |
| `.config/hypr/hyprpaper.conf` | Move | `stow/hypr/.config/hypr/hyprpaper.conf` | **Repo wins** (identical) | Not present in `collision-map.tsv`. Upstream installer never writes to this filename; safe in `stow/`. |
| `.config/hypr/hyprland/scripts/launch_first_available.sh` | Move | `restow/hypr/.config/hypr/hyprland/scripts/launch_first_available.sh` | **Repo wins** | `$XDG_CONFIG_HOME/hypr/hyprland` (`install_dir__sync`, DESTROYED). Live is byte-identical to vendor because installer overwrote it. Taking repo preserves customizations. |
| `.config/hypr/hyprland.conf` | Archive | `docs/archive/hyprland.conf` | N/A (Archive) | No live counterpart in `$HOME`. Upstream renamed `hyprland.conf` to `.old` during Phase 14 adopt (`3.files-legacy.sh:51-54`). Retired. |
| `.config/hypr/hyprland.conf.bak` | Archive | `docs/archive/hyprland.conf.bak` | N/A (Archive) | Backup copy byte-identical to live backup. Preserved in archive for historical provenance (D-23). |

---

## Live-Linking Precondition (Plan 18-11)

No GNU Stow commands are executed in plans 18-04 or 18-06. All live symlinks for migrated packages are created centrally in Plan 18-11 in the main worktree.
