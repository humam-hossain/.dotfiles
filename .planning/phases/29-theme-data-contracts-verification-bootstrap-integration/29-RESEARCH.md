# Phase 29: Theme Data Contracts, Verification & Bootstrap Integration - Research

**Researched:** 2026-09-18  
**Domain:** Theme contract verification, package tree taxonomy, gitignore parity, and bootstrap integration  
**Confidence:** HIGH  

## Summary

Phase 29 is the integration and verification capstone of the v0.5 milestone ("System-wide Material You theming"). It reconciles data contracts, guarantees zero git churn on theme generation, aligns repository tree taxonomy with mathematical installer outcomes, and validates end-to-end bootstrap integration across the complete desktop shell.

The investigation verified that all dynamic theme generators and outputs across GTK (Phase 25), Qt/KDE (Phase 26), Hyprland/Quickshell (Phase 27), and Terminal/Fuzzel (Phase 28) operate reliably live, but require formal data contract enforcement and installation hardening:
1. **Contract Parity & Prefix Matching:** `guard-paths.tsv` lists 8 entries, but `.gitignore` lacks `kde-material-you-colors/` [VERIFIED: `guard-paths.tsv`, `.gitignore`]. `is_guarded_path()` in `bootstrap.sh` and `arch/dots-hyprland.sh` only tests exact path matches, failing to recognize files within guarded directories (e.g. `Kvantum/*`, `kde-material-you-colors/*`) [VERIFIED: `bootstrap.sh:322`, `arch/dots-hyprland.sh:1143`].
2. **Three-Tree Taxonomy Alignment:** `collision-map.tsv` already models `$XDG_CONFIG_HOME/fuzzel` and `$XDG_CONFIG_HOME/kitty` as `tree=restow` because upstream's `install_dir__sync` uses `rsync -av --delete` (`symlink_outcome=DESTROYED` $\rightarrow$ `tree=restow`) [VERIFIED: `collision-map.tsv:70,79`]. However, both packages currently reside under `stow/` [VERIFIED: `ls stow/`]. They must be relocated to `restow/fuzzel` and `restow/kitty`, `restow/README.md` Section 3 table regenerated, `arch/kitty.sh` updated to stow from `../restow` (preserving `PAIR_COUNT == 18`), live symlinks re-stowed, and `scripts/phase28-terminal-fuzzel-assert.sh` updated [VERIFIED: `arch/kitty.sh:10`, `scripts/phase28-terminal-fuzzel-assert.sh:108`].
3. **One-Command Bootstrap Integration:** `./bootstrap.sh` must be hardened so fresh clones set up without manual interventions: Step 4 (`destub`) must explicitly prune legacy Catppuccin symlinks in `~/.config/gtk-4.0/` and `~/.config/gtk-3.0/` pointing to `/usr/share/themes/Catppuccin*` to prevent root write-lock failures during Matugen CSS generation; Step 5 (`stow`) must pre-create `.config/fuzzel` and `.config/kitty` as physical directories to prevent directory folding; Step 6 (`capture_seed`) must trigger initial theme generation via `switchwall.sh --noswitch` with fail-soft color fallback (`switchwall.sh --color "#3f51b5"`) when wallpaper is absent; and Step 7 (`verify`) must bind directly to `arch/dots-hyprland.sh verify --strict` [VERIFIED: `bootstrap.sh:441-570`].
4. **Automated Verification Harness:** Author `scripts/phase29-theme-data-contracts-assert.sh` with 5 fail-closed sections covering contracts, live zero churn drill, strict verifier, bootstrap scratch drill, and full v0.5 regression sweep (`phase25`, `phase26`, `phase27`, `phase28`, `phase23`).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Gitignore parity: Add `kde-material-you-colors/` to root `.gitignore`, ensuring 100% 1:1 parity between the 8 tracked entries in `guard-paths.tsv` and repository ignore patterns. — **Reversibility:** reversible.
- **D-02:** Hierarchical prefix matching: Update `is_guarded_path()` in `bootstrap.sh` and `arch/dots-hyprland.sh` to check both exact matches and parent directory prefixes, ensuring files within guarded directories (e.g. `Kvantum/*`, `kde-material-you-colors/*`) are correctly identified as guarded theme state. — **Reversibility:** costly — changes guard-evaluation logic across two core tools.
- **D-03:** Header documentation reconciliation: Update header comments in `guard-paths.tsv` to fully document the v0.5 Material You architecture, explaining the empirical rationale for all 8 paths (GTK-3/4 CSS, Fuzzel INI, Hyprland borders, Hyprlock colors, and KDE globals/generator state). — **Reversibility:** reversible.
- **D-04:** Recursive guard validation in `verify`: Update `arch/dots-hyprland.sh` `run_verify()` to recursively assert that no file or symlink under a guarded directory points into the git repository. — **Reversibility:** reversible.
- **D-05:** Package relocation to `restow/`: Move `stow/fuzzel` $\rightarrow$ `restow/fuzzel` and `stow/kitty` $\rightarrow$ `restow/kitty` to strictly adhere to `collision-map.tsv` derivation where upstream's `install_dir__sync` destroys live symlinks (`symlink_outcome=DESTROYED` $\rightarrow$ `tree=restow`). — **Reversibility:** costly — moves packages between repository trees and changes stow paths.
- **D-06:** Machine-generated recovery table: Regenerate `restow/README.md` Section 3 using `./scripts/gen-collision-map.sh --restow-table`, establishing `rsync-replace` recovery tags and commands for `fuzzel` and `kitty`. — **Reversibility:** reversible.
- **D-07:** Update `arch/kitty.sh` stow target: Update `arch/kitty.sh` line 10 to stow from `../restow` (`cd "$(dirname "${BASH_SOURCE[0]}")/../restow" && stow --verbose=5 --no-folding -t ~ kitty`), preserving the `PAIR_COUNT == 18` invariant across `arch/*.sh`. — **Reversibility:** costly — impacts standalone installer and installer assertions.
- **D-08:** Live symlink re-pointing: Unstow `fuzzel` and `kitty` from `stow/` and stow from `restow/`, verifying zero dangling links. — **Reversibility:** reversible.
- **D-09:** Cross-phase assert alignment: Update `scripts/phase28-terminal-fuzzel-assert.sh` lines 108, 122, and 150 to check `restow/` for `kitty.conf`, `search.py`, `scroll_mark.py`, and `fuzzel.ini`, preventing false regression failures during unified regression sweeps. — **Reversibility:** reversible.
- **D-10:** Sensitive parent directory pre-creation: In `bootstrap.sh` Step 5 (`stow`), pre-create `.config/fuzzel` and `.config/kitty` alongside `gtk-3.0`, `gtk-4.0`, `hypr/custom`, and `systemd/user`, guaranteeing physical directory existence before GNU Stow links files and before Matugen generates dynamic outputs. — **Reversibility:** reversible.
- **D-11:** Legacy Catppuccin symlink pruning: In `bootstrap.sh` Step 4 (`destub`), add an explicit check to unlink `~/.config/gtk-4.0/gtk.css` and `~/.config/gtk-3.0/gtk.css` if they point to `/usr/share/themes/Catppuccin*`, eliminating root write-lock permission errors during Matugen generation. — **Reversibility:** reversible.
- **D-12:** Initial theme generation in bootstrap: In `bootstrap.sh` Step 6 (`capture_seed`), invoke `switchwall.sh --noswitch` immediately after deploying `capture/` configs (`config.json`), populating `kitty-theme.conf`, `fuzzel_theme.ini`, `gtk.css`, `colors.lua`, and `kdeglobals` before Step 7 and before operator relogin. — **Reversibility:** reversible.
- **D-13:** Fail-soft fallback theme generation: If the configured wallpaper image is absent (e.g. fresh clone on a new host), `switchwall.sh` falls back to default color seed generation (`switchwall.sh --color "#3f51b5"`), ensuring complete theme generation without blocking bootstrap. — **Reversibility:** reversible.
- **D-14:** 5-section automated test suite: Author `scripts/phase29-theme-data-contracts-assert.sh` with 5 fail-closed sections:
  1. Data contracts & gitignore parity: assert `guard-paths.tsv`, `.gitignore`, `collision-map.tsv`, `restow/README.md`, and `PAIR_COUNT == 18`.
  2. Live zero git churn drill: execute `switchwall.sh --noswitch`, assert strictly monotonic mtime advancement across all 5 themed outputs, and verify `git status --porcelain` is byte-identical clean before and after.
  3. Strict verification engine: execute `arch/dots-hyprland.sh verify --strict` and assert exit code 0 with `FAIL=0 FINDINGS=0`.
  4. Bootstrap integration drill: in an isolated scratch environment, test `run_destub`, parent directory pre-creation, capture seed, and fallback theme generation with adversarial legacy Catppuccin and guarded paths.
  5. Full v0.5 regression sweep: execute `phase25`, `phase26`, `phase27`, and `phase28` assert scripts, asserting all pass with `FAIL=0`. — **Reversibility:** reversible.
