# Phase 4: IPC, Keybinds & Integration - Pattern Map

**Mapped:** 2026-07-24
**Files analyzed:** 5 (3 stock QML verify-only + 1 new assert harness + optional UAT doc)
**Analogs found:** 5 / 5
**Nature:** VERIFY-only stock IPC + soft reload; **add QML only if verification fails** (D-13)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.config/quickshell/modules/ii/bar/Bar.qml` | component (IPC surface) | request-response (IPC) | **self** — stock `IpcHandler` target `bar` already complete | exact (verify-only) |
| `.config/quickshell/GlobalStates.qml` | store / singleton | transform (bool flag) | **self** — `barOpen` drives LazyLoader | exact (verify-only) |
| `.config/quickshell/shell.qml` | config / shell root | event-driven (reload) | **self** — `QS_NO_RELOAD_POPUP=1` + `ReloadPopup {}` | exact (verify-only) |
| `scripts/phase04-ipc-reload-assert.sh` (or `.py`) | test / assert harness | request-response + batch | `scripts/phase02-config-assert.py` + `scripts/phase03-config-assert.py` | role-match (Wave 0 pattern; adapt to live `qs` CLI) |
| `.planning/.../04-UAT.md` (optional) | test / UAT doc | manual | Phase 2/3 VALIDATION / UAT notes | role-match |

**Do not create or modify this pass (deferred finishing touch):**

| File | Reason |
|------|--------|
| `.config/hypr/hyprland.conf` | D-01/D-02 — no keybinds, no `exec-once` qs |
| New `IpcHandler` targets / reload IPC | D-04/D-07 |
| Custom `qs reload` wrapper | No CLI on Quickshell 0.3.0; hard-restart ≠ graceful reload |

---

## Pattern Assignments

### 1. `.config/quickshell/modules/ii/bar/Bar.qml` (component, request-response IPC)

**Role in Phase 4:** Stock surface for IPC-01. **No code change unless broken.**

**Analog:** self (lines 218–259 + LazyLoader 27–29)

**Imports / Scope pattern** (lines 1–14) — keep existing:
```qml
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: bar
```

**Core visibility pattern** (lines 27–29) — all monitors share one flag:
```qml
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
```

**IPC core pattern** (lines 218–232) — **copy/preserve exactly**; external UAT uses these names:
```qml
    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }
```

**GlobalShortcut pattern** (lines 234–259) — leave stock for finishing-touch IPC-02; **do not bind in Hyprland this pass** (D-09):
```qml
    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"
        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }
    // barOpen / barClose similarly set GlobalStates.barOpen = true/false
```

**CLI contract (from RESEARCH live verify):**
```bash
qs ipc call bar close   # exit 0; bars hide all monitors
qs ipc call bar open    # exit 0; bars show
qs ipc call bar toggle  # exit 0; flip barOpen
# Default config — no -c ii (this tree is shell.qml at quickshell root)
```

**Error / typing rule:** IpcHandler functions need explicit `: void` (already present). Do not strip types or they will not register.

**Secondary IpcHandler analog** (same shape, different target) — `shell.qml` lines 62–68:
```qml
    IpcHandler {
        target: "panelFamily"
        function cycle(): void {
            root.cyclePanelFamily()
        }
    }
