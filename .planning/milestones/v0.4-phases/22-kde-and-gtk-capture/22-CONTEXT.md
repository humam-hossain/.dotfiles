# Phase 22: KDE and GTK capture - Context

**Gathered:** 2026-09-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Capture Dolphin, KDE, and GTK configurations into granular, per-file repository trees (`stow/` and `restow/`), exclude generated theme outputs provably through an explicit GUARD list and verification enforcement, and resolve long-standing research questions regarding KConfig permissions and theming pipeline write behaviors:

1. **KDE Package (`stow/kde/` — KDE-01):** Establish `stow/kde/.config/{kiorc,ktrashrc,kservicemenurc}` as a clean GNU Stow package holding non-colliding KDE/KIO configurations. Adopt live files using SAFE-01 protocol (timestamped `.bak.<epoch>` backups, `stow -n --no-folding` dry run, and atomic commit). Close Q11 by documenting that git's default mode `100644` is harmless (these files contain no credentials/secrets, git ignores chmod between 0644 and 0600, and KConfig's `setPermissions` automatically enforces `0600` on write). Close Q10 by testing Dolphin/KConfig write-through via `kwriteconfig6` toggle drill, asserting link preservation and repo updates.
2. **GTK Per-File Management (`stow/gtk/` — KDE-02):** Establish `stow/gtk/.config/` managing `gtk-3.0/settings.ini`, `gtk-3.0/bookmarks`, and `gtk-4.0/settings.ini` per file. Enforce `--no-folding` so neither `~/.config/gtk-3.0` nor `~/.config/gtk-4.0` is a symlink. Keep `gtk.css` and `gtk-dark.css` gitignored in root `.gitignore`. Address Q6 by managing GTK files as declarative dotfiles with `verify` acting as the watchdog for any link severance by `g_file_set_contents`.
3. **Cp-Through Restow Packaging (`restow/chrome-flags/` — KDE-03):** Package `chrome-flags.conf` into `restow/chrome-flags/.config/chrome-flags.conf`. Tag both `dolphinrc` and `chrome-flags` as `cp-through` in `restow/README.md` via `scripts/gen-collision-map.sh --restow-table`. Rehearse live installer overwrite via `./arch/dots-hyprland.sh install-files` with a clean-tree preflight assertion, and prove `git checkout -- restow/<pkg>` restores personal configs cleanly.
4. **GUARD List Enforcement & `kdeglobals` Disposition (KDE-02):**
   - Check in `guard-paths.tsv` at the repository root as data (mirroring `collision-map.tsv`), tracking: `kdeglobals`, `Kvantum/`, `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, `fuzzel/fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, and `hyprlock/colors.conf`.
   - Record empirical Q7 (active `kde-material-you-colors` churn) and Q8 (root-owned Catppuccin GTK4 theme symlink) measurement findings in the `guard-paths.tsv` header.
   - Retire `restow/kdeglobals` to `docs/archive/kdeglobals`, update `docs/config-redistribution.md` row 36 to preserve historical provenance and maintain `scripts/phase18-capture-model-assert.sh:635` green, and convert live `~/.config/kdeglobals` to a standalone regular file, permanently eliminating git repo churn on wallpaper changes.
   - Add a dedicated GUARD verification pass to `arch/dots-hyprland.sh verify` asserting that no GUARD path is tracked in `stow/`, `restow/`, or `capture/`, and no live path symlinks into the repo.
5. **No Script Proliferation:** Do not create `arch/kde.sh` or `arch/gtk.sh`, preserving `PAIR_COUNT == 18` in closed assert `scripts/phase17-unblock-assert.sh`. Orchestration of package deployment belongs strictly to Phase 23.

Out of scope:
- Legacy GTK 2.0 files (`~/.gtkrc-2.0`, `~/.config/gtkrc`).
- Custom KIO service menu desktop entries in `~/.local/share/kio/servicemenus/`.
- Other KDE desktop cache rc files (`darklyrc`, `konsolerc`, `kwalletrc`, `baloofileinformationrc`).
- One-command full desktop bootstrap orchestration (Phase 23 owns this).

</domain>

<decisions>
## Implementation Decisions

### KDE Packaging & File Modes (`stow/kde/` — KDE-01)

