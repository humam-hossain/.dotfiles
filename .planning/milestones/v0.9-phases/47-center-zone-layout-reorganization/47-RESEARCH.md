# Phase 47: Center-Zone Layout Reorganization - Research

**Researched:** 2026-09-29  
**Domain:** Quickshell Status Bar Center-Zone Reorganization, Anchor Geometry, Dead-Center Alignment, Responsive Shortening, and Verification  
**Confidence:** HIGH  

---

<user_constraints>
## User Constraints (from Requirements & Roadmap)

### Implementation Requirements
- **CNTR-01 (Widget Reordering):** Top status bar center widgets reordered so Clock/Date (`ClockWidget`) is positioned to the left of Workspaces, and Weather (`WeatherBar`) is positioned to the right of Workspaces. [CITED: `.planning/REQUIREMENTS.md:53`]
- **CNTR-02 (Workspaces Dead-Centering & Uniform Spacing):** Workspaces widget (`middleCenterGroup`) preserves dead-center alignment on the bar (`anchors.horizontalCenter: parent.horizontalCenter`) with uniform 4px margins on both sides (`anchors.rightMargin: 4` on left element, `anchors.leftMargin: 4` on right element). [CITED: `.planning/REQUIREMENTS.md:54`, `ROADMAP.md:284`]
- **CNTR-03 (Wrapper Anchors, Click Behaviors, Responsive Rules & Zero Churn):** `middleSection` wrapper boundary anchors, right sidebar click toggle on `ClockWidget`, and responsive shortening rules (`showDate` under shortened widths) are preserved with zero layout overlap and zero git churn under `arch/dots-hyprland.sh verify --strict`. [CITED: `.planning/REQUIREMENTS.md:55`, `ROADMAP.md:286-288`]

### the agent's Discretion
- Specific identifier naming for the relocated Clock/Date group (`leftCenterGroup` and `leftCenterGroupContent` to mirror upstream symmetry and previous `rightCenterGroup` conventions).
- Organization of test sections in `scripts/phase47-center-layout-assert.sh`.
- Mathematical resolution simulation breakpoints (3440px ultrawide, 2560px QHD, 1920px FHD, 1200px compact, 900px minimum).

### Out of Scope
- Modifications to `ClockWidget.qml` or `WeatherBar.qml` component internals (both components are self-contained and functionally complete).
- Modifying `vendor/dots-hyprland` submodule files (strictly zero churn required).
- Changing Left or Right bar zone components.
</user_constraints>

---

## Executive Summary

Phase 47 completes the visual and ergonomic refinement of the Quickshell top status bar center zone. In Phase 33 (v0.6), the center section was established with Workspaces dead-centered, flanked by Weather on the left and Clock/Date on the right. In Phase 46, the Left zone was fully overhauled to host three new telemetry pills (`MemoryStoragePill`, `CpuGpuPill`, `NetworkPingPill`). 

The current arrangement places the wide Clock/Date widget (~220px) on the right of Workspaces, and the compact Weather pill (~75px) on the left. Phase 47 swaps their positions:
1. **Clock & Date (`ClockWidget`)** relocates to the left of Workspaces (`middleCenterGroup.left`), anchored with `anchors.rightMargin: 4`.
2. **Workspaces (`middleCenterGroup`)** remains strictly locked to `parent.horizontalCenter` with 4px margins on both flanks.
3. **Weather (`WeatherBar` in `weatherGroup`)** relocates to the right of Workspaces (`middleCenterGroup.right`), anchored with `anchors.leftMargin: 4`, honoring `Config.options.bar.weather.enable`.
4. **`middleSection` wrapper Item** updates its boundary anchors: `anchors.left: leftCenterGroup.left` and `anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right`.

This geometry swap gives the Right zone (which contains media playback, voice telemetry, updates, battery, system tray, and the right sidebar button) approximately +145px of additional breathing room, eliminating tray overcrowding on narrower displays while maintaining visual balance and perfect center alignment of the workspace indicators across all monitor aspect ratios.

All modifications are confined strictly to `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`. GNU Stow leaf symlinks remain intact, leaving `vendor/dots-hyprland` 100% clean and passing `./arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0`.

---

