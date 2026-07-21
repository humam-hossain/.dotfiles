---
phase: 2
slug: core-bar-modules
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Full suite command** | smoke launch + live config key asserts + `hyprctl layers` + human UAT |
| **Estimated runtime** | ~10–30 seconds (smoke + config asserts); UAT separate |

---

## Sampling Rate

- **After every task commit:** Run `timeout 4 quickshell 2>&1 | rg 'Configuration Loaded|Error|hl\.dsp'`
- **After every plan wave:** Run smoke + python live-config asserts for `time.*` / `tray.monochromeIcons` / `bar.workspaces` / `bar.weather.enable`
- **Before `/gsd:verify-work`:** Full smoke green + UAT checklist for BAR-01..04
- **Max feedback latency:** ~30 seconds for automated smoke/asserts

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | 01+ | 0–N | BAR-01 | T-02-01 / — | No new Process injection | smoke + static | `rg -n 'workspace \$\{|workspace r' .config/quickshell/modules/ii/bar/Workspaces.qml` | ✅ source | ⬜ pending |
| TBD | 01+ | 0–N | BAR-01 | — | Config keys shown/showAppIcons/monochrome | config assert | python live `bar.workspaces` dump | ❌ Wave 0 | ⬜ pending |
| TBD | 01+ | 0–N | BAR-02 | — | format has ss + AP; secondPrecision | config assert | python live `time.*` | ❌ Wave 0 | ⬜ pending |
| TBD | 01+ | 0–N | BAR-02 | — | showDate false; ClockWidgetPopup only | static | `rg -n 'showDate|ClockWidgetPopup|calendar.google' BarContent/ClockWidget` | ✅ after implement | ⬜ pending |
| TBD | 01+ | 0–N | BAR-03 | — | monochromeIcons false; pin policy | config assert | python live `tray.*` | ❌ Wave 0 | ⬜ pending |
| TBD | 01+ | 0–N | BAR-04 | T-02-01 | Network.materialSymbol only; no bash -c SSID | static + manual | `rg -n 'Network.materialSymbol' BarContent.qml` | ✅ | ⬜ pending |
| TBD | layout | — | D-15/D-19 | — | L→R module + indicators order | static + UAT | child order + visual checklist | ✅ after implement | ⬜ pending |
| TBD | smoke | — | Smoke | T-02-04 | Configuration Loaded; valid JSON config | smoke | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded'` | ✅ Phase 1 pattern | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs refined by planner when PLAN.md files are written.*

---

## Wave 0 Requirements

- [ ] Plan-inline or `scripts/` **live config assert** snippet (python dump of `~/.config/illogical-impulse/config.json` keys: workspaces shown/showAppIcons/monochromeIcons, weather.enable, time.format/secondPrecision, tray.monochromeIcons/invertPinnedItems/pinnedItems)
- [ ] Phase 2 UAT checklist (during verify/UAT, not blocking plan) covering D-15 order, clock string, tray color, network icon + sidebar SSID
- [ ] Framework install: **none** — reuse Phase 1 smoke pattern

### Suggested automated config assert (Wave 0 / per-wave)

```bash
python3 - <<'PY'
import json
from pathlib import Path
c = json.loads(Path.home().joinpath(".config/illogical-impulse/config.json").read_text())
assert c["bar"]["workspaces"]["shown"] == 10
assert c["bar"]["workspaces"]["showAppIcons"] is True
assert c["bar"]["workspaces"]["monochromeIcons"] is True
assert c["bar"]["weather"]["enable"] is False
assert c["time"]["secondPrecision"] is True
assert "ss" in c["time"]["format"] and ("AP" in c["time"]["format"] or "ap" in c["time"]["format"])
assert c["tray"]["monochromeIcons"] is False
assert c["tray"]["invertPinnedItems"] is True
assert "Fcitx" in c["tray"]["pinnedItems"]
print("config asserts OK")
PY
```

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
