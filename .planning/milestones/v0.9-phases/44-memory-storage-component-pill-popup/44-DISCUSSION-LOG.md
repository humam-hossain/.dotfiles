# Phase 44: Memory & Storage Component (Pill & Popup) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-28
**Phase:** 44-memory-storage-component-pill-popup
**Areas discussed:** Status Bar Pill Presentation & Responsive Layout, Popup Memory Breakdown & Visual Hierarchy, Multi-Mount Storage & Cloud FUSE Layout, Disk I/O Activity & Live Throughput

---

## Status Bar Pill Presentation & Responsive Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Percentage with Circular Progress Meter | Matches CpuGpuPill design and keeps pill compact | ✓ |
| Used RAM in Gigabytes | Direct volume readout without total capacity overhead | |
| Fractional Gigabytes | Complete memory context, but requires wider pill width | |
| Percentage and Used GB | Maximum immediate detail | |

**User's choice:** Percentage with Circular Progress Meter (Ring with 'memory' icon + '46%') — Matches CpuGpuPill design and keeps pill compact.  
**Notes:** Creates visual unity across all telemetry pills.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Dual Circular Progress Rings | RAM ring + Root '/' Storage ring with 'storage' icon — Symmetrical with CpuGpuPill | ✓ |
| Dynamic Active Disk Focus | Displays Root '/' normally, switches to active disk during heavy I/O | |
| Compact Disk Text | RAM circular progress ring + compact icon with percentage text | |
| You decide | Flexible builder discretion | |

**User's choice:** Dual Circular Progress Rings (RAM ring + Root '/' Storage ring with 'storage' icon) — Symmetrical with CpuGpuPill's CPU+GPU layout.  
**Notes:** Clean symmetrical aesthetic with two circular progress meters.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Hide Storage, Keep RAM Only | Drop Storage ring & text when shortened, showing only RAM ring + % | |
| Icons & Rings Only | Hide percentage text for both, showing only rings with inner icons | |
| Retain Both with Compact Spacing | Keep both rings and percentages, but tighten padding and margins | |
| Freeform User Input | "retain both and no need compact spacing, match the spacing as the CPU GPU pill okay" | ✓ |

**User's choice:** Retain both and no need compact spacing, match the spacing as the CPU GPU pill okay.  
**Notes:** User explicitly instructed to keep both RAM and Storage rings and percentages with identical spacing to `CpuGpuPill`.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Unified 70%/90% Two-Tier Alert | RAM and Storage both turn amber at >=70%, red with breathing pulse at >=90% | ✓ |
| Tiered Disk Thresholds | RAM at 70%/90%, but Storage at 85% amber / 95% critical red | |
| Color Change Only | Turn amber/red on thresholds, but keep static without breathing animation | |
| You decide | Flexible builder discretion | |

**User's choice:** Unified 70%/90% Two-Tier Alert — RAM and Storage both turn amber at >=70%, red with breathing pulse at >=90% (100% parity with CpuGpuPill).  
**Notes:** Consistent alert semantics across CPU, GPU, Memory, and Storage.

---

## Popup Memory Breakdown & Visual Hierarchy

| Option | Description | Selected |
|--------|-------------|----------|
| Multi-Segment Stacked Allocation Bar | Visual bar partitioned into Used, Buffers/Cached, and Free/Available | ✓ |
| Single Master Progress Bar | Standard progress bar showing total active Used RAM % | |
| Large Circular Progress Gauge | Large central circular ring matching the pill | |
| You decide | Flexible builder discretion | |

**User's choice:** Multi-Segment Stacked Allocation Bar — Visual bar partitioned into Used (active), Buffers/Cached (reclaimable cache), and Free/Available, with overall GB readout.  
**Notes:** Gives immediate structural insight into RAM allocation.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Metric Progress Rows | Individual progress bars for Used, Available, Cached, Buffers | |
| Key-Value Stats Grid | Clean two-column table/grid of labels and GB values | |
| Expandable Details Drawer | Main summary visible by default, details in drawer | |
| Freeform User Input | Clean un-complicated numbers for Used, Available, Buffers, Cached, Free, and Swap with two-tier amber/critical red threshold colors and pulsing | ✓ |

**User's choice:** "in the pop up I think available Used Buffers, Cached, Free And Swap And that's all there is to it I think Buffers or Swap are the same or not Like do not make it complicated There is a pop up Show Just show numbers I don't think anything else is needed. and also same tracial concept would be for each one of them right? like warning ember and critical stuff like that that should be there passing effect those are those should be there"  
**Notes:** User emphasized clarity and simplicity: present numbers clearly without needless visual overengineering, maintaining amber/critical pulsing effects.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic Swap Reveal | Only reveal the Swap section when Swap usage > 0% | |
| Always Visible Swap Row | Show Swap at all times so swap availability is always confirmed | |
| Freeform User Input | Show Swap in popup only if swap is configured/exists (swapTotal > 0); never show on pill | ✓ |