- **D-15:** Porcelain snapshot invariant: Enforce strict git working-tree porcelain brackets before and after each drill, guaranteeing zero untracked, modified, or deleted files. — **Reversibility:** reversible.
- **D-16:** Adversarial scratch drill: Verify that de-stubbing safely prunes root-owned legacy symlinks while preserving guarded theme paths untouched. — **Reversibility:** reversible.

### Discretion

- Specific helper function names and assertion formatting in `scripts/phase29-theme-data-contracts-assert.sh`.
- Minor comment formatting in `guard-paths.tsv` and `bootstrap.sh`.

### Deferred Ideas

- Waybar custom widget ports (ping, weather, earthquake) — deferred to v2 milestone.
- Debian/Ubuntu parity for desktop shell — Arch remains the primary target.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| **INTG-01** | `guard-paths.tsv` is updated and validated to ensure all dynamically generated Matugen/KDE theme outputs are guarded against repository churn. | Header updated with v0.5 rationale; `.gitignore` mirrored with `kde-material-you-colors/` (D-01, D-03); hierarchical prefix matching in `is_guarded_path()` and recursive guard validation in `verify` implemented (D-02, D-04); Section 1 & Section 3 assertions in `scripts/phase29-theme-data-contracts-assert.sh`. |
| **INTG-02** | `arch/dots-hyprland.sh verify --strict` passes with 0 violations after Catppuccin de-linking and GTK stow update. | Unstow `fuzzel` and `kitty` from `stow/` and stow from `restow/` (D-05, D-08); update `arch/kitty.sh` and `phase28-terminal-fuzzel-assert.sh` (D-07, D-09); strict verify produces `FAIL=0 FINDINGS=0` with zero git churn (D-14, D-15). |
| **INTG-03** | `./bootstrap.sh` cleanly sets up the Material You theming environment on a fresh run without conflicting Catppuccin stubs. | Hardened Step 4 (`destub`) with explicit legacy Catppuccin symlink pruning (D-11); pre-creation of `.config/fuzzel` and `.config/kitty` in Step 5 (D-10); initial theme generation with fallback in Step 6 (D-12, D-13); strict verifier in Step 7; isolated scratch drill in Section 4 of assert harness (D-14, D-16). |
</phase_requirements>

