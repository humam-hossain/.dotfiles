# Phase 27: Hyprland & Quickshell ii Accent Coordination - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-17
**Phase:** 27-hyprland-quickshell-ii-accent-coordination
**Areas discussed:** Hyprland Window Decorations & Border Binding, Quickshell ii Accent Styling, Coordinated Reload Pipeline, Test Harness & Strict Verification

---

## Hyprland Window Decorations & Border Binding

| Question | Options Presented | Selected | Notes |
|----------|-------------------|----------|-------|
| Active border color token | 1. Follow upstream dots-hyprland default (outline_variant @ 77%)<br>2. Bind directly to primary accent<br>3. Dual-tone gradient | Follow upstream default (outline_variant @ 77%) | Clean, subtle, matches upstream design intent |
| Inactive borders and window shadows | 1. Upstream default (surface_container_low @ 33% with subtle drop shadow)<br>2. Zero-alpha inactive borders<br>3. Tinted shadows matching palette | Upstream default | Preserves standard drop shadow and subtle border |
| Pinned and grouped window borders | 1. Upstream standard (pinned uses primary gradient; groups inherit active_border + primary)<br>2. Distinct secondary/tertiary tokens<br>3. Builder discretion | Upstream standard | Keeps window rules uniform with dots-hyprland |
| Interaction with personal custom overlays | 1. Zero personal border overrides in custom/general.lua<br>2. Fallback border variables<br>3. Builder discretion | Write-in: "everything default dots-hyprland behavior" | Core project rule affirmed; colors.lua is sole authority |
| Window geometry and squircle rounding | 1. Retain upstream default (18px rounding, 2.5 power, 1px border)<br>2. Square corners (0px)<br>3. 2px border thickness | Retain upstream default geometry | Retains smooth squircle aesthetics |
| Inactive dimming and background blur | 1. Retain upstream defaults (5% dim, 20% special dim, 3-pass blur)<br>2. Disable inactive dimming<br>3. Builder discretion | Retain upstream defaults | Balances focus clarity with contrast |
| Border focus transition animation | 1. Upstream default animation (emphasizedDecel @ speed 10)<br>2. Instant transition<br>3. Builder discretion | Upstream default animation | Smooth visual feedback when changing window focus |
| Canvas background color | 1. Upstream dynamic binding (surface.dark @ FF)<br>2. Pure solid black<br>3. Builder discretion | Upstream dynamic binding | Harmonizes workspace transitions with wallpaper tone |
| Window opacity | 1. Upstream default (1.0 opaque, app-specific transparency)<br>2. Slight global inactive opacity<br>3. Builder discretion | Upstream default | Leaves opacity to app layers (kitty, quickshell) |
| Gaps configuration | 1. Upstream defaults (gaps_in: 4, gaps_out: 5, workspaces: 50)<br>2. Zero outer gaps<br>3. Larger gaps | Upstream defaults | Clean spacing aligned with top bar margin |
| Floating window borders | 1. Upstream standard (same 1px border and shadow as tiled)<br>2. Distinct 2px border<br>3. Builder discretion | Upstream standard | Unified decoration rules |
| Border resize and snapping | 1. Upstream defaults (resize_on_border: true, snap: true)<br>2. Disable resize on border<br>3. Builder discretion | Upstream defaults | Preserves mouse edge grab and edge snapping |

---

## Quickshell ii Accent Styling

| Question | Options Presented | Selected | Notes |
|----------|-------------------|----------|-------|
| Material You scheme type | 1. Upstream default "auto" (dynamic detection via scheme_for_image.py)<br>2. Fixed "scheme-tonal-spot"<br>3. Fixed "scheme-expressive" | Upstream default "auto" | Dynamically selects optimal scheme per wallpaper |
| Top bar indicators and metric rings | 1. Upstream default mapping (primary for metric fill/sliders, secondary/tertiary for workspaces, error on thresholds)<br>2. Monochrome accents<br>3. Builder discretion | Upstream default mapping | Distinct indicator semantics with error alerts |
| Background transparency | 1. Retain baseline config (enable: false, opaque surfaceContainer)<br>2. Enable dynamic transparency<br>3. Builder discretion | Retain baseline config (enable: false) | High contrast, solid readability |
| Token consumption and reload | 1. In-process dynamic hot-reload via MaterialThemeLoader.qml FileView<br>2. Dual reload trigger with IPC signal<br>3. Builder discretion | In-process dynamic hot-reload | Zero process restarts needed |
| Dark / Light mode synchronization | 1. Dynamic mode synchronization (switchwall.sh follows gsettings, terminal forced dark)<br>2. Strict dark mode lock<br>3. Builder discretion | Dynamic mode synchronization | Follows GNOME/GTK preference while keeping terminal dark |
| Top bar icons and utility buttons | 1. Upstream standard tinting (onSurfaceVariant passive, primary active, spark primary)<br>2. Full-color app icons<br>3. Builder discretion | Upstream standard tinting | Consistent system bar visual hierarchy |
| OSD popups and sliders | 1. Upstream standard (primary fill on surfaceContainerHighest track)<br>2. Multi-color accents<br>3. Builder discretion | Upstream standard | Smooth animated pill indicators |
| Action Center quick-toggles | 1. Upstream Android quick-toggle styling (primary active, surfaceContainerHigh inactive)<br>2. Flat outline style<br>3. Builder discretion | Upstream Android quick-toggle styling | Standard Material 3 toggle affordance |

