---
status: in_progress
phase: 04-ipc-keybinds-integration
source:
  - 04-VALIDATION.md
  - 04-UI-SPEC.md
  - scripts/phase04-ipc-reload-assert.py
started: 2026-07-25T05:34:00Z
updated: 2026-07-25T05:39:17Z
---

# Phase 4 UAT — IPC show/hide & soft reload

Scope this pass: **IPC-01** (bar show/hide) + **IPC-03** (graceful soft reload).  
Out of scope: Hyprland keybind (IPC-02), exec-once (FWK-02), Waybar cutover.

**Config contract:** default Quickshell config only — bare `qs` / path `~/.config/quickshell/shell.qml`.  
Do **not** use `qs -c ii`.

**Visual contract:** judge the **Quickshell** bar only. Waybar may still be visible (dual-run).

**Monitors (live session at automated run):** DP-1 (3440×1440). If HDMI-A-2 (or any other bar screen) is connected, apply the same hide/show expectations to **all** QS bar monitors together (`GlobalStates.barOpen`).

---

## Preflight (operator)

```bash
qs list
# Expect at least one instance with Config path containing quickshell/shell.qml

qs ipc show | rg -A4 'target bar'
# Expect:
#   target bar
#     function open(): void
#     function toggle(): void
#     function close(): void

# Full automated gate (static + live open + soft-reload same-PID):
python3 scripts/phase04-ipc-reload-assert.py
# Expect exit 0 and line: ipc/reload asserts OK
```

If multiple instances appear, pin with `qs ipc --pid <pid> …` (prefer `qs list`).

---

## IPC-01 — Bar show/hide

### CLI contract (prescriptive)

| Action | Command | Expected visual (UI-SPEC Visibility Contract) |
|--------|---------|-----------------------------------------------|
| Close | `qs ipc call bar close` | **All** Quickshell bars disappear (every monitor that had a QS bar). No residual QS exclusive zone / bar chrome. |
| Open | `qs ipc call bar open` | **All** QS bars reappear with prior module layout (workspaces, clock, tray, network, resources, volume). |
| Toggle | `qs ipc call bar toggle` | Flips global visibility once. |
| Toggle ×2 | `qs ipc call bar toggle` (again) | Restores prior open/closed visual state for that flip sequence. |

Notes:

- Mechanism: stock `IpcHandler` target `bar` → `GlobalStates.barOpen` → bar `LazyLoader` on every monitor.
- No new toast/badge/status line for IPC calls.
- No Hyprland keybind required for this section (IPC-02 deferred).
- No new IPC targets.

### Automated proof (2026-07-25)

| Check | Result | Evidence |
|-------|--------|----------|
| `python3 scripts/phase04-ipc-reload-assert.py` | **pass** | exit 0, `ipc/reload asserts OK` (PID 63412) |
| `qs ipc call bar close` | **pass** | exit 0 |
| `qs ipc call bar open` | **pass** | exit 0 |
| `qs ipc call bar toggle` | **pass** | exit 0 |
| Product QML edited | **no** | stock only (D-13) |

### Human multi-monitor UAT

| # | Check | expected | result | note |
|---|-------|----------|--------|------|
| IPC-01-1 | `qs ipc call bar close` | QS bar gone on **all** active monitors | **pass** | Human approved 2026-07-25; Ignore Waybar |
| IPC-01-2 | `qs ipc call bar open` | QS bars back on all monitors; modules updating | **pass** | Human approved 2026-07-25 |
| IPC-01-3 | `qs ipc call bar toggle` twice | One hide + one show flip | **pass** | Human approved 2026-07-25 |
| IPC-01-4 | No IPC chrome | No toast/badge/status line for IPC | **pass** | Human approved 2026-07-25 |

**Human signal:** `approved` (2026-07-25) — multi-monitor hide/show/toggle pass.

---

## IPC-03 — Soft reload

### Trigger (prescriptive — Quickshell 0.3.0)

Primary path: **content-change file-watch soft reload** (same process PID).

There is **no** `qs reload` CLI on Quickshell 0.3.0. Do **not** use a missing reload subcommand as the operator happy path. Do **not** kill+relaunch as the graceful path.

**Operator steps (safe probe):**

```bash
# 1. Note PID
qs list
# Process ID: <PID>  — config path must contain quickshell/shell.qml

# 2. Automated preferred:
python3 scripts/phase04-ipc-reload-assert.py
# Expect: ipc/reload asserts OK (includes same-PID soft-reload + restore + post-reload bar open)

# 3. Manual content-change (if not using the script):
#    Append a unique comment line to ~/.config/quickshell/shell.qml
#    Wait ~1–3s for Configuration Loaded
#    Confirm same PID still running
#    Restore the file exactly (remove probe line)
#    qs ipc call bar open   # exit 0
```

**Silent UX (D-10):** `//@ pragma Env QS_NO_RELOAD_POPUP=1` in `shell.qml` must remain. Expect **no** top-of-screen ReloadPopup / reload banner.

**Hide-state survival:** not required across reload. After reload, run `qs ipc call bar open` if bars are not visible.

**Failed reload recovery (D-12):** fix QML syntax, then **manual** `qs` relaunch. No auto-relaunch daemon; no hard-restart keybind this pass (see `04-DEFERRED.md`).

### Expected after successful soft reload

| Area | Expectation |
|------|-------------|
| Process | Same PID (not kill+relaunch) |
| Popup | None (silent pragma) |
| Bar modules | Usable — clock ticks; CPU/RAM/resources update under load |
| Tray | Interactive on **Quickshell** bar (icons present + clickable). Dual Waybar SNI noise alone is not failure. |
| IPC | `qs ipc call bar close` then `open` still exit 0 |

### Automated proof (2026-07-25)

| Check | Result | Evidence |
|-------|--------|----------|
| `QS_NO_RELOAD_POPUP=1` in shell.qml | **pass** | static `rg` |
| No reload IpcHandler on bar | **pass** | Bar.qml stock toggle/open/close only |
| `python3 scripts/phase04-ipc-reload-assert.py` | **pass** | exit 0, includes Section C soft-reload |
| Manual content-change same PID | **pass** | PID 63412 → 63412; probe restored |
| Post-reload `qs ipc call bar open` | **pass** | exit 0 |

### Human soft-reload + tray UAT

| # | Check | expected | result | note |
|---|-------|----------|--------|------|
| IPC-03-1 | Soft reload silent | No top-of-screen reload popup/banner | pending | Keep pragma |
| IPC-03-2 | Same PID | Long-lived process, not kill+relaunch | pending | `qs list` |
| IPC-03-3 | Bar usable after reload | Clock ticks; resources update under load | pending | |
| IPC-03-4 | QS tray interactive | Icons present + clickable on **Quickshell** bar | pending | Dual Waybar SNI noise OK; empty tray OK if no apps |
| IPC-03-5 | IPC after reload | `qs ipc call bar close` then `open` still work | pending | |

**Resume signal:** type `approved` if silent soft reload + bar + tray pass, or describe failures.

## Explicit non-goals (this pass)

- No Hyprland keybind (IPC-02) — see `04-DEFERRED.md`
- No `exec-once` Quickshell auto-start (FWK-02) — see `04-DEFERRED.md`
- No Waybar removal / cutover
- No hard-restart keybind / auto-relaunch daemon
- No new IpcHandler targets; no invented reload CLI/IPC