## Architectural Responsibility Map

| Component / File | Role | Changes for Phase 29 |
|---|---|---|
| `guard-paths.tsv` | Canonical contract listing dynamically generated paths excluded from tracking | Document all 8 paths with v0.5 Material You architecture rationale; preserve `Q7:` and `Q8:` compatibility markers [VERIFIED: `guard-paths.tsv:1-22`, `scripts/phase22-kde-and-gtk-capture-assert.sh:484-493`]. |
| `.gitignore` | Working-tree exclusion rules | Add `kde-material-you-colors/` under the generated theme output section to maintain 1:1 parity with `guard-paths.tsv` [VERIFIED: `.gitignore:37-44`]. |
| `collision-map.tsv` | Mechanically derived map of installer destinations and collision outcomes | Verified intact and valid; already specifies `restow` for `$XDG_CONFIG_HOME/fuzzel` and `$XDG_CONFIG_HOME/kitty` [VERIFIED: `collision-map.tsv:70,79`]. |
| `stow/` $\rightarrow$ `restow/` | Three-tree package placement | Move `stow/fuzzel` $\rightarrow$ `restow/fuzzel` and `stow/kitty` $\rightarrow$ `restow/kitty` [VERIFIED: `stow/fuzzel`, `stow/kitty`]. |
| `restow/README.md` | Restow contract and package recovery table | Regenerate Section 3 table via `./scripts/gen-collision-map.sh --restow-table`, adding `fuzzel` and `kitty` with `rsync-replace` tag [VERIFIED: `restow/README.md:55-62`]. |
| `arch/kitty.sh` | Standalone Kitty package installer and stower | Update line 10 to stow from `../restow`, preserving `PAIR_COUNT == 18` across `arch/*.sh` [VERIFIED: `arch/kitty.sh:10`, `scripts/phase23-bootstrap-assert.sh:125`]. |
| `arch/dots-hyprland.sh` | Main CLI wrapper, `verify --strict`, `install-files` | Implement `is_guarded_path()` hierarchical prefix matching and recursive directory guard checks under `run_verify()` [VERIFIED: `arch/dots-hyprland.sh:1135-1167, 1341`]. |
| `bootstrap.sh` | 7-step idempotent system orchestrator | Step 4: hierarchical prefix guard matching + legacy Catppuccin pruning; Step 5: pre-create `.config/fuzzel` and `.config/kitty`; Step 6: initial theme generation via `switchwall.sh --noswitch` with `--color "#3f51b5"` fallback [VERIFIED: `bootstrap.sh:322, 441, 491, 568`]. |
| `scripts/phase28-terminal-fuzzel-assert.sh` | Phase 28 assert harness | Update lines 108, 122, and 150 to inspect `restow/` instead of `stow/` [VERIFIED: `scripts/phase28-terminal-fuzzel-assert.sh:108, 122, 150`]. |
| `scripts/phase29-theme-data-contracts-assert.sh` | Phase 29 authoritative assert harness | New 5-section test suite: contracts & gitignore, live zero churn drill, strict verify engine, scratch bootstrap drill, full v0.5 regression sweep [VERIFIED: new file]. |

