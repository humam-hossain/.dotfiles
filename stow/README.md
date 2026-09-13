# stow/ — Installer-Never-Collides Tree

Personal dotfile packages managed with GNU Stow where upstream `dots-hyprland` installer primitives never collide with symlinks or overwrite content.

## Purpose

Files in this tree represent personal configurations for applications and components that upstream `dots-hyprland` does not manage, does not touch, or explicitly ignores existing paths for.

1. **Live path guarantee:** Every file linked from `stow/` into `$HOME` remains a live symlink.
2. **Authoring source:** The repo copy is the canonical authoring source.
3. **Collision immunity:** The upstream installer never removes, replaces, or writes through files in this tree.

---

## 1. Contract

The upstream `dots-hyprland` installer never collides with anything in this tree. The live path in `$HOME` remains a symlink, and the repo copy is never written through by installer scripts.

The predicate for membership in `stow/` is derived directly from `collision-map.tsv`:
- A package belongs in `stow/` when every destination at or above its installed paths has `symlink_outcome` as `preserved` and `repo_outcome` as `untouched` (D-05).
- There are only two derived trees in `collision-map.tsv`: `stow` and `restow`. No third tree exists in the collision map.

---

## 2. Recovery & Re-linking

Because the upstream installer never touches or destroys links in `stow/`, there is **nothing to recover** after a normal `dots-hyprland` installation run.

On a fresh machine, or to restore symlinks after manual unlinking, link packages using GNU Stow with the standard verbose and no-folding idiom (D-14):

```bash
# Link a package from stow/ into $HOME
cd stow
stow --verbose=5 --no-folding -t ~ <package-name>
```

`--no-folding` applies uniformly across all packages and trees to guarantee discrete file symlinks rather than directory symlinks, preventing subtree shadowing and minimizing blast radius if an operation is interrupted.

---

## 3. Membership Predicate

A package belongs in `stow/` if:
1. It does not appear in `collision-map.tsv` at all (upstream does not manage it), **OR**
2. In `collision-map.tsv`, every matching entry for the package's target paths has `symlink_outcome: preserved` and `repo_outcome: untouched` (such as `$XDG_CONFIG_HOME/hypr/custom` via `install_dir__ignore_existing`).

Prefix matching is used per D-13: if any destination path of a package sits at or under a `dest` row in `collision-map.tsv` that is destroyed or overwritten, that package does **not** belong in `stow/` — it belongs in `restow/`.

---

## 4. Upstream Quirk: `install_dir__ignore_existing`

The upstream primitive `install_dir__ignore_existing` (used for `hypr/custom`) short-circuits on the whole destination directory, not per file (RESEARCH F-4).

Once `~/.config/hypr/custom` exists on disk:
- Any *new* files added upstream under `dots/.config/hypr/custom/` will **never** be installed.
- The primitive's name promises per-file merge semantics, but the implementation delivers all-or-nothing directory semantics.
- For our personal configuration, this all-or-nothing behavior guarantees that our personal overlay files remain completely isolated from upstream changes.

---

## 5. The Banned Stow Flag and the Procedure that Replaces It

### The Ban (CAP-07)

GNU Stow provides a `--adopt` flag. **The `--adopt` flag is strictly banned from all scripts in `arch/` and `scripts/`.**

**Why it is banned:**
Running `stow --adopt` silently replaces repository content with live filesystem content while exiting with status 0 (RESEARCH F-7). If an operator runs `stow --adopt` when live files have drifted or been overwritten by third parties, the authoring source of truth in git is destroyed without warning.

**The only exception:**
The `--adopt` flag may only ever be used in interactive manual sessions by an operator, on a clean tree, one path at a time.

### Procedure Replacing `--adopt` (stow-over-a-real-file)

When a live target in `$HOME` is already a real file or directory rather than a symlink, GNU Stow will exit with a conflict error. Do not reach for `--adopt`. Follow this safe procedure instead:

1. **Simulate first to see exact conflicts:**
   ```bash
   cd stow
   stow -n --verbose=5 --no-folding -t ~ <package-name>
   ```

2. **Inspect and decide which copy wins:**
   Diff the live file in `$HOME` against the repository file in `stow/<package-name>/...`.

3. **Move the live file aside (never delete immediately):**
   ```bash
   mv ~/.config/example ~/.config/example.aside
   ```

4. **Run the real stow command:**
   ```bash
   stow --verbose=5 --no-folding -t ~ <package-name>
   ```

5. **Verify that the link was created:**
   ```bash
   test -L ~/.config/example
   ```

6. **Clean up the aside copy:**
   Once verified, the `.aside` backup can be removed in a subsequent clean commit.
