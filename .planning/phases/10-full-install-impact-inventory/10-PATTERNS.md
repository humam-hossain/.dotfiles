# Phase 10: Full-install impact inventory - Pattern Map

**Mapped:** 2026-08-04  
**Source:** CONTEXT + RESEARCH file lists + closest repo analogs

## Files this phase creates/modifies

| File | Role | Data flow |
|------|------|-----------|
| `scripts/phase10-inventory-assert.sh` | Wave 0 Nyquist harness | Reads `10-INVENTORY.md` (+ optional live XDG); exits 0/1 |
| `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` | Phase deliverable (D-01) | Assembled from static setup cites + host scan; committed SoT |
| `.planning/phases/10-full-install-impact-inventory/10-VALIDATION.md` | Validation contract | Updated Wave 0 checkboxes / task map statuses |

## Closest analogs

### 1. Assert harness → `scripts/phase07-live-smoke.sh`

**Why:** Bash PASS/FAIL labels, `set -euo pipefail`, REPO_ROOT via `BASH_SOURCE`, no package installs, dry-run/wrapper policy checks without mutating XDG for policy gates.

**Excerpt pattern to mirror:**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
# ... gates ...
exit "$FAIL"
```

**Do not copy:** LIVE-01..04 ii session assertions, soft/hard mode for post-uninstall, waybar dual-run chrome checks (Phase 10 omits chrome per D-15).

### 2. Python stdlib asserts → `scripts/phase02-config-assert.py` / `phase04-ipc-reload-assert.py`

**Why:** Fail-loud exit codes, single success string, stdlib-only discipline.

**Phase 10 choice:** Prefer **bash** (like phase07) because gates are `rg`/`test` on markdown + optional host `test -e` — no JSON/QML parsing needed.

### 3. Inventory narrative / operator path → `docs/dots-hyprland-workflow.md`

**Why:** Documents SAFE_DEFAULTS dual-run path; good residual narrative source for INV-04 wording.

**Do not treat as:** Path-effect SoT (setup scripts are SoT per D-05).

### 4. Effect sources (read-only, not modified)

| Analog | Use in inventory rows |
|--------|----------------------|
| `arch/dots-hyprland.sh` | SAFE_DEFAULTS residual cites |
| `vendor/.../options.sh` | `--core` expansion / skip flags |
| `vendor/.../3.files-legacy.sh` | Hypr + misc path effects (default files path) |
| `vendor/.../3.files.sh` | Helpers: auto_backup, sync, ignore_existing |
| `vendor/.../dist-arch/install-deps.sh` | Syu, metas, asdeps |

### 5. Planning artifact shape → prior phase `*-PLAN.md` / research tables

**Why:** RESEARCH already drafted Path\|Effect\|Risk\|Source\|Host present? tables — executor **copies verified rows into `10-INVENTORY.md`**, re-running host presence at write time (A4).

## Anti-patterns (from RESEARCH)

- Do not center Waybar/rofi/swaync rows
- Do not write dispositions (keep/migrate/accept) as recommendations
- Do not invent firstrun replace for lock/idle when `installed_true` exists
- Do not use `--exp-files` as primary structure (legacy default)
- Do not live-run full install to “discover” effects

## Data flow summary

```text
STATIC SOURCES (vendor + arch) ──► effect rows + Source cites
LIVE ~/.config (read-only)     ──► Host present? + host snapshot
ASSERT SCRIPT                  ──► structural/lint gates on 10-INVENTORY.md
```
