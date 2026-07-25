# Phase 3: System & Audio Modules - Research

**Researched:** 2026-07-23
**Domain:** Quickshell Illogical Impulse bar — system resource metrics (CPU/RAM/disk) + PipeWire audio indicators
**Confidence:** HIGH

## Summary

Phase 3 is **not** a greenfield module build. CPU/RAM rings, the left-bar `Resources` strip, mute/mic icons in the D-19 indicators pill, right-bar volume scroll, PipeWire `Audio` service, and the stock volume OSD already exist under wholesale `ii`. The work is to **productize** those surfaces to locked CONTEXT decisions and Waybar parity for BAR-05..08: dual-threshold rings, always-visible CPU→RAM→Disk order with capacity labels, disk polling for `/`, mute/mic icons with volume %, auto-unmute, 130% max, and pavucontrol middle/right click.

The largest implementation gaps are: (1) `Resource.qml` only supports a single warning threshold and fixed `0–100` percentage text; (2) `ResourceUsage.qml` has no disk and a single 3s poll for CPU+RAM; (3) `Audio.incrementVolume` / `ScreenCorners` hard-cap at linear `1.0` (100%); (4) mute indicators are icon-only with left-click toggle only; (5) PipeWire/wpctl does **not** auto-unmute on volume change — D-21 must be implemented explicitly; (6) `ResourcesPopup` is still attached and must be disabled for Phase 3.

**Primary recommendation:** Extend `ResourceUsage` + `Resource`/`Resources` for metrics (CPU/RAM/Disk strip, dual thresholds, no popup); extend `Audio.qml` + `BarContent.qml` indicators for volume UX (%, auto-unmute, 130% cap, pavucontrol). Dual-write all new/changed Config keys to live `~/.config/illogical-impulse/config.json` using the Phase 2 pattern.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Resource strip — CPU & RAM (BAR-05, BAR-06)
- **D-01:** Keep **ii circular progress rings** as the primary visual (reuse `Resource.qml` / `Resources.qml` patterns), not pure Waybar text-only modules.
- **D-02:** **CPU** = ring + **percentage** (e.g. ring + `12%`).
- **D-03:** **RAM** = ring + **used/total text in GB** (e.g. `8.5/15.5 GB`) — **no %** on the bar label.
- **D-04:** **No swap on the bar.** Swap may remain in service data for a future detail UI but must not render in the Phase 3 strip.
- **D-05:** **Always show** CPU and RAM (no media/MPRIS hide). Override ii `alwaysShowCpu` / media-hide behavior so both stay visible.
- **D-06:** Order L→R after Workspaces: **CPU → RAM → Disk** (disk decisions below).
- **D-07:** Two-step warning colors on the rings (and labels if already recolored with rings):
  - **CPU:** warning ≥ **40%**, error ≥ **80%**
  - **RAM:** warning ≥ **75%**, error ≥ **95%** (of capacity used)
  - Use theme **warning** vs **error** colors (not a single threshold).
- **D-08:** Poll feel: **~1s for CPU**, **~3s for RAM** (planner may implement with one or two timers as long as UX matches).
- **D-09:** **Disable `ResourcesPopup` for Phase 3** — bar numbers only; **no hover tooltip** and **no click action** on the resource strip.

#### Disk (BAR-07)
- **D-10:** **Ring + free/total** text (Waybar-like capacity read), same visual family as RAM.
- **D-11:** Monitor **root `/` only** (not multi-mount /home).
- **D-12:** Placement: **CPU → RAM → Disk** inside the Resources cluster (extend `Resources.qml` / related row — not a separate bar region).
- **D-13:** Thresholds on **used %**: warning ≥ **80%**, error ≥ **95%**.
- **D-14:** Refresh interval **~10s** (disk changes slowly; not tied to 1s CPU).
- **D-15:** Label units: **auto human (G/T)** — switch to TB when totals warrant; consistent with readable capacity labels.
- **D-16:** No disk click, no disk tooltip this phase (same as CPU/RAM).

#### Volume & mic surface (BAR-08)
- **D-17:** **No dedicated volume module.** Enhance the existing **mute indicator** in the D-19 indicators pill (and mic beside it).
- **D-18:** **Output unmuted:** Material volume icon + **volume %**. **Muted:** `volume_off` icon **only** (no %).
- **D-19:** **Mic unmuted:** mic icon + **input level %**. **Muted:** `mic_off` icon **only**.
- **D-20:** **Scroll:** keep **whole right-bar** volume scroll (existing `FocusedScrollMouseArea` habit). Do **not** add a separate scroll-only volume widget.
- **D-21:** **Auto-unmute:** if the user changes volume by **any** path (bar scroll, keyboard volume wheel, etc.) while muted, **unmute automatically**. Same spirit for mic if input gain is changed while mic-muted (planner verifies against Pipewire APIs).
- **D-22:** **Max volume ceiling: 130%** (1.30 linear). Update protection / clamp logic so intentional boost up to 130% is allowed; do not hard-cap at 100% for user-driven changes.
- **D-23:** **Click** on output mute indicator = **toggle mute**. **Middle-click and/or right-click** = open **pavucontrol** (use existing Config launch helper if present). **Same click map for mic** (toggle mic mute; middle/right → pavucontrol).
- **D-24:** **Volume OSD:** do not build a new OSD this phase — **keep whatever ii already does**.

#### Click / detail destinations
- **D-25:** Resource strip (CPU/RAM/Disk): **no click**, **no tooltip**, **no popup** in Phase 3.
- **D-26:** Audio detail escape hatch is **pavucontrol** via middle/right on mute/mic only — not via resource strip.

