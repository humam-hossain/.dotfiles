# Phase 43: CPU & GPU Component (Pill & Popup) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-26
**Phase:** 43-cpu-gpu-component-pill-popup
**Areas discussed:** Pill Layout & Metrics Density, Alert Escalation & Pulse Animation, Popup Inspector Layout & Core Breakdown, Pill Click Action & System Monitor Launcher

---

## Pill Layout & Metrics Density

| Option | Description | Selected |
|--------|-------------|----------|
| CPU % + Package Temp + GPU % | e.g. [planner_review] 14% 42°C  [speed] 5% (Immediate thermal health without opening popup) | ✓ |
| CPU % + GPU % only | e.g. [planner_review] 14%  [speed] 5% (Minimalist layout; thermals in popup only) | |
| Dynamic Temp Reveal | Show CPU/GPU % normally, reveal temp badge when package temp > 65°C | |
| You decide | Builder chooses optimal density | |

**User's choice:** CPU % + Package Temp + GPU % — e.g. [planner_review] 14% 42°C  [speed] 5%
**Notes:** Provides instant thermal health at a glance.

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle dot or vertical separator line | Provides clean visual boundary matching M3 surface conventions | |
| Generous spacing gap | 10–12px whitespace separation without divider lines | |
| Sub-pill rounded badges | Each cluster sits in its own micro-container within the pill | |
| Different icon for CPU and GPU | Different icon for CPU and GPU with the same style as existing bar icons | ✓ |

**User's choice:** different icon for cpu and gpu - the style of icon should be the same as now
**Notes:** Selected via write-in. Anchored by Material Symbols (`planner_review` for CPU, `speed` for GPU) at `Appearance.font.pixelSize.normal`.

| Option | Description | Selected |
|--------|-------------|----------|
| Prioritize CPU load | Hide GPU and temperature in shortened form, showing [planner_review] 14% | |
| Drop temperature only | Retain both [planner_review] 14% [speed] 5% in shortened form | ✓ |
| Compact text badges | Keep all three metrics but drop percentage/degree symbols | |
| You decide | Builder configures responsive fallbacks | |

**User's choice:** Drop temperature only — Retain both [planner_review] 14% [speed] 5% in shortened form
**Notes:** Preserves core processor and GPU loads on narrow screens while gracefully yielding space.

| Option | Description | Selected |
|--------|-------------|----------|
| Natural M3 fluid width animation | Standard formatting (5%, 14%, 100%) with BarGroup's 250ms emphasizedDecel easing between width changes | ✓ |
| Fixed-width text containers | Reserve fixed width for percentage labels | |
| Zero-padded percentages | e.g. 05%, 42°C, 02% | |
| You decide | Builder selects cleanest visual behavior | |

**User's choice:** Natural M3 fluid width animation — Standard formatting (5%, 14%, 100%) with BarGroup's 250ms emphasizedDecel easing between width changes
**Notes:** Leverages existing `BarGroup` transition physics.

| Option | Description | Selected |
|--------|-------------|----------|
| CPU first, then GPU | [planner_review] 14% 42°C  [speed] 5% | ✓ |
| GPU first, then CPU | [speed] 5%  [planner_review] 14% 42°C | |
| Temperature trailing at the end | [planner_review] 14%  [speed] 5%  42°C | |
| You decide | Builder arranges for cleanest visual hierarchy | |

**User's choice:** CPU first, then GPU — [planner_review] 14% 42°C  [speed] 5%
**Notes:** Natural logical flow reflecting primary host computational driver.

| Option | Description | Selected |
|--------|-------------|----------|
| Always show CPU Package Temp in the pill | Predictable single thermal metric; NVMe and VRM thermals remain in the popup inspector | ✓ |
| Dynamic peak escalation | Swap to peak device if non-CPU component exceeds 70°C | |
| Dual temperature readout | e.g. 42°C / 55°C | |
| You decide | Builder chooses safest approach | |

**User's choice:** Always show CPU Package Temp in the pill — Predictable single thermal metric; NVMe and VRM thermals remain in the popup inspector
**Notes:** Package id 0 from `hwmon5/temp1_input`.

| Option | Description | Selected |
|--------|-------------|----------|
| Inherit standard BarGroup background and borderless setting | Guarantees 100% aesthetic harmony with Workspaces, Clock, and Voice pills | ✓ |
| Slightly elevated surface container | Appearance.m3colors.m3surfaceContainerHigh | |
| Subtle persistent outline border | Appearance.colors.colLayer0Border | |
| You decide | Builder aligns with global shell tokens | |

