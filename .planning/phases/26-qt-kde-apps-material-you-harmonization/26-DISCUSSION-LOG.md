# Phase 26: Qt & KDE Apps Material You Harmonization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-17
**Phase:** 26-qt-kde-apps-material-you-harmonization
**Areas discussed:** Kvantum theme capture, kde-material-you-colors config ownership, KDE app verification scope, Qt environment variables

---

## Kvantum theme capture

| Option | Description | Selected |
|--------|-------------|----------|
| Guard them | Treat Kvantum dir as upstream-generated (like kdeglobals). Keep guard-paths.tsv entry, leave live-only, never commit the SVG/kvconfig to git. | ✓ |
| Restow capture | Copy MaterialAdw + kvantum.kvconfig into restow/Kvantum/ so the repo owns the exact theme selection and can restore it on bootstrap. Drop Colloid since it's unused. | |
| Stow capture with no-folding | Stow kvantum.kvconfig only (theme selector), and leave MaterialAdw/Colloid as upstream-installed. Restores theme choice but not theme files. | |

**User's choice:** Guard them.
**Notes:** Kvantum directory remains guarded and upstream-managed.

| Option | Description | Selected |
|--------|-------------|----------|
| Leave upstream-managed | dots-hyprland install handles everything. No need to verify Kvantum files exist since guard-paths.tsv already guards the directory. | ✓ |
| Verify presence only | Assert harness checks that ~/.config/Kvantum/kvantum.kvconfig exists and contains 'MaterialAdw'. | |
| Verify full pipeline | Assert that kvantum.kvconfig selects MaterialAdw, and that a Qt app renders using Kvantum engine. | |

**User's choice:** Leave upstream-managed.

| Option | Description | Selected |
|--------|-------------|----------|
| Leave unused Colloid | It's upstream-installed and lives in a guarded directory we'll never commit. Cleaning it up is unnecessary manual work on upstream-owned paths. | ✓ |
| Clean up Colloid | Remove ~/.config/Kvantum/Colloid/ to reduce desktop noise. | |

**User's choice:** Leave unused Colloid.

| Option | Description | Selected |
|--------|-------------|----------|
| Confirm MaterialAdw is active via collision-map.tsv | The collision map already records $XDG_CONFIG_HOME/Kvantum as restow with outcome DESTROYED/untouched. No new phase work needed. | ✓ |
| Add a bootstrap step that runs kvantummanager | Explicit CLI call during bootstrap to ensure theme selection. | |

**User's choice:** Confirm MaterialAdw is active via collision-map.tsv.

---

## kde-material-you-colors config ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Guard and leave live-only | The config is upstream-installed, scheme_variant/chroma/tone are upstream defaults, and the wallpaper path is hardcoded to the ii pipeline output. No repo capture needed. | ✓ |
| Restow capture config.conf | Copy config.conf into restow/kde-material-you-colors/. | |
| Stow capture config.conf | Make config.conf repo-owned via stow/kde-material-you-colors/. | |

**User's choice:** Guard and leave live-only.

| Option | Description | Selected |
|--------|-------------|----------|
| Add guard-paths.tsv entry | Add $XDG_CONFIG_HOME/kde-material-you-colors as generated_theme. Closes the gap so verify --strict classifies it as guarded theme output. | ✓ |
| No guard entry needed | Rely only on collision-map.tsv. | |

**User's choice:** Add guard-paths.tsv entry.

| Option | Description | Selected |
|--------|-------------|----------|
| Verify the pipeline fires end-to-end | Assert that running switchwall.sh (or matugen) produces updated kdeglobals with Material You color tokens. Proves QT-02. | ✓ |
| Trust the pipeline | switchwall.sh already calls handle_kde_material_you_colors(). No assert needed. | |

**User's choice:** Verify the pipeline fires end-to-end.

| Option | Description | Selected |
|--------|-------------|----------|
| Follow GNOME color-scheme setting dynamically | Keep upstream wrapper behavior that checks gsettings color-scheme and passes -d when prefer-dark. | ✓ |
| Hardcode dark mode (-d) unconditionally | Force dark mode regardless of gsettings. | |

**User's choice:** Follow GNOME color-scheme setting dynamically.

| Option | Description | Selected |
|--------|-------------|----------|
| Retain upstream breeze-plus-dark for KDE | Breeze icons are purpose-built for Qt/KDE toolbars, dialogs, and KIO actions, avoiding missing icons. | ✓ |
| Harmonize icons to Tela-circle-dracula-dark | Update iconsdark in config.conf to match GTK icon theme. | |

**User's choice:** Retain upstream breeze-plus-dark for KDE.

| Option | Description | Selected |
|--------|-------------|----------|
| Standardize on TonalSpot (scheme-tonal-spot / variant 5) | Adheres to upstream dots-hyprland defaults and provides consistent, readable Material You tones. | ✓ |
| Allow custom scheme variant overrides | Enable changing the variant via flags. | |

**User's choice:** Standardize on TonalSpot.