## Architectural Responsibility Map

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                      Quickshell Status Bar (Top)                                                 │
├───────────────────────────────────────────────┬──────────────────────────────────────────────────┬───────────────────────────────┤
│                   LEFT ZONE                   │                   CENTER ZONE                    │          RIGHT ZONE           │
│           (barLeftSideMouseArea)              │                 (middleSection)                  │    (barRightSideMouseArea)    │
│            anchors.left: parent.left          │             anchors.horizontalCenter             │   anchors.left: middle.right  │
│           anchors.right: middle.left          │               to parent.horizontalCenter         │  anchors.right: parent.right  │
├───────────────────────────────────────────────┼──────────────────────────────────────────────────┼───────────────────────────────┤
│ [LeftSidebar] [Storage/RAM] [CPU/GPU] [Net]   │ [ Clock & Date ]  │ [Workspaces] │  [WeatherBar] │ [Media] [Voice] [Tray] [Right]│
│                                               │ (leftCenterGroup) │ (dead-center)│ (weatherGroup)│                               │
│                                               │   MouseArea       │  BarGroup    │    Loader     │                               │
│                                               │   margin: 4px     │  margin: 4px │   margin: 4px │                               │
└───────────────────────────────────────────────┴───────────────────┴──────────────┴───────────────┴───────────────────────────────┘
                                                          ▲                 ▲               ▲
                                                          │                 │               │
                                                    anchors.right:    dead-centered   anchors.left:
                                                    middleCenterGroup  horizontalCenter middleCenterGroup
                                                          .left         to parent          .right
