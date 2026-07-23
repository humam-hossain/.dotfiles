# Phase 3: System & Audio Modules - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add and verify **system resource monitoring** and **audio volume control** on the existing Illogical Impulse bar so the shell approaches Waybar parity for hardware/system indicators.

**In scope (roadmap BAR-05..08):**
- **BAR-05** — CPU utilization visible and updating on the bar
- **BAR-06** — RAM utilization visible and updating on the bar
- **BAR-07** — Disk space for root (`/`) visible on the bar
- **BAR-08** — Volume level displayed; scroll adjusts volume; click toggles mute (plus Phase-3 audio polish locked below)

**Out of scope for this phase:**
- Detailed system-resources dashboard (graphs, sensors, process lists) — future dedicated phase
- Weather, ping, power, notifications product work (other phases / v2)
- IPC, keybinds, Waybar cutover (Phase 4)
- Brightness/backlight (project constraint — no ddcutil)
- New dedicated volume module widget (enhance existing mute indicator instead)

Phase 2 already placed `Resources` on the left bar and mute/mic in the D-19 indicators pill. This phase **configures, extends, and productizes** those surfaces — not a greenfield bar rewrite.

</domain>

<decisions>
## Implementation Decisions

### Resource strip — CPU & RAM (BAR-05, BAR-06)
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

### Disk (BAR-07)
- **D-10:** **Ring + free/total** text (Waybar-like capacity read), same visual family as RAM.
- **D-11:** Monitor **root `/` only** (not multi-mount /home).
- **D-12:** Placement: **CPU → RAM → Disk** inside the Resources cluster (extend `Resources.qml` / related row — not a separate bar region).
- **D-13:** Thresholds on **used %**: warning ≥ **80%**, error ≥ **95%**.
- **D-14:** Refresh interval **~10s** (disk changes slowly; not tied to 1s CPU).
- **D-15:** Label units: **auto human (G/T)** — switch to TB when totals warrant; consistent with readable capacity labels.
- **D-16:** No disk click, no disk tooltip this phase (same as CPU/RAM).

### Volume & mic surface (BAR-08)
- **D-17:** **No dedicated volume module.** Enhance the existing **mute indicator** in the D-19 indicators pill (and mic beside it).
- **D-18:** **Output unmuted:** Material volume icon + **volume %**. **Muted:** `volume_off` icon **only** (no %).
- **D-19:** **Mic unmuted:** mic icon + **input level %**. **Muted:** `mic_off` icon **only**.
- **D-20:** **Scroll:** keep **whole right-bar** volume scroll (existing `FocusedScrollMouseArea` habit). Do **not** add a separate scroll-only volume widget.
- **D-21:** **Auto-unmute:** if the user changes volume by **any** path (bar scroll, keyboard volume wheel, etc.) while muted, **unmute automatically**. Same spirit for mic if input gain is changed while mic-muted (planner verifies against Pipewire APIs).
- **D-22:** **Max volume ceiling: 130%** (1.30 linear). Update protection / clamp logic so intentional boost up to 130% is allowed; do not hard-cap at 100% for user-driven changes.
- **D-23:** **Click** on output mute indicator = **toggle mute**. **Middle-click and/or right-click** = open **pavucontrol** (use existing Config launch helper if present). **Same click map for mic** (toggle mic mute; middle/right → pavucontrol).
- **D-24:** **Volume OSD:** do not build a new OSD this phase — **keep whatever ii already does**.

### Click / detail destinations
- **D-25:** Resource strip (CPU/RAM/Disk): **no click**, **no tooltip**, **no popup** in Phase 3.
- **D-26:** Audio detail escape hatch is **pavucontrol** via middle/right on mute/mic only — not via resource strip.

### Agent's Discretion
- Exact QML structure for dual-threshold ring colors (warning vs error) — may extend `Resource.qml` props
- How to implement disk free/total (FileView, Process/`df`, Quickshell IO) as long as root `/` is correct and ~10s refresh holds
- Auto-human G/T formatting helper shared with RAM if useful
- Whether right-bar scroll stays global while indicator also accepts wheel (must not regress right-bar habit)
- Dual-write `Config.qml` + live `~/.config/illogical-impulse/config.json` for new thresholds/intervals (Phase 2 pattern)
- Exact pavucontrol launch command (existing `Config.options.apps.volumeMixer` / launch_first_available pattern)
- Mic input % source from Pipewire default source volume vs peak meter — prefer **volume level** (not VU meter) unless volume is unavailable

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning
- `.planning/PROJECT.md` — Core value (Waybar parity), no ddcutil, Material/ii foundation
- `.planning/REQUIREMENTS.md` — BAR-05, BAR-06, BAR-07, BAR-08; ADV-05 volume OSD is later advanced
- `.planning/ROADMAP.md` — Phase 3 goal + four success criteria
- `.planning/STATE.md` — Current position Phase 3
- `.planning/phases/01-shell-foundation-theme/01-CONTEXT.md` — Wholesale ii, fix-not-rewrite philosophy
- `.planning/phases/02-core-bar-modules/02-CONTEXT.md` — D-15 layout (Resources left; D-19 indicators mute→mic→…); dual-write config; always-visible indicators UAT overrides

