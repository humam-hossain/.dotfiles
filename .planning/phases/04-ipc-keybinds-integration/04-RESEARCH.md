# Phase 4: IPC, Keybinds & Integration - Research

**Researched:** 2026-07-24
**Domain:** Quickshell stock IPC (`IpcHandler` / `qs ipc`) + graceful soft-reload (file-watch / `Quickshell.reload`) for Illogical Impulse bar
**Confidence:** HIGH

## Summary

Phase 4 (this pass) is a **verify / UAT productization** of stock Quickshell external control and hot-reload — **not** a greenfield feature build. The ii tree already ships `IpcHandler { target: "bar"; toggle|open|close }` in `modules/ii/bar/Bar.qml`, drives visibility via `GlobalStates.barOpen`, and silences reload UI with `//@ pragma Env QS_NO_RELOAD_POPUP=1` in `shell.qml`. Live host checks on 2026-07-24 confirmed: running instance on default config (`~/.config/quickshell/shell.qml`), `qs ipc show` lists `target bar` with the three functions, and `qs ipc call bar open|close` returns exit 0 without restarting the process.

**Critical correction vs discuss-phase wording:** Quickshell **0.3.0** (Arch package `quickshell 0.3.0-2`) has **no** `qs reload` CLI subcommand. Stock graceful reload is **file-watch soft reload** (`Quickshell.watchFiles` defaults `true` — save any watched QML → `Reloading configuration…` / `Configuration Loaded`, **same PID**) or the QML API `Quickshell.reload(hard: bool)`. Planner must treat D-07 as “no custom reload IPC; use stock Quickshell hot-reload,” **not** invent a `qs reload` wrapper. Hard process kill+relaunch is the **manual recovery** path only (D-12).

**In-scope requirements:** IPC-01, IPC-03.  
**Deferred this pass:** IPC-02 (Hyprland keybind), FWK-02 (`exec-once` auto-start), Waybar cutover, hard-restart keybind. Roadmap success criteria 2 and 4 are out of this pass’s acceptance (D-03).

**Primary recommendation:** Plan a short **assert + live smoke + human UAT** wave that proves stock `bar` IPC and soft-reload/tray survival. **Add QML only if verification finds a break** (D-13). Do not wire Hyprland binds or `exec-once`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Phase 4 scope narrowing
- **D-01:** **IPC + reload only** for this discuss/plan/execute cycle. Do **not** wire Hyprland keybinds, `exec-once` auto-start, or Waybar removal in this pass.
- **D-02:** Hyprland bar-toggle keybind, login auto-start (FWK-02), and Waybar cutover are **finishing touches** after bar modules are solid — discuss concrete chords/exec lines only then.
- **D-03:** Roadmap success criteria 2 and 4 (keybind toggle, exec-once auto-start) are **out of this pass’s acceptance**; success criteria 1 and 3 (IPC show/hide/reload path, graceful reload) remain in. Criterion 5 (Waybar-parity module checklist) is a milestone gate, not new module work in Phase 4 code.

#### IPC control surface (IPC-01)
- **D-04:** Keep **stock ii IPC** — no new IpcHandler targets or custom CLI wrappers.
- **D-05:** Bar control surface is `IpcHandler` **target `bar`** with **`toggle`**, **`open`**, **`close`** (already in `modules/ii/bar/Bar.qml`).
- **D-06:** External invocation for UAT/dev: **`qs ipc call bar toggle`**, **`qs ipc call bar open`**, **`qs ipc call bar close`** (exact `qs`/`-c`/`-p` flags left to agent discretion to match how this tree is launched).
- **D-07:** **Do not** add a custom **reload IPC** target. Reload is **stock Quickshell hot-reload** (e.g. `qs reload`), not `ipc call … reload`.
- **D-08:** Bar visibility is **all monitors together** via existing **`GlobalStates.barOpen`** (not per-monitor).
- **D-09:** GlobalShortcut names (`barToggle` / `barOpen` / `barClose`) may remain in QML as shipped by ii; **do not** bind them in Hyprland this pass. Document only if needed for later finishing touch — no active keybind work.

#### Graceful reload (IPC-03)
- **D-10:** Keep **silent reload** — retain `//@ pragma Env QS_NO_RELOAD_POPUP=1` in `shell.qml`. Do **not** enable ReloadPopup for success/fail feedback this pass.
- **D-11:** After `qs reload`, **bar must still be usable** (modules visible/updating) and **system tray must remain usable** (icons reconnect/remain interactive). No requirement for full process kill under normal reload.
- **D-12:** On **broken QML / failed reload**: **manual relaunch only** (user fixes QML and starts `qs` again). No auto-relaunch daemon; no hard-restart Hyprland keybind this pass.
- **D-13:** **Verify stock only** — Phase 4 implementation work is primarily **assert/UAT that stock IPC + reload work**. Add code **only if** verification finds show/hide or reload/tray broken.

