# Phase 4 — Deferred finishing-touch backlog

**Status:** Not in this pass acceptance (CONTEXT D-01..D-03)  
**In-pass requirements:** IPC-01 and IPC-03 (plans 04-01..04-03)  
**Deferred requirement IDs:** FWK-02, IPC-02  
**Rule this pass:** **zero** edits to `.config/hypr/hyprland.conf`; no product QML for these items.

This document packages finishing-touch work so Phase 4 cannot accidentally implement keybinds, login auto-start, Waybar cutover, or hard-restart while still covering FWK-02 / IPC-02 as explicit backlog.

---

## IPC-02 — Hyprland bar toggle keybind

**Requirement (REQUIREMENTS.md):**  
User can toggle bar visibility via a Hyprland keybind.

**Stock surface already present (do not re-invent):**

- `Bar.qml` GlobalShortcut names: `barToggle`, `barOpen`, `barClose` (unbound this pass — D-09)
- IPC: `qs ipc call bar toggle|open|close` (default config, bare `qs`)

**Options for a later finishing plan (pick one then):**

1. Hyprland `global` bind to stock GlobalShortcut name `barToggle` (dots-hyprland style), **or**
2. `bind = …, exec, qs ipc call bar toggle` (direct stock IPC; no new targets)

**Chord:** undecided. Roadmap example was SUPER+B. Current `SUPER+w` restarts Waybar (`pkill waybar && waybar &`) — **do not change now**.

**This pass non-actions:**

- Do not add a Hyprland bind for bar toggle
- Do not bind GlobalShortcut names in Hyprland
- Do not replace SUPER+w

---

## FWK-02 — exec-once auto-start

**Requirement (REQUIREMENTS.md):**  
User sees Quickshell auto-start via Hyprland exec-once at login.

**Future line should use default config** (this repo’s layout is `~/.config/quickshell/shell.qml`):

- Prefer `qs -d` or `qs &` / `quickshell` — **not** `qs -c ii`
- Coordinate with dual-run Waybar until cutover (do not remove Waybar when adding qs)

**Current hyprland.conf (read-only reference; leave as-is this pass):**

- `exec-once = waybar & swaync & hyprpaper &` (and other existing session lines)
- No Quickshell / `qs` exec-once today

**This pass non-actions:**

- Do not add `exec-once` for Quickshell
- Do not remove or reorder existing waybar/swaync/hyprpaper lines for this item

---

## Waybar removal / cutover

- After milestone parity (roadmap SC-5): workspaces, clock, tray, network, CPU, memory, disk, volume all functional on Quickshell
- Leave dual-run Waybar + Quickshell for now
- Cutover is backlog only — not implemented in Phase 4 plans 04-01..04-03

---

## Hard-restart keybind

- Dots-style killall + relaunch (e.g. CTRL+SUPER+R) is **not** graceful reload
- D-12 default recovery remains: fix QML + **manual** `qs` relaunch
- Hard-restart keybind only if desired later; not this pass
- No auto-relaunch daemon

---

## Explicit non-actions this pass

| Item | Status |
|------|--------|
| Edits to `hyprland.conf` | **Forbidden** (zero product edits) |
| Soft commented Hyprland stubs | **No** (user default) |
| Enable ReloadPopup | **No** (keep `QS_NO_RELOAD_POPUP=1`) |
| Auto-relaunch daemon | **No** |
| New IpcHandler targets / reload IPC | **No** |
| Invented `qs reload` CLI dependency | **No** (0.3.0 has no reload CLI; soft reload = content-change) |

---

## In-pass reminder

| ID | This pass |
|----|-----------|
| IPC-01 | Verify stock bar show/hide (04-01 harness + 04-02 UAT) |
| IPC-03 | Verify silent soft reload + bar/tray usable (04-01 harness + 04-03 UAT) |
| IPC-02 | Deferred — this document |
| FWK-02 | Deferred — this document |

When finishing-touch work starts, prefer a dedicated plan that only edits Hyprland session wiring after IPC-01/IPC-03 are green — without re-discussing the stock `bar` IPC surface.
