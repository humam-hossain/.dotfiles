# Phase 4: IPC, Keybinds & Integration - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify and productize **in-shell external control and graceful reload** for the Illogical Impulse Quickshell bar so development and UAT can show/hide the bar and hot-reload without a full process restart.

**In scope this pass (user-locked narrowed Phase 4):**
- **IPC-01** — Bar show/hide via stock Quickshell IPC (`qs ipc call bar toggle|open|close`)
- **IPC-03** — Graceful hot-reload via stock Quickshell reload (`qs reload`); bar + tray remain usable; silent reload (no popup)

**Explicitly deferred from this pass (finishing-touch pass after the bar is solid):**
- **IPC-02** — Hyprland keybind that toggles bar visibility
- **FWK-02** — Quickshell auto-start via Hyprland `exec-once` at login
- Waybar removal / cutover from Hyprland session
- Hard-restart keybind (e.g. CTRL+SUPER+R killall qs + relaunch)

**Out of scope (other phases / later milestones):**
- Launcher, clipboard, notification daemon product work (v2)
- Per-monitor independent bar visibility
- New IPC targets beyond stock ii bar surface
- Custom reload daemon or auto-relaunch on QML failure

Roadmap still lists FWK-02 / IPC-02 / full integration as Phase 4 goals. User decision: treat Hyprland wiring and Waybar cutover as **end-of-milestone finishing touches**, not mid-development work. Planner should plan **IPC verify + reload UAT** now; keep FWK-02/IPC-02 as deferred backlog items (same milestone or explicit follow-up plan), not invent keybinds/exec-once in this pass.

</domain>

<decisions>
## Implementation Decisions

### Phase 4 scope narrowing
- **D-01:** **IPC + reload only** for this discuss/plan/execute cycle. Do **not** wire Hyprland keybinds, `exec-once` auto-start, or Waybar removal in this pass.
- **D-02:** Hyprland bar-toggle keybind, login auto-start (FWK-02), and Waybar cutover are **finishing touches** after bar modules are solid — discuss concrete chords/exec lines only then.
- **D-03:** Roadmap success criteria 2 and 4 (keybind toggle, exec-once auto-start) are **out of this pass’s acceptance**; success criteria 1 and 3 (IPC show/hide/reload path, graceful reload) remain in. Criterion 5 (Waybar-parity module checklist) is a milestone gate, not new module work in Phase 4 code.

### IPC control surface (IPC-01)
- **D-04:** Keep **stock ii IPC** — no new IpcHandler targets or custom CLI wrappers.
- **D-05:** Bar control surface is `IpcHandler` **target `bar`** with **`toggle`**, **`open`**, **`close`** (already in `modules/ii/bar/Bar.qml`).
- **D-06:** External invocation for UAT/dev: **`qs ipc call bar toggle`**, **`qs ipc call bar open`**, **`qs ipc call bar close`** (exact `qs`/`-c`/`-p` flags left to agent discretion to match how this tree is launched).
- **D-07:** **Do not** add a custom **reload IPC** target. Reload is **stock Quickshell hot-reload** (e.g. `qs reload`), not `ipc call … reload`.
- **D-08:** Bar visibility is **all monitors together** via existing **`GlobalStates.barOpen`** (not per-monitor).
- **D-09:** GlobalShortcut names (`barToggle` / `barOpen` / `barClose`) may remain in QML as shipped by ii; **do not** bind them in Hyprland this pass. Document only if needed for later finishing touch — no active keybind work.

### Graceful reload (IPC-03)
- **D-10:** Keep **silent reload** — retain `//@ pragma Env QS_NO_RELOAD_POPUP=1` in `shell.qml`. Do **not** enable ReloadPopup for success/fail feedback this pass.
- **D-11:** After `qs reload`, **bar must still be usable** (modules visible/updating) and **system tray must remain usable** (icons reconnect/remain interactive). No requirement for full process kill under normal reload.
- **D-12:** On **broken QML / failed reload**: **manual relaunch only** (user fixes QML and starts `qs` again). No auto-relaunch daemon; no hard-restart Hyprland keybind this pass.
- **D-13:** **Verify stock only** — Phase 4 implementation work is primarily **assert/UAT that stock IPC + reload work**. Add code **only if** verification finds show/hide or reload/tray broken.