### Claude's Discretion
- Exact `qs` invocation (`qs`, `qs -c …`, path to config) matching how this repo’s shell is already launched for development
- How to structure UAT / smoke scripts for `bar toggle|open|close` and post-reload tray checks
- Whether to leave commented Hyprland stubs — **default no** (user chose not soft stubs; finishing pass only)
- Whether GlobalShortcut blocks stay untouched (prefer leave stock ii as-is)
- If stock reload fails tray criterion, minimum fix only after evidence — do not pre-build hardening

### Deferred Ideas (OUT OF SCOPE)
- **Hyprland keybind for bar toggle (IPC-02)** — finishing touch after bar is solid; chord undecided (SUPER+B was roadmap example; SUPER+w currently restarts Waybar)
- **Quickshell `exec-once` auto-start (FWK-02)** — finishing touch with login integration
- **Waybar removal / cutover** — after parity verified; leave dual-run for now
- **Hard-restart keybind** (dots-style CTRL+SUPER+R killall qs + relaunch) — not this pass
- **Per-monitor bar visibility** — rejected for this phase; possible future
- **Soft Hyprland stubs** (commented binds/exec-once) — user did not choose; omit unless finishing pass wants them
- **Enable ReloadPopup** — rejected for this pass; may revisit if silent failures hurt debugging
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | In this pass? | Research Support |
|----|-------------|-----------------|------------------|
| **IPC-01** | Shell exposes an IPC socket for external commands (show/hide bar, reload) | **YES** (show/hide via IPC; reload is **not** an IPC command — see D-07 + stock reload path) | Stock `IpcHandler` target `bar` with `toggle`/`open`/`close`; socket at `$XDG_RUNTIME_DIR/quickshell/by-id/<id>/ipc.sock`; CLI `qs ipc call bar …` |
| **IPC-03** | Shell supports graceful reload without full restart (preserves runtime state) | **YES** | Soft reload via file-watch (`Quickshell.watchFiles` default true) or `Quickshell.reload(false)`; same PID; silent via `QS_NO_RELOAD_POPUP=1`; UAT tray + bar after reload |
| **IPC-02** | User can toggle bar visibility via a Hyprland keybind | **DEFERRED** | dots-hyprland pattern `hl.dsp.global("quickshell:barToggle")` or `qs ipc call bar toggle`; leave `hyprland.conf` alone this pass |
| **FWK-02** | User sees Quickshell auto-start via Hyprland exec-once at login | **DEFERRED** | dots pattern `exec-once = qs -c $qsConfig`; this tree is **default** config (`shell.qml` at config root → `qs` / `quickshell` with no `-c`); do not change `exec-once` this pass |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bar show/hide state | Desktop shell (`GlobalStates.barOpen`) | `Bar.qml` LazyLoader `active` | Single flag for all monitors (D-08) |
| IPC socket + dispatch | Quickshell runtime (`IpcHandler` / `qs ipc`) | Host CLI | Stock QS IPC; no custom daemon |
| Soft hot-reload | Quickshell runtime (file watcher / `Quickshell.reload`) | Watched QML files | Stock; no process kill |
| Silent reload UX | Shell entry (`QS_NO_RELOAD_POPUP` pragma + `ReloadPopup`) | — | D-10 keep silent |
| System tray after reload | Quickshell `SystemTray` service + `TrayService` / `SysTray` | StatusNotifier D-Bus | D-11 UAT criterion |
| Hyprland keybind toggle | **Deferred** — compositor binds | GlobalShortcut / `qs ipc` | IPC-02 finishing touch |
| Login auto-start | **Deferred** — Hyprland `exec-once` | `arch/quickshell.sh` deploy | FWK-02 finishing touch |
| Hard recovery | User manual process restart | Host shell | D-12 only |