| Option | Description | Selected |
|--------|-------------|----------|
| Assert venv binary exists and is executable | Have test harness verify that $XDG_STATE_HOME/quickshell/.venv/bin/kde-material-you-colors is present and executable, failing closed if broken. | ✓ |
| Soft check with warning | Emit warning without failing test harness. | |

**User's choice:** Assert venv binary exists and is executable.

| Option | Description | Selected |
|--------|-------------|----------|
| Validate Material You INI sections and git guard | Assert that kdeglobals contains standard Material You sections, remains uncommitted, and satisfies guard-paths.tsv during verify --strict. | ✓ |
| Simple non-empty check | Assert only that kdeglobals exists and has non-zero size. | |

**User's choice:** Validate Material You INI sections and git guard.

---

## KDE app verification scope

| Option | Description | Selected |
|--------|-------------|----------|
| Scope definition | User reviewed installed image viewers (feh, swappy, qView), decided Kate is not needed, and explicitly installed Gwenview to be included alongside Dolphin. | ✓ |

**User's choice:** Include Dolphin and Gwenview; exclude Kate. Gwenview must follow dots-hyprland theming standards via kdeglobals without requiring extra repo rc files.

| Option | Description | Selected |
|--------|-------------|----------|
| Leave gwenviewrc unmanaged | gwenviewrc contains volatile GUI state (Recent Files, splitter sizes). Theming is governed by kdeglobals, avoiding git churn. | ✓ |
| Capture in restow/gwenviewrc | Track gwenviewrc in restow/ similar to dolphinrc. | |

**User's choice:** Leave gwenviewrc unmanaged.

| Option | Description | Selected |
|--------|-------------|----------|
| Programmatic luminance and section validation in assert harness | Assert that kdeglobals contains ColorScheme=MaterialYouDark and that [Colors:Window] and [Colors:View] BackgroundNormal RGB values represent dark tones. | ✓ |
| Inspect live app window properties via Hyprctl/IPC | Temporarily spawn Dolphin/Gwenview and query Hyprland window rules/screenshots. | |

**User's choice:** Programmatic luminance and section validation in assert harness.

| Option | Description | Selected |
|--------|-------------|----------|
| Assert FileChooser portal preference | Verify that ~/.config/xdg-desktop-portal/portals.conf sets FileChooser = kde. Confirms file dialogs summon KFileDialog and inherit kdeglobals. | ✓ |
| Rely on kdeglobals alone | Do not inspect portals.conf in test harness. | |

**User's choice:** Assert FileChooser portal preference.

---

## Qt environment variables

| Option | Description | Selected |
|--------|-------------|----------|
| Rely on upstream hyprland/env.lua | Upstream already sets QT_QPA_PLATFORMTHEME=kde and QT_QPA_PLATFORM=wayland;xcb. Keeping custom/env.lua clean respects Phase 20 overlay architecture. | ✓ |
| Pin in custom/env.lua | Explicitly declare Qt environment variables in custom/env.lua. | |

**User's choice:** Rely on upstream hyprland/env.lua.

| Option | Description | Selected |
|--------|-------------|----------|
| Leave QT_STYLE_OVERRIDE unset | Matches upstream dots-hyprland and allows KDE platform theme (QT_QPA_PLATFORMTHEME=kde) and kdeglobals to control Qt widget styles without hardcoding overrides. | ✓ |
| Set QT_STYLE_OVERRIDE=kvantum | Force all Qt apps to use Kvantum engine directly. | |

**User's choice:** Leave QT_STYLE_OVERRIDE unset.

| Option | Description | Selected |
|--------|-------------|----------|
| Assert QT_QPA_PLATFORMTHEME=kde in test harness | Verify that env.lua sets QT_QPA_PLATFORMTHEME to 'kde', guaranteeing Qt apps query kdeglobals rather than qt5ct/qt6ct. | ✓ |
| Do not check env vars in harness | Rely solely on upstream file integrity. | |

**User's choice:** Assert QT_QPA_PLATFORMTHEME=kde in test harness.

| Option | Description | Selected |
|--------|-------------|----------|
| Assert QT_QPA_PLATFORM='wayland;xcb' in test harness | Verify both QT_QPA_PLATFORMTHEME and QT_QPA_PLATFORM in env.lua to ensure native Wayland execution alongside KDE theming. | ✓ |
| Check only QT_QPA_PLATFORMTHEME | Focus solely on theming variable. | |

**User's choice:** Assert QT_QPA_PLATFORM='wayland;xcb' in test harness.

---

## the agent's Discretion

- Choice of wallpaper test fixture or active wallpaper query during test harness verification of kdeglobals generation.
- Exact test assertion formatting and subshell separation in `scripts/phase26-qt-kde-material-you-assert.sh`.

## Deferred Ideas

- Phase 27: Hyprland active/inactive window borders and Quickshell ii widget accents coordination.
- Phase 28: Fuzzel launcher and terminal emulator dynamic palette generation.
- Phase 29: Theme data contracts reconciliation (`guard-paths.tsv`, `collision-map.tsv`) and `./bootstrap.sh` full integration test.