- **D-01:** Single package layout: `kiorc`, `ktrashrc`, and `kservicemenurc` reside in `stow/kde/.config/`. Groups all non-colliding Dolphin and KIO configuration files together in one logical package per ROADMAP KDE-01. — **Reversibility:** reversible
- **D-02:** SAFE-01 adoption protocol: Live files are adopted by taking timestamped backups (`.bak.<epoch>`), copying live content to `stow/kde/`, running `stow -n --no-folding -t ~ kde` dry run, and linking via `stow --verbose=5 --no-folding -t ~ kde`. Inode identity is asserted before committing. — **Reversibility:** reversible
- **D-03:** File mode resolution (Q11): Mode `100644` in git is documented as harmless and requires no mandatory bootstrap chmod. The files contain only UI flags and preferences (no credentials/secrets). Furthermore, git ignores chmod between `0644` and `0600`, and KConfig's `setPermissions` automatically enforces `0600` on its first write. — **Reversibility:** reversible
- **D-04:** Dolphin write-through test (Q10): Two-stage verification drill. First stage executes in an isolated scratch XDG environment using `kwriteconfig6` to prove KConfig writes through symlinks without link destruction. Second stage performs a double-toggle test on live `kiorc` (toggling `ConfirmTrash`, verifying git diff on `stow/kde/.config/kiorc`, toggling back, and reverting via `git checkout -- stow/kde`). — **Reversibility:** reversible
- **D-05:** Process lifecycle safety: Any running Dolphin GUI instances must be closed before initial linking/stowing (mirrors Phase 18 D-18 qBittorrent rule to prevent race conditions or locks). — **Reversibility:** reversible
- **D-06:** Scope boundary: KDE management is strictly confined to configuration files (`kiorc`, `ktrashrc`, `kservicemenurc`). No local action directories in `~/.local/share/kio/servicemenus/` are tracked. Machine-written session rc files (`baloofileinformationrc`, `kwalletrc`, `kconf_updaterc`) remain unmanaged. — **Reversibility:** reversible
- **D-07:** Path portability in `ktrashrc`: `ktrashrc` retains the literal `/home/pera/.local/share/Trash` path as-is, adhering to Phase 18 D-54 single-machine dotfiles repository principles. — **Reversibility:** reversible

### GTK Per-File Management & Directory Safety (`stow/gtk/` — KDE-02)

- **D-08:** Single package layout: `stow/gtk/` manages `.config/gtk-3.0/settings.ini`, `.config/gtk-3.0/bookmarks`, and `.config/gtk-4.0/settings.ini`. Stowed using `--no-folding`. — **Reversibility:** reversible
- **D-09:** Parent directory unfolding enforcement: Assert script explicitly tests `test -d "$HOME/.config/gtk-3.0" && test ! -L "$HOME/.config/gtk-3.0"` and `test -d "$HOME/.config/gtk-4.0" && test ! -L "$HOME/.config/gtk-4.0"`. `verify`'s D-04 folded ancestor gate permanently enforces this invariant. — **Reversibility:** reversible
- **D-10:** Link severance risk (Q6): GTK files are managed as declarative dotfiles in `stow/gtk/`. `g_file_set_contents` write behavior is tested in a scratch fixture, and `verify` acts as the watchdog: if a GTK file chooser severs the link via rename, `verify` immediately detects it (`[FAIL] not a symlink`), recoverable via re-stowing. — **Reversibility:** reversible
- **D-11:** Bookmarks path portability: `gtk-3.0/bookmarks` tracks literal `file:///home/pera/...` paths as-is per D-07. — **Reversibility:** reversible
- **D-12:** Legacy GTK 2.0 exclusion: GTK 2.0 files (`~/.gtkrc-2.0`, `~/.config/gtkrc`) are strictly out of scope per KDE-02; they are machine-generated by `nwg-look` or KDE Plasma and remain unmanaged. — **Reversibility:** reversible
- **D-13:** Gitignore rules: Root `.gitignore` already contains slash-free `gtk.css`. Add `gtk-dark.css` to root `.gitignore` under generated theme outputs. — **Reversibility:** reversible

### Restow Cp-Through Packaging (`restow/chrome-flags/` — KDE-03)

- **D-14:** Package naming: `chrome-flags.conf` is packaged as `restow/chrome-flags/.config/chrome-flags.conf`, matching the semantic package naming convention of `restow/starship` and `restow/dolphinrc`. — **Reversibility:** reversible
- **D-15:** Mechanical table regeneration: `restow/README.md` is regenerated via `scripts/gen-collision-map.sh --restow-table` (D-09, D-12) so `chrome-flags` appears with its `cp-through` tag and exact recovery command: `git checkout -- restow/chrome-flags/.config/chrome-flags.conf && cd restow && stow --verbose=5 --no-folding -t ~ chrome-flags`. — **Reversibility:** reversible
- **D-16:** Live cp-through drill: The assert script asserts a clean tree, invokes `./arch/dots-hyprland.sh install-files` against the live session, verifies `git status --porcelain` shows `restow/dolphinrc/.config/dolphinrc` and `restow/chrome-flags/.config/chrome-flags.conf` modified through their links, and executes `git checkout -- restow/dolphinrc restow/chrome-flags` to restore clean state. — **Reversibility:** reversible
- **D-17:** Manual recovery contract: Adheres strictly to Phase 18 D-10: recovery remains a documented copy-pasteable command in `restow/README.md` without adding automated wrapper hooks. — **Reversibility:** reversible

