---
phase: 2
slug: core-bar-modules
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-07-21
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `02-RESEARCH.md` ## Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual QML validation (quickshell runtime) + shell smoke (same as Phase 1) |
| **Config file** | none — no unit test framework for QML |
| **Quick run command** | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded\|Error\|WARN.*hl\\.dsp'` |
| **Full suite command** | smoke launch + `python3 scripts/phase02-config-assert.py` + `hyprctl layers` + human UAT |
| **Estimated runtime** | ~10–30 seconds (smoke + config asserts); UAT separate |

---

## Sampling Rate

- **After every task commit:** Run `timeout 4 quickshell 2>&1 | rg 'Configuration Loaded|Error|hl\.dsp'`
- **After every plan wave:** Run smoke + `python3 scripts/phase02-config-assert.py`
- **Before `/gsd:verify-work`:** Full smoke green + UAT checklist for BAR-01..04
- **Max feedback latency:** ~30 seconds for automated smoke/asserts

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 02-01 | 0 | Wave 0 | — | Live config assert harness | config assert | `python3 scripts/phase02-config-assert.py` | ✅ script | ⬜ red until 02-02 |
| 02-01-02 | 02-01 | 0 | Wave 0 | — | VALIDATION wiring | static | `rg -n phase02-config-assert 02-VALIDATION.md` | ✅ | ✅ green |
| 02-02-01 / 02-02-02 | 02-02 | 2 | BAR-01 / BAR-02 / BAR-03 | T-02-03 | Dual-write time/tray/workspaces/weather keys | config assert | `python3 scripts/phase02-config-assert.py` | ✅ after 02-02 | ⬜ pending |
| 02-03-01 / 02-03-02 | 02-03 | 3 | BAR-01 / BAR-02 | — | Left/center D-15; showDate false; ClockWidgetPopup only | static + smoke | `rg -n 'showDate|ClockWidgetPopup|Workspaces' BarContent.qml` | ✅ after implement | ⬜ pending |
| 02-04-01 / 02-04-02 | 02-04 | 4 | BAR-03 / BAR-04 | T-02-01 | Right LTR + D-19 indicators; Network.materialSymbol only | static + smoke | `rg -n 'Network.materialSymbol\|SysTray\|volume_off' BarContent.qml` | ✅ after implement | ⬜ pending |
| 02-05-01 | 02-05 | 5 | BAR-01..04 | T-02-01 / T-02-11 | Stock workspace dispatch; no plugin hl.dsp; layout markers | static | `rg -n 'workspace \$\{|workspace r' Workspaces.qml` | ✅ source | ⬜ pending |
| 02-05-02 | 02-05 | 5 | Smoke | T-02-04 | Configuration Loaded; valid JSON config | smoke + assert | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded'`; `python3 scripts/phase02-config-assert.py` | ✅ Phase 1 pattern | ⬜ pending |
| 02-03/04 UAT | layout | — | D-15/D-19 | — | L→R module + indicators order | static + UAT | child order + visual checklist | ✅ after implement | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs map to plans 02-01..02-05.*

---

## Wave 0 Requirements

- [x] Plan-inline or `scripts/` **live config assert** — `python3 scripts/phase02-config-assert.py` (keys: workspaces shown/showAppIcons/monochromeIcons, weather.enable, time.format/secondPrecision, tray.monochromeIcons/invertPinnedItems/pinnedItems)
- [ ] Phase 2 UAT checklist (during verify/UAT, not blocking plan) covering D-15 order, clock string, tray color, network icon + sidebar SSID
- [x] Framework install: **none** — reuse Phase 1 smoke pattern

### Automated config assert (Wave 0 / per-wave)

```bash
python3 scripts/phase02-config-assert.py
```

Expected until plan 02-02 dual-write: non-zero exit (red). After 02-02: prints `config asserts OK` and exits 0.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Click workspace switches focus | BAR-01 | Requires live Hyprland session | Click workspace N; confirm active workspace changes |
| Wheel cycles workspaces | BAR-01 | Input event | Scroll on workspaces strip; confirm `workspace r±1` |
| Clock updates each second | BAR-02 | Visual timing | Watch bar clock tick seconds |
| Clock click opens ClockWidgetPopup | BAR-02 | UI interaction | Click clock; popup shows date/uptime/todos — not Google Calendar |
| Tray icons full-color + interactive | BAR-03 | Visual + SNI | Confirm Discord/Steam/etc color; left-click activate; right-click menu |
| Network icon state + SSID via sidebar | BAR-04 | NM state + UI | Toggle wifi; icon glyph changes; open right sidebar for SSID/signal |
| Module L→R order | D-15 | Visual layout | Left: sidebar→window→workspaces→resources; Center: clock→utils; Right: media→battery→tray→indicators |
| Indicators pill order | D-19 | Visual layout | mute → mic → xkb → Bluetooth → Network → notif |
| Dual-monitor workspaces 1–10 | BAR-01 | Optional if HDMI attached | DP-1: 1–5, HDMI-A-2: 6–10 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (automated)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
