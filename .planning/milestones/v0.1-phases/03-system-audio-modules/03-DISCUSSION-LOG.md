# Phase 3: System & Audio Modules - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 3-System & Audio Modules
**Areas discussed:** Resource strip look, Disk module design, Volume control surface, Click / detail destinations

---

## Resource strip look (CPU/RAM/swap)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep ii circular % | Reuse rings + bare % | |
| Waybar-style text labels | Text modules like Waybar | |
| Hybrid rings + GB for RAM | Rings + richer labels | |
| Freeform | rings + %/GB like waybar | ✓ |

**User's choice:** Rings + Waybar-like labels. CPU: ring + %. RAM: ring + `8.5/15.5 GB` (no %). No swap on bar.

| Option | Description | Selected |
|--------|-------------|----------|
| Always show CPU + RAM | Predictable width | ✓ |
| Hide CPU when media plays | ii default media-hide | |
| You decide | | |

**User's choice:** Always show CPU + RAM.

| Option | Description | Selected |
|--------|-------------|----------|
| CPU then RAM | | ✓ |
| RAM then CPU | | |
| You decide | | |

**User's choice:** CPU then RAM (Disk later appended as third).

| Option | Description | Selected |
|--------|-------------|----------|
| Keep ii single recolor | | |
| Recolor + numeric error | | |
| No warning styling | | |
| Freeform 3-level thresholds | | ✓ |

**User's choice:** Two-step colors — RAM warn ≥75% error ≥95%; CPU warn ≥40% error ≥80%.

| Option | Description | Selected |
|--------|-------------|----------|
| ~1s CPU, ~3s RAM | | ✓ |
| Single ~2–3s | | |
| Waybar 1s/5s | | |

**User's choice:** ~1s CPU feel, ~3s RAM.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep simple ResourcesPopup | | |
| Disable popup; bar only | | ✓ |
| Click opens btop | | |

**User's choice:** Disable popup. Detailed graphs/sensors deferred to dedicated phase.

**Notes:** User said detailed resources UI "needs to be planned in detail" in a future phase.

---

## Disk module design (BAR-07)

| Option | Description | Selected |
|--------|-------------|----------|
| Ring + free/total | Waybar-like | ✓ |
| Ring + % only | | |
| Text only free/total | | |

**User's choice:** Ring + free/total.

| Option | Description | Selected |
|--------|-------------|----------|
| Root / only | | ✓ |
| Root + home if separate | | |
| You decide after probing | | |

**User's choice:** Root `/` only.

| Option | Description | Selected |
|--------|-------------|----------|
| CPU → RAM → Disk | | ✓ |
| CPU → Disk → RAM | | |
| Separate module | | |

**User's choice:** CPU → RAM → Disk in Resources cluster.

| Option | Description | Selected |
|--------|-------------|----------|
| Warn ≥80%, error ≥95% | | ✓ |
| Match RAM 75/95 | | |
| No disk warning colors | | |

**User's choice:** Warn ≥80%, error ≥95% used.

| Option | Description | Selected |
|--------|-------------|----------|
| ~30s | | |
| ~10s | | ✓ |
| Same as RAM ~3s | | |

**User's choice:** ~10s refresh.

| Option | Description | Selected |
|--------|-------------|----------|
| GB one decimal | | |
| Auto human G/T | | ✓ |
| You decide | | |

**User's choice:** Auto human (G/T).

---

## Volume control surface (BAR-08)

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated volume module + % | | |
| Enhance mute indicator only | | ✓ |
| Both module + mute icon | | |

**User's choice:** Enhance mute indicator only.

| Option | Description | Selected |
|--------|-------------|----------|
| Icon + volume% | | ✓ |
| Icon only until hover | | |
| Icon by level no number | | |

**User's choice:** Icon + volume%.

| Option | Description | Selected |
|--------|-------------|----------|
| volume_off only when muted | | ✓ |
| volume_off + last % | | |
| volume_off + 0% | | |

**User's choice:** volume_off icon only when muted.

| Option | Description | Selected |
|--------|-------------|----------|
| Scroll on indicator only | | |
| Whole right-bar + indicator | | |
| Freeform: keep ii habit | | ✓ |

**User's choice:** Preserve current whole right-bar scroll; nothing extra. Keyboard volume wheel present. **Any volume change auto-unmutes.** **Max volume 130%.**

| Option | Description | Selected |
|--------|-------------|----------|
| Click = mute only | | |
| Click mute; middle/right pavucontrol | | ✓ |
| Click opens pavucontrol | | |

**User's choice:** Click mute; middle/right opens pavucontrol — **for both output and mic**.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep existing ii OSD | | ✓ |
| Require OSD this phase | | |
| Disable OSD | | |

**User's choice:** Keep whatever ii already does for OSD.

| Option | Description | Selected |
|--------|-------------|----------|
| Mic icon-only | | |
| Also show mic input % | | ✓ |
| Hide mic | | |

**User's choice:** Also show mic input %. Pattern: mic + % unmuted; mic_off alone when muted.

---

## Click / detail destinations

| Option | Description | Selected |
|--------|-------------|----------|
| No click on resource strip | | ✓ |
| Click opens btop | | |
| Disk → nautilus only | | |

**User's choice:** No click action on CPU/RAM/Disk this phase.

| Option | Description | Selected |
|--------|-------------|----------|
| No hover tooltip | | ✓ |
| Minimal tooltips | | |
| You decide | | |

**User's choice:** No hover tooltip this phase.

| Option | Description | Selected |
|--------|-------------|----------|
| Nothing else for clicks | | ✓ |
| Disk → nautilus exception | | |
| More questions | | |

**User's choice:** Nothing else — volume/mic gestures only.

---

## Claude's Discretion

- Dual-threshold ring implementation details
- Disk sampling mechanism (`df` vs other)
- Auto human G/T formatter
- Pipewire auto-unmute on external volume changes
- Mic % = device volume (not VU) preferred
- Config dual-write for new knobs

## Deferred Ideas

- Dedicated phase: detailed system resources UI (graphs, sensors, rich detail)
- ADV-05 volume OSD product work (stock ii only this phase)
- Swap on bar; btop/nautilus resource clicks
- Phase 4 IPC/cutover; weather/ping/power
