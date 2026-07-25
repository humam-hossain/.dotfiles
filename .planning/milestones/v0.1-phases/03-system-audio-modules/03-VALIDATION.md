---
phase: 3
slug: system-audio-modules
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-23
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `03-RESEARCH.md` ## Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual QML validation (quickshell runtime) + shell smoke + Python config asserts (Phase 2 pattern) |
| **Config file** | none — no unit test framework for QML |
| **Quick run command** | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded\|Error'` |
| **Full suite command** | smoke + `python3 scripts/phase03-config-assert.py` + static `rg` gates + human UAT |
| **Estimated runtime** | ~10–30s automated; UAT separate |

---

## Sampling Rate

- **After every task commit:** Run `timeout 4 quickshell 2>&1 | rg 'Configuration Loaded|Error'`
- **After every plan wave:** Run smoke + `python3 scripts/phase03-config-assert.py` + static gates for that wave
- **Before `/gsd:verify-work`:** Full suite must be green + UAT BAR-05..08
- **Max feedback latency:** ~30 seconds automated

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 0 | BAR-05..08 | T-03-01 | Dual-write thresholds trusted defaults | config assert | `python3 scripts/phase03-config-assert.py` | ✅ script | ✅ green |
| 03-01-02 | 01 | 0 | BAR-05..08 | T-03-01 | VALIDATION Wave 0 task map wired | docs | `rg -n 'phase03-config-assert\|wave_0_complete' .planning/phases/03-system-audio-modules/03-VALIDATION.md` | ✅ docs | ✅ green |
| 03-02-* | 02 | 1 | BAR-05..08 | T-03-01/T-03-04 | Dual-write Config.qml + live JSON | config assert | `python3 scripts/phase03-config-assert.py` | ✅ dual-write | ✅ green |
| 03-03-* | 03 | 2 | BAR-05 | — | Resource.qml dual thresholds / labels | static + smoke | `rg -n 'errorThreshold\|labelText' .config/quickshell/modules/ii/bar/Resource.qml` | ✅ source | ✅ green |
| 03-04-* | 04 | 2 | BAR-08 | T-03-04 | Audio 130% + auto-unmute + clamp paths | static | `rg -n 'maxVolume\|muted = false' .config/quickshell/services/Audio.qml` | ✅ source | ✅ green |
| 03-05-* | 05 | 2 | BAR-07 | T-03-03 | ResourceUsage multi-rate + disk; df ~10s | static | `rg -n 'diskUsedPercentage\|df \|diskUpdateInterval' .config/quickshell/services/ResourceUsage.qml` | ✅ source | ✅ green |
| 03-06-* | 06 | 3 | BAR-05..07 | T-03-05 | Resources.qml strip CPU→RAM→Disk; no swap/popup | static | `rg -n 'cpuUsage\|swap_horiz\|ResourcesPopup' .config/quickshell/modules/ii/bar/Resources.qml` | ✅ source | ✅ green |
| 03-07-* | 07 | 3 | BAR-08 | T-03-02 | BarContent mute/mic % + volumeMixer from Config | static | `rg -n 'volumeMixer\|toggleMute\|incrementVolume' .config/quickshell/modules/ii/bar/BarContent.qml` | ✅ source | ✅ green |
| 03-08-* | 08 | 4 | BAR-05..08 | — | Static gates + nyquist sign-off | static + assert | full suite + set `nyquist_compliant: true` | ✅ after 03-08 | ✅ green |
| smoke | all | all | — | — | N/A | smoke | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded'` | ✅ runtime | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs map to plans 03-01..03-08. Automated suite re-verified green at plan 03-08 (2026-07-23).*

---

## Wave 0 Requirements

