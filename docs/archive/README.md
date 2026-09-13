# Archive Directory (`docs/archive/`)

This directory holds retired configuration files, superseded migration artifacts, and historical reference configs preserved under their original basenames.

## Purpose & Contract

1. **Nothing in this directory is live:** Files preserved here have no active link to `$HOME` and play no role in running desktop sessions.
2. **Nothing reads it:** No runtime scripts, wrappers, installers, or automation read or source files in this directory.
3. **Provenance:** Each entry preserved here records why it was retired, what superseded it, and the commit that retired it.

---

## Basename Collision Rule (D-27)

All archived files are stored in this flat directory under their original basename. If a future retirement introduces a file with the same basename as an existing entry, the collision is resolved by prefixing the filename with its original subsystem or component name (e.g. `hypr-config.conf`).

---

## Archive Entry Registry

| File | Retired in | Why | Superseded by |
|---|---|---|---|
| `hyprland.conf` | Plan 18-04 (`9f1c5d3`) | No live counterpart; installer renamed it to `.old` in Phase 14 (`3.files-legacy.sh:51-54`) | `stow/hypr/.config/hypr/custom/` overlays + upstream `hyprland.lua` |
| `hyprland.conf.bak` | Plan 18-04 (`9f1c5d3`) | Byte-identical to backup already existing live | Historical backup |

> **Note on live `.old` artifact:** `~/.config/hypr/hyprland.conf.old` is the live filesystem artifact of the Phase 14 rename and is deliberately untracked. It is preserved on the host for rollback/reference, not tracked in git.
