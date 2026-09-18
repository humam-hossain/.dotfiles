# Phase 26: Qt & KDE Apps Material You Harmonization - Context

**Gathered:** 2026-09-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Align Qt 5/6, KDE applications (Dolphin, Gwenview), and desktop file pickers with the upstream `dots-hyprland` Material You dynamic color palette generated from the active wallpaper, while maintaining zero git churn and adhering strictly to upstream defaults:

1. **Qt Style Engine Alignment (QT-01):** Verify and document that Qt applications run the upstream `dots-hyprland` style engine (`Darkly::Style` via `darkly-bin` and `widgetStyle=Darkly` in `kdeglobals`) with `~/.config/Kvantum` properly guarded as vendor configuration.
2. **Dynamic Material You Pipeline (QT-02):** Validate that `switchwall.sh` triggers `kde-material-you-colors` to dynamically generate Material You color palettes into `~/.config/kdeglobals` and `~/.local/share/color-schemes/` without manual intervention.
3. **KDE Application Harmonization (QT-03):** Ensure Dolphin, Gwenview, and KFileDialog (via `xdg-desktop-portal-kde`) render consistently with the dark Material You palette.
4. **Data Contract & Guard Invariant (INTG-01, INTG-02):** Add `$XDG_CONFIG_HOME/kde-material-you-colors` to `guard-paths.tsv` as `generated_theme`, ensuring `arch/dots-hyprland.sh verify --strict` passes with 0 violations.
5. **Phase Test Harness:** Author `scripts/phase26-qt-kde-material-you-assert.sh` to enforce all Phase 26 deliverables fail-closed.

Out of scope:
- Installing or forcing `kvantum` package (upstream dots-hyprland intentionally uses `darkly-bin` / `Darkly::Style`).
- Kate integration (user explicitly affirmed Kate is not needed).
- Capturing `~/.config/gwenviewrc` into git (contains volatile window state, not theming rules).
- Modifying `stow/hypr/.config/hypr/custom/env.lua` (upstream `hyprland/env.lua` already defines required Qt variables).
- Hyprland border and Quickshell ii widget accents coordination (Phase 27 owns this).
- Terminal and launcher theming (Phase 28 owns this).

</domain>

<decisions>
## Implementation Decisions

### Qt Style Engine & Kvantum Alignment (QT-01)

- **D-01:** Upstream style engine verification: Empirically verified that upstream `dots-hyprland` uses `darkly-bin` (`/usr/lib/qt6/plugins/styles/darkly6.so`) with `widgetStyle=Darkly` in `kdeglobals` and `~/.config/darklyrc`, resulting in runtime style `Darkly::Style`. Upstream does not install the `kvantum` package. In accordance with the project rule *"everything has to be default dots-hyprland. whatever that is"*, Qt applications use `Darkly::Style` pulling Material You colors directly from `kdeglobals`.
- **D-02:** Guard Kvantum directory: Keep `~/.config/Kvantum/` guarded in `guard-paths.tsv` (`vendor_theme`). Theme files (`MaterialAdw`, `Colloid`) remain live-only and are never committed to git.
- **D-03:** Upstream darklyrc retention: `~/.config/darklyrc` is maintained as an upstream-installed configuration (already registered in `collision-map.tsv` as restow `cp-through`). No personal modifications or extra repo packaging needed.

### Dynamic Pipeline & kde-material-you-colors (QT-02, INTG-01)