---

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Quickshell (`qs` / `quickshell`) | **0.3.0** (Arch `0.3.0-2`) [VERIFIED: `qs --version` + `pacman -Qi`] | Shell runtime, IPC, soft reload | Project foundation |
| `Quickshell.Io.IpcHandler` | 0.3.0 types | Expose QML functions over IPC | Official IPC surface [CITED: quickshell.org/docs/v0.3.0/types/Quickshell.Io/IpcHandler] |
| `Quickshell` singleton (`reload`, `watchFiles`, reload signals) | 0.3.0 | Soft/hard reload API + file watch | Official [CITED: quickshell.org/docs/v0.3.0/types/Quickshell/Quickshell] |
| Illogical Impulse bar (`modules/ii/bar/Bar.qml`) | wholesale ii | Stock `bar` IPC + GlobalShortcut names | Already in tree [VERIFIED: codebase] |
| `GlobalStates` singleton | wholesale ii | `barOpen` visibility flag | Already in tree [VERIFIED: codebase] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `qs list` | 0.3.0 | List running instances + config path | Preflight before IPC smoke |
| `qs ipc show` | 0.3.0 | List registered IPC targets/functions | Assert `target bar` surface |
| `qs ipc call` | 0.3.0 | Invoke handler functions | UAT/dev bar toggle/open/close |
| `qs kill` | 0.3.0 | Kill instance | Manual recovery only (not normal reload) |
| Python stdlib scripts | — | Optional static/live assert harness (Phase 2/3 pattern) | Wave 0 smoke if planner wants automation |
| `rg` / shell | — | Static gates for IpcHandler + pragma | Per-commit verification |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Stock `IpcHandler` | Custom Unix socket / D-Bus service | **Rejected** — D-04 stock only; more code, more failure modes |
| File-watch soft reload | Custom `ipc call … reload` wrapping `Quickshell.reload` | **Rejected for this pass** — D-07 no custom reload IPC |
| File-watch soft reload | `qs reload` CLI | **Does not exist** on 0.3.0 [VERIFIED: `qs reload` → CLI error] |
| Soft reload | `killall qs; qs &` | Hard restart; loses process state; only for failed reload (D-12) |
| Hyprland `global` bind on `barToggle` | `exec, qs ipc call bar toggle` | Finishing touch (IPC-02); either works; dots prefers `global` |

**Installation:** None — no new packages. Runtime already installed via `arch/quickshell.sh`.

**Version verification:**

```text
qs --version  →  Quickshell 0.3.0 (revision , distributed by Arch Linux)
pacman -Qi quickshell → Version: 0.3.0-2  (Build Date: 2026-06-05)
```

---

## Package Legitimacy Audit

> No external packages are installed in this phase.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | N/A | No installs |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```text
External CLI (dev/UAT)
        │
        │  qs ipc call bar toggle|open|close
        ▼
  qs client  ──Unix socket──►  $XDG_RUNTIME_DIR/quickshell/by-id/<id>/ipc.sock
                                        │
                                        ▼
                              Quickshell process (PID stable)
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
             IpcHandler            GlobalStates         File watcher
             target:"bar"          barOpen: bool        (watchFiles=true)
             toggle/open/close           │                     │
                    │                    │                     │ content change
                    └──────────► sets barOpen ◄── GlobalShortcut  │
                                         │                   soft reload
                                         ▼                     │
                              LazyLoader active=                 ▼
                              barOpen && !screenLocked   Rebuild QML tree
                                         │               (soft: reuse windows)
                                         ▼                     │
                              PanelWindow per monitor          ▼
                              (WlrLayershell bar)        reloadCompleted /
                                         │               reloadFailed
                                         ▼                     │
                              BarContent + SysTray             ▼
                              (TrayService / SystemTray)  ReloadPopup
                                                          (suppressed by
                                                           QS_NO_RELOAD_POPUP=1)
```

**Primary use-case traces:**

1. **IPC-01:** `qs ipc call bar close` → socket → `IpcHandler.close` → `GlobalStates.barOpen=false` → LazyLoader deactivates all bar windows → bars hide on every monitor.
2. **IPC-03:** Edit/save watched QML → file watcher → soft reload → same PID → bar reappears if `barOpen` still true (singleton state may reset — see pitfalls) → tray rebinds StatusNotifier host → modules update.

### Recommended Project Structure (unchanged — verify only)

```text
.config/quickshell/
├── shell.qml                 # QS_NO_RELOAD_POPUP; ReloadPopup; panel families
├── GlobalStates.qml          # barOpen (default true)
├── ReloadPopup.qml           # stock feedback (silent via pragma)
├── modules/ii/bar/
│   ├── Bar.qml               # IpcHandler target bar + GlobalShortcuts + LazyLoader
│   ├── SysTray.qml           # tray UI
│   └── …
├── services/
│   └── TrayService.qml       # pin/filter over SystemTray.items
└── panelFamilies/
    └── IllogicalImpulseFamily.qml  # loads Bar {}
```

Optional **new** test artifact only (agent discretion):

```text
scripts/
└── phase04-ipc-reload-assert.sh   # or .py — live IPC + soft-reload log gates
```

### Pattern 1: Stock bar IPC (already present)

**What:** `IpcHandler` on target `bar` mutates `GlobalStates.barOpen`.  
**When to use:** Always for external bar control this phase.  
**Example (repo source):**