### GUARD List Enforcement & `kdeglobals` Disposition (KDE-02)

- **D-18:** GUARD data format & location: Checked in as `guard-paths.tsv` at the repository root, formatted identically to `collision-map.tsv` (columns: `path`, `category`, `generator`, `reason`). Comment header documents empirical Q7 and Q8 measurement findings. — **Reversibility:** costly — changing schema breaks parser in `verify`.
- **D-19:** Guarded path inventory:
  1. `$XDG_CONFIG_HOME/kdeglobals` (`generated_theme`, `kde-material-you-colors`)
  2. `$XDG_CONFIG_HOME/Kvantum` (`vendor_theme`, `dots-hyprland`)
  3. `$XDG_CONFIG_HOME/gtk-3.0/gtk.css` (`generated_theme`, `matugen`)
  4. `$XDG_CONFIG_HOME/gtk-4.0/gtk.css` (`generated_theme`, `matugen`)
  5. `$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini` (`generated_theme`, `matugen`)
  6. `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` (`generated_theme`, `matugen`)
  7. `$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf` (`generated_theme`, `matugen`)
- **D-20:** `kdeglobals` retirement: `restow/kdeglobals/.config/kdeglobals` is retired from `restow/` to `docs/archive/kdeglobals` (matching Phase 18 `docs/archive/hyprland.conf` pattern). `docs/config-redistribution.md` row 36 is updated to point to `docs/archive/kdeglobals` with an explicit audit note, keeping `scripts/phase18-capture-model-assert.sh:635` green. Live `~/.config/kdeglobals` is converted from a symlink to a regular local file, completely eliminating git repo churn on wallpaper switches. — **Reversibility:** costly
- **D-21:** Q7 resolution & finding: `kde-material-you-colors` is active in `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` via `switchwall.sh:34` and actively churns `kdeglobals`. Guarding `kdeglobals` out of the repo is justified by empirical measurement (Phase 21 Section 3).
- **D-22:** Q8 resolution & finding: `~/.config/gtk-4.0/gtk.css` is a symlink to `/usr/share/themes/catppuccin-mocha-teal-standard+default/gtk-4.0/gtk.css` (root-owned, 0644). User writes by matugen cannot overwrite root files, leaving the system theme intact. Both `gtk.css` paths are guarded out of the repository.
- **D-23:** `verify` GUARD check integration: `run_verify()` reads `guard-paths.tsv` and asserts:
  (a) None of the GUARD paths exist in `stow/`, `restow/`, or `capture/`.
  (b) No live counterpart is a symlink resolving into the repository.
  Emits `[PASS] guard path excluded: <path>` (suppressed by `--quiet`) or `[FAIL]` on violation.
- **D-24:** Live sweep entry classification refinement: Update `classify_sweep_entry` in `arch/dots-hyprland.sh` so regular files in managed roots that match `guard-paths.tsv` (such as `~/.config/gtk-3.0/gtk.css`) emit `[INFO] guarded theme output: $entry` instead of `unclaimed upstream stub`.

### Architectural Discipline & Regression Protection

- **D-25:** No script proliferation: Do not create `arch/kde.sh` or `arch/gtk.sh`. Keep `PAIR_COUNT == 18` intact in `scripts/phase17-unblock-assert.sh:90`. Packages are stowed directly via GNU Stow during the deployment task, leaving full multi-package orchestration to Phase 23. — **Reversibility:** reversible
- **D-26:** Comprehensive assert script: `scripts/phase22-kde-and-gtk-capture-assert.sh` gates the phase with 6 sections:
  1. KDE package layout, inode identity, and 0600 mode documentation check.
  2. Dolphin/KIO write-through scratch fixture and double-toggle test.
  3. GTK package layout, unfolded parent directory assertion, and scratch link severance test.
  4. Restow `chrome-flags` packaging and `restow/README.md` generated table match.
  5. Live cp-through drill: clean-tree preflight, `install-files` execution, modified status check, and `git checkout` recovery.
  6. GUARD list data integrity, Q7/Q8 documentation check, `kdeglobals` unlinking, and `verify --strict` pass.

### Claude's Discretion