- **D-04:** Guard kde-material-you-colors config: Add `$XDG_CONFIG_HOME/kde-material-you-colors` to `guard-paths.tsv` with category `generated_theme`, generator `kde-material-you-colors`, and reason `Upstream directory sync`. Keeps `~/.config/kde-material-you-colors/config.conf` live-only without repo churn.
- **D-05:** Dynamic color-scheme following: `kde-material-you-colors-wrapper.sh` dynamically checks `gsettings get org.gnome.desktop.interface color-scheme` and passes `-d` for `prefer-dark`. This keeps Qt/KDE and GTK dark preferences in lockstep.
- **D-06:** Standard scheme variant: Standardize on `TonalSpot` (`scheme-tonal-spot` / variant 5), matching upstream default for balanced, accessible Material You tones.
- **D-07:** KDE icon theme retention: Retain upstream `breeze-plus-dark` icons in `config.conf` for complete coverage of KDE action icons and KIO dialogs.
- **D-08:** Python virtual environment assertion: Test harness verifies that `$XDG_STATE_HOME/quickshell/.venv/bin/kde-material-you-colors` exists and is executable.
- **D-09:** Pipeline robustness against missing KWin DBus: In Hyprland, `kde-material-you-colors` finishes writing `kdeglobals` and `color-schemes/` before raising a `DBusException` when attempting `kwin_utils.reload()`. The test harness validates actual output deliverables (`kdeglobals` mtime, `[Colors:Window]`, `[Colors:View]`, and `ColorScheme=MaterialYouDark`) rather than asserting exit 0 on the Python script.

### KDE Application Scope & File Pickers (QT-03)

- **D-10:** Verified applications: Scope includes Dolphin (`/usr/bin/dolphin`) and Gwenview (`/usr/bin/gwenview`). Kate is dropped from testing as it is not needed on this host. Both Dolphin and Gwenview automatically inherit the `kdeglobals` dark palette.
- **D-11:** Gwenview configuration unmanaged: `~/.config/gwenviewrc` remains unmanaged live runtime state to avoid git churn from recent file lists and splitter coordinates.
- **D-12:** FileChooser portal preference: Verify `~/.config/xdg-desktop-portal/portals.conf` retains `org.freedesktop.impl.portal.FileChooser = kde`, confirming desktop file dialogs invoke `xdg-desktop-portal-kde` and display the dark Material You theme.
- **D-13:** Dark palette programmatic assertion: Assert that `kdeglobals` sets `ColorScheme=MaterialYouDark` and that `[Colors:Window] BackgroundNormal` and `[Colors:View] BackgroundNormal` have RGB values with dark luminance (< 50/255).

### Qt Environment Variables

- **D-14:** Upstream environment ownership: Qt environment variables remain managed by upstream `~/.config/hypr/hyprland/env.lua` (`QT_QPA_PLATFORMTHEME="kde"`, `QT_QPA_PLATFORM="wayland;xcb"`). `stow/hypr/.config/hypr/custom/env.lua` remains untouched.
- **D-15:** No QT_STYLE_OVERRIDE: `QT_STYLE_OVERRIDE` remains unset to allow the KDE platform theme and `kdeglobals` to govern styles cleanly without collision.

### Verification Engine & Test Harness (INTG-02)

- **D-16:** Phase test harness: Author `scripts/phase26-qt-kde-material-you-assert.sh` exercising 5 automated sections:
  1. Virtualenv & binary readiness: verify `kde-material-you-colors` executable in quickshell venv.
  2. Environment variables: verify `QT_QPA_PLATFORMTHEME=kde` and `QT_QPA_PLATFORM=wayland;xcb` in `env.lua`, `QT_STYLE_OVERRIDE` unset.
  3. Style engine & guard status: verify `Darkly::Style` runtime load and `Kvantum` / `kde-material-you-colors` guarded in `guard-paths.tsv`.
  4. Material You generation: execute color generation probe and verify `kdeglobals` dark tokens.
  5. Desktop integration & zero churn: verify `portals.conf` FileChooser setting and run `arch/dots-hyprland.sh verify --strict` (asserting 0 findings).

### the agent's Discretion