### Claude's Discretion
- Exact QML structure for dual-threshold ring colors (warning vs error) — may extend `Resource.qml` props
- How to implement disk free/total (FileView, Process/`df`, Quickshell IO) as long as root `/` is correct and ~10s refresh holds
- Auto-human G/T formatting helper shared with RAM if useful
- Whether right-bar scroll stays global while indicator also accepts wheel (must not regress right-bar habit)
- Dual-write `Config.qml` + live `~/.config/illogical-impulse/config.json` for new thresholds/intervals (Phase 2 pattern)
- Exact pavucontrol launch command (existing `Config.options.apps.volumeMixer` / launch_first_available pattern)
- Mic input % source from Pipewire default source volume vs peak meter — prefer **volume level** (not VU meter) unless volume is unavailable

### Deferred Ideas (OUT OF SCOPE)
- **Dedicated resources detail phase** — rich popup/dashboard with graphs, sensors, process detail, etc. (user: plan in detail later; not Phase 3)
- **Volume OSD product work** — ADV-05; keep stock ii behavior only this phase
- **Weather / ping / power modules** — not Phase 3
- **IPC / keybinds / Waybar cutover** — Phase 4
- **Swap on bar** — rejected for Phase 3; may appear in future detail UI
- **btop / nautilus on resource click** — rejected for Phase 3 (no click on strip)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAR-05 | User sees current CPU utilization in the bar | `ResourceUsage.cpuUsage` + `Resource` ring; force always-shown; label `N%`; dual thresholds 40/80; ~1s poll |
| BAR-06 | User sees current RAM utilization in the bar | `ResourceUsage.memoryUsed/Total`; ring = used%; label used/total GB (no %); dual thresholds 75/95; ~3s poll; drop swap from bar |
| BAR-07 | User sees disk space information in the bar | New disk props on `ResourceUsage` (root `/` only); ring used%; label free/total auto G/T; thresholds 80/95; ~10s poll; order after RAM |
| BAR-08 | User can see and adjust audio volume from the bar (scroll to change, click to mute) | Enhance mute/mic in indicators: icon+% / mute-only; right-bar scroll; `Audio` 130% + auto-unmute; middle/right → pavucontrol; keep ii OSD |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CPU % sampling | Service (`ResourceUsage`) | Host `/proc/stat` | FWK-03 singleton; widget only renders |
| RAM used/total | Service (`ResourceUsage`) | Host `/proc/meminfo` | MemAvailable-based free already present |
| Disk free/total for `/` | Service (`ResourceUsage`) | Host `df` / `statvfs` via `Process` | No Quickshell disk API; poll ~10s |
| Resource strip layout / rings | Desktop shell UI (`Resources.qml` / `Resource.qml`) | Appearance tokens | D-01 rings; dual-threshold color |
| Disable resource popup | Desktop shell UI | — | D-09/D-25: remove/disable `ResourcesPopup` |
| Output/mic volume + mute state | Service (`Audio` + PipeWire) | WirePlumber session | `PwNodeAudio.volume` / `muted` |
| Volume % / mute icons on bar | Desktop shell UI (`BarContent` indicators) | `Audio` service | D-17..D-19 enhance pill, no new module |
| Right-bar scroll volume | Desktop shell UI (`FocusedScrollMouseArea`) | `Audio.increment/decrementVolume` | D-20 keep habit |
| Keyboard volume wheel | OS / Hyprland binds (`wpctl`) | `Audio` auto-unmute listener | External path; D-21 must cover |
| Volume OSD | Desktop shell UI (`ii/onScreenDisplay`) | `Audio.sink.audio` signals | D-24 keep stock |
| pavucontrol launch | Desktop shell UI click handler | Host process via `apps.volumeMixer` | D-23 / D-26 |
| Thresholds / intervals | Config dual-write | Live JSON overrides | Phase 2 dual-write pattern |

---

## Current vs Target Gap Matrix

Verified against live tree + `~/.config/illogical-impulse/config.json` on 2026-07-23. [VERIFIED: codebase + host config]

| Area | Current | Target (CONTEXT) | Plan action |
|------|---------|------------------|-------------|
| Resources order | Memory → Swap → CPU | **CPU → RAM → Disk** | Reorder in `Resources.qml`; drop Swap UI |
| Swap on bar | Shown (alwaysShowSwap true) | **Hidden** (D-04) | Remove swap `Resource` from strip (service may keep data) |
| CPU always shown | `alwaysShowCpu: true` + media-hide fallback | Always (D-05) | Keep true; simplify `shown: true` |
| RAM always shown | Always (no `shown` prop) | Always | Keep |
| CPU label | Integer `12` (no `%`) | `12%` (D-02) | Extend label format |
| RAM label | Integer percent of capacity | `8.5/15.5 GB` no % (D-03) | Custom label + ring still uses used% |
| Disk | **Missing** | Ring + free/total `/` (D-10..15) | Service + third `Resource` |
| Thresholds | Single `warningThreshold` → `colError` only; CPU 90, mem 95 | Dual warning/error with locked % | Extend `Resource.qml` + Config keys |
| Poll interval | Single timer → 3000 ms | ~1s CPU / ~3s RAM / ~10s Disk | Split timers or multi-rate counter |
| ResourcesPopup | Attached; hover opens | **Disabled** (D-09) | Remove instance / no hoverTarget |
| Mute indicator | Icon only; left-click toggle | Icon + `%` unmuted; icon only muted | Row with `StyledText` + mute-aware text |
| Mic indicator | Icon only; left-click toggle | Same pattern as mute with source volume % | Symmetric to output |
| Scroll volume | Right `FocusedScrollMouseArea` → `Audio.inc/dec` | Keep (D-20) | No layout change |
| Volume max | `Math.min(1, …)` in `incrementVolume`; corners same | **1.30** (D-22) | Raise clamp; dual-write protection maxAllowed 130 |
| Auto-unmute | **None** — `wpctl set-volume` leaves `[MUTED]` | Unmute on volume change (D-21) | Explicit in `Audio.qml` (+ ensure all volume setters) |
| Middle/right pavucontrol | Not wired on mute/mic | Middle and/or right → `apps.volumeMixer` | Multi-button `MouseArea` |
| Volume OSD | ii `OnScreenDisplay` listens to sink volume/mute | Keep stock (D-24) | No product work |
| Config dual-write | Old thresholds/interval in live JSON | New thresholds/intervals/max | Dual-write + assert script |

