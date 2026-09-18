# Phase 29: Theme Data Contracts, Verification & Bootstrap Integration - Context

**Gathered:** 2026-09-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile data contracts, verify zero git churn on theme generation, and validate end-to-end bootstrap integration across the entire v0.5 Material You desktop shell:

1. **Guard Paths & Gitignore Parity (INTG-01):** Reconcile `guard-paths.tsv` to cover all 8 dynamic theme outputs and generator directories (`kdeglobals`, `Kvantum/`, `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, `fuzzel/fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, `hypr/hyprlock/colors.conf`, `kde-material-you-colors`). Mirror all guarded entries into root `.gitignore` to guarantee 1:1 parity against repository working-tree churn. Update `is_guarded_path()` in `bootstrap.sh` and `arch/dots-hyprland.sh` to enforce hierarchical prefix matching for guarded directories. Reconcile header comments in `guard-paths.tsv` with full v0.5 architecture documentation.
2. **Collision Map & Three-Tree Capture Taxonomy (INTG-01, INTG-02):** Reconcile repository package tree placement with `collision-map.tsv`. Upstream installer primitive `install_dir__sync` (`3.files-legacy.sh:14`) destroys live symlinks via `rsync -av --delete`. Relocate `fuzzel` and `kitty` packages from `stow/` to `restow/` (`restow/fuzzel`, `restow/kitty`) to strictly honor the mathematical outcome formula (`symlink DESTROYED -> restow`). Regenerate `restow/README.md` Section 3 table via `./scripts/gen-collision-map.sh --restow-table` (tagging both as `rsync-replace`). Update `arch/kitty.sh` to stow from `../restow` while preserving the `PAIR_COUNT == 18` invariant. Update `scripts/phase28-terminal-fuzzel-assert.sh` to check `restow/` to prevent cross-phase regression failures. Re-stow live symlinks cleanly.
3. **One-Command Bootstrap Integration (INTG-03):** Enhance `./bootstrap.sh` to guarantee clean fresh-machine deployment without manual intervention:
   - Step 4 (`destub`): Automatically unlink conflicting files, preserve guarded theme outputs via hierarchical prefix matching, and explicitly prune legacy Catppuccin symlinks in `~/.config/gtk-4.0/` or `~/.config/gtk-3.0/` pointing to `/usr/share/themes/Catppuccin*` to eliminate root write-lock failures.
   - Step 5 (`stow`): Pre-create `.config/fuzzel` and `.config/kitty` alongside `gtk-3.0`, `gtk-4.0`, `hypr/custom`, and `systemd/user` prior to stowing with `--verbose=5 --no-folding`.
   - Step 6 (`capture_seed`): Trigger initial theme generation via `switchwall.sh --noswitch` immediately after deploying `config.json`. If the configured wallpaper image is absent, fail soft with fallback seed generation (`switchwall.sh --color "#3f51b5"`), ensuring `fuzzel_theme.ini`, `kitty-theme.conf`, `gtk.css`, `colors.lua`, and `kdeglobals` exist before Step 7 and before operator relogin.
   - Step 7 (`verify`): Enable `dotfiles-capture.timer` and run `arch/dots-hyprland.sh verify --strict` with exit code bound 1:1.
4. **Automated Test Harness & Verification Suite (INTG-01, INTG-02, INTG-03):** Author `scripts/phase29-theme-data-contracts-assert.sh` with 5 automated sections:
   - Section 1: Data contracts & gitignore parity (`guard-paths.tsv`, `.gitignore`, `collision-map.tsv`, `restow/README.md`, `PAIR_COUNT == 18`).
   - Section 2: Live zero git churn drill (`switchwall.sh --noswitch` monotonic mtime advancement on all 5 themed components with byte-identical porcelain snapshot before and after).
   - Section 3: Strict repository verification engine gate (`arch/dots-hyprland.sh verify --strict` exits 0 with `FAIL=0 FINDINGS=0`).
   - Section 4: Bootstrap integration drill (isolated scratch environment verifying `destub`, legacy Catppuccin pruning, guard preservation, parent dir pre-creation, and fallback theme generation).
   - Section 5: Full v0.5 regression sweep (running `phase25`, `phase26`, `phase27`, and `phase28` assert scripts, requiring all to pass with 0 failures).

