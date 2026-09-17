# Phase 27: Hyprland & Quickshell ii Accent Coordination - Context

**Gathered:** 2026-09-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Coordinate Hyprland window decorations, active/inactive borders, and Quickshell ii widget accents with Matugen-generated Material You color palettes and wallpaper reload:

1. **Hyprland Window Decorations & Border Binding (SHELL-01):** Active and inactive window borders, pinned borders, and canvas background bind directly to Matugen `colors.lua` palette tokens (`outline_variant`, `surface_container_low`, `primary`, `surface.dark`).
2. **Quickshell ii Accent Styling (SHELL-02):** Quickshell ii top bar indicators, resource metric rings, workspace pills, sliders, OSD popups, and quick toggles consume Material You palette tokens (`primary`, `secondary`, `tertiary`, `surface`, `error`) from `colors.json`.
3. **Coordinated Reload Pipeline (SHELL-03):** `switchwall.sh` wallpaper switcher triggers a coordinated, non-blocking reload across Hyprland borders, Quickshell, GTK, and Qt with zero visual stutter and 100% git clean working tree.
4. **Phase Test Harness & Strict Verification (INTG-01, INTG-02):** Author `scripts/phase27-accent-coordination-assert.sh` exercising 5 automated fail-closed sections, and ensure `arch/dots-hyprland.sh verify --strict` exits 0 with 0 findings.

Out of scope:
- Fuzzel app launcher theme and terminal emulator dynamic palette reload (Phase 28 owns this).
- Theme data contracts reconciliation (`guard-paths.tsv`, `collision-map.tsv`) and `./bootstrap.sh` full integration testing (Phase 29 owns this).
- Custom Waybar widget ports (v2 requirements).
- Adding personal custom border overrides that deviate from upstream `dots-hyprland`.

</domain>

<decisions>
## Implementation Decisions

### Hyprland Window Decorations & Border Binding (SHELL-01)

- **D-01:** Active border token: Bind `col.active_border` to `outline_variant` with 77% alpha (`rgba({{colors.outline_variant.default.hex_stripped}}77)`), adhering strictly to upstream `dots-hyprland` default design intent.
- **D-02:** Inactive border & shadows: Inactive border bound to `surface_container_low` with 33% alpha (`rgba({{colors.surface_container_low.default.hex_stripped}}33)`); subtle black drop shadows (`rgba(00000020)` with range 20 and render power 10).
- **D-03:** Pinned & group borders: Pinned windows use primary accent gradient (`rgba({{colors.primary.default.hex_stripped}}AA) rgba({{colors.primary.default.hex_stripped}}77)`); window group borders inherit active_border and primary accent for active tab.
- **D-04:** Upstream overlay purity: Zero personal border overrides in `stow/hypr/.config/hypr/custom/general.lua`. `colors.lua` is the sole dynamic authority for window decorations in accordance with the project rule *"everything has to be default dots-hyprland. whatever that is"*.
- **D-05:** Window geometry: Retain upstream default geometry (18px rounding with 2.5 rounding power squircle and 1px border size).
- **D-06:** Dimming & blur: 5% inactive dimming (`dim_strength = 0.05`), 20% special workspace dimming (`dim_special = 0.2`), and 3-pass x-ray blur.
- **D-07:** Border animations: Smooth border transition animation via `emphasizedDecel` bezier curve at speed 10.
- **D-08:** Canvas background: Hyprland canvas background (`misc:background_color`) dynamically bound to `surface.dark` with FF alpha (`rgba({{colors.surface.dark.hex_stripped}}FF)`).
- **D-09:** Window opacity: 1.0 opaque for standard application windows; transparency delegated to terminal/app configurations.
- **D-10:** Gaps spacing: Upstream defaults — `gaps_in = 4`, `gaps_out = 5`, `gaps_workspaces = 50`.
- **D-11:** Floating windows: Floating windows inherit the same 1px border and shadow as tiled windows; pinned floating windows use primary accent gradient.
- **D-12:** Border resizing & snapping: `resize_on_border = true` with edge snapping enabled (`window_gap = 4`, `monitor_gap = 5`).

### Quickshell ii Accent Styling (SHELL-02)