---

## Standard Stack

This phase installs **no new packages**. Stack is the existing Quickshell / ii shell on Arch.

### Core

| Library / Component | Version | Purpose | Why Standard |
|---------------------|---------|---------|--------------|
| Quickshell | **0.3.0** (Arch) | QML desktop shell runtime | Host-installed; project foundation [VERIFIED: host `quickshell --version`] |
| `Quickshell.Services.Pipewire` | bundled w/ QS 0.3.0 | Default sink/source volume + mute | Already used by `Audio.qml`; `PwNodeAudio.volume` / `muted` [VERIFIED: qmltypes + codebase] |
| `Quickshell.Io` (`FileView`, `Process`, `StdioCollector`) | bundled | Poll `/proc` and run `df` | Established in `ResourceUsage` / `Network` [VERIFIED: codebase] |
| Qt Quick / QtQuick.Layouts | Qt 6 (system) | UI layout | Existing bar widgets |

### Supporting (already present)

| Component | Path | Purpose | When to Use |
|-----------|------|---------|-------------|
| `ResourceUsage` singleton | `services/ResourceUsage.qml` | CPU/RAM(/disk) state | All resource widgets |
| `Audio` singleton | `services/Audio.qml` | Volume/mute API wrapper | Indicators, scroll, OSD |
| `Resource` / `Resources` | `modules/ii/bar/` | Ring strip UI | BAR-05..07 surface |
| `BarContent` indicators | `modules/ii/bar/BarContent.qml` | Mute/mic icons | BAR-08 surface |
| `OnScreenDisplay` | `modules/ii/onScreenDisplay/` | Volume OSD | D-24 keep |
| `Config` + live JSON | `modules/common/Config.qml` + `~/.config/illogical-impulse/config.json` | Thresholds/intervals/max | Dual-write |
| `pavucontrol` | `/usr/bin/pavucontrol` | Mixer GUI | Middle/right click (D-23) |
| `wpctl` | WirePlumber CLI | Hyprland XF86 binds | Keyboard volume path |
| Waybar (reference only) | `.config/waybar/config.jsonc` | Parity labels | Do not port modules |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Process` + `df -B1` for disk | Python `os.statvfs` via Process | Extra interpreter; `df` is simpler and available |
| `Process` + `df` | Read `/proc/self/mounts` + block device sysfs | Complex; still no free-space without statfs |
| PipeWire volume level for mic % | `PwNodePeakMonitor` VU | User discretion prefers **volume level**, not peak meter |
| Enhance mute indicator | Dedicated volume module | **Rejected** D-17 |
| Enable ResourcesPopup | Click → btop/nautilus | **Deferred** D-09/D-25 |

**Installation:** none (no npm/pip/cargo packages).

**Host tools verified:**

| Tool | Available | Version / path |
|------|-----------|----------------|
| quickshell | ✓ | 0.3.0 `/usr/bin/quickshell` |
| pavucontrol | ✓ | `/usr/bin/pavucontrol` |
| wpctl | ✓ | present; sink volume 1.00 at research time |
| df | ✓ | `/usr/bin/df` |
| python3 | ✓ | 3.14.6 (assert scripts) |

---

## Package Legitimacy Audit

> No external packages are installed in this phase. All work is QML/config against system Quickshell + host utilities.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | — | N/A — no installs |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```text
                    ┌─────────────────────────────────────────┐
                    │           Hyprland session               │
                    │  XF86 volume binds → wpctl set-volume    │
                    └───────────────┬─────────────────────────┘
                                    │ volume/mute changes
                                    ▼
┌──────────────┐   FileView    ┌──────────────────┐   PwNodeAudio   ┌────────────────┐
│ /proc/meminfo│──────────────►│  ResourceUsage   │◄───────────────│ PipeWire sink/ │
│ /proc/stat   │               │  (singleton)     │                │ source         │
│ df -B1 /     │──Process─────►│  cpu/mem/disk    │                └───────┬────────┘
└──────────────┘               └────────┬─────────┘                        │
                                        │ props                            │
                                        ▼                                  ▼
                               ┌─────────────────┐              ┌──────────────────┐
                               │ Resources.qml   │              │   Audio.qml      │
                               │ CPU → RAM → Disk│              │ inc/dec, mute,   │
                               │ Resource rings  │              │ auto-unmute,     │
                               │ (no popup)      │              │ 130% clamp       │
                               └────────┬────────┘              └────────┬─────────┘
                                        │                                │
          BarContent left               │         BarContent right       │
          Workspaces ── Resources ◄─────┘         FocusedScrollMouseArea │
                                                      │ scroll           │
                                                      ▼                  │
                                               Audio.inc/dec ◄───────────┘
                                                      │
                               Indicators pill: mute(+%) → mic(+%) → xkb → BT → Net → notif
                                      │ left: toggle mute
                                      │ mid/right: pavucontrol
                                      ▼
                               OnScreenDisplay (stock volume OSD)