- Choice of wallpaper test fixture or active wallpaper query during test harness verification.
- Internal test assertions formatting in `scripts/phase26-qt-kde-material-you-assert.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` §Phase 26 — goal statement, requirements, 3 success criteria
- `.planning/REQUIREMENTS.md` lines 15–20 — QT-01, QT-02, QT-03 specifications
- `.planning/STATE.md` §Milestone v0.5 — current project state and accumulated decisions

### Data Contracts and Capture
- `guard-paths.tsv` — lines 14–15 guarding `kdeglobals` and `Kvantum/`
- `collision-map.tsv` — tracking for `Kvantum`, `dolphinrc`, `kde-material-you-colors`, and `darklyrc`
- `restow/dolphinrc/.config/dolphinrc` — captured Dolphin file manager configuration
- `restow/README.md` §3 — package recovery table for restow packages

### Upstream Dots-Hyprland Qt/KDE Pipeline
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/env.lua` line 12 — `QT_QPA_PLATFORMTHEME=kde` and `QT_QPA_PLATFORM`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh` lines 15–35, 58 — `handle_kde_material_you_colors` invocation
- `vendor/dots-hyprland/dots/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh` — wrapper invoking Python CLI in virtualenv
- `vendor/dots-hyprland/sdata/subcmd-install/2.setups.sh` line 72 — upstream `kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly`
- `~/.config/kde-material-you-colors/config.conf` — active configuration for KDE color generator
- `~/.config/xdg-desktop-portal/portals.conf` — file chooser portal configuration (`FileChooser = kde`)

### Verification Engine
- `arch/dots-hyprland.sh` lines 1120–1385 — `run_verify`, guard path check, and `classify_sweep_entry`
- `scripts/phase25-gtk-material-you-assert.sh` — model assert harness from Phase 25

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `~/.local/state/quickshell/.venv/bin/kde-material-you-colors`: Installed, operational CLI generator.
- `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh`: Established wrapper mapping Matugen seed color and variant flags.
- `arch/dots-hyprland.sh verify --strict`: Verification watchdog reporting 0 findings on clean state.

### Established Patterns
- **GUARD Protection:** Generated theme outputs (`kdeglobals`, `Kvantum/`, `kde-material-you-colors/`) are excluded from repo tracking to prevent wallpaper-driven git churn.
- **Upstream Default Adherence:** Personal config layer leaves upstream environment and style defaults intact unless explicit customization is required.
- **Zero Drift Invariant:** Repository working tree must remain clean; `verify --strict` must exit 0.

### Integration Points
- `~/.config/kdeglobals` -> Written by `kde-material-you-colors`, read by `Darkly::Style`, Dolphin, Gwenview, and KFileDialog.
- `~/.config/xdg-desktop-portal/portals.conf` -> Directs desktop file open/save requests to `xdg-desktop-portal-kde`.
- `guard-paths.tsv` -> Controls which live `$HOME/.config/` paths are exempted from git tracking.

</code_context>

<specifics>
## Specific Ideas

- **Darkly::Style vs Kvantum Reality:** The user explicitly affirmed: *"everything has to be default dots-hyprland. whatever that is"*. Upstream `dots-hyprland` standardizes on `darkly-bin` as its Qt widget style engine, not Kvantum. QT-01 is verified against `Darkly::Style` reading `kdeglobals` Material You colors.
- **KWin DBus Exception Handling:** Because `kde-material-you-colors` was built for Plasma, its attempt to reload KWin fails on Hyprland without affecting theme generation. The assert harness checks output artifacts rather than relying on exit code 0 from the script.

</specifics>

<deferred>
## Deferred Ideas

- Phase 27: Hyprland active/inactive window borders and Quickshell ii widget accents coordination.
- Phase 28: Fuzzel launcher and terminal emulator dynamic palette generation.
- Phase 29: Theme data contracts reconciliation (`guard-paths.tsv`, `collision-map.tsv`) and `./bootstrap.sh` full integration test.

</deferred>

---

*Phase: 26-qt-kde-apps-material-you-harmonization*
*Context gathered: 2026-09-17*
