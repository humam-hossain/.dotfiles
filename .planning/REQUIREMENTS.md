# Requirements: Quickshell Desktop Shell (v0.6)

**Defined:** 2026-09-20  
**Core Value:** Desktop capability via upstream dots-hyprland + personal overlays with unified system-wide Material You theming across GTK, Qt/KDE, Hyprland, Quickshell ii, and terminal/launcher tools with zero git churn.

## v1 Requirements

### Overlay & Pill Foundation

- [x] **PILL-01**: User has a dedicated personal Quickshell overlay under `restow/quickshell/` that hot-reloads live on save without modifying `vendor/dots-hyprland`.
- [x] **PILL-02**: User sees all bar groups/pills rendered with modern rounded rectangle geometry (12–16px corner radius).
- [x] **PILL-03**: User sees consistent, balanced internal padding (4–6px) and configurable vertical/horizontal margins across all pill containers.
- [x] **PILL-04**: User can toggle subtle pill borders or transparent/borderless container backgrounds via bar configuration.

### Component Representation & Formatting Customization

- [ ] **COMP-01**: User can view memory usage formatted as definite gigabytes used out of total gigabytes (`X.X GB / Y.Y GB`) instead of a simple percentage.
- [ ] **COMP-02**: User can view CPU usage with custom formatting, warning thresholds, and clean visual indicators.
- [ ] **COMP-03**: User can configure Clock & Date widget representation, date pattern, and 12h/24h formats via native configuration.
- [ ] **COMP-04**: User can view Media Player pill with track title, playback controls, and volume/seek scroll actions.
- [ ] **COMP-05**: User can view Weather pill displaying temperature, conditions glyph, and interactive weather forecast popup.
- [ ] **COMP-06**: User can access Utility buttons pill providing shortcuts for Screen Snip, Color Picker, and Power menu.
- [ ] **COMP-07**: User can view pending Pacman and AUR package updates count via a dedicated status pill.
- [ ] **COMP-08**: User can view Privacy in-use alerts whenever the microphone, camera, or screen recording is actively capturing.
- [ ] **COMP-09**: User can interact with System Tray icons and context menus with balanced icon spacing and padding.
- [ ] **COMP-10**: User can view audio/mic mute states, network connectivity, bluetooth status, and unread notification counter.

### Modular Layout & Live Trial-and-Error

- [ ] **LAYOUT-01**: User can modularly place, reorder, or swap components across Left, Center, and Right bar sections in `BarContent.qml`.
- [ ] **LAYOUT-02**: User can evaluate candidate arrangements live (e.g. Workspaces & Weather in center, Clock & Utilities on left, Media & Resources & Tray on right) on active monitors (`DP-1` and `HDMI-A-1`).
- [ ] **LAYOUT-03**: User can view responsive scaling across dual monitors with no component clipping or awkward line wrapping.

### Integration & Verification

- [ ] **INTG-01**: Dynamic Material You palette changes via wallpaper switch (`switchwall.sh`) cleanly tint all customized pills and components with zero visual defects.
- [ ] **INTG-02**: Repository state passes `arch/dots-hyprland.sh verify --strict` with 0 findings and zero working tree drift.
- [ ] **INTG-03**: Fresh-machine bootstrap (`./bootstrap.sh`) deploys the customized bar and pill configurations cleanly.

## v2 Requirements

### Advanced Telemetry & Enhancements

- **TEL-01**: Custom procfs/statvfs disk usage monitoring pill with partition popup.
- **TEL-02**: Custom ping latency telemetry daemon and local web dashboard launcher.
- **TEL-03**: Multi-day forecast card arrays in weather popup.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Brand-new background daemons (e.g. ping/disk/net speed) | Focus is on existing dots-hyprland components, pill dimensions/padding, and formatting |
| Full QML shell rewrite | Upstream dots-hyprland (`ii`) remains the managed base; customizations ride strictly as personal overlays |
| Waybar restoration | Waybar is permanently retired in favor of Quickshell |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PILL-01 | Phase 31 | Complete |
| PILL-02 | Phase 31 | Complete |
| PILL-03 | Phase 31 | Complete |
| PILL-04 | Phase 31 | Complete |
| COMP-01 | Phase 32 | Pending |
| COMP-02 | Phase 32 | Pending |
| COMP-03 | Phase 32 | Pending |
| COMP-04 | Phase 32 | Pending |
| COMP-05 | Phase 32 | Pending |
| COMP-06 | Phase 32 | Pending |
| COMP-07 | Phase 32 | Pending |
| COMP-08 | Phase 32 | Pending |
| COMP-09 | Phase 32 | Pending |
| COMP-10 | Phase 32 | Pending |
| LAYOUT-01 | Phase 33 | Pending |
| LAYOUT-02 | Phase 33 | Pending |
| LAYOUT-03 | Phase 33 | Pending |
| INTG-01 | Phase 34 | Pending |
| INTG-02 | Phase 34 | Pending |
| INTG-03 | Phase 34 | Pending |

**Coverage:**

- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-20*
*Last updated: 2026-09-20 after initial definition*