Out of scope:
- Modifying upstream dots-hyprland submodule files directly in `vendor/dots-hyprland`.
- Custom Waybar widget ports (ping, weather, earthquake) — reserved for v2 milestone.
- Re-implementing `./setup` or altering the one-way install path.

</domain>

<decisions>
## Implementation Decisions

### Guard Paths & Gitignore Parity (INTG-01)

- **D-01:** Gitignore parity: Add `kde-material-you-colors/` to root `.gitignore`, ensuring 100% 1:1 parity between the 8 tracked entries in `guard-paths.tsv` and repository ignore patterns. — **Reversibility:** reversible.
- **D-02:** Hierarchical prefix matching: Update `is_guarded_path()` in `bootstrap.sh` and `arch/dots-hyprland.sh` to check both exact matches and parent directory prefixes, ensuring files within guarded directories (e.g. `Kvantum/*`, `kde-material-you-colors/*`) are correctly identified as guarded theme state. — **Reversibility:** costly — changes guard-evaluation logic across two core tools.
- **D-03:** Header documentation reconciliation: Update header comments in `guard-paths.tsv` to fully document the v0.5 Material You architecture, explaining the empirical rationale for all 8 paths (GTK-3/4 CSS, Fuzzel INI, Hyprland borders, Hyprlock colors, and KDE globals/generator state). — **Reversibility:** reversible.
- **D-04:** Recursive guard validation in `verify`: Update `arch/dots-hyprland.sh` `run_verify()` to recursively assert that no file or symlink under a guarded directory points into the git repository. — **Reversibility:** reversible.

### Collision Map & Package Tree Taxonomy (INTG-01, INTG-02)

- **D-05:** Package relocation to `restow/`: Move `stow/fuzzel` $\rightarrow$ `restow/fuzzel` and `stow/kitty` $\rightarrow$ `restow/kitty` to strictly adhere to `collision-map.tsv` derivation where upstream's `install_dir__sync` destroys live symlinks (`symlink_outcome=DESTROYED` $\rightarrow$ `tree=restow`). — **Reversibility:** costly — moves packages between repository trees and changes stow paths.
- **D-06:** Machine-generated recovery table: Regenerate `restow/README.md` Section 3 using `./scripts/gen-collision-map.sh --restow-table`, establishing `rsync-replace` recovery tags and commands for `fuzzel` and `kitty`. — **Reversibility:** reversible.
- **D-07:** Update `arch/kitty.sh` stow target: Update `arch/kitty.sh` line 10 to stow from `../restow` (`cd "$(dirname "${BASH_SOURCE[0]}")/../restow" && stow --verbose=5 --no-folding -t ~ kitty`), preserving the `PAIR_COUNT == 18` invariant across `arch/*.sh`. — **Reversibility:** costly — impacts standalone installer and installer assertions.
- **D-08:** Live symlink re-pointing: Unstow `fuzzel` and `kitty` from `stow/` and stow from `restow/` to point live symlinks in `~/.config/fuzzel` and `~/.config/kitty` to `restow/`, verifying zero dangling links. — **Reversibility:** reversible.
- **D-09:** Cross-phase assert alignment: Update `scripts/phase28-terminal-fuzzel-assert.sh` lines 108, 122, and 150 to check `restow/` for `kitty.conf`, `search.py`, `scroll_mark.py`, and `fuzzel.ini`, preventing false regression failures during unified regression sweeps. — **Reversibility:** reversible.

### One-Command Bootstrap Integration (INTG-03)