- Exact temporary variable naming and scratch fixture path patterns in `scripts/phase22-kde-and-gtk-capture-assert.sh`.
- Minor phrasing of `[PASS]` and `[INFO]` log outputs in `run_verify()` GUARD checks.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 22 — goal statement, dependencies, 4 success criteria, verification risks
- `.planning/REQUIREMENTS.md` lines 50–55, 140–142 — KDE-01, KDE-02, KDE-03

### Collision map, three trees, and redistribution contracts
- `collision-map.tsv` — machine-readable collision definitions (lines 13–18: chrome-flags, dolphinrc, kdeglobals)
- `restow/README.md` — restow contract, recovery commands, and generated package table
- `docs/config-redistribution.md` — FIX-03 canonical redistribution table (row 36: kdeglobals archive update)
- `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-CONTEXT.md` §D-05, D-09, D-12, D-22 — tree placement, recovery commands, live adoption
- `.planning/phases/19-link-aware-verify/19-CONTEXT.md` §D-04, D-13, D-20 — folded ancestor check, strict mode, quiet flag

### Research findings & theme pipeline architecture
- `.planning/research/SUMMARY.md` §8 lines 245–267 — Q6, Q7, Q8, Q10, Q11 research questions and tests
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh` lines 12–60 — matugen invocation and `kde-material-you-colors-wrapper.sh`
- `~/.config/matugen/config.toml` — matugen template outputs (gtk3, gtk4, fuzzel, hyprland, hyprlock)
- `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh` — virtualenv wrapper rewriting `kdeglobals`

### Scripts and assertions
- `arch/dots-hyprland.sh` lines 740–1385 — `run_verify` implementation, `managed_roots` derivation, sweep classifier
- `scripts/gen-collision-map.sh` lines 105–170 — `--restow-table` generator logic
- `scripts/phase18-capture-model-assert.sh` lines 620–644 — Section 6b redistribution destination check
- `scripts/phase17-unblock-assert.sh` lines 88–95 — Section 1b `PAIR_COUNT == 18` literal audit

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/gen-collision-map.sh --restow-table`: Regenerates Section 3 of `restow/README.md` dynamically from package directories in `restow/`.
- `arch/dots-hyprland.sh run_verify()`: Established multi-pass verification engine with precondition checks, link-identity tests, and live-side sweep.
- `docs/archive/`: Established location for historical configuration files removed from live management (e.g. `hyprland.conf`).

### Established Patterns
- Three-Tree Stow Layout: Stow-relative package hierarchy where `<tree>/<pkg>/<rel_to_home>` maps to `$HOME/<rel_to_home>`.
- Invariant verify output: `=== done: FAIL=n FINDINGS=n ===` summary line frozen across all runs; `--quiet` suppresses passing lines without altering verdict.
- SAFE-01 escape protocol: Timestamped backup before link creation, `--no-folding` dry run, atomic commit.

### Integration Points
- `guard-paths.tsv`: New data file at repo root parsed by `run_verify()` in `arch/dots-hyprland.sh`.
- `arch/dots-hyprland.sh`: `run_verify()` augmented with GUARD validation pass and sweep classifier refinement.
- `.gitignore`: Generated theme block updated with `gtk-dark.css`.
- `docs/config-redistribution.md`: Row 36 updated from `restow/kdeglobals` to `docs/archive/kdeglobals`.

</code_context>

<specifics>
## Specific Ideas

- Fast GUARD check in verify: Reading `guard-paths.tsv` line-by-line in bash, stripping comments, resolving `$XDG_CONFIG_HOME` and `$HOME`, and testing existence with `test -e "$REPO_ROOT/stow/.../$rel"` and `test -L "$live"`.
- Clean kdeglobals live conversion: `cp ~/.config/kdeglobals ~/.config/kdeglobals.tmp && rm ~/.config/kdeglobals && mv ~/.config/kdeglobals.tmp ~/.config/kdeglobals`. This ensures the live file is severed from git without losing current sorting or window settings.
- Proving live cp-through with `git status`: The live installer drill invokes `./arch/dots-hyprland.sh install-files` with a clean working tree; git status diffs on `restow/dolphinrc` and `restow/chrome-flags` provide definitive empirical proof that the installer writes through symlinks.

</specifics>

<deferred>
## Deferred Ideas

- Phase 23: One-command full desktop bootstrap orchestration (`BOOT-01`–`BOOT-05`).
- Future phase: Managing custom KIO service menu scripts under `~/.local/share/kio/servicemenus/` if personal action scripts are authored.
- Future phase: Evaluating whether personal non-color keys in `kdeglobals` should be templated or managed via helper scripts in bootstrap.

</deferred>

---

*Phase: 22-KDE-and-GTK-capture*
*Context gathered: 2026-09-15*