```218:231:.config/quickshell/modules/ii/bar/Bar.qml
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

[VERIFIED: codebase]

### Pattern 2: Visibility via LazyLoader (all monitors)

```27:29:.config/quickshell/modules/ii/bar/Bar.qml
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
```

One flag → every screen’s bar. [VERIFIED: codebase]

### Pattern 3: Silent soft reload (already present)

```1:3:.config/quickshell/shell.qml
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
```

```23:23:.config/quickshell/shell.qml
    ReloadPopup {}
```

Official docs: `QS_NO_RELOAD_POPUP=1` or `Quickshell.inhibitReloadPopup()` suppress default popup. [CITED: quickshell.org docs Quickshell.inhibitReloadPopup / QS_NO_RELOAD_POPUP]

### Pattern 4: This repo’s launch / IPC selection (agent discretion resolved)

| Fact | Value | Source |
|------|-------|--------|
| Config layout | `~/.config/quickshell/shell.qml` → **default** config | Symlink to repo; [VERIFIED: `readlink` + `qs list`] |
| Launch | `qs` or `quickshell` (**no** `-c ii`) | Unlike dots-hyprland `qs -c $qsConfig` |
| Live instance | PID 183769, id `psx3awwnit`, path `/home/pera/.config/quickshell/shell.qml` | [VERIFIED: `qs list` 2026-07-24] |
| IPC invoke | `qs ipc call bar toggle` (no `-c` needed when only default instance) | [VERIFIED: live exit 0] |
| Socket | `/run/user/<uid>/quickshell/by-id/<id>/ipc.sock` | [VERIFIED: filesystem] |

**Prescriptive CLI for all Phase 4 plans:**

```bash
# Preflight
qs list
qs ipc show | rg -n 'target bar|function (toggle|open|close)'

# IPC-01
qs ipc call bar close   # expect exit 0; bars hide
qs ipc call bar open    # expect exit 0; bars show
qs ipc call bar toggle  # expect exit 0; flips visibility
```

If multiple instances ever exist, pin with `-i <id>` or `--pid <pid>` (from `qs list`). [VERIFIED: `qs ipc --help`]

### Pattern 5: Soft reload trigger (stock, no CLI)

**There is no `qs reload`.** [VERIFIED: `qs reload` → “The following argument was not expected: reload”]

**Stock graceful reload for UAT:**

```bash
# Capture PID + log path from qs list / XDG_RUNTIME_DIR
PID=$(qs list 2>/dev/null | rg -o 'Process ID: [0-9]+' | head -1 | awk '{print $3}')
# Or: pgrep -n quickshell

