# Phase 29: Theme Data Contracts, Verification & Bootstrap Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-18
**Phase:** 29-theme-data-contracts-verification-bootstrap-integration
**Areas discussed:** Guard Paths & Gitignore Reconciliation, Collision Map & Package Tree Taxonomy, Bootstrap Fresh-Run Validation & De-stubbing, Phase 29 Automated Test Harness & Zero Churn Gates

---

## Guard Paths & Gitignore Reconciliation

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Mirror all guard-paths in .gitignore | Add kde-material-you-colors/ to .gitignore to ensure 1:1 parity between guard-paths.tsv and git tracking exclusions. | ✓ |
| Keep .gitignore as-is | kde-material-you-colors is only generated in ~/.config and will never enter the repo trees. | |
| You decide | Whatever best enforces zero git drift and passes strict verification. | |

**User's choice:** Mirror all guard-paths in .gitignore — add kde-material-you-colors/ to .gitignore to ensure 1:1 parity between guard-paths.tsv and git tracking exclusions.
**Notes:** Establishes mechanical consistency across both files.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Hierarchical prefix matching | is_guarded_path matches both exact file paths and any sub-file under a guarded directory (e.g. Kvantum/* or kde-material-you-colors/*). | ✓ |
| Exact path matching only | Keep dictionary lookup as-is; directory entries only guard the directory itself. | |
| You decide | Implement the most robust mechanism to prevent accidental de-stubbing or unlinking of guarded theme state. | |

**User's choice:** Hierarchical prefix matching — is_guarded_path matches both exact file paths and any sub-file under a guarded directory (e.g. Kvantum/* or kde-material-you-colors/*).
**Notes:** Essential so child files created by generator daemons inside guarded directories are not treated as conflicts during bootstrap de-stubbing.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Fully reconcile header documentation | Update the empirical rationale in guard-paths.tsv to accurately reflect v0.5 Material You dynamic generation across all 8 entries (GTK 3/4, Fuzzel, Hyprland, Hyprlock, KDE). | ✓ |
| Keep existing header comments | Leave historical Q7/Q8 notes unchanged and only verify TSV data rows. | |
| You decide | Whichever maintains clean documentation integrity. | |

**User's choice:** Fully reconcile header documentation — update the empirical rationale in guard-paths.tsv to accurately reflect v0.5 Material You dynamic generation across all 8 entries (GTK 3/4, Fuzzel, Hyprland, Hyprlock, KDE).
**Notes:** Clarifies why each of the 8 paths is guarded for future maintainers.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Recursive guard validation in verify | Ensure that if a guarded path is a directory (or prefix), any symlink within it pointing into the repo is also rejected, matching bootstrap.sh prefix matching. | ✓ |
| Keep verify guard check as-is | Exact file/directory readlink check is already sufficient and passes strict verification. | |
| You decide | Prioritize bulletproof protection against accidental symlinks into git. | |

**User's choice:** Recursive guard validation in verify — ensure that if a guarded path is a directory (or prefix), any symlink within it pointing into the repo is also rejected, matching bootstrap.sh prefix matching.
**Notes:** Reconciles the verification engine with the prefix rule in bootstrap.

---

## Collision Map & Package Tree Taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Move fuzzel and kitty to restow/ | Strictly honors collision-map.tsv mathematical derivation (install_dir__sync -> DESTROYED -> restow) and generates their recovery commands in restow/README.md. | ✓ |
| Keep fuzzel and kitty in stow/ | Document an exception to collision-map tree derivation in collision-map.tsv header. | |
| You decide | Whichever makes the three-tree capture model 100% consistent and machine-checked. | |

**User's choice:** Move fuzzel and kitty to restow/ — strictly honors collision-map.tsv mathematical derivation (install_dir__sync -> DESTROYED -> restow) and generates their recovery commands in restow/README.md.
**Notes:** Mathematically sound; live test confirmed upstream's `install_dir__sync` destroys symlinks on install.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Regenerate restow/README.md table via scripts/gen-collision-map.sh --restow-table | Updates the machine-generated section to list fuzzel and kitty with rsync-replace tags. | ✓ |
| Keep restow/README.md table manual | Without running the generator script. | |
| You decide | Maintain strict machine-generated parity. | |

**User's choice:** Regenerate restow/README.md table via scripts/gen-collision-map.sh --restow-table — updates the machine-generated section to list fuzzel and kitty with rsync-replace tags.
**Notes:** Preserves the machine-checked property asserted in Phase 18 and Phase 22.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Update arch/kitty.sh to stow from ../restow | Preserves the PAIR_COUNT == 18 invariant while correctly targeting restow/kitty. | ✓ |
| Leave arch/kitty.sh targeting stow/ | (Requires keeping kitty in stow/). | |
| You decide | Maintain script consistency and pass the PAIR_COUNT invariant. | |

**User's choice:** Update arch/kitty.sh to stow from ../restow — preserves the PAIR_COUNT == 18 invariant while correctly targeting restow/kitty.
**Notes:** Retargets the stow command without altering the `--verbose=5 --no-folding` flag occurrence count.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Re-stow cleanly from restow/ | Unstow from stow/ then stow from restow/ to point live symlinks cleanly to restow/ without dangling references. | ✓ |
| Rely on bootstrap.sh destub to re-point symlinks | On next bootstrap run. | |
| You decide | Ensure verify --strict exits 0 with 0 findings immediately after the move. | |

**User's choice:** Re-stow cleanly from restow/ — unstow from stow/ then stow from restow/ to point live symlinks cleanly to restow/ without dangling references.
**Notes:** Immediate live verification hygiene.

---

## Bootstrap Fresh-Run Validation & De-stubbing

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Pre-create .config/fuzzel and .config/kitty | Ensure physical directory existence before stowing and before Matugen generates fuzzel_theme.ini / kitty-theme.conf. | ✓ |
| Keep current pre-created directory list as-is | GNU Stow --no-folding already creates parent directories. | |
| You decide | Whatever prevents directory folding and race conditions on fresh bootstrap. | |

**User's choice:** Pre-create .config/fuzzel and .config/kitty — ensure physical directory existence before stowing and before Matugen generates fuzzel_theme.ini / kitty-theme.conf.
**Notes:** Added to `run_stow_step()` in `bootstrap.sh`.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Explicit legacy Catppuccin symlink pruning in destub | If ~/.config/gtk-4.0/gtk.css or ~/.config/gtk-3.0/gtk.css points to /usr/share/themes/Catppuccin*, unlink it so Matugen can write regular user files without permission errors. | ✓ |
| Rely on manual intervention or operator pre-clean | Do not add special-cased unlinking to destub. | |
| You decide | Ensure automated bootstrap succeeds without permission-denied errors on dirty/legacy setups. | |

**User's choice:** Explicit legacy Catppuccin symlink pruning in destub — if ~/.config/gtk-4.0/gtk.css or ~/.config/gtk-3.0/gtk.css points to /usr/share/themes/Catppuccin*, unlink it so Matugen can write regular user files without permission errors.
**Notes:** Fulfills INTG-03 explicitly.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Initial theme generation in bootstrap | Invoke switchwall.sh --noswitch (or colors sub-pipeline) after capture_seed so generated configs (kitty-theme.conf, fuzzel_theme.ini, gtk.css) are populated before user relogin. | ✓ |
| Rely on Hyprland startup hooks | To generate them on first graphical login. | |
| You decide | Ensure fresh boots have complete valid theme files without error dialogs. | |

**User's choice:** Initial theme generation in bootstrap — invoke switchwall.sh --noswitch (or colors sub-pipeline) after capture_seed so generated configs (kitty-theme.conf, fuzzel_theme.ini, gtk.css) are populated before user relogin.
**Notes:** Guarantees all theme outputs exist before `step_verify` runs.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Fail-soft with fallback color | Attempt switchwall.sh --noswitch; if wallpaper image is absent, fall back to default color seed (e.g. switchwall.sh --color "#3f51b5") so theme files are always generated without blocking bootstrap. | ✓ |
| Fail-closed | Require the wallpaper image to exist or abort bootstrap. | |
| You decide | Ensure bootstrap completes cleanly even on a fresh machine without pre-copied pictures. | |

**User's choice:** Fail-soft with fallback color — attempt switchwall.sh --noswitch; if wallpaper image is absent, fall back to default color seed (e.g. switchwall.sh --color "#3f51b5") so theme files are always generated without blocking bootstrap.
**Notes:** Makes headless/clean-clone execution reliable.

---

## Phase 29 Automated Test Harness & Zero Churn Gates

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) 5-section comprehensive assert suite | Section 1: Data contracts & gitignore parity; Section 2: Live switchwall.sh zero-churn drill; Section 3: verify --strict 0 findings; Section 4: Bootstrap destub & stow drill; Section 5: Full v0.5 regression sweep. | ✓ |
| Lean assert suite | Test only guard-paths and verify --strict without running switchwall or bootstrap simulation. | |
| You decide | Whatever provides 100% Nyquist compliance and covers INTG-01..03. | |

**User's choice:** 5-section comprehensive assert suite — Section 1: Data contracts & gitignore parity; Section 2: Live switchwall.sh zero-churn drill; Section 3: verify --strict 0 findings; Section 4: Bootstrap destub & stow drill; Section 5: Full v0.5 regression sweep.
**Notes:** Authoritative regression prevention across all v0.5 phases.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Porcelain snapshot with mtime advancement | Execute switchwall.sh --noswitch, verify mtimes advance on all generated outputs, and assert git status --porcelain is byte-identical clean before and after. | ✓ |
| Check git status only | Without asserting mtime advancement on output files. | |
| You decide | Ensure fail-closed detection of any un-guarded theme output. | |

**User's choice:** Porcelain snapshot with mtime advancement — execute switchwall.sh --noswitch, verify mtimes advance on all generated outputs, and assert git status --porcelain is byte-identical clean before and after.
**Notes:** Proves live theme updates actually took place and resulted in zero working-tree churn.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Adversarial scratch drill with Catppuccin & theme stubs | Verify in isolated scratch home that legacy Catppuccin symlinks are pruned, guarded paths are preserved, and fuzzel/kitty are cleanly linked from restow/. | ✓ |
| Basic bootstrap --dry-run check only | Rely on Phase 23 harness for scratch testing. | |
| You decide | Ensure automated detection of regression in bootstrap de-stubbing and stowing. | |

**User's choice:** Adversarial scratch drill with Catppuccin & theme stubs — verify in isolated scratch home that legacy Catppuccin symlinks are pruned, guarded paths are preserved, and fuzzel/kitty are cleanly linked from restow/.
**Notes:** Validates de-stubbing and stow safety against realistic failure modes.

---

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Full v0.5 regression sweep | Execute phase25, phase26, phase27, and phase28 assert scripts in Section 5 to guarantee 100% cross-phase contract preservation. | ✓ |
| Individual phase test only | Execute only Phase 29 asserts without re-running prior phase harnesses. | |
| You decide | Balance thoroughness and execution speed. | |

**User's choice:** Full v0.5 regression sweep — execute phase25, phase26, phase27, and phase28 assert scripts in Section 5 to guarantee 100% cross-phase contract preservation.
**Notes:** Final integration gate for Milestone v0.5 completion.

---

## the agent's Discretion

- Test script organization and detailed test names in `scripts/phase29-theme-data-contracts-assert.sh`.
- Minor comment formatting in `guard-paths.tsv` and `bootstrap.sh`.

## Deferred Ideas

- Custom Waybar widget ports (ping, weather, earthquake) — reserved for v2 milestone.
