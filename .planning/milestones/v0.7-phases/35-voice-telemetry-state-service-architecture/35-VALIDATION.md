---
phase: "35"
slug: "voice-telemetry-state-service-architecture"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-21"
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash assertion harness (`scripts/phase35-voice-telemetry-assert.sh`) + Headless Quickshell execution (`quickshell -p`) |
| **Config file** | `scripts/phase35-voice-telemetry-assert.sh` |
| **Quick run command** | `./scripts/phase35-voice-telemetry-assert.sh --section 1` |
| **Full suite command** | `./scripts/phase35-voice-telemetry-assert.sh` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase35-voice-telemetry-assert.sh --section 1`
- **After every plan wave:** Run `./scripts/phase35-voice-telemetry-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0 FINDINGS=0`)
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | TELEM-01, TELEM-02 | T-35-01, T-35-04 | Read tmpfs state files asynchronously, evaluate lifecycle states, and enforce typing linger | Integration (Headless QML) | `./scripts/phase35-voice-telemetry-assert.sh --section 1 && ./scripts/phase35-voice-telemetry-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 35-01-02 | 01 | 1 | TELEM-03 | T-35-02, T-35-03 | Verify /proc/<pid>/cmdline, purge stale/recycled locks via execDetached, and log warning | Integration (Headless QML) | `./scripts/phase35-voice-telemetry-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 35-01-03 | 01 | 1 | TELEM-04, TELEM-05 | — | Drift-free duration anchored to procfs start time, freeze on transcribe/type, and parse TTS metadata | Integration (Headless QML) | `./scripts/phase35-voice-telemetry-assert.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase35-voice-telemetry-assert.sh` — automated 6-section assertion test harness for TELEM-01 through TELEM-05
- [ ] `restow/quickshell/.config/quickshell/ii/services/Voice.qml` — Singleton service component stub

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Quickshell reload duration recovery | TELEM-04 | Requires live Hyprland GUI reload (`Ctrl+Super+R`) during active recording | Trigger STT recording, press `Ctrl+Super+R`, observe that elapsed counter maintains continuous duration |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending 2026-09-21
