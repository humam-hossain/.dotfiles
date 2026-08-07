# Phase 11: Disposition decisions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-07
**Phase:** 11-disposition-decisions
**Mode:** `--auto` (yolo post-Phase-10 UAT transition)
**Areas discussed:** Disposition artifact shape, Staged flag profile (DISP-02), Dual-run chrome (DISP-03), hyprlock/hypridle (DISP-04), High-risk hypr policy (DISP-01), Misc/packages under Stage 1

---

## Disposition artifact shape

| Option | Description | Selected |
|--------|-------------|----------|
| Single `11-DISPOSITIONS.md` in phase dir | Mirrors Phase 10 inventory SoT pattern | ✓ |
| Split files per axis | Separate hypr/misc/pkg disposition files | |
| Docs under `docs/` | Playbook-adjacent SoT | |

**User's choice:** [auto] Single `11-DISPOSITIONS.md` in phase dir (recommended — matches 10-INVENTORY pattern)
**Notes:** Columns Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source; enum locked to five values.

---

## Staged flag profile (DISP-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Stage 1: drop skip-hyprland only | Keep --core + skip-sysupdate | ✓ |
| Drop all three SAFE_DEFAULTS at once | Full greenfield in one step | |
| Drop skip-hyprland + core, keep skip-sysupdate | Hypr + misc, no Syu | |

**User's choice:** [auto] Stage 1 = drop `--skip-hyprland` only (recommended — flag independence + HIGH misc/Syu risk)
**Notes:** Stage 2/3 documented as deferred follow-ups toward North Star (Phase 10 D-17). Default install SAFE_DEFAULTS unchanged until Phase 12.

---

## Dual-run chrome (DISP-03)

| Option | Description | Selected |
|--------|-------------|----------|
| keep dual-run (Waybar/rofi/swaync) | DISP-03 + ROADMAP default | ✓ |
| accept-remove chrome now | Early CUT-01 | |
| defer decision entirely | No chrome row | |

**User's choice:** [auto] keep (recommended — DISP-03 / ROADMAP success criteria #3)
**Notes:** Phase 10 D-15 "can be removed" does not override formal keep default.

---

## hyprlock / hypridle (DISP-04)

| Option | Description | Selected |
|--------|-------------|----------|
| keep-personal live lock/idle; defer *.new | Matches not-firstrun + no QS lock | ✓ |
| accept-upstream lock (replace live) | Force ii lock conf | |
| migrate lock into custom | Overlay lock | |

**User's choice:** [auto] keep-personal live conf; defer `*.new` sidecars; defer hyprlock/ dir UNKNOWN
**Notes:** PRODUCT constraint: keep hyprlock, no QS LockScreen investment.

---

## High-risk hypr policy (DISP-01 / Axis A)

| Option | Description | Selected |
|--------|-------------|----------|
| migrate must-keeps + accept ii primary | conf→.old; custom overlays; accept hyprland/ + lua | ✓ |
| keep-personal conf as primary | Blocks ADOPT-02 lua session | |
| accept-upstream everything blind | Loses monitors/workspace pins | |

**User's choice:** [auto] migrate must-keep categories + accept-upstream for ii tree/lua (recommended)
**Notes:** Must-keeps: monitors, workspaces, env, dual-run exec-once, essential binds. hyprpaper keep-personal. hyprland/scripts risk called out.

---

## Misc / packages under Stage 1

| Option | Description | Selected |
|--------|-------------|----------|
| defer HIGH misc + Syu (core + skip-sysupdate retained) | Visibility without forced accept | ✓ |
| force keep-personal all PRESENT misc now | Implies Stage 2 decisions early | |
| accept-upstream all misc | Unsafe under Stage 1 (core still on) | |

**User's choice:** [auto] defer HIGH misc PRESENT + Syu under Stage 1; accept installed metas remain
**Notes:** Satisfies DISP-01 row coverage with Stage 2/3 sequencing.

---

## Claude's Discretion

- Table formatting / heading names inside `11-DISPOSITIONS.md`
- Collapsing ABSENT+core-retained misc into summary
- Optional structural assert (not required)

## Deferred Ideas

- Stage 2 drop `--core` per-row dispositions
- Stage 3 allow sysupdate
- CUT-01 chrome removal if operator revises keep
- CUST-* Waybar ports