```

### Recommended Project Structure (touch set)

```text
.config/quickshell/
├── services/
│   ├── ResourceUsage.qml      # +disk; multi-rate poll; format helpers
│   └── Audio.qml              # auto-unmute; 130% clamp; optional openMixer()
├── modules/
│   ├── common/Config.qml      # dual-threshold + interval + maxAllowed defaults
│   └── ii/bar/
│       ├── Resource.qml       # dual threshold colors; custom labelText
│       ├── Resources.qml      # CPU→RAM→Disk; no swap; no popup
│       ├── ResourcesPopup.qml # leave file; unhook from Resources (do not productize)
│       └── BarContent.qml     # mute/mic % + multi-button clicks
scripts/
└── phase03-config-assert.py   # Wave 0 live config asserts (new)
~/.config/illogical-impulse/
└── config.json                # LIVE dual-write targets
```

Vertical bar copies (`modules/ii/verticalBar/Resource*.qml`) exist but `bar.vertical: false` on host. Prefer updating them only if trivial keep-in-sync; **horizontal ii bar is the Phase 3 success surface.**

### Pattern 1: Service singleton → widget render (FWK-03)

**What:** Services own polling/PipeWire; widgets bind properties.  
**When to use:** All BAR-05..08 surfaces.  
**Example:**

```qml
// Source: services/ResourceUsage.qml + modules/ii/bar/Resources.qml [VERIFIED: codebase]
Resource {
    iconName: "planner_review"
    percentage: ResourceUsage.cpuUsage
    // extended: labelText, warningThreshold, errorThreshold
}
```

### Pattern 2: Config defaults + live JSON dual-write

**What:** `Config.qml` sets defaults; `FileView` persists to `Directories.shellConfigPath` → `~/.config/illogical-impulse/config.json`. Live values override QML defaults.  
**How to avoid footgun:** Update **both** `Config.qml` and live JSON (Phase 1/2 learning). [VERIFIED: Phase 2 RESEARCH + `Config.qml` FileView]

### Pattern 3: Process with LANG=C for CLI metrics

**What:** Disk via `Process` + `StdioCollector`, same family as `Network` / `lscpu` in `ResourceUsage`.  
**Recommended command (discretion, verified host):**

```bash
df -B1 --output=size,used,avail,pcent /
# sample host: 981238816768 414532866048 520303374336 45%
```

[VERIFIED: host `df` output]

### Pattern 4: PipeWire volume/mute are independent

**What:** `PwNodeAudio.muted` and `.volume` are separate r/w properties; setting volume does **not** clear mute.  
**Implication:** Auto-unmute must set `muted = false` explicitly when volume changes while muted. [VERIFIED: qmltypes + host `wpctl` test]

### Pattern 5: App launch via `Config.options.apps.*`

**What:** Existing waffle volume control launches mixer with:

```qml
// Source: modules/waffle/actionCenter/volumeControl/VolumeControl.qml [VERIFIED: codebase]
Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
```

`volumeMixer` default: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"` — `pavucontrol` is installed on host.

### Anti-Patterns to Avoid

- **Building a dedicated volume module** — violates D-17.
- **Re-enabling / productizing ResourcesPopup** — deferred detail phase; D-09.
- **Hand-rolling OSD** — D-24 keeps stock ii OSD.
- **Using `PwNodePeakMonitor` for mic %** — prefer volume level (discretion).
- **Updating only `Config.qml`** — live JSON will shadow thresholds.
- **Hard-capping volume at 1.0 in one path only** — `Audio.incrementVolume` and `ScreenCorners` both clamp today; fix all user-driven raise paths or 130% will be inconsistent.
- **Assuming wpctl auto-unmutes** — empirically false on this host.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CPU/RAM sampling | Custom C++/syscalls | Existing `ResourceUsage` + `/proc` FileView | Already correct; extend only |
| Disk free space | Parse every mount from sysfs by hand | `Process` + `df -B1 /` (or one-shot statvfs) | Simple, root-only, portable |
| Volume/mute control | `pactl`/`wpctl` from every click | `Audio.qml` + PipeWire QML bindings | Reactive; drives OSD |
| Circular progress | Custom Canvas from scratch | `ClippedFilledCircularProgress` | Theme-aligned, used by Resource |
| Mixer GUI | Custom QML mixer in Phase 3 | `pavucontrol` via `apps.volumeMixer` | D-23 escape hatch |
| Volume OSD | New overlay | `modules/ii/onScreenDisplay` | D-24 |
| Config persistence | Ad-hoc file write | `Config` FileView adapter | Existing dual-write |

**Key insight:** Phase 3 is extension and productization of working ii surfaces — not a second metrics stack.

---

## Common Pitfalls

### Pitfall 1: Dual-write miss on thresholds/intervals

**What goes wrong:** Change `Config.qml` defaults; bar still uses old CPU 90 / mem 95 / 3000 ms.  
**Why it happens:** Live `~/.config/illogical-impulse/config.json` already contains keys.  
**How to avoid:** Dual-write every key; Wave 0 `phase03-config-assert.py`.  
**Warning signs:** Assert fails; UAT thresholds never trip at 40/75/80.

### Pitfall 2: Single-threshold Resource only recolors to error

**What goes wrong:** Warning and error look the same (both `colError`).  
**Why it happens:** `Resource.qml` has one `warningThreshold` and one color branch.  
**How to avoid:** Add `errorThreshold`; color ladder: normal → warning color → `colError`.  
**Warning signs:** Ring jumps straight to error red at first threshold.

### Pitfall 3: Fixed label width for `"100"`