**User's choice:** Show swap in the popup if it actually exists on the system (`swapTotal > 0`); never display swap in the status bar pill. (User noted no swap is currently set up on their machine).  
**Notes:** Clean contextual suppression when unconfigured.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Balanced Two-Column Layout | Memory on Left, Storage & Disks on Right (mirrors CpuGpuPopup) | ✓ |
| Single Vertical Stack | Memory card on Top, Storage card on Bottom | |
| Unified Single Card with Tabs | Tabbed interface between Memory and Storage | |
| You decide | Flexible builder discretion | |

**User's choice:** Balanced Two-Column Layout (Memory on Left, Storage & Disks on Right) — Mirrors CpuGpuPopup width and card structure.  
**Notes:** Structural visual symmetry with `CpuGpuPopup.qml`.

---

## Multi-Mount Storage & Cloud FUSE Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Friendly Name with Mount Path Subtext | Prominent friendly name with mount path in smaller subtle font | |
| Mount Path as Primary Label | Use mount path ('/', '/mnt/windows') as primary title | |
| Device Name + Mount Path | Use raw block device name ('nvme1n1p2', 'sda1') alongside mount point | ✓ |
| You decide | Flexible builder discretion | |

**User's choice:** Device Name + Mount Path — Use raw block device name ('nvme1n1p2', 'sda1') alongside mount point.  
**Notes:** Clear, unambiguous identification of exact underlying partitions.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Two Sub-Sections with Headers | Distinct 'Physical Drives' and 'Cloud Mounts' sections | ✓ |
| Unified Flat List with Cloud Badges | All mounts in a single list with cloud badges | |
| Physical Drives Primary with Cloud Drawer | Cloud mounts tucked into an expandable drawer | |
| You decide | Flexible builder discretion | |

**User's choice:** Two Sub-Sections with Headers — Distinct 'Physical Drives' and 'Cloud Mounts' sections inside the Storage card, each with clean progress bars.  
**Notes:** Clear separation between local hardware and remote network mounts.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic Display | Show mounted cloud drives; if none connected, hide Cloud Mounts entirely | ✓ |
| Static Section with Placeholder | Always keep header, showing 'No cloud drives active' | |
| Configured List with Offline Status | List known drives showing 'Disconnected' | |
| You decide | Flexible builder discretion | |

**User's choice:** Dynamic Display — Show currently mounted cloud drives; if none are connected, hide the Cloud Mounts sub-section entirely (zero clutter).  
**Notes:** Zero visual overhead when remote shares are not mounted.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Used / Total GB + Percentage | Standard desktop convention ('45.2 / 120.0 GB (38%)') | ✓ |
| Free Space Remaining + Percentage | Emphasizes remaining headroom | |
| Used GB and Free GB Explicit | Detailed breakdown without fractional slash | |
| You decide | Flexible builder discretion | |

**User's choice:** Used / Total GB + Percentage (e.g. '45.2 / 120.0 GB (38%)') — Standard desktop convention showing both consumed and total capacity alongside the progress bar.  
**Notes:** Standard and informative.

---

## Disk I/O Activity & Live Throughput

| Option | Description | Selected |
|--------|-------------|----------|
| Pure Capacity in Pill (I/O in Popup Only) | Pill strictly focused on capacity %, I/O in popup | ✓ |
| Subtle Pill Icon Activity Glow | Storage icon reflects active I/O | |
| Pill Activity Dot | Small indicator dot next to storage ring | |
| You decide | Flexible builder discretion | |

**User's choice:** Pure Capacity in Pill (I/O in Popup Only) — Keep the pill cleanly focused on capacity %, reserving live I/O % and read/write speeds for the popup.  
**Notes:** Keeps the status bar calm and uncluttered.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Storage Header I/O Bar | Dedicated row at top showing overall load and R/W speeds | |
| Footer Throughput Summary | Throughput placed in footer bar | |
| Integrated with Title | Compact throughput badge directly in the Storage card title header | ✓ |
| You decide | Flexible builder discretion | |

**User's choice:** Integrated with Title — Compact throughput badge directly in the Storage card title header.  
**Notes:** Compact, integrated header presentation.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle Activity Highlight | Small indicator dot or accent highlight on active drive progress bar | ✓ |
| Uniform Display (No Highlight) | Keep all drive rows visually uniform | |
| Bold Active Drive Focus | Tinted background container on active drive | |
| You decide | Flexible builder discretion | |

**User's choice:** Subtle Activity Highlight — Small indicator dot or accent highlight on the progress bar of whichever drive is actively performing I/O.  
**Notes:** Quick visual identification of active disk I/O without overwhelming the layout.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-Scaling Units | Automatically adapts to scale (B/s, KB/s, MB/s with 1 decimal) | ✓ |
| Fixed MB/s | Always display in megabytes per second | |
| You decide | Flexible builder discretion | |

**User's choice:** Auto-Scaling Units (B/s, KB/s, MB/s with 1 decimal place) — Automatically adapts to scale (e.g. '350 KB/s', '12.4 MB/s').  
**Notes:** Optimal readability at all I/O rates.

---

## the agent's Discretion

- Exact mathematical smoothing or threshold rounding for multi-segment stacked bar sub-segments.
- Exact icon glyphs for Google Drive cloud mounts if distinguished from generic storage icons.

## Deferred Ideas

- None — discussion stayed strictly within Phase 44 boundary. Left zone integration deferred to Phase 46.