- [x] `scripts/phase03-config-assert.py` — command: `python3 scripts/phase03-config-assert.py` — asserts dual-written keys:
  - `bar.resources.cpuWarningThreshold == 40`
  - `bar.resources.cpuErrorThreshold == 80`
  - `bar.resources.memoryWarningThreshold == 75`
  - `bar.resources.memoryErrorThreshold == 95`
  - `bar.resources.diskWarningThreshold == 80`
  - `bar.resources.diskErrorThreshold == 95`
  - `bar.resources.alwaysShowCpu is True`
  - `bar.resources.alwaysShowSwap is False`
  - `resources.updateInterval == 1000` / `memoryUpdateInterval == 3000` / `diskUpdateInterval == 10000` (D-08/D-14)
  - `audio.protection.maxAllowed >= 130`
- [x] Static gate snippets for: Resources order (CPU→RAM→Disk), no swap UI, no ResourcesPopup attach, Audio maxVolume ≥ 1.30, mute % visibility, volumeMixer click
- [x] Framework install: **none** — reuse Phase 1/2 smoke pattern

### Automated full suite (Wave 0 / plan 03-08)

```bash
python3 scripts/phase03-config-assert.py
rg -n 'swap_horiz|ResourcesPopup' .config/quickshell/modules/ii/bar/Resources.qml   # empty
rg -n 'errorThreshold|labelText' .config/quickshell/modules/ii/bar/Resource.qml
rg -n 'diskUsedPercentage|df ' .config/quickshell/services/ResourceUsage.qml
rg -n 'maxVolume|muted = false' .config/quickshell/services/Audio.qml
rg -n 'volumeMixer|toggleMute|incrementVolume' .config/quickshell/modules/ii/bar/BarContent.qml
rg -n 'XF86AudioRaiseVolume' .config/hypr/hyprland.conf   # -l 1.3
timeout 4 quickshell 2>&1 | rg 'Configuration Loaded|Error'
```

After plans 03-02..03-07 product work: prints `config asserts OK`, static markers present, smoke reaches `Configuration Loaded`. Re-verified green at plan 03-08 (2026-07-23).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CPU % updates live | BAR-05 | Visual timing | Stress CPU (`yes > /dev/null`); ring/label move within ~1–2s |
| RAM GB label sensible | BAR-06 | Visual + units | Compare to `free -h` roughly; no % on label |
| Disk free/total for `/` | BAR-07 | Visual | Compare to `df -h /`; ring tracks used% |
| Scroll right bar changes volume | BAR-08 | Input | Wheel over right region; OSD + % update |
| Click mute toggles; % hides when muted | BAR-08 | UI | Left-click mute icon; icon → volume_off; % gone |
| Volume while muted auto-unmutes | BAR-08 | UI + keyboard | Mute; scroll or keyboard volume; icon unmutes |
| Volume can reach ~130% | BAR-08 | UI | Scroll up past 100%; label/OSD ~130 |
| Middle/right opens pavucontrol | BAR-08 | Process | Middle/right on mute or mic; mixer window |
| No resource hover popup | D-09 | UI | Hover CPU/RAM/Disk; no popup |
| Mic % tracks input gain | BAR-08 | UI | Change source volume in pavucontrol; mic % updates |

---

## Threat Model References (from RESEARCH Security Domain)

| ID | Pattern | STRIDE | Mitigation |
|----|---------|--------|------------|
| T-03-01 | Malicious live config thresholds / volumeMixer string | Tampering | Dual-write from known defaults; assert script |
| T-03-02 | Shell injection via crafted volumeMixer | Injection | Existing Config path; no untrusted bar text into shell; argv for new Process |
| T-03-03 | Process spam (df every 1s) | DoS | Disk interval ~10s (D-14) |
| T-03-04 | Accidental volume blast to 200%+ | Tampering | Clamp to 1.30 user max + hardMaxValue 2.00 safety |
| T-03-05 | Sensitive path disclosure in disk tooltips | Info disclosure | No disk tooltip Phase 3 (D-16) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Automated approval:** 2026-07-23 (plan 03-08) — config assert green, static resource/audio/prohibition gates green, `Configuration Loaded` smoke green. Manual-Only table remains for human UAT via `/gsd-verify-work`.

**Approval:** pending human UAT