# Trigger soft reload by real content change on a watched file
# (mtime-only touch is NOT enough — content must change)
printf '\n// phase04-reload-probe\n' >> ~/.config/quickshell/shell.qml
# wait for "Reloading configuration..." / "Configuration Loaded" in instance log
# restore file
# Assert: same PID; qs ipc call bar open still works
```

Live experiment 2026-07-24: content append → log `Reloading configuration...` + `Configuration Loaded` within ~0.5s; PID **183769 unchanged**; subsequent `qs ipc call bar open` exit 0. [VERIFIED: live host]

QML API alternative (must **not** be exposed as new IPC this pass per D-07 unless verification requires a minimal escape hatch — and even then prefer fixing file-watch path first):

```qml
// Source: https://quickshell.org/docs/v0.3.0/types/Quickshell/Quickshell
Quickshell.reload(false)  // soft — attempt to reuse windows
Quickshell.reload(true)   // hard — recreate windows
```

### Anti-Patterns to Avoid

- **Implementing `qs reload` wrapper scripts** that kill/restart — that is hard restart, not graceful reload.
- **Adding `IpcHandler` reload function** this pass (D-07).
- **Editing `hyprland.conf` exec-once / SUPER+w** (D-01/D-02).
- **Assuming `-c ii`** — this tree is default config; `-c ii` will miss the running shell.
- **Pre-hardening tray** before UAT evidence (D-13).
- **Treating REQUIREMENTS “reload” as IPC method** — roadmap text says “show, hide, reload” on the socket; locked decisions separate reload from IPC (D-07). Mark IPC-01 satisfied by show/hide IPC + separate stock reload path.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| External bar show/hide | Custom socket protocol | Stock `IpcHandler` + `qs ipc call bar …` | Already works; typed args; multi-instance selection |
| Graceful reload | Auto-relaunch daemon / systemd unit | File-watch soft reload / `Quickshell.reload` | Stock QS; D-12 forbids auto-relaunch |
| Reload feedback | Custom toast | Keep silent pragma; optional later ReloadPopup | D-10 |
| Instance discovery | Parse /proc manually | `qs list` / `qs ipc -i` / `--pid` | Official CLI |
| Keybind (deferred) | New IPC target | Hyprland `global,quickshell:barToggle` or `exec, qs ipc call bar toggle` | dots-hyprland pattern |
| Tray reconnect logic | Custom SNI host | `Quickshell.Services.SystemTray` + `TrayService` | Stock; only patch if UAT fails |

**Key insight:** Phase 4 success is **evidence that stock surfaces work**, not new architecture. The planner’s default plan should be Wave 0 harness + static gates + live smoke + human UAT; code tasks are **conditional** on red verification.

---

## Common Pitfalls

### Pitfall 1: Believing `qs reload` exists on 0.3.0
**What goes wrong:** Plans/scripts call `qs reload` and fail immediately.  
**Why it happens:** Discuss-phase / training knowledge assumed a CLI that is not in 0.3.0 help.  
**How to avoid:** Use file-watch soft reload or document `Quickshell.reload` for later; never gate UAT on `qs reload`.  
**Warning signs:** CLI “argument was not expected: reload”.  
[VERIFIED: live CLI]

### Pitfall 2: Wrong config selector (`-c ii` vs default)
**What goes wrong:** `qs -c ii ipc call bar toggle` targets nothing / wrong instance while default shell runs.  
**Why it happens:** dots-hyprland uses named config dirs; this repo symlinks shell at `quickshell/shell.qml` (default).  
**How to avoid:** Prefer bare `qs ipc …`; confirm with `qs list` Config path.  
[VERIFIED: `qs list` + symlink]

### Pitfall 3: Soft reload may reset `GlobalStates.barOpen`
**What goes wrong:** User hid bar via IPC, then reloads; bar returns (default `barOpen: true`) or other panel flags reset.  
**Why it happens:** Soft reload rebuilds QML; non-`Reloadable`/`PersistentProperties` state is not guaranteed.  
**How to avoid:** UAT should re-open bar after reload if needed; do not require hide state to survive reload unless proven. D-11 requires **usable** bar+tray after reload, not preservation of `barOpen=false`.  
[ASSUMED: state reset on reload for plain properties — not formally documented for GlobalStates; planner should treat as expected risk]

### Pitfall 4: Tray / StatusNotifier flakiness around reload
**What goes wrong:** Icons missing, unclickable, or log spam (`Ignoring invalid StatusNotifierHost registration`, DBus IconName errors).  
**Why it happens:** SNI host re-registration race; other hosts (Waybar may also present tray); flaky clients.  
**How to avoid:** UAT with known tray apps; dual Waybar+QS is current state — note possible dual-host noise; only code-fix if **QS tray unusable** after reload.  
[VERIFIED: live log warnings present on current session]

### Pitfall 5: mtime-only `touch` does not reload
**What goes wrong:** Smoke script touches `shell.qml` and asserts reload — never fires.  
**Why it happens:** Watcher reacts to content changes (rewrite same bytes / mtime alone insufficient in live test).  
**How to avoid:** Append+restore a probe comment, or edit a real character.  
[VERIFIED: live touch vs content change]

### Pitfall 6: Stale instance dirs under `$XDG_RUNTIME_DIR/quickshell/by-id`
**What goes wrong:** Scripts pick wrong socket / id.  
**Why it happens:** Prior runs leave by-id directories (6 observed while 1 process live).  
**How to avoid:** Always use `qs list` / `qs ipc` instance selection, not raw first socket.  
[VERIFIED: filesystem]

### Pitfall 7: Scope creep into Hyprland finishing work
**What goes wrong:** Plan “helpfully” adds SUPER+B and exec-once.  
**Why it happens:** Roadmap still lists full Phase 4 goals.  
**How to avoid:** D-01–D-03 — backlog FWK-02/IPC-02 only.  
[VERIFIED: CONTEXT.md]

### Pitfall 8: Broken QML leaves shell dead with no popup (silent reload)
**What goes wrong:** User thinks nothing happened; shell stuck failed.  
**Why it happens:** D-10 silences ReloadPopup.  
**How to avoid:** UAT documents checking instance log for `reloadFailed`; recovery = fix QML + manual relaunch (D-12).  
[CITED: Quickshell reloadFailed signal + QS_NO_RELOAD_POPUP]

---

## Code Examples

### Exact IPC surface (official shape)

```bash
# Source: live host 2026-07-24 + official IpcHandler docs
qs ipc show
# … includes:
# target bar
#   function close(): void
#   function toggle(): void
#   function open(): void