**User's choice:** Inherit standard BarGroup background and borderless setting (Guarantees 100% aesthetic harmony with Workspaces, Clock, and Voice pills)
**Notes:** Ensures consistent visual language across top bar.

| Option | Description | Selected |
|--------|-------------|----------|
| Vertical Column Stack | Stack [planner_review], CPU %, Temp, [speed], GPU % vertically | ✓ |
| Minimal Icon-Only Vertical | Display [planner_review] and [speed] icons only | |
| You decide | Builder designs responsive vertical bar layout | |

**User's choice:** Vertical Column Stack — Stack [planner_review], CPU %, Temp, [speed], GPU % vertically (Fits narrow vertical bar cleanly without horizontal clipping)
**Notes:** Standard responsive adaptation for vertical bar orientation.

---

## Alert Escalation & Pulse Animation

| Option | Description | Selected |
|--------|-------------|----------|
| Dual-trigger threshold | Escalate color if either Load OR Temperature hits threshold | |
| Independent coloring | CPU cluster colors by CPU load, GPU cluster colors by GPU load, Temperature colors by thermal degrees independently | ✓ |
| Load-only coloring | Pill colors strictly by utilization % | |
| You decide | Builder designs balanced alert logic | |

**User's choice:** Independent coloring — CPU cluster colors by CPU load, GPU cluster colors by GPU load, Temperature colors by thermal degrees independently
**Notes:** Avoids false alarms; each metric reflects its own condition.

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle breathing opacity pulse on icon only | Icon pulses opacity 1.0 to 0.6 over 600ms during critical Red state | ✓ |
| Steady solid Red | High-contrast static color with zero pulsing | |
| Pill border glow pulse | Subtle breathing pulse on the entire pill outline | |
| You decide | Builder chooses least distracting animation | |

**User's choice:** Subtle breathing opacity pulse on icon only — Icon pulses opacity 1.0 to 0.6 over 600ms during critical Red state (Draws peripheral awareness without visual clutter)
**Notes:** Reuses breathing animation pattern established in `VoicePill.qml`.

| Option | Description | Selected |
|--------|-------------|----------|
| M3 Semantic Tokens | Warning uses Appearance.colors.colTertiary, Critical uses Appearance.colors.colError | ✓ |
| Error container variant | Warning uses Appearance.m3colors.m3errorContainer, Critical uses Appearance.colors.colError | |
| You decide | Builder ensures 100% Material You dynamic theme compliance | |

**User's choice:** M3 Semantic Tokens — Warning uses Appearance.colors.colTertiary (harmonized dynamic gold/amber), Critical uses Appearance.colors.colError (dynamic M3 error red)
**Notes:** Pure dynamic Material You color tokens, 0 hardcoded hex values.

| Option | Description | Selected |
|--------|-------------|----------|
| 75°C Amber / 85°C Red | Realistic thermal bounds for Intel Core i5-13500 under gaming or compilation before throttling | ✓ |
| 70°C Amber / 90°C Red | Direct numeric alignment with the 70%/90% load thresholds | |
| 80°C Amber / 95°C Red | High-performance ceiling for heavy multithreaded turbo workloads | |
| You decide | Builder configures standard CPU thermal curve | |

**User's choice:** 75°C Amber / 85°C Red — Realistic thermal bounds for Intel Core i5-13500 under gaming or compilation before throttling
**Notes:** Aligned with Core i5-13500 desktop TJMax and fan profiles.

---

## Popup Inspector Layout & Core Breakdown

| Option | Description | Selected |
|--------|-------------|----------|
| Dual-Card Side-by-Side | CPU inspector card on left, GPU card on right | |
| Single Vertical Column | Unified card with CPU section on top, GPU below | |
| Three-Section Layout | CPU left, GPU center, System thermals right | |
| Dual-Column with Right-Side Split | Left: CPU; Right Top: GPU; Right Bottom: Motherboard VRM & Platform | ✓ |

**User's choice:** option 1 modified: left: cpu, right: gpu (top), rest (bottom)
**Notes:** Custom structure providing compact dual-column width while accommodating motherboard platform sensors.

| Option | Description | Selected |
|--------|-------------|----------|
| Segregated P-Core & E-Core progress bars | Two distinct meter bars: "P-Cores (12T)" and "E-Cores (8T)" with active MHz | ✓ |
| Full 20-thread micro-meter grid | 20 mini load bars showing all individual logical threads (CPUs 0–19) | |
| Unified CPU meter + text breakdown | Single overall CPU progress bar with text badges for P/E Core MHz | |
| You decide | Builder designs cleanest visual balance | |

