---
phase: 1
slug: shell-foundation-theme
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-21
validated: 2026-07-21
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Closed out after UAT pass + verification status=passed (2026-07-21).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual QML validation (quickshell runtime) + shell smoke |
| **Config file** | none — no formal unit test framework for QML |
| **Quick run command** | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded\|Error'` |
| **Full suite command** | smoke launch + `hyprctl layers` + human UAT (`01-UAT.md`) |
| **Estimated runtime** | ~5–30 seconds automated; human UAT separate |

---

## Sampling Rate

- **After every task commit:** Run quickshell smoke (Configuration Loaded)
- **After every plan wave:** Smoke + layer check when session available
- **Before `/gsd-verify-work`:** Full smoke green
- **Max feedback latency:** 5 seconds for smoke

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01-01 | 1 | FWK-01, FWK-03, FWK-04 | — | N/A | other | `test -f .config/quickshell/shell.qml` | ✅ | ✅ green |
| 01-02-01 | 01-02 | 2 | THM-01, THM-02 | — | N/A | other | `test -f ~/.local/state/quickshell/user/generated/colors.json` | ✅ | ✅ green |
| 01-03-01 | 01-03 | 3 | FWK-05 | — | N/A | other | `timeout 4 quickshell → Configuration Loaded` | ✅ | ✅ green |
| 01-04-01 | 01-04 | 4 | FWK-01, THM-02 | T-01-* | N/A | other | smoke: no m3primaryDim/forceMonitor/hl.dsp warnings | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Verify `quickshell` binary is installed and accessible (0.3.0 Arch)
- [x] Verify `../dots-hyprland/dots/.config/quickshell/ii/` source exists
- [x] Theme pipeline produced `colors.json` (63 keys); system `python-materialyoucolor` may need reinstall for re-runs
- [x] Verify `~/.config/quickshell` symlink → repo `.config/quickshell`

*Wave 0 complete.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Result |
|----------|-------------|------------|--------|
| Bar usable (icons, layout, workspace click) | FWK-01 | Live session eyes | ✅ UAT Test 1 pass (retest after 01-04) |
| Material colors applied | THM-01 | Visual palette | ✅ UAT Test 2 pass |
| Multi-monitor HDMI-A-2 | FWK-01 | Hardware attach | Optional when HDMI connected |

---

## Validation Sign-Off

- [x] All executed plans have smoke or artifact verify
- [x] Sampling continuity: each plan SUMMARY includes verification evidence
- [x] Wave 0 covered
- [x] No watch-mode flags
- [x] Feedback latency < 5s for smoke
- [x] `nyquist_compliant: true` set in frontmatter
- [x] Human UAT complete (`01-UAT.md` status: complete, 2/2 pass)

**Approval:** validated 2026-07-21