```
Use only if adding a new target later; **not** for Phase 4.

---

### 2. `.config/quickshell/GlobalStates.qml` (store, transform)

**Role in Phase 4:** Single source of truth for bar visibility (D-08). **Verify only.**

**Analog:** self

**Singleton + barOpen pattern** (lines 1–13):
```qml
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
```

**Data-flow notes for planner/UAT:**
- Default `true` → after soft reload, plain properties may reset (RESEARCH pitfall A1).
- D-11 requires **usable** bar after reload, **not** preservation of `barOpen=false`.
- IPC handlers only mutate this flag; LazyLoader reacts.

**Do not** introduce per-monitor `barOpen` maps this phase.

---

### 3. `.config/quickshell/shell.qml` (config / shell root, event-driven reload)

**Role in Phase 4:** Silent soft-reload UX (IPC-03 / D-10). **Verify pragma present; do not enable popup.**

**Analog:** self (+ `settings.qml` / `welcome.qml` same pragma)

**Silent reload pragma pattern** (lines 1–3):
```qml
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
```

**ReloadPopup still instantiated but suppressed** (lines 19–23):
```qml
ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}
```

**Soft reload trigger (stock, no CLI)** — RESEARCH-verified; **do not invent `qs reload`:**
```bash
# Content change required (mtime-only touch is NOT enough)
printf '\n// phase04-reload-probe\n' >> ~/.config/quickshell/shell.qml
# Expect log: Reloading configuration... / Configuration Loaded
# Assert: same PID; then restore file
# After: qs ipc call bar open still works
```

**Hard recovery only (D-12)** — not the happy path:
```bash
qs kill
qs -d   # or qs &
```

---

### 4. `scripts/phase04-ipc-reload-assert.sh` (or `.py`) (test, request-response + batch)

**Role in Phase 4:** Wave 0 automated gates for IPC-01 + IPC-03 static/live smoke. **Primary new artifact.**

**Analogs:**
| Analog | What to copy |
|--------|----------------|
| `scripts/phase02-config-assert.py` | Wave 0 harness shape: stdlib-only, fail-loud, exit 0 iff all pass, clear stderr messages |
| `scripts/phase03-config-assert.py` | Same structure for next-phase asserts; docstring naming (`Phase N Wave 0…`) |
| RESEARCH “Prescriptive automated suite” | Live `qs` / `rg` gates (not config.json) |

#### Wave 0 harness skeleton from Phase 2 (lines 1–28, 63–75)

**Docstring + entry + fail paths:**
```python
#!/usr/bin/env python3
"""Phase 2 Wave 0 live-config asserts for BAR-01..04 keys.
...
Expected to FAIL until plan 02-02 dual-writes Config defaults into live config.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "illogical-impulse" / "config.json"


def main() -> int:
    if not CONFIG_PATH.is_file():
        print(f"error: missing config file: {CONFIG_PATH}", file=sys.stderr)
        return 1
    # ... load + assert ...
    except KeyError as exc:
        print(f"config assert FAIL: missing key {exc}", file=sys.stderr)
        return 1
    except AssertionError as exc:
        print(f"config assert FAIL: {exc}", file=sys.stderr)
        return 1

    print("config asserts OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

#### Wave 0 harness from Phase 3 (same control flow)

Phase 3 is the freshest twin: same `main() -> int`, KeyError/AssertionError split, final `config asserts OK`. **Copy control-flow + messaging style**; **replace** JSON domain with `qs` subprocess checks.

#### Phase 4 domain adaptation (prescribed content)

Unlike Phase 2/3 (read `config.json`), Phase 4 asserts **runtime + static source**:

```bash
# Static (always runnable without display)
rg -n 'target: "bar"' .config/quickshell/modules/ii/bar/Bar.qml
rg -n 'function toggle\(\): void|function open\(\): void|function close\(\): void' \
  .config/quickshell/modules/ii/bar/Bar.qml
rg -n 'QS_NO_RELOAD_POPUP=1' .config/quickshell/shell.qml
rg -n 'property bool barOpen' .config/quickshell/GlobalStates.qml
# Expect empty this pass (deferred FWK-02):
# rg -n 'exec-once.*quickshell|exec-once.*\bqs\b' .config/hypr/hyprland.conf

# Live (requires running qs instance — default config)
qs list   # config path should include quickshell/shell.qml
qs ipc show | rg -A5 'target bar'   # functions toggle|open|close
qs ipc call bar open                # exit 0 (idempotent)

# Soft reload (optional automated section)
# 1. capture PID from qs list
# 2. append probe comment to shell.qml (content change)
# 3. wait for log "Configuration Loaded"
# 4. assert same PID
# 5. restore shell.qml
# 6. qs ipc call bar open
```

**Recommended script conventions (map from Phase 2/3):**

| Phase 2/3 pattern | Phase 4 mapping |
|-------------------|-----------------|
| `CONFIG_PATH` constant | Prefer repo-relative static paths + `qs` on `PATH` |
| Missing file → exit 1 | Missing `qs` or no running instance → exit 1 with stderr |
| `AssertionError` messages | e.g. `ipc assert FAIL: bar target missing` |
| Success line `config asserts OK` | e.g. `ipc/reload asserts OK` |
| Stdlib only / no deps | bash + `rg` + `qs`, **or** Python `subprocess` + stdlib only |
| Expected red until dual-write | Expected **green** if stock already works; red only if break |

**Anti-patterns for this script:**
- Call `qs reload` (does not exist on 0.3.0)
- Use `qs -c ii` (wrong config selector for this tree)
- Pick first `$XDG_RUNTIME_DIR/quickshell/by-id/*/ipc.sock` without `qs list` (stale dirs)
- Require `barOpen=false` to survive soft reload
- Touch file without content change for reload probe

---

## Shared Patterns

### Stock IpcHandler (typed void functions)

**Source:** `.config/quickshell/modules/ii/bar/Bar.qml` lines 218–232  
**Also:** `.config/quickshell/shell.qml` lines 62–68 (`panelFamily`)  
**Apply to:** Any future IPC surface; Phase 4 only **verifies** `bar`

```qml
IpcHandler {
    target: "bar"
    function toggle(): void { GlobalStates.barOpen = !GlobalStates.barOpen }
    function close(): void { GlobalStates.barOpen = false }
    function open(): void { GlobalStates.barOpen = true }
}
```

### GlobalStates flag driving LazyLoader

**Source:** `GlobalStates.qml` L12 + `Bar.qml` L27–29  
**Apply to:** Visibility UAT; multi-monitor (D-08)

```qml
// GlobalStates
property bool barOpen: true
// Bar.qml
active: GlobalStates.barOpen && !GlobalStates.screenLocked
```

### Silent soft reload

**Source:** `shell.qml` L1–3, L23  
**Apply to:** IPC-03 / D-10 — keep pragma; do not enable ReloadPopup feedback this pass

```qml
//@ pragma Env QS_NO_RELOAD_POPUP=1
// ...
ReloadPopup {}
```

### Wave 0 assert harness (exit codes + stderr)

**Source:** `scripts/phase02-config-assert.py`, `scripts/phase03-config-assert.py`  
**Apply to:** `scripts/phase04-ipc-reload-assert.sh` (or `.py`)

```python
# Control flow to copy:
# 1. shebang + phase docstring (what it asserts, when green)
# 2. main() -> int
# 3. preflight missing deps → stderr + return 1
# 4. try/assert block
# 5. KeyError/AssertionError (or equivalent) → "… assert FAIL: …"
# 6. print success → return 0
# 7. if __name__ == "__main__": sys.exit(main())
```

### Default-config `qs` invocation

**Source:** RESEARCH live host 2026-07-24  
**Apply to:** All Phase 4 plans, UAT, assert script

```bash
qs list
qs ipc show
qs ipc call bar open|close|toggle
# NOT: qs -c ii …
# NOT: qs reload
```

### Deferred Hyprland (do not copy into this pass)

**Source:** dots-hyprland keybinds/execs (reference only)  
**Apply to:** Finishing-touch backlog only — **zero tasks** in Phase 4 plans

```text
# Later: bind global quickshell:barToggle OR exec qs ipc call bar toggle
# Later: exec-once = qs -d   (default config, not -c ii)
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | None for in-scope work. Soft-reload **CLI** has no analog because `qs reload` does not exist; use file-watch content-change probe (RESEARCH Pattern 5) instead of inventing a wrapper. |

**Conditional fix files** (only if UAT red — no pre-built analog plan):

| If broken | Likely touch | Closest read-first |
|-----------|--------------|--------------------|
| Tray unusable post-reload | `services/TrayService.qml`, `modules/ii/bar/SysTray.qml` | existing tray service patterns |
| IPC missing at runtime | `Bar.qml` IpcHandler typing/scope | self + `shell.qml` panelFamily handler |
| Popup flashes on reload | `shell.qml` pragma | self + `settings.qml` pragma |

---

## Planner Guidance (verify-only phase)

1. **Default plan:** Wave 0 assert script + static `rg` gates + live IPC sequence + soft-reload same-PID gate + human UAT (bar hide/show all monitors, tray clickable on QS bar).
2. **No QML edits** unless a gate fails with evidence (D-13).
3. **No Hyprland edits** (D-01/D-02).
4. **Success criteria this pass:** IPC-01 show/hide via stock IPC; IPC-03 graceful soft reload (same PID, silent, bar+tray usable). SC-2 keybind and SC-4 exec-once are **out**.
5. **Copy assert style from Phase 2/3**, not their JSON domain.

---

## Metadata

**Analog search scope:**
- `.config/quickshell/modules/ii/bar/Bar.qml`
- `.config/quickshell/GlobalStates.qml`
- `.config/quickshell/shell.qml`
- `.config/quickshell/**/*.qml` (IpcHandler / QS_NO_RELOAD_POPUP)
- `scripts/phase02-config-assert.py`, `scripts/phase03-config-assert.py`
- Prior phase PATTERNS.md headers (02, 03)

**Files scanned:** ~15 primary + grep hits across quickshell QML  
**Pattern extraction date:** 2026-07-24  
**Phase constraint:** VERIFY stock only — patterns exist to **preserve and gate**, not redesign
