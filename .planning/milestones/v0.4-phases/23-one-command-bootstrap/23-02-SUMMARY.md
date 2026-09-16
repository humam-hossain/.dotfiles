---
phase: 23-one-command-bootstrap
plan: 02
subsystem: bootstrap-pipeline
tags: [bootstrap, destub, backup, stow, capture, guard-paths]
key-files:
  modified:
    - bootstrap.sh
    - scripts/phase23-bootstrap-assert.sh
requirements: [BOOT-03, BOOT-05]
requirements_completed: [BOOT-03, BOOT-05]
status: complete
completed_at: 2026-09-15T12:12:00Z
---

# Plan 23-02: Core Disk Reproduction Pipeline (Steps 1–6) and Section 2 Assert Suite Summary

Implemented Steps 1 through 6 of the desktop reproduction pipeline in `./bootstrap.sh`: submodule recursion (`step_submodules`), base prerequisite checks (`step_packages`), upstream installer invocation (`step_installer`), GNU Stow conflict discovery, safe backup archiving, and stub unlinking (`run_destub`), sensitive parent directory pre-creation and dynamic stow package linking (`run_stow_step`), and atomic capture seed deployment with JSON syntax validation (`deploy_capture_seeds`). Validated all behaviors in an isolated scratch environment in Section 2 of `scripts/phase23-bootstrap-assert.sh`.

## Key Changes

1. **De-Stubbing & Safe Hierarchical Backup (`run_destub`)**:
   - Parses GNU Stow conflict outputs across all 5 conflict forms (`stow -n --no-folding`).
   - Cross-references conflicting paths against `guard-paths.tsv` (`load_guard_paths()`, `is_guarded_path()`) and preserves all theme outputs untouched.
   - Archives conflicting regular files into `$target/.dotfiles-backup.<epoch>/` preserving directory hierarchy.
   - Generates a cryptographic `MANIFEST.txt` recording timestamps, SHA-256 hashes, and relative paths (directly verifiable via `sha256sum -c`).
   - Unlinks stubs only after archive confirmation, adhering strictly to the `--adopt` ban.
   - Prunes foreign/dangling symlinks safely.

2. **GNU Stow Orchestration & Directory Protection (`run_stow_step`)**:
   - Pre-creates sensitive parent directories (`~/.config/gtk-3.0`, `~/.config/gtk-4.0`, `~/.config/hypr/custom`, `~/.config/systemd/user`) before stowing, guaranteeing leaf-file linking and zero directory folding.
   - Dynamically iterates and stows all packages in `stow/` followed by `restow/` using `--verbose=5 --no-folding -t ~`.

3. **Atomic Capture Seed Deployment (`deploy_capture_seeds`)**:
   - Iterates all files under `capture/` and strips package prefix directories.
   - Validates JSON files via `jq empty` prior to deployment; fails closed if syntax is invalid.
   - Deploys atomically via temporary file rename on the same filesystem (`${dest_file}.tmp.$$` -> `${dest_file}`).

4. **Pipeline Steps 1–3 Integration**:
   - `step_submodules`: executes `git submodule update --init --recursive`.
   - `step_packages`: verifies `git`, `stow`, `jq`, and delegates to `arch/aur.sh` if `yay` is missing.
   - `step_installer`: dispatches `arch/dots-hyprland.sh install` (or `install-files`).

5. **Assert Test Harness Section 2 (`scripts/phase23-bootstrap-assert.sh`)**:
   - Isolated scratch fixture testing mock repo, home, stubs, and live guard files.
   - Verified that guarded theme outputs (`kdeglobals`) are preserved untouched.
   - Verified conflicting stub removal and safe archiving into `.dotfiles-backup.<epoch>/` with valid `MANIFEST.txt` verified by `sha256sum -c`.
   - Verified parent directory preservation (no directory folding) and inode identity (`-ef`) between stowed symlinks and repository source.
   - Verified capture seed deployment (fail-closed on invalid JSON, atomic deploy on valid JSON).

## Verification Results

- `scripts/phase23-bootstrap-assert.sh --section 2`: PASSED (12/12 checks passed, FAIL=0, FINDINGS=0).
- `scripts/phase23-bootstrap-assert.sh`: PASSED (all active sections 1, 2, and 3 passed cleanly, FAIL=0, FINDINGS=0).
- Working-tree porcelain bracket: unchanged.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
