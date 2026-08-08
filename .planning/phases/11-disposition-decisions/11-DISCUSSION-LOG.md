# Phase 11: Disposition decisions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-08
**Phase:** 11-disposition-decisions
**Areas discussed:** First full-adopt flag stage, Dual-run chrome policy, Personal hypr must-keeps, Misc collision timing
**Note:** Fresh restart; supersedes 2026-08-07 `--auto` CONTEXT/DISCUSSION-LOG

---

## First full-adopt flag stage

| Option | Description | Selected |
|--------|-------------|----------|
| Hypr only | Drop `--skip-hyprland` only; keep `--core` + `--skip-sysupdate` | |
| Hypr + misc | Drop skip-hyprland + core; keep skip-sysupdate | |
| All three (greenfield now) | Drop all SAFE_DEFAULTS residuals | |
| Other (freeform) | Full dots-hyprland; repo `.config` for fresh reinstall | ✓ (then confirmed) |

**User's choice:** Full installation of dots-hyprland; repo should hold configs from `~/.config` for fresh reinstall bootstrap.

**Follow-up — flag meaning:**

| Option | Description | Selected |
|--------|-------------|----------|
| All three off | No skip-hyprland, no core, no skip-sysupdate | ✓ |
| Files full, no Syu | Drop hypr+core flags only | |
| Hypr full only | Drop only skip-hyprland | |

**Follow-up — pre-flight capture:**

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — sync first | Refresh repo `.config` from live PRESENT before full install | ✓ |
| Capture must-keeps only | | |
| No pre-flight capture | | |

**Follow-up — after install / bootstrap:**

| Option | Description | Selected |
|--------|-------------|----------|
| Personal archive + overlays | | |
| Mirror live after install | | |
| Replace personal with ii tree | | |
| Other | Repo is for all dotfiles / fresh reinstall | ✓ |

**Follow-up — product model:**

| Option | Description | Selected |
|--------|-------------|----------|
| Full dots-hyprland + repo personal layer | No local QS revival; ii may be upstream shell name | ✓ |
| dots-hyprland only, no qs/ii shell | | |
| Something else | | |

**Notes:** User said “no ii, only dots-hyprland; remove previous ii or quickshell” — clarified as product = dots-hyprland, no local Quickshell revival; upstream `ii` naming OK.

---

## Dual-run chrome policy

| Option | Description | Selected |
|--------|-------------|----------|
| Remove on full adopt | Accept-remove dual-run chrome | ✓ |
| Keep dual-run through Stage 1 | | |
| Keep Waybar only | | |

**Follow-up — repo fate of chrome configs:**

| Option | Description | Selected |
|--------|-------------|----------|
| Keep in repo as archive | Stop launching; keep configs | ✓ |
| Archive then prune | | |
| Delete after cutover | | |

**Follow-up — binds after chrome remove:**

| Option | Description | Selected |
|--------|-------------|----------|
| Rely on dots-hyprland defaults | | ✓ |
| List must-remap binds | | |
| You decide | | |

**Follow-up — timing:**

| Option | Description | Selected |
|--------|-------------|----------|
| Same adopt window | Chrome ends with full files install | ✓ |
| After first successful ii session | | |
| Before full install | | |

**Notes:** Explicit DISP-03 override of default-keep.

---

## Personal hypr must-keeps

| Option | Description | Selected |
|--------|-------------|----------|
| Monitors + workspaces + env only | Minimum multi-monitor set | ✓ |
| Plus personal exec-once | | |
| Broad binds/rules/exec | | |

**Follow-up — autostart / tools:**

| Option | Description | Selected |
|--------|-------------|----------|
| Accept-upstream / drop | | ✓ |
| Migrate autostart apps only | | |
| Migrate named personal tools too | | |

**Follow-up — lock/idle:**

| Option | Description | Selected |
|--------|-------------|----------|
| keep-personal live + defer *.new | | |
| accept-upstream later | | |
| Other | “dots-hyprland is perfectly fine” then “I really do not use lock… if boot issues then no need” | ✓ |

**Resolved lock policy:** Leave live lock/idle alone (no-touch); no promote of `.new`; no QS lock; avoid boot risk.

**Follow-up — hyprpaper:**

| Option | Description | Selected |
|--------|-------------|----------|
| keep-personal | | |
| Other | “wallpaper is not important, so can be removed” | ✓ |

**Follow-up — hyprland/ scripts:**

| Option | Description | Selected |
|--------|-------------|----------|
| accept-upstream wipe | | |
| Migrate scripts out first | | |
| You decide | Scripts in repo; accept-upstream + pre-flight | ✓ |

**Follow-up — hypr/custom:**

| Option | Description | Selected |
|--------|-------------|----------|
| Seed OK + overlays after | | |
| Pre-create custom | | |
| Other | “hypr/custom not important, can be removed” | ✓ (then clarified) |

**Tension resolve:**

| Option | Description | Selected |
|--------|-------------|----------|
| Must-keeps via hypr/custom overlays | Minimal custom = monitors/workspaces/env only | ✓ |
| No overlays — accept upstream layout | | |
| Must-keeps elsewhere | | |

**Notes:** “Custom not important” = no extra fluff beyond must-keeps, not skip overlays entirely.

---

## Misc collision timing

| Option | Description | Selected |
|--------|-------------|----------|
| accept-upstream all misc | Greenfield live replace | ✓ |
| keep-personal named set | | |
| Per-row mix now | | |

**Follow-up — post-install personal layer:**

| Option | Description | Selected |
|--------|-------------|----------|
| Repo archive only | No reapply over live | ✓ |
| Reapply selected after install | | |
| You decide | | |

**Follow-up — packages/sysupdate:**

| Option | Description | Selected |
|--------|-------------|----------|
| Accept full deps path | Syu + metas + asdeps | ✓ |
| Accept packages but document asdeps carefully | | |
| Defer Syu only | | |

**Follow-up — plasmaintg:**

| Option | Description | Selected |
|--------|-------------|----------|
| Skip / do not install | | |
| Accept if setup wants it | | ✓ |
| You decide | | |

---

## Claude's Discretion

- Exact `11-DISPOSITIONS.md` heading/table layout
- LOW residual row granularity
- Optional disposition assert harness
- Exact pre-flight sync command inventory
- hyprland/scripts: accept-upstream with repo capture (user said you decide)
- Whether `ILLOGICAL_IMPULSE_VIRTUAL_ENV` is explicit env migrate vs assumed post-adopt

---

## Deferred Ideas

- CUST-* Waybar ports (chrome archived for possible later use)
- Separate CUT-01 milestone (folded into full-adopt chrome remove)
- Later lock/idle upstream promote if operator starts using lock
- Post-adopt reapply of personal fish/kitty/starship (rejected now)
