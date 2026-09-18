# Requirements: Quickshell Desktop Shell

**Defined:** 2026-09-16
**Core Value:** The desktop must keep (and eventually exceed) current Waybar-era capability while consolidating toward one themeable shell. Delivery is via upstream dots-hyprland + personal overlays, with dynamic Material You / Matugen colors unified across all desktop surfaces.

## v1 Requirements

### GTK (GTK 3 & GTK 4 / libadwaita)

- [x] **GTK-01**: User can run Matugen to dynamically generate GTK 3 theme (`~/.config/gtk-3.0/gtk.css`) from the current wallpaper.
- [x] **GTK-02**: System unlinks old hardcoded Catppuccin assets and symlinks from `~/.config/gtk-4.0/` (`gtk.css`, `assets`) so libadwaita/GTK-4 applications inherit Matugen generated colors.
- [x] **GTK-03**: `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` in repo `stow/gtk` are updated to remove legacy Catppuccin theme references (`catppuccin-mocha-teal-standard+default`) and use upstream standard (`adw-gtk3` / `adw-gtk3-dark` with dark preference).
- [x] **GTK-04**: GNOME desktop interface gsettings (`gtk-theme`, `color-scheme`, `icon-theme`) reflect dark Material You defaults consistently.

### QT (Qt 5/6 & KDE Applications)

- [x] **QT-01**: Qt applications use Kvantum theme with dots-hyprland / Material You configuration.
- [x] **QT-02**: `kde-material-you-colors` dynamically updates `kdeglobals` color scheme upon wallpaper change without manual intervention.
- [x] **QT-03**: KDE applications (Dolphin, Kate, Gwenview) render with consistent Material You color scheme and dark palette.

### SHELL (Hyprland & Quickshell ii)

- [x] **SHELL-01**: Hyprland active and inactive window borders, shadows, and group borders read color values from Matugen-generated `~/.config/hypr/hyprland/colors.lua`.
- [x] **SHELL-02**: Quickshell ii top bar and widgets dynamically consume Material You palette tokens (primary, secondary, surface, error).
- [x] **SHELL-03**: `switchwall.sh` wallpaper switcher triggers a coordinated reload across Hyprland, Quickshell, GTK, and Qt seamlessly.

### TERM (Terminals & Launchers)

- [x] **TERM-01**: Fuzzel launcher is configured with Matugen theme template (`~/.config/fuzzel/fuzzel_theme.ini`) matching wallpaper colors.
- [x] **TERM-02**: Terminal emulator (Foot / Kitty / Alacritty) dynamically reloads or adopts Matugen generated palette.

### INTG (Data Contracts & Verification)

- [x] **INTG-01**: `guard-paths.tsv` is updated and validated to ensure all dynamically generated Matugen/KDE theme outputs are guarded against repository churn.
- [x] **INTG-02**: `arch/dots-hyprland.sh verify --strict` passes with 0 violations after Catppuccin de-linking and GTK stow update.
- [x] **INTG-03**: `./bootstrap.sh` cleanly sets up the Material You theming environment on a fresh run without conflicting Catppuccin stubs.

### DEBT (Technical Debt & Validation Cleanup)

- [x] **DEBT-05**: Kitty background opacity aligned to 0.90 per Phase 28 UAT preference with native parser assert and live process signaling.
- [x] **DEBT-06**: Bootstrap virtualenv fallback export and idempotent template sanitization hooks for headless and dynamic reload robustness.
- [x] **DEBT-07**: Phase 29 validation sign-off and 100% Nyquist compliance across all Milestone v0.5 phases (25–30).
- [x] **DEBT-08**: Phase 30 assert harness with strict verifier gate and multi-phase regression sweep across Phases 25–29 with zero git drift.

## v2 Requirements

### Waybar Custom Ports

- **CUST-01**: Port self-hosted ping monitor widget into Quickshell ii bar.
- **CUST-02**: Port weather (+ forecast) widget into Quickshell ii bar.
- **CUST-03**: Port earthquake monitoring widget into Quickshell ii bar.
- **CUST-04**: Machine-specific overlay profile layer.

### Session Polish

- **POLISH-02**: Upstream FWK-02 / IPC-02 bar toggle keybinding and session integration.
- **POLISH-03**: Review and retire outstanding v0.1 legacy debug items on stock ii.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Maintaining dual Catppuccin & Material You switchers | Goal is full unification on dots-hyprland Material You; maintaining two complete parallel theming systems adds severe complexity |
| DDC/CI hardware display brightness | Causes iGPU crashes documented in `issues/2026-07-16_igpu-flickering-hang-no-display.md` |
| Quickshell lock screen | Hyprlock works reliably and is intentionally kept |
| Hand-rolled QML theme engine | Upstream dots-hyprland Matugen + Material You is the product vehicle |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GTK-01 | Phase 25 | Complete |
| GTK-02 | Phase 25 | Complete |
| GTK-03 | Phase 25 | Complete |
| GTK-04 | Phase 25 | Complete |
| QT-01 | Phase 26 | Complete |
| QT-02 | Phase 26 | Complete |
| QT-03 | Phase 26 | Complete |
| SHELL-01 | Phase 27 | Complete |
| SHELL-02 | Phase 27 | Complete |
| SHELL-03 | Phase 27 | Complete |
| TERM-01 | Phase 28 | Complete |
| TERM-02 | Phase 28 | Complete |
| INTG-01 | Phase 29 | Complete |
| INTG-02 | Phase 29 | Complete |
| INTG-03 | Phase 29 | Complete |
| DEBT-05 | Phase 30 | Complete |
| DEBT-06 | Phase 30 | Complete |
| DEBT-07 | Phase 30 | Complete |
| DEBT-08 | Phase 30 | Complete |

**Coverage:**

- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-16*
*Last updated: 2026-09-18 during Phase 30 tech debt reconciliation*
