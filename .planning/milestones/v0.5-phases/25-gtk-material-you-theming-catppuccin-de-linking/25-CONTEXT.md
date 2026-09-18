# Phase 25: GTK Material You Theming & Catppuccin De-linking - Context

**Gathered:** 2026-09-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Retire legacy Catppuccin theme assets and symlinks from `~/.config/gtk-4.0/` and repo `stow/gtk/`, configure standard `adw-gtk3-dark` base theme with `dots-hyprland` defaults, and wire Matugen dynamic GTK-3/4 CSS generation from active wallpaper with zero git repository churn:

1. **Catppuccin De-linking (`~/.config/gtk-4.0/` — GTK-02):** Safely remove legacy symlinks in `~/.config/gtk-4.0/` (`assets`, `gtk.css`, and `gtk-dark.css`) pointing to static system `/usr/share/themes/catppuccin-...` packages. Resolves Q8 permanently by freeing `~/.config/gtk-4.0/gtk.css` as a regular target file for Matugen dynamic generation without touching system packages.
2. **GTK Settings Alignment (`stow/gtk/` — GTK-03):** Update `stow/gtk/.config/gtk-3.0/settings.ini` and `stow/gtk/.config/gtk-4.0/settings.ini` to replace legacy Catppuccin theme references (`catppuccin-mocha-teal-standard+default`) with `adw-gtk3-dark`, setting `gtk-application-prefer-dark-theme=1`, font to `Google Sans Flex Medium 11 @opsz=11,wght=500`, and cursor to `Bibata-Modern-Classic` (size 24). Retain GTK3 rendering/hinting flags in `gtk-3.0/settings.ini` and personal bookmarks in `gtk-3.0/bookmarks` per Phase 22 D-11.
3. **Dynamic Matugen Theme Generation (`~/.config/gtk-3.0/gtk.css` & `gtk-4.0/gtk.css` — GTK-01):** Ensure Matugen templates in `~/.config/matugen/templates/gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` generate valid CSS stylesheets in `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` populated with Material You color tokens derived from the active wallpaper.
4. **Desktop Interface GSettings Alignment (GTK-04):** Ensure GNOME desktop interface keys in `org.gnome.desktop.interface` reflect `dots-hyprland` defaults: `gtk-theme 'adw-gtk3-dark'`, `color-scheme 'prefer-dark'`, `font-name 'Google Sans Flex Medium 11 @opsz=11,wght=500'`, `cursor-theme 'Bibata-Modern-Classic'`, and `cursor-size 24`.
5. **Phase Test Harness & Zero Churn Enforcement (INTG-01, INTG-02):** Author `scripts/phase25-gtk-material-you-assert.sh` exercising all Phase 25 deliverables, verifying that generated theme files remain excluded via `guard-paths.tsv` and `.gitignore`, and proving `arch/dots-hyprland.sh verify --strict` exits 0 with 0 findings.

Out of scope:
- Root-level package uninstallation (`pacman -R`) of system themes in `/usr/share/themes/`.
- Unmanaged GTK 2.0 files (`~/.gtkrc-2.0`, `~/.config/gtkrc`) per Phase 22 D-12.
- Qt, Kvantum, and KDE color scheme synchronization (Phase 26 owns this).
- Hyprland border and Quickshell ii widget accents coordination (Phase 27 owns this).
- Terminal and Fuzzel launcher palette dynamic generation (Phase 28 owns this).

</domain>

<decisions>
## Implementation Decisions

### GTK Base Theme & Settings Alignment (`stow/gtk/` — GTK-03)