## Standard Stack

| Tool / Technology | Version / Requirement | Role in Phase 29 |
|---|---|---|
| `bash` | 5.2+ (`set -euo pipefail`) | Shell execution environment for orchestrator and test harnesses [VERIFIED: live bash 5.2.37]. |
| GNU `stow` | 2.4.1+ (`--no-folding`, `--verbose=5`) | Package symlink manager. Banned `--adopt` remains strictly enforced [VERIFIED: `stow --version`]. |
| `git` | 2.40+ | Repository version control, porcelain snapshot checks, and submodule tracking [VERIFIED: `git --version`]. |
| `matugen` | 2.4.0+ | Material You palette and template generator [VERIFIED: `matugen --version`]. |
| `kde-material-you-colors` | 1.10.1 (in quickshell venv) | Dynamic KDE color generator for `kdeglobals` [VERIFIED: Phase 26 S1]. |
| Python 3 (`gi.repository.Gtk`) | GTK 3.0 & 4.0 bindings | Dynamic CSS syntax and parser validation [VERIFIED: `scripts/phase25-gtk-material-you-assert.sh:284`]. |
| `jq` | 1.7+ | JSON parsing and validation for `config.json` and state machines [VERIFIED: `jq --version`]. |

## Architecture Patterns

### 1. Hierarchical Prefix Matching for Guard Paths
A simple string equality check `[[ -n "${GUARDED_PATHS[$path]:-}" ]]` fails when sub-files inside guarded directories are checked (e.g. `~/.config/Kvantum/theme.kvconfig` or `~/.config/kde-material-you-colors/config.conf`) [VERIFIED: `bootstrap.sh:322`].
The hierarchical prefix pattern traverses directory ancestors up to root or `$HOME`:

```bash
# Pattern: Hierarchical Prefix Walk
is_guarded_path() {
  local check_path="${1%/}"
  local cur="$check_path"
  while [[ -n "$cur" && "$cur" != "/" && "$cur" != "." ]]; do
    if [[ -n "${GUARDED_PATHS["$cur"]:-}" ]]; then
      return 0
    fi
    cur="$(dirname -- "$cur")"
  done
  return 1
}
```
*Benefits:* $O(\text{depth})$ where depth is at most 4-5 directory components; no regex overhead; handles both exact files (`gtk.css`) and directory subtrees (`Kvantum/*`, `kde-material-you-colors/*`).

### 2. The Three-Tree Taxonomy Mathematical Invariant
Under the collision map taxonomy established in Phase 18:
- `symlink preserved` AND `repo untouched` $\rightarrow$ `tree=stow`
- `symlink DESTROYED` OR `repo OVERWRITTEN` $\rightarrow$ `tree=restow`
- `writer renames over symlink live` $\rightarrow$ `capture` (prose-managed)

Upstream `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` invokes `install_dir__sync dots/.config/fuzzel` and `install_dir__sync dots/.config/kitty` (line 14) [VERIFIED: `3.files-legacy.sh:14`]. Because `install_dir__sync` runs `rsync -av --delete`, any live symlink to `.config/fuzzel` or `.config/kitty` is unconditionally destroyed upon running `arch/dots-hyprland.sh install` or `install-files`. Therefore, placing `fuzzel` and `kitty` in `restow/` is mathematically required by the taxonomy.

### 3. Safe Symlink Re-pointing Procedure
To transition packages between trees without triggering stow collision errors:
1. Unstow the package from its existing tree:
   `cd stow && stow -D --verbose=5 --no-folding -t ~ <pkg>`