---

## Coordinated Reload Pipeline

| Question | Options Presented | Selected | Notes |
|----------|-------------------|----------|-------|
| Hyprland border reload trigger | 1. Coordinated background reload<br>2. Passive file write only<br>3. Builder discretion | Coordinated reload | Empirically verified: Hyprland inotify reloads colors.lua automatically upon write |
| Execution concurrency model | 1. Upstream non-blocking pipeline (Matugen sync, background jobs for Qt/terminals)<br>2. Strict sequential execution<br>3. Builder discretion | Upstream non-blocking pipeline | Instant UI response without blocking UI |
| Error handling during reload | 1. Fail-soft per component (kitty/kwin warnings do not abort shell)<br>2. Fail-closed with desktop alert<br>3. Builder discretion | Fail-soft per component | Robust wallpaper switching |
| Invocation modes parity | 1. Full pipeline parity across all flags (--noswitch, --image, --mode, --color)<br>2. Selective reloading<br>3. Builder discretion | Full pipeline parity | Consistent desktop state across all triggers |
| Desktop wallpaper rendering engine | 1. Upstream Quickshell background engine (mpvpaper for video)<br>2. Dual engine with hyprpaper<br>3. Builder discretion | Upstream Quickshell engine | Direct QML wallpaper binding |
| Wallpaper switching entry points | 1. Single entry point via switchwall.sh<br>2. Optional lightweight bypass<br>3. Builder discretion | Single entry point via switchwall.sh | Ensures palettes never fall out of sync |
| Session startup behavior | 1. Instant startup from persisted disk files<br>2. Force regeneration on every login<br>3. Builder discretion | Instant startup from persisted disk files | Zero login delay |
| Repository integrity and git churn | 1. Strict zero git churn invariant (git status clean, guard-paths satisfied)<br>2. Permissive tracking<br>3. Builder discretion | Strict zero git churn invariant | Verified with FAIL=0 FINDINGS=0 on verify --strict |

---

## Test Harness & Strict Verification

| Question | Options Presented | Selected | Notes |
|----------|-------------------|----------|-------|
| Test harness scope and sections | 1. 5-section automated test suite<br>2. Minimal assert script<br>3. Builder discretion | 5-section automated test suite | Follows Phase 25 and 26 test harness conventions |
| Hyprland border verification | 1. Live compositor probe with headless fallback<br>2. Static file assert only<br>3. Builder discretion | Live compositor probe with headless fallback | Confirms runtime compositor state matches colors.lua |
| Quickshell colors.json assertions | 1. Comprehensive token validation (non-empty, valid JSON, required tokens, hex format)<br>2. Simple presence check<br>3. Builder discretion | Comprehensive token validation | Strict schema checking |
| Coordinated reload live probe | 1. Live reload drill (switchwall.sh --noswitch mtime advance + clean git)<br>2. Static inspection only<br>3. Builder discretion | Live reload drill | Empirically proves reload pipeline end-to-end |

---

## Builder's Discretion

- Choice of wallpaper test fixtures for `--noswitch` drill in test harness.
- Internal test assertion formatting and section headers in `scripts/phase27-accent-coordination-assert.sh`.

## Deferred Ideas

- Phase 28: Fuzzel launcher and terminal emulator dynamic palette generation.
- Phase 29: Theme data contracts reconciliation (`guard-paths.tsv`, `collision-map.tsv`) and `./bootstrap.sh` full integration test.
- v2 Milestone: Waybar custom widget ports (ping, weather, earthquake).
