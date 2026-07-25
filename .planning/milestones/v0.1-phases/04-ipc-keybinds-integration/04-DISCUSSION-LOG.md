# Phase 4: IPC, Keybinds & Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-24
**Phase:** 4-IPC, Keybinds & Integration
**Areas discussed:** Bar toggle keybind, IPC control surface, Graceful reload policy
**Areas offered but not selected:** Login auto-start & Waybar coexistence

---

## Area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Login auto-start & Waybar coexistence | exec-once + dual-run vs cutover | |
| Bar toggle keybind | Which Hyprland keybind toggles bar | ✓ |
| IPC control surface | qs ipc vs global shortcut vs both | ✓ |
| Graceful reload policy | Hot-reload UX and survival criteria | ✓ |

**User's choice:** Bar toggle keybind, IPC control surface, Graceful reload policy  
**Notes:** Login/Waybar area not selected; later free-text deferred those topics as finishing touches anyway.

---

## Bar toggle keybind

| Option | Description | Selected |
|--------|-------------|----------|
| SUPER+B | Roadmap example | |
| Repurpose SUPER+w | Replace waybar restart bind | |
| SUPER+Shift+B | Less collision risk | |
| Other (free text) | Not a concern mid-dev | ✓ |

**User's choice:** Other — keybind not a real concern right now; finishing touch with login exec and Waybar remove after everything is done.  
**Notes:** User under development; no need for keybinds/exec/cutover mid-stream.

### Follow-up: Phase 4 scope lock

| Option | Description | Selected |
|--------|-------------|----------|
| IPC + reload only | Defer keybinds, exec-once, Waybar cutover | ✓ |
| IPC + reload + soft Hyprland stubs | Commented/optional Hyprland lines | |
| Do full Phase 4 as roadmap | Wire keybinds + exec-once now | |

**User's choice:** IPC + reload only (Recommended)  
**Notes:** Narrows Phase 4 acceptance; FWK-02 and IPC-02 deferred.

---

## IPC control surface

| Option | Description | Selected |
|--------|-------------|----------|
| Keep stock ii IPC | IpcHandler bar toggle/open/close | ✓ |
| IPC + document GlobalShortcut names | Same + document for later binds | |
| You decide | Match dots-hyprland minimal surface | |

**User's choice:** Keep stock ii IPC (Recommended)

### Reload trigger

| Option | Description | Selected |
|--------|-------------|----------|
| Stock Quickshell reload | qs reload; no custom reload IPC | ✓ |
| Add a reload IPC target | ipc call … reload | |
| You decide | Least new code | |

**User's choice:** Stock Quickshell reload (Recommended)

### Minimum bar commands

| Option | Description | Selected |
|--------|-------------|----------|
| toggle + open + close | All three for UAT | ✓ |
| toggle only | Minimum viable | |
| You decide | Keep whatever ii ships | |

**User's choice:** toggle + open + close (Recommended)

### Multi-monitor toggle scope

| Option | Description | Selected |
|--------|-------------|----------|
| All monitors together | GlobalStates.barOpen | ✓ |
| Per-monitor (future) | Deferred | |
| You decide | Stock behavior | |

**User's choice:** All monitors together (Recommended)

---

## Graceful reload policy

| Option | Description | Selected |
|--------|-------------|----------|
| Keep silent | QS_NO_RELOAD_POPUP=1 | ✓ |
| Enable ReloadPopup | Show success/fail popup | |
| You decide | Least disruptive | |

**User's choice:** Keep silent (Recommended)

### Post-reload survival

| Option | Description | Selected |
|--------|-------------|----------|
| Bar + tray stay usable | Matches roadmap tray language | ✓ |
| Bar modules only | Tray lag OK | |
| Full process restart OK | Weaker IPC-03 | |

**User's choice:** Bar + tray stay usable (Recommended)

### Failed reload recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Manual relaunch only | No daemon / no hard-restart bind | ✓ |
| Hard-restart keybind now | CTRL+SUPER+R style | |
| You decide | Minimal recovery docs | |

**User's choice:** Manual relaunch only (Recommended)

### Implementation depth

| Option | Description | Selected |
|--------|-------------|----------|
| Verify stock only | UAT first; fix only if broken | ✓ |
| Harden reload if tray drops | Conditional fix after evidence | |
| You decide | Minimum fixes if stock fails | |

**User's choice:** Verify stock only (Recommended)

---

## Claude's Discretion

- Exact `qs` CLI flags for this tree’s launch path
- UAT/smoke script shape for IPC and post-reload checks
- Leave GlobalShortcut QML blocks untouched (stock ii)
- No soft Hyprland stubs unless finishing pass asks

---

## Deferred Ideas

- Hyprland keybind for bar toggle (IPC-02) — finishing touch
- Login exec-once for Quickshell (FWK-02) — finishing touch
- Waybar removal / cutover — finishing touch
- Hard-restart keybind (dots-style)
- Per-monitor bar visibility
- Enable ReloadPopup for debugging
- Soft commented Hyprland stubs (not chosen)