**What goes wrong:** RAM/disk labels clip or layout jumps.  
**Why it happens:** `TextMetrics { text: "100" }` assumes 3-digit percent.  
**How to avoid:** Metrics on actual `labelText` or a wide sample (`"99.9/99.9 GB"`).  
**Warning signs:** Truncated `8.5/15…` or overlapping rings.

### Pitfall 4: Volume clamp inconsistency (100% vs 130%)

**What goes wrong:** Bar scroll stops at 100% or corners stop at 100% while config says 130.  
**Why it happens:** `Audio.incrementVolume` uses `Math.min(1, …)`; `ScreenCorners` duplicates clamp; Hyprland bind uses `wpctl set-volume -l 1`.  
**How to avoid:** Centralize max in `Audio` (e.g. `maxVolume = 1.30`); call `incrementVolume` from all UI paths; dual-write `audio.protection.maxAllowed: 130`; optionally raise Hyprland `-l 1.3` (discretion — keyboard path).  
**Warning signs:** OSD shows 100% ceiling while user expects boost.

### Pitfall 5: Auto-unmute not covering keyboard path

**What goes wrong:** Bar scroll unmutes but keyboard volume wheel leaves mute on.  
**Why it happens:** `wpctl set-volume` does **not** clear mute (host-verified); mute and volume are independent.  
**How to avoid:** In `Audio.qml` `Connections` on sink/source `onVolumeChanged`, if muted and volume actually changed, set `muted = false`. Also unmute inside `incrementVolume`/`decrementVolume` before/after set.  
**Warning signs:** Icon stays `volume_off` while OSD level moves.

### Pitfall 6: Indicator MouseArea steals right-bar left-click or scroll

**What goes wrong:** Clicking mute opens sidebar, or scroll stops working over icons.  
**Why it happens:** Indicators sit inside right-sidebar `RippleButton` and `FocusedScrollMouseArea`; Phase 2 already used `z: 10` + `mouse.accepted = true` for mute.  
**How to avoid:** Keep per-icon MouseArea with explicit accepted buttons; do not block wheel unless intentional; middle/right must not fall through to sidebar toggle.  
**Warning signs:** Right-click mute opens sidebar instead of pavucontrol.

### Pitfall 7: Media-hide still drops CPU when MPRIS active

**What goes wrong:** CPU disappears during music playback.  
**Why it happens:** `shown: alwaysShowCpu || !Mpris…` — safe only if alwaysShowCpu stays true.  
**How to avoid:** Force `shown: true` for CPU/RAM/Disk in Phase 3 (D-05).  
**Warning signs:** Strip collapses to RAM-only when media plays.

### Pitfall 8: Disk parse locale / header line

**What goes wrong:** NaN disk values.  
**Why it happens:** `df` header line or localized numbers.  
**How to avoid:** `environment: { LANG: "C", LC_ALL: "C" }`; skip header; parse integers only.  
**Warning signs:** Disk ring empty; QML warnings on Number().

### Pitfall 9: ResourcesPopup still opens after “disable”

**What goes wrong:** Hover still shows popup.  
**Why it happens:** Leaving `ResourcesPopup { hoverTarget: root }` with parent still a hover-enabled MouseArea.  
**How to avoid:** Remove popup instance; set `hoverEnabled: false`; prefer `Item` root over clickable `MouseArea` for the strip.  
**Warning signs:** Hover reveals RAM/Swap/CPU popup (fails D-09).

### Pitfall 10: Protection re-clamps intentional 130%

**What goes wrong:** Setting volume to 1.30 immediately pulled back if protection enabled with maxAllowed 99.  
**Why it happens:** Live/default `audio.protection.maxAllowed: 99` (enable currently false).  
**How to avoid:** Dual-write `maxAllowed: 130`; leave enable false unless product wants protection; if enable true, max must be ≥ 130.  
**Warning signs:** Volume snaps down after boost.

---

## Code Examples

### ResourceUsage multi-rate poll (pattern)

```qml
// Source pattern: services/ResourceUsage.qml [VERIFIED: codebase]
// Extend with separate timers or a tick counter:
// - every 1s: reload /proc/stat → cpuUsage
// - every 3s: reload /proc/meminfo → memory*
// - every 10s: run df Process → disk*
Timer {
    interval: 1000
    running: true
    repeat: true
    property int tick: 0
    onTriggered: {
        fileStat.reload()
        // parse CPU ...
        tick++
        if (tick % 3 === 0) {
            fileMeminfo.reload()
            // parse memory ...
        }
        if (tick % 10 === 0) {
            diskProc.running = true
        }
    }
}
```

### Dual-threshold ring color (Resource.qml extension)

```qml
// Source: modules/ii/bar/Resource.qml + Appearance.colors [VERIFIED: codebase]
// Appearance has colError; no dedicated colWarning — recommend colPrimary (or colTertiary) for warning tier [ASSUMED: best token choice]
property int warningThreshold: 100
property int errorThreshold: 100
readonly property real pct: percentage * 100
readonly property bool isError: pct >= errorThreshold
readonly property bool isWarning: !isError && pct >= warningThreshold
// colPrimary: isError ? Appearance.colors.colError
//            : isWarning ? Appearance.colors.colPrimary
//            : Appearance.colors.colOnSecondaryContainer
```

### Disk Process

```qml
// Source pattern: ResourceUsage findCpuMaxFreqProc + Network Process [VERIFIED: codebase]
Process {
    id: diskProc
    environment: ({ LANG: "C", LC_ALL: "C" })
    command: ["df", "-B1", "--output=size,used,avail,pcent", "/"]
    stdout: StdioCollector {
        onStreamFinished: {
            // skip header; parse size used avail pcent
        }
    }
}
```