- **D-13:** Palette scheme type: Upstream default `"auto"` (dynamically analyzes wallpaper using `scheme_for_image.py`, falling back to `scheme-tonal-spot`).
- **D-14:** Top bar & metric rings: Normal resource fill and sliders use `m3primary`; active workspace pills use `m3secondary`/`tertiary`; high threshold warnings (CPU > 90%, RAM > 95%, Swap > 85%) switch to `m3error`.
- **D-15:** Background transparency: Retain baseline config (`enable: false`) — opaque `m3surfaceContainer` backgrounds for solid contrast and clean readability.
- **D-16:** In-process dynamic hot-reload: `MaterialThemeLoader.qml` reacts to `colors.json` changes via `FileView` with zero process restarts; runtime state directory remains untracked cache outside git.
- **D-17:** Dark/Light mode sync: Dynamic mode synchronization — `switchwall.sh` follows `gsettings prefer-dark/prefer-light` and updates GTK/Qt/Quickshell in lockstep; keep terminal forced to dark mode per baseline config.
- **D-18:** Top bar icon tinting: `m3onSurfaceVariant` for passive icons, `m3primary` for active toggles and focused workspace pill, spark icon highlighted with `m3primary`.
- **D-19:** Sliders & OSD: `m3primary` fill on `m3surfaceContainerHighest` track with smooth pill animations.
- **D-20:** Action Center quick-toggles: Upstream Android quick-toggle styling — `m3primary` background with `m3onPrimary` text for active toggles, `m3surfaceContainerHigh` for inactive states.

### Coordinated Reload Pipeline (SHELL-03)

- **D-21:** Native inotify Hyprland reload: Empirically proven that Hyprland 0.56 automatically places inotify watches on all files required by `hyprland.lua` (including `colors.lua`). When Matugen updates `colors.lua`, Hyprland re-evaluates border colors live without needing explicit `hyprctl reload` or daemon watchers.
- **D-22:** Execution concurrency: Upstream non-blocking pipeline — Matugen runs synchronously for token generation, then dispatches Qt (`kde-material-you-colors`), terminals, and desktop services in parallel background jobs (`&`) for instant UI response.
- **D-23:** Error handling: Fail-soft per component — non-critical reload failures (e.g. kitty signal when not running, KDE kwin DBus warning) never abort or break the core shell and wallpaper transition.
- **D-24:** Full pipeline parity: All invocation paths (`--noswitch`, `--image`, `--mode`, `--color`) consistently trigger the complete reload pipeline across Hyprland, Quickshell, GTK, and Qt.
- **D-25:** Wallpaper rendering engine: Quickshell ii renders static wallpapers directly via `Config.options.background.wallpaperPath`, with `mpvpaper` automatically spawned for video wallpapers.
- **D-26:** Unified entry point: All wallpaper triggers (shortcuts, random selection, file picker) route exclusively through `switchwall.sh`.
- **D-27:** Session startup: Load persisted theme files on session boot with zero lag; run `switchwall.sh --noswitch` only if generated files are missing.
- **D-28:** Strict zero git churn: Running `switchwall.sh` must leave `git status --porcelain` 100% clean and strictly adhere to `guard-paths.tsv` data contracts.

### Test Harness & Strict Verification (INTG-01, INTG-02)

- **D-29:** 5-section automated test suite: Author `scripts/phase27-accent-coordination-assert.sh` exercising 5 fail-closed sections:
  1. Template & config readiness: verify Matugen templates, `colors.lua`, and `guard-paths.tsv` protection.
  2. Hyprland border token match: query live `hyprctl getoption general:col.active_border` and assert match with `colors.lua` (with headless fallback).
  3. Quickshell token integrity: validate `colors.json` non-empty JSON, presence of primary/secondary/surface/error/outline tokens, and `#RRGGBB` format.
  4. Live coordinated reload probe: execute `switchwall.sh --noswitch`, assert mtime advancement on `colors.lua` and `colors.json`, and verify border sync.
  5. Strict verification & zero git drift: assert `arch/dots-hyprland.sh verify --strict` reports `FAIL=0 FINDINGS=0` and `git status --porcelain` is clean.
- **D-30:** Live compositor probe: Live `hyprctl` queries check runtime state when `HYPRLAND_INSTANCE_SIGNATURE` is set, with graceful fallback to static file validation in headless environments.
- **D-31:** Quickshell token schema assertion: Programmatically validate `primary`, `secondary`, `surface`, `error`, and `outline_variant` keys in `colors.json`.
- **D-32:** Live reload drill: Use recorded pre-run mtimes to ensure live generation occurred.

### the agent's Discretion