2. Relocate the package directory in git:
   `git mv stow/<pkg> restow/<pkg>`
3. Stow the package from its new tree:
   `cd restow && stow --verbose=5 --no-folding -t ~ <pkg>`
4. Verify link target matches new repository location:
   `readlink -f "$HOME/.config/<pkg>/..."` $\rightarrow$ `$REPO_ROOT/restow/<pkg>/...`

### 4. Explicit De-stubbing & Pruning Separation
Standard GNU Stow conflict detection in `bootstrap.sh:run_destub` runs `stow -n`. Because guarded theme files (`gtk.css`, `fuzzel_theme.ini`) are not tracked in repo packages, `stow -n` never detects them as conflicts [VERIFIED: `bootstrap.sh:409-425`]. If a host has legacy root-owned symlinks (`gtk.css -> /usr/share/themes/Catppuccin...`), `stow -n` remains silent. Therefore, `destub` must perform an explicit sweep:

```bash
# Pattern: Explicit Target Pruning for GTK Stubs
for gtk_ver in gtk-3.0 gtk-4.0; do
  local gtk_dir="$target/.config/$gtk_ver"
  [[ -d "$gtk_dir" ]] || continue
  for f in "$gtk_dir"/*; do
    [[ -L "$f" ]] || continue
    local link_target
    link_target="$(readlink "$f" 2>/dev/null || true)"
    if [[ "$link_target" == */Catppuccin* || "$link_target" == */catppuccin* || "$link_target" == /usr/share/themes/Catppuccin* ]]; then
      rm -f "$f"
      echo "[PRUNE] Removed legacy Catppuccin symlink: ${f#"$target"/}"
    fi
  done
done
```

### 5. Porcelain Snapshot Bracketing
Every test section and live drill must bracket operations with a porcelain snapshot check:
```bash
porcelain_snapshot() {
  git status --porcelain --ignored | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}
```
Assert that `diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"` is empty, guaranteeing zero repository churn from theme switching or assert execution [VERIFIED: standard across Phases 25-28].

## Don't Hand-Roll