**User's choice:** Segregated P-Core & E-Core progress bars — Two distinct meter bars: "P-Cores (12T)" and "E-Cores (8T)" with active MHz (Clean, highly legible, shows foreground vs background thread scheduling)
**Notes:** Clearly surfaces Intel Thread Director workload segregation.

| Option | Description | Selected |
|--------|-------------|----------|
| Load progress bar + Clock speed (MHz) + Thermal throttle status badge | Displays active load bar, frequency in MHz, and clean status tag e.g. "Normal" or "Thermal Throttle" | ✓ |
| Value rows only | Text rows for Load %, Active Clock, and Throttling state | |
| Load meter + frequency only | Clean progress bar and clock MHz | |
| You decide | Builder designs matching M3 style | |

**User's choice:** Load progress bar + Clock speed (MHz) + Thermal throttle status badge (Displays active load bar, frequency in MHz, and clean status tag e.g. "Normal" or "Thermal Throttle")
**Notes:** Provides comprehensive Intel UHD 770 telemetry.

| Option | Description | Selected |
|--------|-------------|----------|
| NVMe + Motherboard VRM in CpuGpuPopup | Mixed secondary thermals | |
| Domain-specific separation | Motherboard VRM in CpuGpuPopup; NVMe in Storage; Ethernet in Network | ✓ |

**User's choice:** only motherboard telemetries should be here. for nvmes there is specifically storage component
**Notes:** User provided live sensors breakdown. NVMe drives (Samsung PM9A1, Samsung 980) routed to Phase 44; Ethernet PHY (r8169) routed to Phase 45; Motherboard VRM (`gigabyte_wmi-virtual-0`) retained here.

---

## Pill Click Action & System Monitor Launcher

| Option | Description | Selected |
|--------|-------------|----------|
| Hover reveals popup; Left-Click launches btop in Kitty | Hover provides instant stats; click launches full process manager | |
| Left-Click toggles popup | Strict click-to-toggle overlay; no hover popups | |
| Left-Click toggles popup, Middle-Click launches btop | Keeps popup on left click while providing btop shortcut | |
| Only hover, no clicks | Hover reveals popup; clicks are inert | ✓ |

**User's choice:** only hover, no clicks
**Notes:** Selected via write-in. Prevents accidental clicks and bar click-bleed.

| Option | Description | Selected |
|--------|-------------|----------|
| Seamless cursor tracking | Keep popup open while mouse is over either the pill OR inside the popup itself | ✓ |
| Strict pill-only hover | Popup closes immediately when cursor leaves bar pill bounds | |
| Graceful 200ms linger timer | Brief buffer before closing | |
| You decide | Builder uses standard StyledPopup mechanics | |

**User's choice:** Seamless cursor tracking — Keep popup open while mouse is over either the pill OR inside the popup itself (Allows hovering over core meters without popup closing)
**Notes:** Standard Quickshell `StyledPopup` hoverTarget binding.

| Option | Description | Selected |
|--------|-------------|----------|
| Centered directly beneath the pill with screen boundary clamping | Standard Quickshell ii popup geometry matching StyledPopup | ✓ |
| Left-aligned with the pill's left edge | Anchors flush with the left boundary of the pill | |
| You decide | Builder uses standard StyledPopup alignment | |

**User's choice:** Centered directly beneath the pill with screen boundary clamping (Standard Quickshell ii popup geometry matching StyledPopup)
**Notes:** Symmetrical visual alignment.

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle M3 fade + slide | 150ms opacity fade with a gentle 4px downward slide using Appearance.animationCurves.expressiveEffects | ✓ |
| Pure opacity fade | 150ms smooth crossfade without spatial movement | |
| Instant appearance | 0ms immediate render without animations | |
| You decide | Builder matches system popup entrance style | |

**User's choice:** Subtle M3 fade + slide — 150ms opacity fade with a gentle 4px downward slide using Appearance.animationCurves.expressiveEffects
**Notes:** Expressive Material 3 entrance motion.

---

## the agent's Discretion

- Exact spacing constants and margins between progress bars in `CpuGpuPopup.qml`.
- Internal helper bindings for mapping temperature values to formatted strings.

---

## Deferred Ideas

- Dedicated NVMe 1 & 2 thermals integration into Phase 44 Storage Popup.
- Dedicated Ethernet PHY (r8169) transceiver temp into Phase 45 Network Popup.