- **D-10:** Sensitive parent directory pre-creation: In `bootstrap.sh` Step 5 (`stow`), pre-create `.config/fuzzel` and `.config/kitty` alongside `gtk-3.0`, `gtk-4.0`, `hypr/custom`, and `systemd/user`, guaranteeing physical directory existence before GNU Stow links files and before Matugen generates dynamic outputs. — **Reversibility:** reversible.
- **D-11:** Legacy Catppuccin symlink pruning: In `bootstrap.sh` Step 4 (`destub`), add an explicit check to unlink `~/.config/gtk-4.0/gtk.css` and `~/.config/gtk-3.0/gtk.css` if they point to `/usr/share/themes/Catppuccin*`, eliminating root write-lock permission errors during Matugen generation. — **Reversibility:** reversible.
- **D-12:** Initial theme generation in bootstrap: In `bootstrap.sh` Step 6 (`capture_seed`), invoke `switchwall.sh --noswitch` immediately after deploying `capture/` configs (`config.json`), populating `kitty-theme.conf`, `fuzzel_theme.ini`, `gtk.css`, `colors.lua`, and `kdeglobals` before Step 7 and before operator relogin. — **Reversibility:** reversible.
- **D-13:** Fail-soft fallback theme generation: If the configured wallpaper image is absent (e.g. fresh clone on a new host), `switchwall.sh` falls back to default color seed generation (`switchwall.sh --color "#3f51b5"`), ensuring complete theme generation without blocking bootstrap. — **Reversibility:** reversible.

### Test Harness & Zero Churn Gates (INTG-01, INTG-02, INTG-03)

- **D-14:** 5-section automated test suite: Author `scripts/phase29-theme-data-contracts-assert.sh` with 5 fail-closed sections:
  1. Data contracts & gitignore parity: assert `guard-paths.tsv`, `.gitignore`, `collision-map.tsv`, `restow/README.md`, and `PAIR_COUNT == 18`.
  2. Live zero git churn drill: execute `switchwall.sh --noswitch`, assert strictly monotonic mtime advancement across all 5 themed outputs, and verify `git status --porcelain` is byte-identical clean before and after.
  3. Strict verification engine: execute `arch/dots-hyprland.sh verify --strict` and assert exit code 0 with `FAIL=0 FINDINGS=0`.
  4. Bootstrap integration drill: in an isolated scratch environment, test `run_destub`, parent directory pre-creation, capture seed, and fallback theme generation with adversarial legacy Catppuccin and guarded paths.
  5. Full v0.5 regression sweep: execute `phase25`, `phase26`, `phase27`, and `phase28` assert scripts, asserting all pass with `FAIL=0`. — **Reversibility:** reversible.
- **D-15:** Porcelain snapshot invariant: Enforce strict git working-tree porcelain brackets before and after each drill, guaranteeing zero untracked, modified, or deleted files. — **Reversibility:** reversible.
- **D-16:** Adversarial scratch drill: Verify that de-stubbing safely prunes root-owned legacy symlinks while preserving guarded theme paths untouched. — **Reversibility:** reversible.

### the agent's Discretion

- Specific helper function names and assertion formatting in `scripts/phase29-theme-data-contracts-assert.sh`.
- Minor comment formatting in `guard-paths.tsv` and `bootstrap.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` §Phase 29 — goal statement, requirements (INTG-01, INTG-02, INTG-03), and success criteria
- `.planning/REQUIREMENTS.md` §INTG — data contracts, verification, and bootstrap specifications
- `.planning/STATE.md` §Milestone v0.5 — accumulated phase decisions and state

### Data Contracts and Capture Taxonomy
- `guard-paths.tsv` — machine-readable data contract of all 8 guarded dynamic theme paths
- `collision-map.tsv` — machine-asserted collision map derived from `vendor/dots-hyprland`
- `scripts/gen-collision-map.sh` — collision map and restow table generator
- `restow/README.md` — contract, recovery tags (`rsync-replace`, `cp-through`), and generated package recovery table
- `stow/README.md` — stow discipline, `--no-folding`, and `--adopt` ban
- `docs/config-redistribution.md` — redistribution registry and prefix matching rules

### Bootstrap Orchestrator & Installers
- `bootstrap.sh` — root orchestrator with 7-step resumable JSON state machine and strict verify gate
- `arch/dots-hyprland.sh` — thin wrapper with `verify --strict`, `install`, `install-files`, and guard validation
- `arch/kitty.sh` — standalone Kitty installer and stow site
- `scripts/phase23-bootstrap-assert.sh` — Phase 23 bootstrap assert harness

