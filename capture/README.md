# capture/ — Writer-Renames-Over-The-Link Tree

Personal dotfile packages captured by copying from live `$HOME` into the repository, for configurations where external tools or background writers break symlinks via atomic renames.

## Purpose

Files in this tree represent configurations modified at runtime by applications that write atomically — saving new content to a temporary file and renaming it over the destination (e.g. `switchwall.sh`, `matugen`, theme switchers).

1. **Copy, never symlink:** Files in `capture/` are copied from the live filesystem to the repository, never linked into `$HOME`. A symlink at these paths would be destroyed immediately by the application's rename operation.
2. **Periodic capture:** Changes are captured into git by running the wrapper's `capture` subcommand.
3. **Inverted verification:** `verify` requires that live counterparts are **not** symlinks into the repo; if a live path in this tree is a symlink, it is considered a defect.

---

## 1. Contract

Files in this tree are subject to non-installer writers that rename over the live destination path. Because symlinks cannot survive such atomic writes, this tree uses a copy-based capture model.

- Repo copies are updated from `$HOME` using `./arch/dots-hyprland.sh capture`.
- `capture` copies files from live `$HOME` into the working tree, but **never runs `git add` and never commits** (D-38). The operator reviews `git diff` and commits intentionally.
- Untracked, absent, or dirty repository mirrors are refused per-path to avoid clobbering uncommitted work (D-36, D-37).

---

## 2. Refresh & Recovery Commands

There is nothing to re-stow in this tree. To synchronize modifications from live `$HOME` into the repository:

```bash
# Preview what would be captured without touching the repo
./arch/dots-hyprland.sh capture --dry-run

# Capture clean paths from live into capture/
./arch/dots-hyprland.sh capture
```

---

## 3. Membership Rule (Hand-Assigned Prose)

Membership in `capture/` is **hand-assigned prose**, not machine-derived (D-05):
- A file belongs in `capture/` when a non-installer writer renames over the live link (such as wallpaper switchers or theme generators writing JSON/CSS state).
- `capture` is **never derived** from `collision-map.tsv` and **never appears** in its `tree` column. `collision-map.tsv` is strictly scoped to the `dots-hyprland` installer.
- `verify` checks `capture/` with an inverted expectation (live path must NOT be a symlink into the repo) without consulting the collision map.

---

## 4. Initial State (Empty Tree)

This tree is **legitimately empty** upon creation in Phase 18 (D-11, D-41).
- Phase 18 establishes the capture model, wrapper subcommands, and verification contracts.
- The first inhabitant (`config.json` and theme state) arrives in Phase 21.
- This `capture/README.md` file is tracked in git and keeps the directory present in fresh clones without needing a `.gitkeep` placeholder.