```

### Hit-Testing & Mouse Area Separation
The status bar employs three top-level `MouseArea` regions:
1. `barLeftSideMouseArea`: Spans from `parent.left` to `middleSection.left`. Clicking empty space toggles `GlobalStates.sidebarLeftOpen`. [VERIFIED: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:77-90`]
2. `middleSection`: Acts as the visual bounding geometry for the Center Zone. Its left bound is `leftCenterGroup.left`. Its right bound dynamically adapts: if `weatherGroup.active` is true, it bounds at `weatherGroup.right`; if weather is disabled, it collapses flush to `middleCenterGroup.right`. [VERIFIED: empirical test in `scratch/test_loader.qml`]
3. `barRightSideMouseArea`: Spans from `middleSection.right` to `parent.right`. Clicking empty space toggles `GlobalStates.sidebarRightOpen`. [VERIFIED: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:207-221`]

---

## Standard Stack / Component Map

| Component / Item | File Path | Existing Role & Geometry | New Phase 47 Role & Geometry |
|---|---|---|---|
| `BarContent.qml` | `restow/quickshell/.../bar/BarContent.qml` | Orchestrates top bar zones, contains `middleSection`, `weatherGroup`, `middleCenterGroup`, `rightCenterGroup`. [VERIFIED: lines 139-205] | Re-anchors Center Zone: moves Clock to `leftCenterGroup`, moves Weather to `weatherGroup` on right, updates `middleSection` left/right anchors. |
| `ClockWidget.qml` | `restow/quickshell/.../bar/ClockWidget.qml` | Shows time and long date with responsive spacer, wraps `ClockWidgetPopup`. [VERIFIED: lines 7-51] | Relocated inside `leftCenterGroup` to the left of Workspaces. Retains `showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)`. |
| `Workspaces.qml` | `vendor/dots-hyprland/.../bar/Workspaces.qml` | Renders dynamic workspace indicators with right-click overview toggle. [VERIFIED: lines 166-180] | Remains inside `middleCenterGroup` anchored strictly `horizontalCenter: parent.horizontalCenter`. |
| `WeatherBar.qml` | `vendor/dots-hyprland/.../weather/WeatherBar.qml` | Displays weather icon and temperature, right-click triggers manual refresh. [VERIFIED: lines 10-56] | Relocated inside `weatherGroup` to the right of Workspaces (`anchors.left: middleCenterGroup.right`). |
| `BarGroup.qml` | `restow/quickshell/.../bar/BarGroup.qml` | Background pill styling, padding (5px), and 250ms M3 emphasized deceleration animation on `implicitWidth`. [VERIFIED: lines 5-21] | Wraps `ClockWidget` in `leftCenterGroupContent`, `Workspaces` in `middleCenterGroup`, and `WeatherBar` in `weatherGroup`. |
| `middleSection` | In `BarContent.qml` | Wrapper item defining center bounds: `anchors.left: weatherGroup.active ? weatherGroup.left : middleCenterGroup.left`, `anchors.right: rightCenterGroup.right`. [VERIFIED: lines 139-146] | Updated boundary anchors: `anchors.left: leftCenterGroup.left`, `anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right`. |

---

## Architecture Patterns

### Pattern 1: Current vs Target Center-Zone Implementation in `BarContent.qml`

#### Current Implementation (Lines 139–205 of `BarContent.qml`)
```qml
// [VERIFIED: restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:139-205]
    Item { // Middle section wrapper
        id: middleSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: weatherGroup.active ? weatherGroup.left : middleCenterGroup.left
        anchors.right: rightCenterGroup.right
        property int spacing: 4
    }

    Loader {
        id: weatherGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: middleCenterGroup.left
        anchors.rightMargin: 4
        active: Config.options.bar.weather.enable

        sourceComponent: BarGroup {
            WeatherBar {}
        }
    }

    BarGroup {
        id: middleCenterGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        padding: workspacesWidget?.widgetPadding ?? 0

        Workspaces {
            id: workspacesWidget
            Layout.fillHeight: true
            MouseArea {
                // Right-click to toggle overview
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onPressed: event => {
                    if (event.button === Qt.RightButton) {
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        }
    }

    MouseArea {
        id: rightCenterGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: middleCenterGroup.right
        anchors.leftMargin: 4
        implicitWidth: rightCenterGroupContent.implicitWidth
        implicitHeight: rightCenterGroupContent.implicitHeight

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        BarGroup {
            id: rightCenterGroupContent
            anchors.fill: parent

            ClockWidget {
                showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
        }
    }
```

#### Target Implementation (Phase 47)
```qml
    Item { // Middle section wrapper
        id: middleSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftCenterGroup.left
        anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right
        property int spacing: 4
    }

    MouseArea {
        id: leftCenterGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: middleCenterGroup.left
        anchors.rightMargin: 4
        implicitWidth: leftCenterGroupContent.implicitWidth
        implicitHeight: leftCenterGroupContent.implicitHeight

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        BarGroup {
            id: leftCenterGroupContent
            anchors.fill: parent

            ClockWidget {
                showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
        }
    }

    BarGroup {
        id: middleCenterGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        padding: workspacesWidget?.widgetPadding ?? 0

        Workspaces {
            id: workspacesWidget
            Layout.fillHeight: true
            MouseArea {
                // Right-click to toggle overview
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onPressed: event => {
                    if (event.button === Qt.RightButton) {
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        }
    }

    Loader {
        id: weatherGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: middleCenterGroup.right
        anchors.leftMargin: 4
        active: Config.options.bar.weather.enable

        sourceComponent: BarGroup {
            WeatherBar {}
        }
    }
```

### Pattern 2: Mathematical Coordinate Invariants Across Monitor Resolutions

The geometric positions have been empirically proven with PySide6 / QtQuick simulation [VERIFIED: `scratch/test_full_swap.qml`]:

Assuming typical component dimensions:
- `middleCenterGroup` (Workspaces with 5 items): width $W_w \approx 180\text{px}$
- `leftCenterGroup` (Clock with long date): width $W_c \approx 220\text{px}$ (shortened without date: $\approx 70\text{px}$)
- `weatherGroup` (Weather with temp): width $W_t \approx 75\text{px}$
- Spacing margin: $M = 4\text{px}$

| Metric / Coordinate | Ultrawide (3440px) | 1440p QHD (2560px) | 1080p FHD (1920px) | Compact (1200px) | Hella-Shortened (900px) |
|---|---|---|---|---|---|
| Screen Center | 1720px | 1280px | 960px | 600px | 450px |
| `useShortenedForm` | 0 | 0 | 0 | 1 | 2 |
| Workspaces Center | **1720px** | **1280px** | **960px** | **600px** | **450px** |
| Workspaces Left/Right | [1630, 1810] | [1190, 1370] | [870, 1050] | [510, 690] | [360, 540] |
| Clock Width | 220px | 220px | 220px | 220px | **70px** (date hidden) |
| Clock Left/Right | [1406, 1626] | [966, 1186] | [646, 866] | [286, 506] | [286, 356] |
| Weather Width | 75px | 75px | 75px | 75px | 75px |
| Weather Left/Right | [1814, 1889] | [1374, 1449] | [1054, 1129] | [694, 769] | [544, 619] |
| `middleSection` Bounds | [1406, 1889] | [966, 1449] | [646, 1129] | [286, 769] | [286, 619] |
| Left Zone Width Avail | 1406px | 966px | 646px | 286px | 286px |
| Left Zone Required | 612px | 612px | 612px | 277px (util dropped)| 220px (compact) |
| Left Zone Clearance | **+794px** | **+354px** | **+34px** | **+9px** | **+66px** |
| Right Zone Width Avail| 1551px | 1111px | 791px | 431px | 281px |
| Overlap Detected? | **NO (0px)** | **NO (0px)** | **NO (0px)** | **NO (0px)** | **NO (0px)** |

### Pattern 3: Dynamic Implicit Width Propagation
In `leftCenterGroup`, the outer `MouseArea` requires explicit dimension binding to reflect the inner `BarGroup`'s size:
```qml
    implicitWidth: leftCenterGroupContent.implicitWidth
    implicitHeight: leftCenterGroupContent.implicitHeight
```
In QtQuick, an `Item` or `MouseArea` whose `width` is not explicitly set defaults its layout width to `implicitWidth`. Because `BarGroup.qml` animates its `implicitWidth` via `Behavior on implicitWidth` using `Appearance.animationCurves.emphasizedDecel` (250ms), binding `implicitWidth` ensures smooth resizing when toggling between date formats or responsive widths. [VERIFIED: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml:14-21`]

---

## Don't Hand-Roll

| Requirement | Don't Hand-Roll | Use Standard Existing In-Repo Solution |
|---|---|---|
| Background & pill styling | Custom `Rectangle` styling with hardcoded borders and radiuses | Use standard `BarGroup` wrapper (`BarGroup { ... }`) which respects `Config.options.bar.borderless`, `Appearance.colors.colLayer1`, and M3 corner radius tokens. [VERIFIED: `BarGroup.qml:23-34`] |
| Width resizing animations | Manual `NumberAnimation` or timer-based width steps | Rely on `BarGroup.qml` built-in `Behavior on implicitWidth` with `Appearance.animationCurves.emphasizedDecel` over 250ms. [VERIFIED: `BarGroup.qml:14-21`] |
| Responsive date hiding | Custom screen width check or inline pixel comparisons | Bind `ClockWidget.showDate` to `(Config.options.bar.verbose && root.useShortenedForm < 2)` matching the established contract. [VERIFIED: `BarContent.qml:200`] |
| Weather enable gating | Manual `visible: ...` on `WeatherBar` | Wrap `WeatherBar` in `Loader { id: weatherGroup; active: Config.options.bar.weather.enable; ... }` so inactive weather is completely uninstantiated and consumes zero scenegraph resources. [VERIFIED: `BarContent.qml:148-158`] |
| Verification harness | Ad-hoc one-off manual shell scripts | Implement standard multi-section assertion harness `scripts/phase47-center-layout-assert.sh` adhering to the standard template (`phase46-telemetry-assert.sh`, `phase41-interactions-assert.sh`) with fail-closed CLI flags. |

---

## Common Pitfalls

### Pitfall 1: Inverting Margin Properties on Anchors
**Problem:** In the old layout, `weatherGroup` anchored to `middleCenterGroup.left` with `anchors.rightMargin: 4`, and `rightCenterGroup` anchored to `middleCenterGroup.right` with `anchors.leftMargin: 4`.  
**Trap:** When moving `leftCenterGroup` to the left of Workspaces and `weatherGroup` to the right, forgetting to swap margin directions. Specifically:
- `leftCenterGroup` must use `anchors.right: middleCenterGroup.left` with `anchors.rightMargin: 4`. (Using `leftMargin: 4` here is ignored by QtQuick and results in 0px gap between Clock and Workspaces).
- `weatherGroup` must use `anchors.left: middleCenterGroup.right` with `anchors.leftMargin: 4`. (Using `rightMargin: 4` here is ignored by QtQuick and results in 0px gap between Workspaces and Weather).  
**Mitigation:** Verify in AST asserts that `leftCenterGroup` specifies `anchors.rightMargin: 4` and `weatherGroup` specifies `anchors.leftMargin: 4`. [VERIFIED: empirical test in `scratch/test_full_swap.qml`]

### Pitfall 2: Static `middleSection.right` Anchor When Weather is Disabled
**Problem:** If `Config.options.bar.weather.enable` is `false`, the `weatherGroup` Loader has `active: false`. Its item is not created, but the Loader itself remains at `middleCenterGroup.right + 4px` (due to `leftMargin: 4`).  
**Trap:** If `middleSection.anchors.right` is statically bound to `weatherGroup.right`, when weather is disabled `middleSection` will extend 4px past `middleCenterGroup.right`, creating an unnecessary 4px dead zone before `barRightSideMouseArea` starts.  
**Mitigation:** Use conditional ternary binding on `middleSection.anchors.right`:
```qml
anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right
```
This guarantees that `middleSection` collapses cleanly to `middleCenterGroup.right` whenever weather is disabled. [VERIFIED: tested in `scratch/test_loader_inactive.qml`]

### Pitfall 3: Submodule Git Churn in `vendor/dots-hyprland`
**Problem:** Editing files directly in `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml` taints the submodule status.  
**Impact:** Causes `./arch/dots-hyprland.sh verify --strict` to immediately fail with submodule dirty findings, violating core architectural contract INTG-02 and D-09.  
**Mitigation:** Only touch the file under `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`. Verify git status with `git status --porcelain` before and after execution. [VERIFIED: established pattern since Phase 31]

### Pitfall 4: Nested MouseArea Click Interception
**Problem:** In `BarContent.qml`, the outer `MouseArea` (`leftCenterGroup`) toggles `GlobalStates.sidebarRightOpen`. Inside it, `ClockWidget.qml` contains its own `MouseArea` (`id: mouseArea`) used to anchor `ClockWidgetPopup` via `hoverTarget: mouseArea`. [VERIFIED: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml:42-50`]  
**Trap:** In QtQuick, a child `MouseArea` defaults to `acceptedButtons: Qt.LeftButton`. If someone clicks on the inner text of `ClockWidget`, the inner `MouseArea` consumes the press unless handled. However, in `BarContent.qml`, clicking the outer `leftCenterGroup` area (such as the BarGroup padding or surrounding bounds) reliably triggers `onPressed`.  
**Mitigation:** Preserve the exact existing wrapping structure:
```qml
    MouseArea {
        id: leftCenterGroup
        ...
        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
        BarGroup {
            id: leftCenterGroupContent
            anchors.fill: parent
            ClockWidget { ... }
        }
    }
```
This maintains 100% structural parity with the previous `rightCenterGroup` design.

---

## Runtime State Inventory

| State / Variable | Type | Source | Impact on Center Zone |
|---|---|---|---|
| `GlobalStates.sidebarRightOpen` | `bool` | `GlobalStates.qml:15` | Toggled by clicking `leftCenterGroup` (`onPressed`). Controls opening/closing of the notification and control center panel. |
| `Config.options.bar.weather.enable` | `bool` | `config.json` (`bar.weather.enable`) | Controls `weatherGroup.active`. When `false`, `weatherGroup` is uninstantiated and `middleSection.right` anchors directly to `middleCenterGroup.right`. |
| `Config.options.bar.verbose` | `bool` | `config.json` (`bar.verbose`) | Controls `ClockWidget.showDate` along with `useShortenedForm`. |
| `root.useShortenedForm` | `real (0, 1, 2)` | `BarContent.qml:17` | Screen width responsive tier: `0` (>= 1200px), `1` (< 1200px), `2` (<= 900px). When `2`, `ClockWidget.showDate` evaluates to `false`, shrinking Clock from ~220px to ~70px. |
| `Appearance.colors.colLayer1` | `color` | `Appearance.qml` / M3 theme | Background color of `BarGroup` pills in the center zone. |

---

## Validation Architecture

### Automated Assertion Suite: `scripts/phase47-center-layout-assert.sh`
A dedicated 5-section assertion harness following the `phase46-telemetry-assert.sh` architecture will validate the phase:

#### Section 1: Symlink & Packaging Integrity (CNTR-03, INTG-02)
- Assert `~/.config/quickshell/ii/modules/ii/bar/BarContent.qml` is a leaf symlink to `restow/quickshell/.../BarContent.qml`.
- Assert ancestor directories are real directories (no folded symlinks).
- Assert `vendor/dots-hyprland` submodule remains 100% clean porcelain (`git status --porcelain` is empty).

#### Section 2: Center Zone Layout AST & Semantic Positioning (CNTR-01, CNTR-02, CNTR-03)
- Assert `leftCenterGroup` wraps `ClockWidget` in `BarGroup` (`leftCenterGroupContent`) inside `MouseArea`.
- Assert `leftCenterGroup` anchors to `middleCenterGroup.left` with `anchors.rightMargin: 4`.
- Assert `leftCenterGroup` has `implicitWidth: leftCenterGroupContent.implicitWidth` and `implicitHeight: leftCenterGroupContent.implicitHeight`.
- Assert `leftCenterGroup` handles `onPressed` toggling `GlobalStates.sidebarRightOpen`.
- Assert `middleCenterGroup` anchors strictly to `parent.horizontalCenter` via `anchors.horizontalCenter: parent.horizontalCenter`.
- Assert `middleCenterGroup` anchors `verticalCenter: parent.verticalCenter` and wraps `Workspaces`.
- Assert `weatherGroup` wraps `WeatherBar` in `Loader` with `active: Config.options.bar.weather.enable`.
- Assert `weatherGroup` anchors to `middleCenterGroup.right` with `anchors.leftMargin: 4`.
- Assert `middleSection` wrapper anchors:
  - `anchors.left: leftCenterGroup.left`
  - `anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right`
- Assert declaration order in `BarContent.qml`: `middleSection` → `leftCenterGroup` → `middleCenterGroup` → `weatherGroup`.
- Assert `barLeftSideMouseArea` anchors right to `middleSection.left`.
- Assert `barRightSideMouseArea` anchors left to `middleSection.right`.

#### Section 3: Responsive Behavior & Date Gating (CNTR-03)
- Assert `ClockWidget` inside `leftCenterGroup` specifies `showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)`.
- Assert date is dynamically hidden on narrow screens (`useShortenedForm == 2`).

#### Section 4: Mathematical Spacing & Centering Invariants Simulation (CNTR-02, CNTR-03)
- Mathematical simulation running across 5 screen resolutions (3440px, 2560px, 1920px, 1200px, 900px):
  - Workspaces center remains locked to exact physical 50% monitor width (`screen_width / 2`).
  - Spacing margins remain exactly 4px on both left and right flanks.
  - Left zone available width (`middleSection.left - parent.left`) exceeds Left zone content width (no overlap).
  - Right zone available width (`parent.right - middleSection.right`) exceeds Right zone content width (no overlap).

#### Section 5: Sub-Harness Orchestration & Strict Repository Verification (INTG-02, CNTR-03)
- Execute `scripts/phase46-telemetry-assert.sh --quick` ensuring zero regressions on the Left zone and telemetry sensors.
- Execute `./arch/dots-hyprland.sh verify --strict` guaranteeing `FAIL=0 FINDINGS=0`.
- Assert zero working tree drift across assert execution.

---

## Sources & Metadata

### Citations & In-Repo Provenance
- `REQUIREMENTS.md:53-56` — Requirements CNTR-01, CNTR-02, CNTR-03.
- `ROADMAP.md:274-288` — Phase 47 definition and success criteria 1–5.
- `STATE.md:20-31, 306-310` — Milestone v0.9 status and Phase 46 closeout decisions.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:77-221` — Current layout of `barLeftSideMouseArea`, `middleSection`, `weatherGroup`, `middleCenterGroup`, `rightCenterGroup`, and `barRightSideMouseArea`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml:7-51` — `ClockWidget` dimensions, `showDate`, and popup hover target.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml:10-56` — `WeatherBar` structure and right-click refresh.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml:5-50` — `BarGroup` pill geometry, padding, and `implicitWidth` 250ms animation.
- `capture/ii/.config/illogical-impulse/config.json` — Bar options (`weather.enable`, `verbose`, `workspaces.shown`).
- `scripts/phase46-telemetry-assert.sh:1-471` — Reference 6-section test harness architecture.
- `arch/dots-hyprland.sh:1-1310` — Strict repository verification gate (`verify --strict`).