### Human capacity label (auto G/T)

```qml
// Source: adapt ResourceUsage.kbToGbString [VERIFIED: codebase]
function formatBytesFromKb(kb) {
    const gb = kb / (1024 * 1024);
    if (gb >= 1024)
        return (gb / 1024).toFixed(1) + "T";
    return gb.toFixed(1) + "G";
}
// RAM label: `${formatBytesFromKb(memoryUsed)}/${formatBytesFromKb(memoryTotal)}`
// Disk label (free/total): `${formatBytesFromKb(diskAvail/1024)}/${formatBytesFromKb(diskTotal/1024)}`
// Note: df -B1 returns bytes; convert consistently [ASSUMED: use one unit base throughout]
```

### Auto-unmute + 130% max (Audio.qml)

```qml
// Source: services/Audio.qml [VERIFIED: codebase] — recommended changes
readonly property real maxVolume: 1.30  // D-22

function incrementVolume() {
    if (sink?.audio) {
        if (sink.audio.muted)
            sink.audio.muted = false; // D-21 for scroll path
        const step = value < 0.1 ? 0.01 : 0.02;
        sink.audio.volume = Math.min(maxVolume, sink.audio.volume + step);
    }
}

// In Connections on sink.audio:
// onVolumeChanged: if protection ...; if muted && volume changed by external → muted = false
// Host test: wpctl set-volume while MUTED leaves [MUTED] [VERIFIED: host 2026-07-23]
```

### Mute indicator with % + multi-button click

```qml
// Source: BarContent.qml indicators + VolumeControl launch [VERIFIED: codebase]
Row {
    spacing: 2
    MaterialSymbol {
        text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
        // ...
    }
    StyledText {
        visible: !(Audio.sink?.audio?.muted ?? false)
        text: `${Math.round((Audio.sink?.audio?.volume ?? 0) * 100)}%`
        // Note: volume may be >1.0 → shows 130% when boosted
    }
    MouseArea {
        anchors.fill: parent
        z: 10
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                Audio.toggleMute();
            else
                Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
            mouse.accepted = true;
        }
    }
}
```

### Config keys to dual-write (recommended)

```json
{
  "bar": {
    "resources": {
      "alwaysShowCpu": true,
      "alwaysShowSwap": false,
      "cpuWarningThreshold": 40,
      "cpuErrorThreshold": 80,
      "memoryWarningThreshold": 75,
      "memoryErrorThreshold": 95,
      "diskWarningThreshold": 80,
      "diskErrorThreshold": 95
    }
  },
  "resources": {
    "updateInterval": 1000,
    "memoryUpdateInterval": 3000,
    "diskUpdateInterval": 10000,
    "historyLength": 60
  },
  "audio": {
    "protection": {
      "enable": false,
      "maxAllowed": 130,
      "maxAllowedIncrease": 10
    }
  }
}
```

Exact key nesting is planner discretion as long as dual-write + assert cover D-07/D-08/D-13/D-14/D-22. [ASSUMED: interval key names if split]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Waybar `cpu` / `custom/memory` / `disk` / `pulseaudio` modules | ii `Resources` rings + PipeWire indicators | Phase 1 wholesale ii | Productize, don't re-port Waybar scripts |
| Single `warningThreshold` → error color | Dual warning/error thresholds | Phase 3 (this) | Matches D-07/D-13 |
| Media-hide swap/CPU | Always-visible CPU/RAM/Disk | Phase 3 | Predictable strip width |
| Volume hard-cap 100% in UI | Allow 130% boost | Phase 3 | Matches user keyboard/boost intent |
| Mute icons only | Icon + % (unmuted) | Phase 3 | Waybar-like volume read |

**Deprecated/outdated for this phase:**

- **ResourcesPopup as product surface** — deferred to dedicated detail phase.
- **Swap on bar** — rejected for Phase 3.
- **Dedicated volume module** — rejected D-17.
- **Waybar memory.sh / disk on-click nautilus** — parity reference only; no click on resources.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Warning-tier color should use `Appearance.colors.colPrimary` (no `colWarning` token exists) | Code Examples / Resource | Visual mismatch; user may want amber-like tertiary mix |
| A2 | Disk bytes from `df -B1` should convert with 1024-base (GiB/TiB style) for G/T labels | Disk formatting | Label disagrees with Waybar/df -h (1000-base) slightly |
| A3 | Mic % = `Audio.source.audio.volume` (not peak meter) | BAR-08 | If source volume missing for some devices, % blank |
| A4 | Split interval config key names (`memoryUpdateInterval`, `diskUpdateInterval`) | Config dual-write | Planner may keep single interval + counters without new keys |
| A5 | Hyprland `wpctl -l 1` may remain 100% for keyboard; bar path still hits 130% | Pitfall 4 | Keyboard cannot boost past 100% until bind updated |
| A6 | Vertical bar Resource copies can lag horizontal without failing Phase 3 success criteria | Structure | Vertical mode users (none on host) see old UI |

**If this table is empty:** N/A — assumptions listed above need planner/user awareness.

---

## Open Questions

1. **Hyprland keyboard volume ceiling vs D-22**
   - What we know: binds use `wpctl set-volume -l 1` (100% hard limit). [VERIFIED: `.config/hypr/hyprland.conf`]
   - What's unclear: whether Phase 3 must raise to `-l 1.3` for keyboard boost parity.
   - Recommendation: Implement 130% in `Audio.qml` UI paths for sure; treat Hyprland bind update as optional same-phase fix if UAT expects keyboard boost to 130%.