### Prior Phase Theme Implementations & Assert Scripts
- `scripts/phase25-gtk-material-you-assert.sh` — Phase 25 GTK Material You assert harness
- `scripts/phase26-qt-kde-material-you-assert.sh` — Phase 26 Qt/KDE Material You assert harness
- `scripts/phase27-accent-coordination-assert.sh` — Phase 27 Hyprland/Quickshell assert harness
- `scripts/phase28-terminal-fuzzel-assert.sh` — Phase 28 Terminal/Fuzzel assert harness
- `.planning/phases/25-gtk-material-you-theming-catppuccin-de-linking/25-CONTEXT.md`
- `.planning/phases/26-qt-kde-apps-material-you-harmonization/26-CONTEXT.md`
- `.planning/phases/27-hyprland-quickshell-ii-accent-coordination/27-CONTEXT.md`
- `.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-CONTEXT.md`

### Live Theme Pipeline Scripts
- `~/.config/quickshell/ii/scripts/colors/switchwall.sh` — wallpaper switcher and theme generation orchestrator
- `~/.config/quickshell/ii/scripts/colors/applycolor.sh` — terminal palette reloader
- `~/.config/matugen/config.toml` — Matugen template mapping configuration
- `capture/ii/.config/illogical-impulse/config.json` — baseline shell and theming configuration

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/gen-collision-map.sh --restow-table`: Automatically parses `collision-map.tsv` and `restow/` to generate the Markdown recovery table for `restow/README.md`.
- `arch/dots-hyprland.sh verify --strict`: Authoritative verification engine checking link identity, content drift, guard path exclusion, and live sweep.
- `bootstrap.sh`: Established 7-step idempotent orchestrator with resumable JSON state machine at `$XDG_STATE_HOME/dotfiles/bootstrap-state`.
- `porcelain_snapshot()` bracket pattern: Proven across all phase assert scripts to detect working-tree churn.

### Established Patterns
- **Three-Tree Capture Taxonomy:**
  - `stow/`: Installer never collides or touches paths.
  - `restow/`: Installer primitives destroy live symlinks (`rsync-replace`) or write through (`cp-through`).
  - `capture/`: Live writers rename over symlinks (`config.json` copy-capture).
- **Zero Git Churn Invariant:** Running live operations (wallpaper changes, theme updates, assertions) must produce zero modifications in `git status --porcelain`.
- **Fail-Closed Verification:** Verification scripts report exact non-zero exit codes with explicit `[FAIL]` messages; warnings fail closed under `--strict`.
- **PAIR_COUNT Invariant:** Exactly 18 stow invocations (`--verbose=5 --no-folding`) exist across `arch/*.sh`.

### Integration Points
- `guard-paths.tsv` & `.gitignore` $\rightarrow$ Enforced by `arch/dots-hyprland.sh verify --strict`.
- `collision-map.tsv` $\rightarrow$ Verified against `restow/` package membership and `restow/README.md`.
- `arch/kitty.sh` $\rightarrow$ Points to `restow/kitty` while maintaining the 18 stow sites.
- `bootstrap.sh` $\rightarrow$ Runs de-stubbing, parent pre-creation, stow, capture seed, initial theme generation, and strict verification.

</code_context>

<specifics>
## Specific Ideas

- **Moving `fuzzel` and `kitty` to `restow/`:** Ensures mathematical consistency with `collision-map.tsv` where `install_dir__sync` destroys symlinks. Updating `scripts/phase28-terminal-fuzzel-assert.sh` prevents false regression.
- **Fail-soft theme generation in bootstrap:** Prevents bootstrap failure when run in headless fixtures or clean environments without pre-existing wallpaper images by falling back to `--color "#3f51b5"`.
- **Catppuccin symlink pruning in `destub`:** Specifically targets legacy symlinks in `~/.config/gtk-4.0/` pointing to `/usr/share/themes/Catppuccin*`, preventing root permission errors when Matugen generates user CSS.

</specifics>

<deferred>
## Deferred Ideas

- Waybar custom widget ports (ping, weather, earthquake) — deferred to v2 milestone.
- Debian/Ubuntu parity for desktop shell — Arch remains the primary target.

</deferred>

---

*Phase: 29-theme-data-contracts-verification-bootstrap-integration*
*Context gathered: 2026-09-18*