- Choice of wallpaper test fixtures for `--noswitch` drill during test harness verification.
- Internal test assertion formatting and section headers in `scripts/phase27-accent-coordination-assert.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` §Phase 27 — goal statement, requirements, 3 success criteria
- `.planning/REQUIREMENTS.md` lines 12–16 — SHELL-01, SHELL-02, SHELL-03 specifications
- `.planning/STATE.md` §Milestone v0.5 — current project state and accumulated decisions

### Data Contracts and Guard Status
- `guard-paths.tsv` line 19 — `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` guarded as `generated_theme`
- `collision-map.tsv` line 14 — `$XDG_CONFIG_HOME/matugen` tracked as restow
- `capture/ii/.config/illogical-impulse/config.json` — adopted baseline for Quickshell appearance and bar configuration

### Hyprland Window Borders & Colors
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` line 18 — `require("hyprland.colors")`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua` lines 56–59 — `col.active_border` and `col.inactive_border`
- `vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua` — upstream Matugen template for borders and background
- `~/.config/hypr/hyprland/colors.lua` — live generated Hyprland colors configuration
- `stow/hypr/.config/hypr/custom/general.lua` — personal monitor/workspace layout overlay

### Quickshell Theming & Wallpaper Pipeline
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml` — in-process theme watcher for `colors.json`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` — M3 palette singleton and transparency calculations
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh` — central wallpaper switcher and reload orchestrator
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh` — terminal and color sequence dispatcher
- `~/.local/state/quickshell/user/generated/colors.json` — live M3 color tokens consumed by Quickshell

### Verification Engine & Existing Test Harnesses
- `arch/dots-hyprland.sh` lines 1120–1385 — `run_verify`, guard path checks, and live sweep
- `scripts/phase25-gtk-material-you-assert.sh` — Phase 25 model test harness
- `scripts/phase26-qt-kde-material-you-assert.sh` — Phase 26 model test harness

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `~/.config/quickshell/ii/scripts/colors/switchwall.sh`: Established orchestrator for wallpaper changes and palette generation.
- `~/.config/quickshell/ii/services/MaterialThemeLoader.qml`: Reactive QML singleton reloading `colors.json` automatically.
- `hyprctl getoption general:col.active_border`: Fast CLI tool querying live compositor border state.
- `arch/dots-hyprland.sh verify --strict`: Verification watchdog reporting 0 findings on clean state.

### Established Patterns
- **Empirical Inotify Reactivity:** Hyprland automatically monitors `colors.lua` via inotify watches established during `hyprland.lua` evaluation, eliminating the need for external reload signals or daemons.
- **Purity of Upstream Defaults:** Zero personal overrides in `stow/hypr/custom/` for properties governed dynamically by upstream (`colors.lua`).
- **Zero Drift Invariant:** Repository working tree must remain clean (`git status --porcelain` empty); all generated theme files must be guarded in `guard-paths.tsv` or stored under `$XDG_STATE_HOME`.

### Integration Points
- `~/.config/matugen/config.toml` -> Generates `colors.lua` (read by Hyprland) and `colors.json` (read by Quickshell).
- `~/.config/hypr/hyprland/colors.lua` -> Generated by Matugen, watched by Hyprland inotify, sets `col.active_border`.
- `~/.local/state/quickshell/user/generated/colors.json` -> Generated by Matugen, watched by `MaterialThemeLoader.qml`, populates `Appearance.m3colors`.
- `guard-paths.tsv` -> Guards `colors.lua` from repository churn.

</code_context>

<specifics>
## Specific Ideas

- **Native Inotify Reloading Discovery:** During rigorous empirical probing, we discovered that Hyprland 0.56's Lua configuration engine automatically places inotify watches on all files required by `hyprland.lua`. Touching or rewriting `colors.lua` immediately updates the live border gradient without requiring an external `hyprctl reload` call.
- **Fail-Soft Pipeline:** Individual reloader errors (such as Kitty signals when no terminal is open or KWin DBus notices on Hyprland) are safely absorbed without breaking wallpaper switching or core desktop shell styling.

</specifics>

<deferred>
## Deferred Ideas

- Phase 28: Fuzzel launcher and terminal emulator dynamic palette generation (`fuzzel_theme.ini`, kitty/foot/alacritty).
- Phase 29: Theme data contracts reconciliation (`guard-paths.tsv`, `collision-map.tsv`) and `./bootstrap.sh` full integration run.
- v2 Milestone: Waybar custom widget ports (ping, weather, earthquake).

</deferred>

---

*Phase: 27-hyprland-quickshell-ii-accent-coordination*
*Context gathered: 2026-09-17*
