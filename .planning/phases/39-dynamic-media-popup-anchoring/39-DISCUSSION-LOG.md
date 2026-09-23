# Phase 39: Dynamic Media Popup Anchoring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-23
**Phase:** 39-Dynamic Media Popup Anchoring
**Areas discussed:** Popup-to-pill alignment, Position communication, Edge clamping margins

---

## Popup-to-pill alignment

| Option | Description | Selected |
|--------|-------------|----------|
| Center-align popup under the pill | The popup's horizontal center lines up with the Media pill's center. Most natural dropdown feel. | ✓ |
| Left-edge-align | The popup's left edge aligns with the pill's left edge. Simpler math, looks like a menu dropdown. | |
| You decide | Agent picks the best alignment during planning. | |

**User's choice:** Center-align popup under the pill — The popup's horizontal center lines up with the Media pill's center.
**Notes:** User specifically emphasized boundary clamping to ensure the popup never overflows screen dimensions on the left, right, top, or bottom.

| Option | Description | Selected |
|--------|-------------|----------|
| Vertical bar too | When the bar is vertical (left/right), the popup should anchor vertically relative to the Media pill's Y position with top/bottom screen clamping. | ✓ |
| Horizontal bar only | Only do dynamic anchoring for top/bottom bar. Keep the existing vertical bar positioning as-is. | |
| You decide | Agent determines best behavior for vertical bar during planning. | |

**User's choice:** Vertical bar too.

| Option | Description | Selected |
|--------|-------------|----------|
| Same popup dimensions | Keep the existing widgetWidth / widgetHeight from Appearance.sizes. Only change the positioning math. | ✓ |
| Responsive sizing | Also adjust the popup width based on available screen space. | |

**User's choice:** Same popup dimensions.

| Option | Description | Selected |
|--------|-------------|----------|
| Smooth reposition | If the bar layout shifts, animate to the new position using existing Appearance.animation transitions. | ✓ |
| Instant snap | Popup just snaps to the new position immediately. | |
| You decide | Agent decides reposition strategy. | |

**User's choice:** Smooth reposition (harmonized to reactive QML property binding to prevent Wayland layer-shell compositor jitter).

---

## Position communication

| Option | Description | Selected |
|--------|-------------|----------|
| GlobalStates singleton property | Add mediaPillCenterX, mediaPillCenterY, mediaPillWidth to GlobalStates.qml. | ✓ |
| Compute from bar layout assumptions | Calculate pill position based on bar width and right-section layout offsets. | |
| You decide | Agent picks best approach. | |

**User's choice:** GlobalStates singleton property.

| Option | Description | Selected |
|--------|-------------|----------|
| Override GlobalStates.qml in restow | Add new properties in restow overlay, keeping vendor pristine. | ✓ |
| Use a new separate singleton | Create a new MediaPillPosition.qml singleton in restow. | |
| You decide | Agent decides singleton strategy. | |

**User's choice:** Override GlobalStates.qml in restow.

| Option | Description | Selected |
|--------|-------------|----------|
| Pill center + pill width | mediaPillCenterX, mediaPillCenterY, and mediaPillWidth. | ✓ |
| Pill center only | Just mediaPillCenterX and mediaPillCenterY. | |
| Pill bounding rect | Full mediaPillX, mediaPillY, mediaPillWidth, mediaPillHeight. | |

**User's choice:** Pill center + pill width (harmonized to centerX and centerY as width is mathematically redundant for center anchoring).

| Option | Description | Selected |
|--------|-------------|----------|
| mapToGlobal on position change | Use an onXChanged / onYChanged handler or Binding to continuously update GlobalStates. | ✓ |
| Update only on toggle | Only compute and publish pill position when the user clicks the Media pill. | |
| You decide | Agent decides timing. | |

**User's choice:** mapToGlobal on position change (harmonized to click-triggered update in BarContent with reactive synchronization when open to prevent multi-monitor race conditions).

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal restow override of MediaControls.qml | Copy file but only change lines 101–104 (margins block) to read from GlobalStates. | ✓ |
| Wrapper approach | Create a wrapper that loads upstream MediaControls. | |
| Fork in vendor | Make changes directly in vendor submodule. | |

**User's choice:** Minimal restow override of MediaControls.qml.

---

## Edge clamping margins

| Option | Description | Selected |
|--------|-------------|----------|
| Use Appearance.sizes.hyprlandGapsOut | Gap constant used throughout shell for consistent boundary spacing (5px). | ✓ |
| Fixed pixel margin | Hardcode small pixel margin (e.g. 8px). | |
| Zero margin | Clamp to screen edge exactly. | |
| You decide | Agent decides margin. | |

**User's choice:** Use Appearance.sizes.hyprlandGapsOut.

| Option | Description | Selected |
|--------|-------------|----------|
| Both edges symmetrically | Clamp on both left and right (or top and bottom for vertical bar). | ✓ |
| Near-edge only | Only clamp the edge nearest the screen boundary. | |

**User's choice:** Both edges symmetrically.

| Option | Description | Selected |
|--------|-------------|----------|
| Separate vertical gap | Maintain gap between bottom of bar and top of popup. | |
| Flush against bar | Popup top edge touches bar bottom edge. | |
| Match upstream default | Keep upstream vertical spacing (Appearance.sizes.barHeight). | ✓ |

**User's choice:** Match upstream default.

| Option | Description | Selected |
|--------|-------------|----------|
| Silent clamp | Just clamp to boundary without visual indicators. | ✓ |
| Visual offset indicator | Show arrow or pointer toward actual pill position. | |

**User's choice:** Silent clamp.

| Option | Description | Selected |
|--------|-------------|----------|
| Track screen via GlobalStates | Publish originating ShellScreen from BarContent so popup targets the clicked monitor. | ✓ |
| Match upstream default | Use panelWindow.screen (harmonized with GlobalStates.mediaPillScreen to fix upstream multi-monitor bug). | ✓ |

**User's choice:** Match upstream default + multi-monitor target display alignment.

| Option | Description | Selected |
|--------|-------------|----------|
| Clamp to left margin | Pin popup left margin to hyprlandGapsOut if screen width is narrower than widget. | ✓ |
| Center on screen as fallback | Center on screen if narrower than widget plus margins. | |
| You decide | Planner handles edge cases. | |

**User's choice:** Clamp to left margin.

---

## the agent's Discretion

- Variable naming for internal clamping math in `MediaControls.qml`.
- Specific automated test harness assertion commands in `scripts/`.

## Deferred Ideas

- None — all topics discussed were strictly within Phase 39 scope.