### Agent's Discretion
- Exact `qs` invocation (`qs`, `qs -c …`, path to config) matching how this repo’s shell is already launched for development
- How to structure UAT / smoke scripts for `bar toggle|open|close` and post-reload tray checks
- Whether to leave commented Hyprland stubs — **default no** (user chose not soft stubs; finishing pass only)
- Whether GlobalShortcut blocks stay untouched (prefer leave stock ii as-is)
- If stock reload fails tray criterion, minimum fix only after evidence — do not pre-build hardening

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning
- `.planning/PROJECT.md` — Core value (Waybar parity before cutover); global shortcuts/IPC as foundation; cutover removes Waybar when parity verified
- `.planning/REQUIREMENTS.md` — FWK-02, IPC-01, IPC-02, IPC-03 (FWK-02/IPC-02 deferred this pass per D-01/D-02)
- `.planning/ROADMAP.md` — Phase 4 goal + five success criteria (narrow acceptance per D-03)
- `.planning/STATE.md` — Current position Phase 4
- `.planning/phases/01-shell-foundation-theme/01-CONTEXT.md` — Wholesale ii; exec-once deferred from Phase 1 to later integration
- `.planning/phases/02-core-bar-modules/02-CONTEXT.md` — Bar layout; dual-write config; tray behavior
- `.planning/phases/03-system-audio-modules/03-CONTEXT.md` — Dual bars OK during testing; IPC/keybinds/cutover pointed at Phase 4

### Implementation (this repo)
- `.config/quickshell/shell.qml` — `QS_NO_RELOAD_POPUP=1`, ReloadPopup instantiation, panel family loaders
- `.config/quickshell/GlobalStates.qml` — `barOpen` and other panel flags
- `.config/quickshell/ReloadPopup.qml` — Stock reload feedback (kept silent via pragma)
- `.config/quickshell/modules/ii/bar/Bar.qml` — `IpcHandler` target `bar` + GlobalShortcut barToggle/barOpen/barClose; `active: GlobalStates.barOpen`
- `.config/quickshell/modules/ii/bar/SysTray.qml` / `services/TrayService.qml` — Tray surface that must survive reload (D-11)
- `.config/hypr/hyprland.conf` — Current `exec-once` (waybar & swaync & hyprpaper); `SUPER+w` restarts waybar — **do not change this pass** (D-01/D-02)
- `arch/quickshell.sh` — Symlink deploy of quickshell config

### Inspiration (reference only)
- `../dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` — `qs -c $qsConfig ipc call` and global shortcut patterns (finishing touch later)
- `../dots-hyprland/dots/.config/hypr/hyprland/execs.lua` — `qs -c $qsConfig` auto-start pattern (finishing touch later)

### Prior maps (may be stale vs wholesale ii)
- `.planning/codebase/INTEGRATIONS.md` — Hyprland exec-once / desktop service map
- `.planning/codebase/ARCHITECTURE.md` — High-level session architecture
- `.planning/codebase/STACK.md` — Tooling stack

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Bar.qml` `IpcHandler { target: "bar"; toggle/open/close }` — already implements IPC-01 surface
- `GlobalStates.barOpen` — single flag driving all bar instances
- `ReloadPopup.qml` + `QS_NO_RELOAD_POPUP=1` — silent hot-reload already configured
- `SysTray` / `TrayService` — tray to validate after reload
- Stock Quickshell CLI (`qs ipc call`, `qs reload`) — no new tooling required

### Established Patterns
- Wholesale ii / fix-only-what-breaks (Phase 1)
- Dual-write Config.qml + live config.json for product knobs (Phases 2–3) — **not required** for stock IPC/reload unless a config bug surfaces
- Waybar still coexists until finishing cutover
- GlobalShortcut names exist for later Hyprland `global` binds; unused this pass

### Integration Points
- External control: shell IPC socket via Quickshell runtime (not Hyprland binds yet)
- Reload: Quickshell process hot-reload path; user may also restart process manually
- Hyprland session: leave `hyprland.conf` exec-once and SUPER+w as-is until finishing pass
- Dual monitor: one `barOpen` for DP-1 and HDMI-A-2 bars

</code_context>

<specifics>
## Specific Ideas

- User is **under active development** — does not want keybind / login / Waybar-removal churn mid-stream
- “At the end for finishing touch we can discuss keybind, login-time exec quickshell, waybar remove”
- Prefer **stock ii/Quickshell** over new control surfaces
- Silent reload preferred over popup noise during rapid iteration

</specifics>

<deferred>
## Deferred Ideas

- **Hyprland keybind for bar toggle (IPC-02)** — finishing touch after bar is solid; chord undecided (SUPER+B was roadmap example; SUPER+w currently restarts Waybar)
- **Quickshell `exec-once` auto-start (FWK-02)** — finishing touch with login integration
- **Waybar removal / cutover** — after parity verified; leave dual-run for now
- **Hard-restart keybind** (dots-style CTRL+SUPER+R killall qs + relaunch) — not this pass
- **Per-monitor bar visibility** — rejected for this phase; possible future
- **Soft Hyprland stubs** (commented binds/exec-once) — user did not choose; omit unless finishing pass wants them
- **Enable ReloadPopup** — rejected for this pass; may revisit if silent failures hurt debugging

</deferred>

---

*Phase: 4-IPC, Keybinds & Integration*
*Context gathered: 2026-07-24*