2. **Warning color token**
   - What we know: `colError` exists; no `colWarning`. Tertiary is muted pink-gray, not “warning amber.” [VERIFIED: Appearance.qml]
   - What's unclear: preferred Material token for warning tier.
   - Recommendation: `colPrimary` for warning, `colError` for error; UAT can recolor if needed.

3. **Whether to dual-write interval split keys or only change timer internals**
   - What we know: only `resources.updateInterval: 3000` exists today. [VERIFIED: Config + live JSON]
   - Recommendation: Prefer configurable intervals dual-written for assertability; counters with hard-coded 1/3/10 also satisfy D-08/D-14 if documented.

4. **Protection enable flag**
   - What we know: `audio.protection.enable: false`, `maxAllowed: 99`.
   - Recommendation: Keep enable false; still set maxAllowed 130 so enabling later does not re-break boost.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Quickshell | Shell runtime | ✓ | 0.3.0 | — |
| PipeWire / WirePlumber | Audio BAR-08 | ✓ | wpctl present | — |
| pavucontrol | D-23 mixer | ✓ | `/usr/bin/pavucontrol` | `pavucontrol-qt` via launch script |
| df | Disk BAR-07 | ✓ | coreutils | `statvfs` via python3 Process |
| python3 | Config assert script | ✓ | 3.14.6 | — |
| /proc/meminfo, /proc/stat | CPU/RAM | ✓ | kernel | — |
| Root filesystem `/` | Disk | ✓ | nvme, ~45% used | — |

**Missing dependencies with no fallback:** none  
**Missing dependencies with fallback:** `pavucontrol-qt` not required (`pavucontrol` present)

---

## Validation Architecture

> `workflow.nyquist_validation: true` in `.planning/config.json` — section required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual QML validation (quickshell runtime) + shell smoke + Python config asserts (same as Phase 2) |
| Config file | none — no unit test framework for QML |
| Quick run command | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded\|Error'` |
| Full suite command | smoke + `python3 scripts/phase03-config-assert.py` + static `rg` gates + human UAT |
| Estimated runtime | ~10–30s automated; UAT separate |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BAR-05 | CPU ring + `%` on bar; updates ~1s | static + smoke + UAT | `rg -n 'cpuUsage|planner_review' modules/ii/bar/Resources.qml` | ✅ source; UAT visual |
| BAR-05 | Dual thresholds 40/80 dual-written | config assert | `python3 scripts/phase03-config-assert.py` | ❌ Wave 0 |
| BAR-06 | RAM used/total GB label; no swap widget | static | `rg -n 'swap_horiz' modules/ii/bar/Resources.qml` expect **no** bar instance | ✅ source |
| BAR-06 | RAM thresholds 75/95 | config assert | phase03 assert | ❌ Wave 0 |
| BAR-07 | Disk Process/props for `/` | static | `rg -n 'disk\|df ' services/ResourceUsage.qml` | ❌ until implemented |
| BAR-07 | Order CPU then RAM then Disk | static | child order in `Resources.qml` | ✅ after edit |
| BAR-07 | Disk thresholds 80/95; ~10s interval | config assert | phase03 assert | ❌ Wave 0 |
| BAR-08 | Volume % text when unmuted | static | `rg -n 'volume_off|Audio.sink' modules/ii/bar/BarContent.qml` | ✅ partial |
| BAR-08 | incrementVolume max ≥ 1.30 | static | `rg -n '1\.3|maxVolume|Math.min\\(1' services/Audio.qml` | ✅ after edit |
| BAR-08 | Auto-unmute on volume change | static + UAT | `rg -n 'muted = false' services/Audio.qml` | ❌ until implemented |
| BAR-08 | Middle/right → volumeMixer | static | `rg -n 'volumeMixer' modules/ii/bar/BarContent.qml` | ❌ until implemented |
| D-09 | No ResourcesPopup hover | static | `rg -n 'ResourcesPopup' modules/ii/bar/Resources.qml` expect absent/disabled | ✅ after edit |
| Smoke | Configuration Loaded | smoke | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded'` | ✅ runtime |

### Sampling Rate

- **Per task commit:** `timeout 4 quickshell 2>&1 | rg 'Configuration Loaded|Error'`
- **Per wave merge:** smoke + `python3 scripts/phase03-config-assert.py` + static gates for that wave
- **Phase gate:** Full suite green + UAT BAR-05..08 before `/gsd-verify-work`
- **Max feedback latency:** ~30s automated

### Wave 0 Gaps

- [ ] `scripts/phase03-config-assert.py` — asserts dual-written keys:
  - `bar.resources.cpuWarningThreshold == 40`
  - `bar.resources.cpuErrorThreshold == 80` (or agreed key names)
  - `bar.resources.memoryWarningThreshold == 75`
  - `bar.resources.memoryErrorThreshold == 95`
  - `bar.resources.diskWarningThreshold == 80`
  - `bar.resources.diskErrorThreshold == 95`
  - `bar.resources.alwaysShowCpu is True`
  - CPU/RAM/disk intervals match D-08/D-14 (if dual-written)
  - `audio.protection.maxAllowed >= 130`
- [ ] Static gate snippets in VALIDATION.md for: Resources order, no swap UI, no ResourcesPopup attach, Audio maxVolume, mute % visibility, volumeMixer click
- [ ] Framework install: **none** — reuse Phase 1/2 smoke pattern

### Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CPU % updates live | BAR-05 | Visual timing | Stress CPU (`yes > /dev/null`); ring/label move within ~1–2s |
| RAM GB label sensible | BAR-06 | Visual + units | Compare to `free -h` roughly; no % on label |
| Disk free/total for `/` | BAR-07 | Visual | Compare to `df -h /`; ring tracks used% |
| Scroll right bar changes volume | BAR-08 | Input | Wheel over right region; OSD + % update |
| Click mute toggles; % hides when muted | BAR-08 | UI | Left-click mute icon; icon → volume_off; % gone |
| Volume while muted auto-unmutes | BAR-08 | UI + keyboard | Mute; scroll or keyboard volume; icon unmutes |
| Volume can reach ~130% | BAR-08 | UI | Scroll up past 100%; label/OSD ~130 |
| Middle/right opens pavucontrol | BAR-08 | Process | Middle/right on mute or mic; mixer window |
| No resource hover popup | D-09 | UI | Hover CPU/RAM/Disk; no popup |
| Mic % tracks input gain | BAR-08 | UI | Change source volume in pavucontrol; mic % updates |

---

## Security Domain

> `security_enforcement` enabled (ASVS level 1 per `.planning/config.json`).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Local desktop session only |
| V3 Session Management | no | — |
| V4 Access Control | no | User-owned session processes only |
| V5 Input Validation | yes | Parse `df` /proc with regex/Number; reject non-numeric |
| V6 Cryptography | no | — |
| V5.3 OS command | yes | Prefer argv arrays (`["df",…]`); mixer launch uses existing trusted Config string + bash -c pattern |

### Known Threat Patterns for Quickshell bar metrics/audio

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious live config thresholds / volumeMixer string | Tampering | Dual-write from known defaults; assert script; volumeMixer already user-controlled config (same as stock ii) |
| Shell injection via crafted volumeMixer | Elevation / Injection | Keep using existing Config path; do not interpolate untrusted bar text into shell; argv form preferred for new Process |
| Unexpected Process spam (df every 1s) | Denial of service | Disk interval ~10s (D-14) |
| Accidental volume blast to 200%+ | Tampering / DoS-audio | Clamp to 1.30 user max + hardMaxValue 2.00 safety |
| Sensitive path disclosure in disk tooltips | Info disclosure | No disk tooltip Phase 3 (D-16) |

### Trust boundaries (Phase 3)

| Boundary | Data |
|----------|------|
| Host `/proc` + `df` | Metrics only; local |
| PipeWire session | Volume/mute; local |
| Live config JSON | Thresholds, intervals, maxAllowed, volumeMixer command |
| pavucontrol child process | User-launched mixer UI |

---

## Sources

### Primary (HIGH confidence)

- `.config/quickshell/modules/ii/bar/Resources.qml` — strip order, media-hide, ResourcesPopup
- `.config/quickshell/modules/ii/bar/Resource.qml` — ring + single threshold + percent text
- `.config/quickshell/services/ResourceUsage.qml` — /proc polling, no disk, 3s interval
- `.config/quickshell/services/Audio.qml` — mute, inc/dec cap at 1.0, protection
- `.config/quickshell/modules/ii/bar/BarContent.qml` — Resources placement, right scroll, mute/mic
- `.config/quickshell/modules/common/Config.qml` — bar.resources, resources.updateInterval, audio.protection, apps.volumeMixer
- `~/.config/illogical-impulse/config.json` — live overrides (thresholds 90/95, interval 3000, maxAllowed 99)
- `/usr/lib/qt6/qml/Quickshell/Services/Pipewire/quickshell-service-pipewire.qmltypes` — PwNodeAudio muted/volume API
- Host empirical: `wpctl set-volume` while MUTED leaves `[MUTED]` (2026-07-23)
- Host empirical: `df -B1 --output=size,used,avail,pcent /` works; root ~45% used
- `.config/waybar/config.jsonc` + `scripts/system/memory.sh` — parity reference for labels
- `.planning/phases/02-core-bar-modules/02-RESEARCH.md` + `02-VALIDATION.md` — dual-write + nyquist patterns
- `modules/ii/onScreenDisplay/OnScreenDisplay.qml` — stock OSD listens to volume/mute

### Secondary (MEDIUM confidence)

- `modules/waffle/actionCenter/volumeControl/VolumeControl.qml` — volumeMixer launch pattern
- `modules/ii/screenCorners/ScreenCorners.qml` — duplicate volume clamp at 1.0
- Hyprland binds XF86 volume with `-l 1` — keyboard 100% ceiling

### Tertiary (LOW confidence)

- Warning color token choice (`colPrimary` vs custom mix) — no Material “warning” token in Appearance [ASSUMED]
- Exact dual-write key names for split intervals [ASSUMED]

---

## Project Constraints (from CLAUDE.md)

`./.claude/CLAUDE.md` is referenced in `.planning/config.json` (`claude_md_path`) but **file is absent** in the working tree at research time. No additional CLAUDE.md directives to enforce.

Project-level constraints still in force from planning docs:

- **No ddcutil / brightness polling** (iGPU crash post-mortem) — Phase 3 must not reintroduce backlight.
- **Wholesale ii, fix-not-rewrite** (Phase 1 philosophy).
- **Service-singleton pattern** (FWK-03).
- **Dual-write Config.qml + live config.json** (Phase 1/2 learning).

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Standard stack | HIGH | Host tools + existing services verified; no new packages |
| Architecture | HIGH | Full read of Resource/Audio/BarContent/Config + gap matrix |
| Pitfalls | HIGH | Dual-write, mute independence, clamp paths empirically verified |
| Disk implementation detail | MEDIUM | Process+df recommended; not yet in tree |
| Warning color token | LOW–MEDIUM | No colWarning; recommendation assumed |

**Research date:** 2026-07-23  
**Valid until:** 2026-08-22 (30 days; shell APIs stable)

**Runtime State Inventory:** SKIPPED — not a rename/refactor/migration phase.

**Graph context:** `.planning/graphs/graph.json` absent — no graphify queries.
