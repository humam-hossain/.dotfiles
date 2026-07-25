---
phase: 4
slug: ipc-keybinds-integration
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-07-24
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `04-RESEARCH.md` ## Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual QML/runtime UAT + shell smoke + Python assert script (Phase 2/3 pattern) |
| **Config file** | none — no unit test framework for QML |
| **Quick run command** | `python3 scripts/phase04-ipc-reload-assert.py` |
| **Full suite command** | `python3 scripts/phase04-ipc-reload-assert.py` + human UAT (tray/bar hide-show / post-reload) |
| **Estimated runtime** | ~10–30s automated; UAT separate |

---

## Sampling Rate

- **After every task commit:** static `rg` gates for IpcHandler + `QS_NO_RELOAD_POPUP` (if any file touched)
- **After every plan wave:** full live IPC + soft-reload smoke via `python3 scripts/phase04-ipc-reload-assert.py`
- **Before `/gsd:verify-work`:** automated green + human UAT for bar/tray post-reload
- **Max feedback latency:** ~30 seconds for automated smoke/asserts

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 04-01 | 1 | Wave 0 | T-04-01 / T-04-04 | IPC/reload assert harness (static + live + soft-reload) | live smoke | `python3 scripts/phase04-ipc-reload-assert.py` | ✅ harness | ✅ green |
| 04-01-02 | 04-01 | 1 | Wave 0 | — | VALIDATION.md wired to concrete plan/task IDs | docs | `rg -n 'phase04-ipc-reload-assert\|wave_0_complete\|04-0[1-4]' 04-VALIDATION.md` | ✅ docs | ✅ green |
| 04-02-01 | 04-02 | 2 | IPC-01 | T-04-01 | Stock `bar` IPC only; no new targets | static | `rg -n 'target: "bar"' .config/quickshell/modules/ii/bar/Bar.qml` | ✅ source | ✅ green |
| 04-02-02 | 04-02 | 2 | IPC-01 | T-04-01 | `toggle`/`open`/`close` functions present | static | `rg -n 'function toggle\|function open\|function close' .config/quickshell/modules/ii/bar/Bar.qml` | ✅ source | ✅ green |
| 04-02-03 | 04-02 | 2 | IPC-01 | T-04-01 | Live instance exposes target `bar` | live smoke | `python3 scripts/phase04-ipc-reload-assert.py` (Section B) / `qs ipc show` | ✅ runtime | ✅ green |
| 04-02-04 | 04-02 | 2 | IPC-01 | T-04-01 | `open`/`close`/`toggle` exit 0 + multi-monitor UAT | live smoke + manual | `qs ipc call bar close; qs ipc call bar open; qs ipc call bar toggle` | ✅ runtime | ✅ green |
| 04-03-01 | 04-03 | 3 | IPC-03 | T-04-02 | Silent reload pragma retained | static | `rg -n 'QS_NO_RELOAD_POPUP=1' .config/quickshell/shell.qml` | ✅ source | ✅ green |
| 04-03-02 | 04-03 | 3 | IPC-03 | T-04-04 | Soft reload same PID + post-reload IPC | live smoke | `python3 scripts/phase04-ipc-reload-assert.py` (Section C) | ✅ runtime | ✅ green |
| 04-03-03 | 04-03 | 3 | IPC-03 | — | IPC works after soft reload | live smoke | after reload: `qs ipc call bar open` exit 0 | ✅ runtime | ✅ green |
| 04-UAT-01 | UAT | — | IPC-03 / D-11 | — | Bar modules usable post-reload | manual | Visual: workspaces/clock/resources update | ❌ | ⬜ pending |
| 04-UAT-02 | UAT | — | IPC-03 / D-11 | — | Tray usable post-reload on QS bar | manual | Visual: tray icons present + clickable | ❌ | ⬜ pending |
| 04-04-01 | 04-04 | 2 | IPC-02 / FWK-02 | — | Deferred packaging — no product tests this pass | N/A | N/A | N/A | ⏭ deferred |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · ⏭ deferred*

*Task IDs mapped to concrete plans: 04-01 Wave 0 harness, 04-02 IPC-01 live+UAT, 04-03 IPC-03 soft-reload+tray UAT, 04-04 deferred FWK-02/IPC-02.*

---

## Wave 0 Requirements

- [x] `scripts/phase04-ipc-reload-assert.py` — Wave 0 harness (shipped by 04-01-01):
  - Asserts `qs list` has an instance with config path containing `quickshell/shell.qml`
  - Asserts `qs ipc show` lists `bar` + `toggle`/`open`/`close`
  - Calls `open` (idempotent) exit 0
  - Soft-reload probe with content-change + try/finally restore + same-PID assert + post-reload `bar open`
  - Command: `python3 scripts/phase04-ipc-reload-assert.py` (success line: `ipc/reload asserts OK`)
- [x] Static gates documented below (no new framework install)
- [x] Human UAT checklist covering visual hide/show + post-reload tray (`04-UAT.md` — IPC-01 rows pending human; IPC-03 section pending 04-03)
- [x] Framework install: **none**

### Prescriptive automated suite

```bash
# Preferred single entrypoint (static + live + soft-reload)
python3 scripts/phase04-ipc-reload-assert.py

# Static (also encoded in the script)
rg -n 'target: "bar"' .config/quickshell/modules/ii/bar/Bar.qml
rg -n 'function toggle\(\): void|function open\(\): void|function close\(\): void' \
  .config/quickshell/modules/ii/bar/Bar.qml
rg -n 'QS_NO_RELOAD_POPUP=1' .config/quickshell/shell.qml
rg -n 'property bool barOpen' .config/quickshell/GlobalStates.qml
# Do NOT require hyprland.conf changes this pass
rg -n 'exec-once.*quickshell|exec-once.*\bqs\b' .config/hypr/hyprland.conf  # expect empty / no new QS exec-once

# Live (requires running shell; also encoded in the script)
qs list
qs ipc show | rg -A5 'target bar'
qs ipc call bar open
# Soft reload: content probe + restore (scripted carefully in phase04-ipc-reload-assert.py)
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