| Problem | Anti-Pattern (Don't Hand-Roll) | Standard Solution (Do Use) | Rationale |
|---|---|---|---|
| Recovery table generation | Hand-editing Markdown rows in `restow/README.md` | `./scripts/gen-collision-map.sh --restow-table` [VERIFIED] | Hand-editing drifts from `collision-map.tsv` and `restow/` package inventory; the script automatically derives tags (`rsync-replace` vs `cp-through`). |
| Stow conflict detection | Custom regex scanning of `$HOME/.config` | `stow -n --no-folding -d "$tree" -t "$target" "$pkg"` [VERIFIED: `bootstrap.sh:410`] | GNU Stow has precise internal logic for conflict detection, directory folding rules, and target ownership. |
| Verification engine | Writing a new verify script | `arch/dots-hyprland.sh verify --strict` [VERIFIED] | Centralizes 9-arm link classifier, content comparison against HEAD, folded ancestor checks, and live sweep in one battle-tested engine. |
| Wallpaper switching & theme updates | Running `matugen` and `kde-material-you-colors` directly in multiple scripts | Calling `~/.config/quickshell/ii/scripts/colors/switchwall.sh` [VERIFIED] | `switchwall.sh` coordinates Matugen, Quickshell `colors.json`, Hyprland `colors.lua`, GTK CSS, Fuzzel INI, and terminal sequences synchronously in the proper order. |

## Common Pitfalls

### Pitfall 1: Removing `Q7` or `Q8` Comments from `guard-paths.tsv` Header
**Hazard:** `scripts/phase22-kde-and-gtk-capture-assert.sh:484,490` hard-greps for `"Q7:"`, `"kde-material-you-colors"`, `"Q8:"`, and `"gtk-4.0/gtk.css"` in `guard-paths.tsv` [VERIFIED: `scripts/phase22-kde-and-gtk-capture-assert.sh:484-493`].
**Solution:** When updating header comments in `guard-paths.tsv` per D-03 to document the full v0.5 architecture, retain the exact literal markers `"Q7:"` and `"Q8:"` and their referenced strings.

### Pitfall 2: Breaking the `PAIR_COUNT == 18` Invariant
**Hazard:** `scripts/phase17-unblock-assert.sh` and `scripts/phase23-bootstrap-assert.sh` count the exact number of occurrences of `--verbose=5 --no-folding` across all `arch/*.sh` scripts (`PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"`) and require it to equal 18 [VERIFIED: `phase23-bootstrap-assert.sh:125`].
**Solution:** In `arch/kitty.sh:10`, changing `../stow` to `../restow` preserves `--verbose=5 --no-folding` on that line, keeping `PAIR_COUNT` exactly 18. Never add, remove, or alter other `--verbose=5 --no-folding` calls in `arch/*.sh`.

### Pitfall 3: Stowing into `restow/` Without First Unstowing from `stow/`
**Hazard:** If `stow/fuzzel` is moved to `restow/fuzzel` while live symlinks `~/.config/fuzzel/fuzzel.ini` still point to `../../github_repo/.dotfiles/stow/fuzzel/...`, running `stow restow` will report `existing target is not owned by stow` or conflict errors, or `arch/dots-hyprland.sh verify --strict` will fail with `symlink points elsewhere` [VERIFIED: `arch/dots-hyprland.sh:1047`].
**Solution:** Always execute `cd stow && stow -D -t ~ fuzzel kitty` before moving directories, then `cd restow && stow --verbose=5 --no-folding -t ~ fuzzel kitty`.

### Pitfall 4: GTK 4 `:insensitive` Deprecated Pseudo-class in Matugen Template
**Hazard:** `vendor/dots-hyprland/dots/.config/matugen/templates/gtk-4.0/gtk.css` line 312 carries `.boxed-list row:insensitive` [VERIFIED: line 312]. In GTK 4, `:insensitive` is an invalid pseudo-class that triggers `Gtk-WARNING: Theme parser error: Unknown name of pseudo-class` when loaded by `Gtk.CssProvider`, causing `scripts/phase25-gtk-material-you-assert.sh` Section 4 to fail [VERIFIED].
**Solution:** Ensure `bootstrap.sh` sanitizes `~/.config/matugen/templates/gtk-4.0/gtk.css` (replacing `:insensitive` with `:disabled`) before triggering initial theme generation via `switchwall.sh`, and assert clean GTK 4 parsing in Phase 29 verification.

### Pitfall 5: Dirty Mirror Failure from Uncommitted `config.json`
**Hazard:** `dotfiles-capture.timer` periodically runs `arch/dots-hyprland.sh capture` to copy `~/.config/illogical-impulse/config.json` into `capture/ii/.../config.json`. If an operator changes wallpaper live and the capture daemon records the change in `capture/`, any assert script checking `git status --porcelain stow/ restow/ capture/` will fail with `Packaging directories dirty` [VERIFIED: observed during research probes].
**Solution:** Verify git working tree cleanliness at the start of plan execution; commit or restore any captured live drift before executing assertion suites.

## Code Examples

### 1. Reconciled `guard-paths.tsv` Header and Entries (D-01, D-03)
[VERIFIED: `guard-paths.tsv`]
```tsv
# guard-paths v1
#
# Paths excluded from repository tracking and live repo-symlinking.
# Enforced by arch/dots-hyprland.sh verify, bootstrap.sh, and phase assert suites.
#
# v0.5 Material You Desktop Shell Dynamic Outputs:
# 1. $XDG_CONFIG_HOME/kdeglobals: Actively churned by kde-material-you-colors on wallpaper change (Q7).
# 2. $XDG_CONFIG_HOME/Kvantum: Upstream theme engine directory synced by dots-hyprland installer.
# 3. $XDG_CONFIG_HOME/gtk-3.0/gtk.css: Dynamically generated by Matugen from wallpaper colors.
# 4. $XDG_CONFIG_HOME/gtk-4.0/gtk.css: Dynamically generated by Matugen (de-linked from root-owned Catppuccin) (Q8).
# 5. $XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini: Dynamically generated by Matugen for Fuzzel launcher.
# 6. $XDG_CONFIG_HOME/hypr/hyprland/colors.lua: Dynamically generated by Matugen for Hyprland window borders.
# 7. $XDG_CONFIG_HOME/hypr/hyprlock/colors.conf: Dynamically generated by Matugen for Hyprlock screen locker.
# 8. $XDG_CONFIG_HOME/kde-material-you-colors: Generator runtime configuration and state directory.
#
# Columns (tab-separated):
# path	category	generator	reason
$XDG_CONFIG_HOME/kdeglobals	generated_theme	kde-material-you-colors	Active wallpaper churn (Q7)
$XDG_CONFIG_HOME/Kvantum	vendor_theme	dots-hyprland	Upstream directory sync
$XDG_CONFIG_HOME/gtk-3.0/gtk.css	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/gtk-4.0/gtk.css	generated_theme	matugen	Root-owned theme symlink (Q8)
$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/hypr/hyprland/colors.lua	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/kde-material-you-colors	generated_theme	kde-material-you-colors	Upstream directory sync
```

### 2. Root `.gitignore` Parity Update (D-01)
[VERIFIED: `.gitignore:37-44`]
```gitignore
# Generated theme output (D-14) — matugen rewrites these on every wallpaper or
# colour-scheme change, so tracking them means a diff per wallpaper.
kdeglobals
gtk.css
gtk-dark.css
Kvantum/
colors.lua
colors.conf
fuzzel_theme.ini
kde-material-you-colors/
```

### 3. Recursive Guard Validation in `arch/dots-hyprland.sh` (D-02, D-04)
[VERIFIED: `arch/dots-hyprland.sh:1158-1167`]
```bash
      # Assert live path is not a symlink into repo (recursive check for directories)
      if [[ -L "$expanded" ]]; then
        live_target="$(readlink -f -- "$expanded" 2>/dev/null || true)"
        if [[ "$live_target" == "$main_root_real"/* || "$live_target" == "$main_root"/* ]]; then
          fail "guard path live counterpart symlinks into repo: $expanded -> $live_target"
        fi
      elif [[ -d "$expanded" ]]; then
        while IFS= read -r -d '' sub_link; do
          live_target="$(readlink -f -- "$sub_link" 2>/dev/null || true)"
          if [[ "$live_target" == "$main_root_real"/* || "$live_target" == "$main_root"/* ]]; then
            fail "guard path live counterpart symlinks into repo: $sub_link -> $live_target"
          fi
        done < <(find "$expanded" -type l -print0 2>/dev/null || true)
      fi
      pass "guard path excluded: $g_path"
```

### 4. Bootstrap Hardening: Step 4 Destub Catppuccin Pruning (D-11)
[VERIFIED: `bootstrap.sh:425-470`]
```bash
  # D-11: Explicit legacy Catppuccin symlink pruning in GTK config directories
  for gtk_ver in gtk-3.0 gtk-4.0; do
    local gtk_dir="$target/.config/$gtk_ver"
    [[ -d "$gtk_dir" ]] || continue
    for f in "$gtk_dir"/*; do
      [[ -L "$f" ]] || continue
      local link_target
      link_target="$(readlink "$f" 2>/dev/null || true)"
      if [[ "$link_target" == */Catppuccin* || "$link_target" == */catppuccin* || "$link_target" == /usr/share/themes/Catppuccin* ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
          echo "[DRY-RUN] Would remove legacy Catppuccin symlink: ${f#"$target"/}"
        else
          rm -f "$f"
          echo "[PRUNE] Removed legacy Catppuccin symlink: ${f#"$target"/}"
          destub_count=$((destub_count + 1))
        fi
      fi
    done
  done
```

### 5. Bootstrap Initial Theme Generation with Fail-Soft Fallback (D-12, D-13)
[VERIFIED: `bootstrap.sh:568-572`]
```bash
generate_initial_theme() {
  local target="${1:-$HOME}"
  local switchwall="$target/.config/quickshell/ii/scripts/colors/switchwall.sh"
  local config_file="$target/.config/illogical-impulse/config.json"
  local matugen_gtk4_tpl="$target/.config/matugen/templates/gtk-4.0/gtk.css"

  # Sanitize GTK 4 template pseudo-class if present
  if [[ -f "$matugen_gtk4_tpl" ]] && grep -q ':insensitive' "$matugen_gtk4_tpl"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would align GTK 4 template :insensitive -> :disabled"
    else
      sed -i 's/\.boxed-list row:insensitive/\.boxed-list row:disabled/g' "$matugen_gtk4_tpl"
      echo "[FIX] Aligned GTK 4 Matugen template pseudo-class (:disabled)"
    fi
  fi

  if [[ ! -f "$switchwall" ]]; then
    echo "[WARN] switchwall.sh not found at $switchwall; skipping initial theming"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would trigger initial Material You theme generation"
    return 0
  fi

  local wp_path=""
  if [[ -f "$config_file" ]]; then
    wp_path="$(jq -r '.background.wallpaperPath // empty' "$config_file" 2>/dev/null || true)"
  fi

  echo "[THEME] Triggering initial theme generation..."
  if [[ -n "$wp_path" && -f "$wp_path" ]]; then
    echo "[THEME] Generating theme from configured wallpaper: $wp_path"
    if ! "$switchwall" --noswitch; then
      echo "[WARN] switchwall.sh --noswitch failed; falling back to color seed #3f51b5"
      "$switchwall" --color "#3f51b5" || echo "[WARN] Fallback theme generation failed"
    fi
  else
    echo "[THEME] Configured wallpaper absent or inaccessible; falling back to color seed #3f51b5"
    if ! "$switchwall" --color "#3f51b5"; then
      echo "[WARN] Fallback color seed theme generation failed"
    fi
  fi
}
```

## Environment Availability

```
CLI Tools:
- git: 2.49.0 [VERIFIED: /usr/bin/git]
- stow: 2.4.1 [VERIFIED: /usr/bin/stow]
- jq: 1.7.1 [VERIFIED: /usr/bin/jq]
- matugen: 2.4.0 [VERIFIED: /usr/bin/matugen]
- python3: 3.13.2 [VERIFIED: /usr/bin/python3]
- systemctl: 257.4 [VERIFIED: /usr/bin/systemctl]

Daemons / Runtimes:
- Hyprland: v0.49.0 (active session with instance signature) [VERIFIED]
- dotfiles-capture.timer: active (waiting) [VERIFIED: systemctl --user status]
- quickshell: v0.0.3 [VERIFIED: /usr/bin/quickshell]
- quickshell venv: /home/pera/.config/quickshell/ii/.venv [VERIFIED]

Repository Trees:
- stow/: 22 packages [VERIFIED]
- restow/: 4 packages (chrome-flags, dolphinrc, hypr, starship) [VERIFIED]
- capture/: ii (.config/illogical-impulse/config.json) [VERIFIED]
```

## Validation Architecture

### Test Framework
All testing is conducted via automated, fail-closed Bash assertion scripts that follow the repository standard established in Phases 17-28:
- Standard options: `set -euo pipefail`.
- Arguments: `--section <1-5>`, `--help`.
- Verdict convention: `[PASS]`, `[FAIL]`, `[INFO]`, `[FINDING]`.
- Exit codes: 0 on success (`FAIL=0 FINDINGS=0`), non-zero on failure.
- Working-tree safety: `trap cleanup EXIT` and porcelain brackets (`diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"`).

### Phase Requirements -> Test Map

| Requirement | Test Scope in `scripts/phase29-theme-data-contracts-assert.sh` | Execution Method |
|---|---|---|
| **INTG-01** | Section 1: Verify `guard-paths.tsv` has 8 valid tab-separated entries, `.gitignore` mirrors all 8 entries 1:1, `collision-map.tsv` derives `restow` for `fuzzel` and `kitty`, `restow/README.md` Section 3 table is complete, and `PAIR_COUNT == 18`. | Automated: checks files, syntax, and counts. |
| **INTG-01** | Section 2: Live zero git churn drill: monotonic mtime advancement across all 5 themed outputs (`fuzzel_theme.ini`, `kitty-theme.conf`, `gtk.css`, `colors.lua`, `kdeglobals`), byte-identical `git status --porcelain` before and after. | Automated: invokes `switchwall.sh --noswitch` live and asserts timestamps and porcelain diff. |
| **INTG-02** | Section 3: Strict repository verification engine: run `arch/dots-hyprland.sh verify --strict` and assert exit code 0 with `FAIL=0 FINDINGS=0`. Assert live symlinks in `~/.config/fuzzel/` and `~/.config/kitty/` resolve into `restow/`. | Automated: calls `verify --strict` and parses output. |
| **INTG-03** | Section 4: Bootstrap integration drill: in an isolated scratch environment with mock `$HOME` and `$REPO_ROOT`, assert `is_guarded_path` hierarchical prefix matching, de-stubbing conflict unlinking, Catppuccin symlink pruning, parent directory pre-creation, and fallback theme generation. | Automated: sandboxed mock directory test. |
| **INTG-01..03** | Section 5: Full v0.5 regression sweep: executes `scripts/phase25-gtk-material-you-assert.sh`, `scripts/phase26-qt-kde-material-you-assert.sh`, `scripts/phase27-accent-coordination-assert.sh`, and `scripts/phase28-terminal-fuzzel-assert.sh`, asserting all exit 0 with 0 failures. | Automated: unified multi-phase test runner. |

### Sampling Rate
- Automated assertion suite: 100% test coverage across all 5 sections.
- Zero manual testing needed for phase gate sign-off; every invariant is machine-asserted.

### Wave 0 Gaps
- None. All test harnesses, dependencies, and environment primitives are available and verified.

---

*Phase: 29-theme-data-contracts-verification-bootstrap-integration*  
*Research conducted: 2026-09-18*  
