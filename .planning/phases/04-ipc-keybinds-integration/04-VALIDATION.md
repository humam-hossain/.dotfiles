---
phase: 4
slug: ipc-keybinds-integration
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-24
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `04-RESEARCH.md` ## Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual QML/runtime UAT + shell smoke + optional bash/Python assert script (Phase 2/3 pattern) |
| **Config file** | none — no unit test framework for QML |
| **Quick run command** | `qs list && qs ipc show \| rg 'target bar' && qs ipc call bar open` |
| **Full suite command** | static `rg` gates + live IPC sequence + soft-reload log gate + human UAT (tray/bar) |
| **Estimated runtime** | ~10–30s automated; UAT separate |

---

## Sampling Rate

- **After every task commit:** static `rg` gates for IpcHandler + `QS_NO_RELOAD_POPUP` (if any file touched)
- **After every plan wave:** full live IPC + soft-reload smoke
- **Before `/gsd:verify-work`:** automated green + human UAT for bar/tray post-reload
- **Max feedback latency:** ~30 seconds for automated smoke/asserts

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-W0-01 | 04-01 | 0 | Wave 0 | — | IPC/reload assert harness | live smoke | `bash scripts/phase04-ipc-reload-assert.sh` (or equivalent) | ❌ W0 | ⬜ pending |
| 04-IPC-01 | 04-0x | 1 | IPC-01 | T-04-01 | Stock `bar` IPC only; no new targets | static | `rg -n 'target: "bar"' .config/quickshell/modules/ii/bar/Bar.qml` | ✅ source | ⬜ pending |
| 04-IPC-02 | 04-0x | 1 | IPC-01 | T-04-01 | `toggle`/`open`/`close` functions present | static | `rg -n 'function toggle\|function open\|function close' .config/quickshell/modules/ii/bar/Bar.qml` | ✅ source | ⬜ pending |
| 04-IPC-03 | 04-0x | 1 | IPC-01 | T-04-01 | Live instance exposes target `bar` | live smoke | `qs ipc show \| rg -A5 'target bar'` | ✅ runtime | ⬜ pending |
| 04-IPC-04 | 04-0x | 1 | IPC-01 | T-04-01 | `open`/`close`/`toggle` exit 0 | live smoke | `qs ipc call bar close; qs ipc call bar open; qs ipc call bar toggle` | ✅ runtime | ⬜ pending |
| 04-RLD-01 | 04-0x | 1 | IPC-03 | T-04-02 | Silent reload pragma retained | static | `rg -n 'QS_NO_RELOAD_POPUP=1' .config/quickshell/shell.qml` | ✅ source | ⬜ pending |
| 04-RLD-02 | 04-0x | 1 | IPC-03 | — | Soft reload same PID + Configuration Loaded | live smoke | content-change probe; PID compare; log `Configuration Loaded` | ✅ runtime | ⬜ pending |
| 04-RLD-03 | 04-0x | 1 | IPC-03 | — | IPC works after soft reload | live smoke | after reload: `qs ipc call bar open` exit 0 | ✅ runtime | ⬜ pending |
| 04-UAT-01 | UAT | — | IPC-03 / D-11 | — | Bar modules usable post-reload | manual | Visual: workspaces/clock/resources update | ❌ | ⬜ pending |
| 04-UAT-02 | UAT | — | IPC-03 / D-11 | — | Tray usable post-reload on QS bar | manual | Visual: tray icons present + clickable | ❌ | ⬜ pending |
| 04-DEF | — | — | IPC-02 / FWK-02 | — | Deferred — no tests this pass | N/A | N/A | N/A | ⏭ deferred |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · ⏭ deferred*

*Task IDs will be remapped to concrete plan IDs by the planner.*

---

## Wave 0 Requirements

- [ ] `scripts/phase04-ipc-reload-assert.sh` (or `.py`) — recommended:
  - Asserts `qs list` has an instance with config path containing `quickshell/shell.qml`
  - Asserts `qs ipc show` lists `bar` + `toggle`/`open`/`close`
  - Calls `open` (idempotent) exit 0
  - Optional: soft-reload probe with backup/restore of a single comment line + same-PID assert
- [ ] Static gates documented below (no new framework install)
- [ ] Human UAT checklist covering visual hide/show + post-reload tray (`04-UAT.md` during verify)
- [ ] Framework install: **none**

*If planner chooses zero new scripts: static `rg` + documented manual commands still satisfy Nyquist with higher manual share.*

### Prescriptive automated suite

```bash
# Static
rg -n 'target: "bar"' .config/quickshell/modules/ii/bar/Bar.qml
rg -n 'function toggle\(\): void|function open\(\): void|function close\(\): void' \
  .config/quickshell/modules/ii/bar/Bar.qml
rg -n 'QS_NO_RELOAD_POPUP=1' .config/quickshell/shell.qml
rg -n 'property bool barOpen' .config/quickshell/GlobalStates.qml
# Do NOT require hyprland.conf changes this pass
rg -n 'exec-once.*quickshell|exec-once.*\bqs\b' .config/hypr/hyprland.conf  # expect empty / no new QS exec-once

# Live (requires running shell)
qs list
qs ipc show | rg -A5 'target bar'
qs ipc call bar open
# Soft reload: content probe + restore (scripted carefully)
# Then:
qs ipc call bar open
pgrep -a quickshell   # still one long-lived process preferred
```

---

## Manual-Only Verifications

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

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (automated)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