### Implementation (this repo)
- `.config/quickshell/modules/ii/bar/Resources.qml` — CPU/memory/swap strip; media-hide; ResourcesPopup host
- `.config/quickshell/modules/ii/bar/Resource.qml` — Ring + percentage text; single warningThreshold
- `.config/quickshell/modules/ii/bar/ResourcesPopup.qml` — **Disable for Phase 3** (D-09)
- `.config/quickshell/services/ResourceUsage.qml` — `/proc/meminfo` + `/proc/stat`; no disk yet; updateInterval
- `.config/quickshell/services/Audio.qml` — Pipewire sink/source, mute, increment/decrement, protection max
- `.config/quickshell/modules/ii/bar/BarContent.qml` — Resources placement; right-side volume scroll; D-19 mute/mic indicators
- `.config/quickshell/modules/common/Config.qml` — `bar.resources.*`, `resources.updateInterval`, `audio.protection`, apps volumeMixer
- `.config/waybar/config.jsonc` — Parity reference: cpu, custom/memory, disk, pulseaudio
- `.config/waybar/scripts/system/memory.sh` — Waybar RAM `used/total` + % reference (Phase 3 bar uses GB text without %)

### Prior maps (may be stale vs wholesale ii)
- `.planning/codebase/ARCHITECTURE.md`
- `.planning/codebase/STRUCTURE.md`
- `.planning/codebase/STACK.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Resources.qml` + `Resource.qml` — Circular progress + label; extend for dual thresholds, RAM GB text, disk, drop swap, force always-shown
- `ResourceUsage.qml` — CPU/RAM polling already; add disk for `/`; adjust intervals
- `Audio.qml` — `toggleMute` / `toggleMicMute` / `incrementVolume` / `decrementVolume` / protection clamps — extend for auto-unmute and 130% max
- Indicators in `BarContent.qml` — mute/mic `MaterialSymbol` rows; add % text and middle/right click handlers
- `Config.options.apps.volumeMixer` / launch script pattern — pavucontrol open path

### Established Patterns
- Service singleton → widget render (FWK-03)
- Dual-write Config.qml defaults + live config.json (Phase 2)
- Indicators pill is one visual cluster; per-icon MouseAreas already used for mute/mic after Phase 2 UAT
- Right section volume scroll via `FocusedScrollMouseArea` wrapping right content
- Warning via recolor of ring (`Appearance.colors.colError`) — needs warning-tier color addition for two-step

### Integration Points
- Left bar: Workspaces → **Resources** (CPU/RAM/Disk) per Phase 2 layout minus ActiveWindow
- Right bar: Media → Battery → SysTray → **Indicators** (mute with % → mic with % → xkb → BT → Network → notif)
- Waybar still coexists until Phase 4 — dual bars OK during testing
- Pipewire via `Quickshell.Services.Pipewire` (not pulseaudio CLI)

</code_context>

<specifics>
## Specific Ideas

- Hybrid aesthetic: **ii rings** + **Waybar-like capacity labels** (GB free/total for RAM/disk; % for CPU and volume)
- User has a **dedicated keyboard volume wheel** — volume changes from hardware must auto-unmute (D-21)
- **130%** max volume is intentional boost, not a bug
- **Detailed resources UI** (graphs, sensors, "lots of things") explicitly deferred to a **dedicated future phase** — Phase 3 must not half-build that popup
- Mic gets the same level-display treatment as output (user requested symmetry)

</specifics>

<deferred>
## Deferred Ideas

- **Dedicated resources detail phase** — rich popup/dashboard with graphs, sensors, process detail, etc. (user: plan in detail later; not Phase 3)
- **Volume OSD product work** — ADV-05; keep stock ii behavior only this phase
- **Weather / ping / power modules** — not Phase 3
- **IPC / keybinds / Waybar cutover** — Phase 4
- **Swap on bar** — rejected for Phase 3; may appear in future detail UI
- **btop / nautilus on resource click** — rejected for Phase 3 (no click on strip)

</deferred>

---

*Phase: 3-System & Audio Modules*
*Context gathered: 2026-07-23*
