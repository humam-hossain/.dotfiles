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
<!-- Plan 18-06 populates the first entries: hyprland.conf and hyprland.conf.bak -->
