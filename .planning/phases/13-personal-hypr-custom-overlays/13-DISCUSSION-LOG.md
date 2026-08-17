# Phase 13: Personal hypr/custom overlays - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-17
**Phase:** 13-Personal hypr/custom overlays
**Areas discussed:** Overlay SoT (OVL-03), Monitor/workspace file slot, Env overlay contents, Prep vs apply timing (OVL-02)

---

## Overlay SoT (OVL-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Repo `.config/hypr/custom/` | Author and commit overlays in the parent repo. Live is an applied copy. | ✓ (after correction) |
| Live `~/.config/hypr/custom/` only | Live tree is SoT after adopt. Repo only archives. | |
| Personal fork / vendor submodule | Commit overlays inside vendor/dots-hyprland. | |
| You decide | Lock recommended repo-authored policy. | |

**User's choice:** Other, then correction. First: “I don't want my own custom hypr stuff, if dots-hyprland requires it then do it.” After D-16 reminder: keep Phase 11 D-16; prefer `.config/hypr/custom/` because a completely new machine should set up effortlessly.

**Notes:** Upstream does not require any `custom/` files. Overlays exist only to carry D-16 machine layout. Not a personal hypr product.

### Cold-machine apply

| Option | Description | Selected |
|--------|-------------|----------|
| Documented apply after install | Copy/rsync repo custom/ onto live after ii seed. Phase 14 runs it. | ✓ |
| Stow or symlink from repo into live | Live custom/ is a symlink/stow of repo files. | |
| Pre-seed live before full install | Write live custom/ before `./setup --full` so ignore_existing keeps our files. | |
| You decide | Apply-after-install unless ignore_existing makes pre-seed safer. | |

**User's choice:** Documented apply after install (Recommended)

**Notes:** Remaining SoT follow-ups locked when operator asked to continue through plan-phase: one-way repo → live (copy back to persist); never commit machine overlays into the fork.

---

## Monitor/workspace file slot

| Option | Description | Selected |
|--------|-------------|----------|
| `hypr/custom/` slots only | env → `custom/env.lua`; monitors + pins → `custom/general.lua`; optional setcursor → `custom/execs.lua`. Not nwg-displays root files. | ✓ (from repo-custom preference) |
| nwg-displays root files | `~/.config/hypr/monitors.lua` + `workspaces.lua` as loaded by `hyprland.lua`. | |
| Mix | Env in custom/; layout in root nwg-displays files. | |

**User's choice:** Not asked as a menu. Locked from “`.config/hypr/custom/` is preferable place for custom stuff.”

**Notes:** If `custom/general.lua` cannot express workspace pins, CONTEXT D-07 says stop and record the gap — do not silently switch SoT.

---

## Env overlay contents

| Option | Description | Selected |
|--------|-------------|----------|
| Include cursor + `ILLOGICAL_IMPULSE_VIRTUAL_ENV` | Self-contained after conf→`.old`; duplicate venv env is OK. | ✓ (keep D-16) |
| Omit VIRTUAL_ENV | Upstream `hyprland/env.lua` already sets the same path. | |
| Drop env overlay | Rely on upstream env + Phase 12 conf hooks only. | |

**User's choice:** Keep Phase 11 D-16 (explicit after the “dots-hyprland requires it” miss).

**Notes:** Cursor theme/size is not in upstream env.lua. Upstream execs set `Bibata-Modern-Classic 24`; personal is Catppuccin 30.

---

## Prep vs apply timing (OVL-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Write real overlay files in repo this phase | OVL-02 met by committed files before Phase 14. | ✓ (new-machine effortless) |
| Checklist-gate only | Document what to write; create files at adopt. | |
| Write and apply live this phase | Mutate `~/.config` before Phase 14. | |

**User's choice:** Not asked as a menu. Locked from new-machine / apply-after-install: files in repo now; live apply in Phase 14; no live mutation this phase.

**Notes:** Operator asked to continue through `/gsd-plan-phase` after the two Overlay SoT answers; remaining area questions used recommended locks consistent with D-16 + repo `custom/` + apply-after-install.

---

## Claude's Discretion

- Exact Lua fields for monitors / workspace pins
- Exact apply command and overwrite of empty seeds
- Whether `setcursor` is needed in `custom/execs.lua`
- SoT note artifact shape
- Optional light lint that custom files omit D-17 content

## Deferred Ideas

- Phase 14 live apply + adopt
- Phase 15 DOC-04 playbook prose
- Stow/symlink and pre-seed live — rejected
- Dropping D-16 overlays entirely — considered then rejected