- **D-01:** Base theme selection: In both `stow/gtk/.config/gtk-3.0/settings.ini` and `stow/gtk/.config/gtk-4.0/settings.ini`, set `gtk-theme-name=adw-gtk3-dark` and `gtk-application-prefer-dark-theme=1`. Matches `switchwall.sh:42` and guarantees GTK3 and non-libadwaita GTK4 apps load the dark Adwaita theme base before Matugen custom colors apply.
- **D-02:** Font configuration: Set `gtk-font-name=Google Sans Flex Medium 11 @opsz=11,wght=500` in both `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`, adhering strictly to `dots-hyprland` upstream installer specification (`2.setups.sh:70`).
- **D-03:** Cursor configuration: Set `gtk-cursor-theme-name=Bibata-Modern-Classic` and `gtk-cursor-theme-size=24` across both `settings.ini` files, matching `dots-hyprland` default (`execs.lua:24`).
- **D-04:** Icon theme retention: Retain `gtk-icon-theme-name=Tela-circle-dracula-dark` across both `settings.ini` files, matching the installed active circular dark icon theme.
- **D-05:** GTK 3 rendering & sound flags: Preserve antialiasing, hinting (`hintslight`), subpixel rendering (`rgb`), and sound event properties in `stow/gtk/.config/gtk-3.0/settings.ini` alongside the updated theme keys.
- **D-06:** Bookmarks preservation: Keep `stow/gtk/.config/gtk-3.0/bookmarks` unchanged per Phase 22 D-11 single-machine personal dotfiles convention.

### Catppuccin De-linking & Cleanup (`~/.config/gtk-4.0/` — GTK-02)

- **D-07:** Direct symlink removal: Remove legacy symlinks `~/.config/gtk-4.0/assets`, `~/.config/gtk-4.0/gtk.css`, and `~/.config/gtk-4.0/gtk-dark.css` pointing to `/usr/share/themes/catppuccin-mocha-teal-standard+default/gtk-4.0/`. No backup artifacts required since targets are static system packages.
- **D-08:** No unmanaged `gtk-dark.css`: Do not create an unmanaged `gtk-dark.css` symlink in `~/.config/gtk-4.0/`. Upstream `dots-hyprland` template `[templates.gtk4]` writes exclusively to `gtk.css`, and its stylesheet encapsulates `@media (prefers-color-scheme: dark)` and light blocks.
- **D-09:** Scope boundary: De-linking is strictly confined to user configuration (`~/.config/gtk-4.0/` and repo `stow/gtk/`). System packages in `/usr/share/themes/` remain untouched.
- **D-10:** GTK 2.0 exclusion: Legacy GTK 2.0 files (`~/.gtkrc-2.0`, `~/.config/gtkrc`) remain unmanaged per Phase 22 D-12.

### GSettings Desktop Interface Alignment (GTK-04)

- **D-11:** GNOME gsettings keys: Ensure `org.gnome.desktop.interface` keys match `dots-hyprland` upstream defaults:
  - `gtk-theme 'adw-gtk3-dark'`
  - `color-scheme 'prefer-dark'`
  - `font-name 'Google Sans Flex Medium 11 @opsz=11,wght=500'`
  - `cursor-theme 'Bibata-Modern-Classic'`
  - `cursor-size 24`

### Dynamic Matugen Pipeline & Zero Churn (GTK-01, INTG-01, INTG-02)

- **D-12:** Matugen GTK CSS generation: Running Matugen (`matugen image <wallpaper>` or via `switchwall.sh`) dynamically populates both `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` from active wallpaper colors.
- **D-13:** Zero git churn & GUARD invariant: Both `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` remain guarded by `guard-paths.tsv` and root `.gitignore`. `arch/dots-hyprland.sh verify --strict` classifies both as `[INFO] guarded theme output` and exits 0 with 0 findings.
- **D-14:** Phase assert test harness: Author `scripts/phase25-gtk-material-you-assert.sh` verifying:
  1. Catppuccin symlinks absent from `~/.config/gtk-4.0/`.
  2. `stow/gtk/` settings files contain 0 Catppuccin strings and specify `adw-gtk3-dark`.
  3. GSettings keys match dark `dots-hyprland` defaults.
  4. Matugen execution generates valid `@define-color` definitions in both GTK 3 and GTK 4 `gtk.css`.
  5. `arch/dots-hyprland.sh verify --strict` exits 0 with zero drift.

### the agent's Discretion

- Choice of wallpaper test fixture or active wallpaper query during test harness verification of Matugen CSS generation.
- Minor helper assertion formatting in `scripts/phase25-gtk-material-you-assert.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` §Phase 25 — goal statement, requirements, 4 success criteria
- `.planning/REQUIREMENTS.md` lines 8–14 — GTK-01, GTK-02, GTK-03, GTK-04 specifications
- `.planning/STATE.md` §Milestone v0.5 — current project state and accumulated decisions