qs ipc call bar close
qs ipc call bar open
qs ipc call bar toggle
```

[VERIFIED: live `qs ipc show` + call exit 0]

### Official IpcHandler typing rule

Functions need **explicit** argument/return types or they will not register. Bar handlers already use `: void`. [CITED: quickshell.org IpcHandler docs]

### Soft reload signals (for UAT observation)

```qml
// Source: https://quickshell.org/docs/v0.3.0/types/Quickshell/Quickshell
// Already used by ReloadPopup.qml
Connections {
    target: Quickshell
    function onReloadCompleted() { /* success */ }
    function onReloadFailed(error: string) { /* failure */ }
}
```

[VERIFIED: ReloadPopup.qml + official docs]

### Deferred finishing-touch references (do not implement)

```lua
-- Source: dots-hyprland keybinds.lua (reference only)
-- SUPER+J → global quickshell:barToggle
-- CTRL+SUPER+R → killall ydotool qs quickshell; qs -c $qsConfig &
```

```lua
-- Source: dots-hyprland execs.lua (reference only)
-- exec-once qs -c $qsConfig
```

This repo would use `qs` / `quickshell` (default config), not `qs -c ii`, if/when FWK-02 is implemented. [VERIFIED: dots-hyprland paths + this repo layout]

### Manual hard recovery (D-12)

```bash
qs kill          # or: killall qs quickshell
qs -d            # or: qs &   / quickshell &
# confirm:
qs list
qs ipc call bar open
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `qs msg` | `qs ipc call` | Pre-0.3 deprecation | Use `ipc call` only [VERIFIED: `qs --help`] |
| Assumed `qs reload` CLI | File-watch soft reload + `Quickshell.reload(hard)` | Confirmed 0.3.0 Arch | Plans must not call `qs reload` |
| Named config `qs -c ii` (dots) | Default `shell.qml` at config root | This repo Phase 1 deploy | Bare `qs` / `qs ipc` |
| Waybar-only session control | Dual Waybar + Quickshell during development | Current | Leave SUPER+w / exec-once alone |

**Deprecated/outdated:**
- `qs msg` → `qs ipc call` [VERIFIED: help text]
- `qs reload` as a documented CLI for this install — **does not exist** [VERIFIED]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Soft reload does **not** guarantee preserving `GlobalStates.barOpen` / other plain properties | Pitfalls / Validation | UAT may over-assert hide survival; should only require post-reload usability |
| A2 | No code changes will be required if live UAT passes (stock already sufficient) | Summary / Primary rec | If tray dies after reload, a minimal fix plan is needed mid-execute |
| A3 | Dual Waybar+QS tray coexistence is acceptable noise until finishing cutover | Pitfalls | UAT may confuse Waybar tray with QS tray — instruct visual check on QS bar only |

**If empty:** N/A — three assumptions logged for planner/user confirmation where needed.

---

## Open Questions / Deferred

1. **`qs reload` wording in D-07/D-11 vs 0.3.0 reality**
   - What we know: no CLI; soft reload is file-watch / `Quickshell.reload`.
   - What's unclear: whether user expected a future CLI or meant “stock hot-reload.”
   - Recommendation: Planner interprets D-07/D-11 as **stock soft reload**; document correction in plan notes; do not invent CLI.

2. **Does REQUIREMENTS IPC-01 “reload” require an IPC method?**
   - What we know: D-07 forbids custom reload IPC; roadmap phrasing is looser.
   - Recommendation: Satisfy IPC-01 with show/hide IPC + separate IPC-03 soft reload; note requirement text vs locked decision in verification.

3. **Tray pass criteria under dual hosts (Waybar + QS)**
   - What we know: SNI warnings already in logs.
   - Recommendation: Human UAT on QS bar tray icons only; optional “kill waybar temporarily” note for isolation — but do **not** remove Waybar from exec-once (deferred cutover).

4. **Deferred backlog packaging**
   - FWK-02, IPC-02, Waybar cutover, hard-restart keybind → finishing-touch plan after bar solid.
   - Recommendation: Explicit “Deferred backlog” section in PLAN.md / ROADMAP note; zero implementation tasks this pass.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `qs` / `quickshell` | IPC + shell | ✓ | 0.3.0 | — |
| Running QS instance | Live IPC smoke | ✓ (dev session) | PID via `qs list` | Launch `qs -d` if missing |
| Wayland session (Hyprland) | Visual UAT | ✓ | wayland-1 | Manual-only without display |
| `python3` | Optional assert scripts | ✓ | system | Pure bash/rg gates |
| `rg` | Static gates | ✓ | system | `grep -E` |
| New npm/pip packages | — | N/A | — | None needed |
| Hyprland config write access | Deferred only | ✓ | — | Do not use this pass |

