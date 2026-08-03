# Phase 10: Full-install impact inventory - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-04
**Phase:** 10-Full-install impact inventory
**Areas discussed:** Inventory artifact shape, Evidence sources, Flag-axis presentation, Personal surface depth

---

## Inventory artifact shape

### Where should the committed impact inventory live?

| Option | Description | Selected |
|--------|-------------|----------|
| Phase dir markdown (Recommended) | `.planning/phases/10-.../10-INVENTORY.md` | ✓ |
| docs/ playbook sibling | `docs/dots-hyprland-full-install-inventory.md` | |
| Both: phase SoT + docs summary | Full matrix in phase dir; short docs pointer | |

**User's choice:** Phase dir markdown
**Notes:** Single SoT next to phase plans for Phase 11.

### What form should the inventory document take?

| Option | Description | Selected |
|--------|-------------|----------|
| One multi-section markdown (Recommended) | Single `10-INVENTORY.md` with tables | ✓ |
| Split files by flag axis | Separate hypr/misc/sysupdate files | |
| You decide | Planner picks minimal structure | |

**User's choice:** One multi-section markdown

### Machine-specific host snapshot?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — dated host presence table (Recommended) | Live + (originally) repo presence | ✓ (later narrowed to live-only in Evidence) |
| Generic only | Setup capability map only | |
| Host snapshot as appendix only | Core generic; appendix can go stale | |

**User's choice:** Yes — dated host presence table
**Notes:** Evidence sources later locked host tree to live XDG only.

### Uncertain / unverified rows?

| Option | Description | Selected |
|--------|-------------|----------|
| Mark UNKNOWN + research note (Recommended) | Keep row; never invent certainty | ✓ |
| Omit until proven | Only confirmed paths | |
| You decide | | |

**User's choice:** Mark UNKNOWN + research note

---

## Evidence sources

### What evidence backs each row?

| Option | Description | Selected |
|--------|-------------|----------|
| Static setup source + host scan (Recommended) | 3.files-legacy/options/wrapper + live `~/.config` | ✓ |
| Static setup source only | No host path checks | |
| Static + host + dry-run argv | Also wrapper dry-run | |

**User's choice:** Static setup source + host scan

### Which host trees for presence scan?

| Option | Description | Selected |
|--------|-------------|----------|
| Live XDG + repo .config (Recommended) | Dual track | |
| Live XDG only | Only `~/.config` | ✓ |
| Repo only | Only in-repo `.config` | |

**User's choice:** Live XDG only

### Cite every row?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — cite path or command (Recommended) | Every row re-verifiable | ✓ |
| Cite only high-risk rows | | |
| You decide | | |

**User's choice:** Yes — cite path or command

### Wrapper --dry-run required?

| Option | Description | Selected |
|--------|-------------|----------|
| Optional / not required (Recommended) | Phase 12 owns dry-run proof | ✓ |
| Required for SAFE_DEFAULTS residual only | | |
| Required for every flag axis | | |

**User's choice:** Optional / not required

---

## Flag-axis presentation

### How to present three flag axes?

| Option | Description | Selected |
|--------|-------------|----------|
| Three independent sections (Recommended) | skip-hyprland / core / sysupdate | ✓ |
| Cross-product staged profiles | Named combos primary | |
| Axes primary + profile appendix | | |

**User's choice:** Three independent sections

### Row column schema?

| Option | Description | Selected |
|--------|-------------|----------|
| Path \| Effect \| Risk \| Source \| Host present? (Recommended) | | ✓ |
| Path \| Effect \| Source only | | |
| You decide | | |

**User's choice:** Path | Effect | Risk | Source | Host present?

### SAFE_DEFAULTS residual placement (INV-04)?

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated top section before axes (Recommended) | | ✓ |
| Footer after all axes | | |
| Repeated one-liner under each axis | | |

**User's choice:** Dedicated top section before axes

### Recommend staged full profile?

| Option | Description | Selected |
|--------|-------------|----------|
| Stay neutral — map only (Recommended) | Phase 11 owns DISP-02 | ✓ |
| Soft recommend hypr-first | | |
| You decide | | |

**User's choice:** Stay neutral — map only

---

## Personal surface depth

### Depth inside hyprland.conf?

| Option | Description | Selected |
|--------|-------------|----------|
| Category annotations, no dispositions (Recommended) | monitors/workspaces/binds/exec-once/env/rules tags | ✓ |
| Path-level only | Single conf row | |
| Near line-level extraction | Almost Phase 11 migration design | |

**User's choice:** Category annotations, no dispositions

### Hypr-adjacent explicit rows?

| Option | Description | Selected |
|--------|-------------|----------|
| INV-02 minimum set (Recommended) | conf, hyprland/, lua, lock, idle, paper, custom + host extras | ✓ |
| Only files setup installs | | |
| Everything under ~/.config/hypr recursively | | |

**User's choice:** INV-02 minimum set

### Dual-run chrome (Waybar/rofi/swaync) in inventory?

| Option | Description | Selected |
|--------|-------------|----------|
| Session-risk note, not misc clash rows (Recommended) | | |
| Full clash rows like fish/kitty | | |
| Omit entirely from Phase 10 | | |
| Other (free text) | "These can be removed." | ✓ (clarified) |

**User's choice (clarified):** Yes — and omit dual-run from inventory entirely
**Notes:** Operator said dual-run chrome can be removed. Confirmed: **omit Waybar/rofi/swaync from 10-INVENTORY.md entirely**. Formal disposition still Phase 11; lean is removable.

### Non-hypr misc breadth?

| Option | Description | Selected |
|--------|-------------|----------|
| INV-03 named set + live-present ii targets (Recommended) | | |
| Only surfaces present on this host | | |
| Full ii misc catalog whether present or not | | |
| Other (free text) | "If i were to install into a completely new machine with default installation of dots-hyprland thats what i want." | ✓ (clarified) |

**User's choice (clarified):** Full ii misc catalog + host present?
**Notes:** Greenfield / default full dots-hyprland on a new machine is the North Star. Inventory lists full default misc catalog; Host present? marks this machine’s collisions.

---

## Claude's Discretion

- Markdown heading names, Risk vocabulary, UNKNOWN formatting
- Package/sysupdate row grain as long as INV-01 + citations hold
- Optional cheap dry-run not required for success

## Deferred Ideas

- Dual-run formal disposition (operator lean: removable) → Phase 11 DISP-03
- Staged flag profile choice → Phase 11 DISP-02
- Dry-run full profile → Phase 12
- Overlay migration / live adopt / playbook → Phases 13–15
- CUST-* Waybar ports → later milestone