### GTK Packaging and Repository Contracts
- `stow/gtk/.config/gtk-3.0/settings.ini` — repo source of truth for GTK 3 settings
- `stow/gtk/.config/gtk-4.0/settings.ini` — repo source of truth for GTK 4 settings
- `stow/gtk/.config/gtk-3.0/bookmarks` — personal file manager bookmarks
- `guard-paths.tsv` — lines 16–17 guarding `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css`
- `.gitignore` — generated theme outputs ignore rules (`gtk.css`, `gtk-dark.css`)
- `.planning/milestones/v0.4-phases/22-kde-and-gtk-capture/22-CONTEXT.md` — Phase 22 GTK per-file decisions (D-08..D-13, D-18..D-24)

### Upstream dots-hyprland Theming Pipeline
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh` lines 37–50, 306–311 — gsettings set commands and Matugen execution
- `vendor/dots-hyprland/sdata/subcmd-install/2.setups.sh` lines 70–72 — upstream font-name and color-scheme defaults
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` line 24 — Bibata cursor default
- `~/.config/matugen/config.toml` — template mappings for `[templates.gtk3]` and `[templates.gtk4]`
- `~/.config/matugen/templates/gtk-3.0/gtk.css` — GTK 3 CSS template with Material You color tokens
- `~/.config/matugen/templates/gtk-4.0/gtk.css` — GTK 4 / libadwaita CSS template with `@media (prefers-color-scheme)` blocks

### Verification Engine
- `arch/dots-hyprland.sh` lines 1120–1385 — `run_verify`, guard path check, and `classify_sweep_entry`
- `scripts/phase22-kde-and-gtk-capture-assert.sh` — Section 3 (GTK layout) and Section 6 (guard paths) assertions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `~/.config/matugen/config.toml`: Already defines `output_path = '~/.config/gtk-3.0/gtk.css'` and `output_path = '~/.config/gtk-4.0/gtk.css'`.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh`: Established upstream theme coordinator setting gsettings and invoking Matugen.
- `arch/dots-hyprland.sh verify --strict`: Robust verification watchdog reporting 0 findings on clean state.

### Established Patterns
- **Unfolded Directory Management:** `stow/gtk/` is stowed with `--no-folding` so `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/` remain real directories containing individual symlinks.
- **GUARD Protection:** Generated theme outputs are never committed to git and never symlink back into the repository.
- **Zero Drift Invariant:** Repository working tree must remain clean; `verify --strict` must exit 0.

### Integration Points
- `stow/gtk/.config/gtk-3.0/settings.ini` -> Symlinked to `~/.config/gtk-3.0/settings.ini`.
- `stow/gtk/.config/gtk-4.0/settings.ini` -> Symlinked to `~/.config/gtk-4.0/settings.ini`.
- `~/.config/gtk-4.0/gtk.css` -> Target for Matugen generation once legacy Catppuccin symlinks are unlinked.

</code_context>

<specifics>
## Specific Ideas

- **Strict Adherence to Upstream defaults:** The user explicitly affirmed: *"everything has to be default dots-hyprland. whatever that is"*. Every setting (theme name, font, cursor, color-scheme) strictly follows upstream dots-hyprland code (`switchwall.sh`, `2.setups.sh`, `execs.lua`).
- **Clean Inode Conversion:** In `~/.config/gtk-4.0/`, unlinking `assets`, `gtk.css`, and `gtk-dark.css` converts `gtk-4.0` from a broken root-pointing legacy Catppuccin stub into a pure Material You recipient directory.

</specifics>

<deferred>
## Deferred Ideas

- Phase 26: Aligning Qt 5/6, Kvantum, and KDE applications (Dolphin, Kate) with Material You dynamic colors.
- Phase 27: Hyprland active/inactive window borders and Quickshell ii widget accents coordination.
- Phase 28: Fuzzel launcher and terminal emulator dynamic palette generation.
- Phase 29: Theme data contracts reconciliation (`guard-paths.tsv`, `collision-map.tsv`) and `./bootstrap.sh` full integration test.

</deferred>

---

*Phase: 25-gtk-material-you-theming-catppuccin-de-linking*
*Context gathered: 2026-09-16*