**Missing dependencies with no fallback:** none for in-scope work.

**Missing dependencies with fallback:** none.

---

## Validation Architecture

> `workflow.nyquist_validation` is **true** in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual QML/runtime UAT + shell smoke + optional Python/bash assert script (Phase 2/3 pattern) |
| Config file | none — no unit test framework for QML |
| Quick run command | `qs list && qs ipc show \| rg 'target bar' && qs ipc call bar open` |
| Full suite command | static `rg` gates + live IPC sequence + soft-reload log gate + human UAT (tray/bar) |
| Estimated runtime | ~10–30s automated; UAT separate |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| IPC-01 | `IpcHandler` target `bar` with toggle/open/close in source | static | `rg -n 'target: "bar"|function toggle|function open|function close' .config/quickshell/modules/ii/bar/Bar.qml` | ✅ source |
| IPC-01 | Instance exposes IPC target `bar` | live smoke | `qs ipc show \| rg -A3 'target bar'` | ✅ runtime |
| IPC-01 | `close` / `open` / `toggle` exit 0 | live smoke | `qs ipc call bar close; qs ipc call bar open; qs ipc call bar toggle` | ✅ runtime (verified 2026-07-24) |
| IPC-01 | Socket exists for live instance | live smoke | `qs list` + socket under `$XDG_RUNTIME_DIR/quickshell/by-id/*/ipc.sock` | ✅ runtime |
| IPC-03 | Silent reload pragma present | static | `rg -n 'QS_NO_RELOAD_POPUP=1' .config/quickshell/shell.qml` | ✅ source |
| IPC-03 | Soft reload same PID + Configuration Loaded | live smoke | content-change probe on watched QML; compare PID; `rg 'Reloading configuration\|Configuration Loaded' $LOG` | ✅ runtime (verified) |
| IPC-03 | IPC still works after soft reload | live smoke | after reload: `qs ipc call bar open` exit 0 | ✅ runtime |
| IPC-03 | Bar modules usable after reload | manual UAT | Visual: workspaces/clock/resources update | ❌ Wave 0 UAT |
| IPC-03 | Tray usable after reload | manual UAT | Visual: tray icons present + clickable on QS bar | ❌ Wave 0 UAT |
| IPC-02 | Hyprland keybind | **deferred** | N/A this pass | N/A |
| FWK-02 | exec-once auto-start | **deferred** | N/A this pass | N/A |
| Milestone SC-5 | Waybar-parity module checklist | milestone gate | Optional checklist in UAT — not new code | manual |

### Sampling Rate

- **Per task commit:** static `rg` gates for IpcHandler + pragma (if any file touched)
- **Per wave merge:** full live IPC + soft-reload smoke
- **Phase gate:** automated green + human UAT for bar/tray post-reload before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `scripts/phase04-ipc-reload-assert.sh` (or `.py`) — optional but recommended:
  - Asserts `qs list` has an instance with config path containing `quickshell/shell.qml`
  - Asserts `qs ipc show` lists `bar` + `toggle`/`open`/`close`
  - Calls `open` (idempotent) exit 0
  - Optional: soft-reload probe with backup/restore of a single comment line + same-PID assert
- [ ] Static gates documented in VALIDATION.md (no new framework install)
- [ ] Human UAT script in `04-UAT.md` covering visual hide/show + post-reload tray
- [ ] Framework install: **none**

*(If planner chooses zero new scripts: static `rg` + documented manual commands still satisfy Nyquist with higher manual share.)*

### Prescriptive automated suite (recommended)

```bash
# Static
rg -n 'target: "bar"' .config/quickshell/modules/ii/bar/Bar.qml
rg -n 'function toggle\(\): void|function open\(\): void|function close\(\): void' \
  .config/quickshell/modules/ii/bar/Bar.qml
rg -n 'QS_NO_RELOAD_POPUP=1' .config/quickshell/shell.qml
rg -n 'property bool barOpen' .config/quickshell/GlobalStates.qml
# Do NOT require hyprland.conf changes this pass
rg -n 'exec-once.*quickshell|exec-once.*\bqs\b' .config/hypr/hyprland.conf  # expect empty

# Live (requires running shell)
qs list
qs ipc show | rg -A5 'target bar'
qs ipc call bar open
# Soft reload: content probe + restore (scripted carefully)
# Then:
qs ipc call bar open
pgrep -a quickshell   # still one long-lived process preferred
```

### Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bars hide on all monitors | IPC-01 / D-08 | Visual multi-monitor | `qs ipc call bar close`; confirm DP-1 + HDMI-A-2 |
| Bars show again | IPC-01 | Visual | `qs ipc call bar open` |
| Toggle flips | IPC-01 | Visual | `qs ipc call bar toggle` twice |
| No reload popup flash | IPC-03 / D-10 | Visual | Trigger soft reload; no top popup |
| Modules update post-reload | IPC-03 / D-11 | Visual timing | Clock ticks; CPU/RAM move |
| Tray interactive post-reload | IPC-03 / D-11 | Visual/input | Click tray icon menu on **Quickshell** bar |
| Failed reload recovery | D-12 | Destructive | Optional: introduce syntax error, confirm no auto-relaunch; fix + manual start |

---

## Security Domain

> `security_enforcement` enabled (default). Phase is local desktop IPC — low network exposure.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Local user session only; no remote auth |
| V3 Session Management | no | — |
| V4 Access Control | partial | Unix socket under `$XDG_RUNTIME_DIR` (user-private dir) [VERIFIED: path perms root `srwx` user-owned] |
| V5 Input Validation | yes | Stock `IpcHandler` typed args (string/int/bool/real/color only) [CITED: official docs]; bar handlers take no args |
| V6 Cryptography | no | No secrets in IPC surface |

### Known Threat Patterns for Quickshell IPC / desktop shell

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-user IPC call | Elevation of privilege | Socket in user runtime dir (0700 tree); do not move socket to `/tmp` |
| Unexpected IPC target abuse | Tampering | D-04: no new targets; only use stock `bar` this pass |
| Malicious QML on reload | Tampering | User-owned config tree; soft reload executes local QML — treat config as trusted code |
| Auto-relaunch daemon after crash | Availability / integrity | Explicitly **out of scope** (D-12) — avoids restart loops on bad QML |
| Command injection via `exec` keybinds | Injection | Deferred keybinds; when added prefer `global` shortcut over shell-interpolated `exec` |

---

## Deferred Backlog (for planner — do not implement)

| Item | Req | Notes for finishing pass |
|------|-----|--------------------------|
| Hyprland bar toggle keybind | IPC-02 | Prefer `bind = SUPER, J, global, quickshell:barToggle` (dots) **or** `exec, qs ipc call bar toggle`; chord undecided; SUPER+w still restarts Waybar |
| `exec-once` Quickshell | FWK-02 | Use `qs -d` or `qs &` (default config); coordinate with Waybar dual-run |
| Waybar removal / cutover | milestone | After parity SC-5 |
| Hard-restart keybind | — | dots `CTRL+SUPER+R` killall + relaunch — only if desired later |
| ReloadPopup enable | — | Debug aid if silent failures hurt |

---

## Sources

### Primary (HIGH confidence)

- Live host: `qs --version`, `qs list`, `qs ipc show`, `qs ipc call bar open|close`, soft-reload log experiment (2026-07-24) — [VERIFIED: runtime]
- Codebase: `Bar.qml`, `GlobalStates.qml`, `shell.qml`, `ReloadPopup.qml`, `TrayService.qml`, `SysTray.qml`, `hyprland.conf`, `arch/quickshell.sh` — [VERIFIED: read/grep]
- Official docs: [IpcHandler](https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/IpcHandler), [Quickshell singleton](https://quickshell.org/docs/v0.3.0/types/Quickshell/Quickshell), [Reloadable](https://quickshell.org/docs/v0.3.0/types/Quickshell/Reloadable) — [CITED: quickshell.org]
- qmltypes on system: `quickshell-core.qmltypes` reload/watchFiles methods — [VERIFIED: filesystem]
- CONTEXT.md locked decisions D-01..D-13 — user constraints

### Secondary (MEDIUM confidence)

- dots-hyprland `keybinds.lua` / `execs.lua` patterns for finishing touch — [VERIFIED: local clone paths]
- Quickshell 0.3 release notes (outfoxxed.me blog 2026-05-04) — product context only

### Tertiary (LOW confidence)

- WebSearch generic “qs reload” claims — **contradicted** by live CLI; discarded for stack facts
- A1 GlobalStates survival across reload — not proven; flagged assumed

---

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — live package + official docs + running instance
- Architecture: **HIGH** — full path traced in-repo + live IPC/reload
- Pitfalls: **HIGH** for CLI/config mistakes; **MEDIUM** for tray edge cases under dual hosts
- Deferred Hyprland wiring: **HIGH** as out-of-scope; low detail intentional

**Research date:** 2026-07-24  
**Valid until:** ~2026-08-24 (30 days; recheck if Quickshell upgrades past 0.3.0 and gains a reload CLI)

**Planner one-liner:** *Verify stock `qs ipc call bar {toggle,open,close}` + file-watch soft reload (same PID, silent, tray/bar usable); fix only if red; backlog FWK-02/IPC-02.*
