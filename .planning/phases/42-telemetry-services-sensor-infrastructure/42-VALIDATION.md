---
phase: "42"
slug: "telemetry-services-sensor-infrastructure"
status: draft
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-25"
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertion harness + QML syntax verification |
| **Config file** | `scripts/phase42-telemetry-services-assert.sh` (Wave 0 creates) |
| **Quick run command** | `bash scripts/phase42-telemetry-services-assert.sh --quick` |
| **Full suite command** | `bash scripts/phase42-telemetry-services-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase42-telemetry-services-assert.sh --quick`
- **After every plan wave:** Run `bash scripts/phase42-telemetry-services-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 42-00-01 | 00 | 0 | Harness | — | Validates harness structure and permissions | unit | `bash scripts/phase42-telemetry-services-assert.sh --help` | ❌ W0 | ⬜ pending |
| 42-01-01 | 01 | 1 | CPUGPU-01..04 | T-42-01 | Non-blocking sysfs parsing; unprivileged execution with zero RAPL root/udev dependencies | unit | `bash scripts/phase42-telemetry-services-assert.sh 2` | ❌ W0 | ⬜ pending |
| 42-01-02 | 01 | 1 | MEMDSK-01..04 | T-42-02 | Zero polling on idle; non-blocking `/proc/diskstats` and `df -k -P` execution | unit | `bash scripts/phase42-telemetry-services-assert.sh 3` | ❌ W0 | ⬜ pending |
| 42-02-01 | 02 | 2 | NETPING-01..05 | T-42-03 | Strict JSON schema parsing with safe fallback; offline backoff without error log spam | integration | `bash scripts/phase42-telemetry-services-assert.sh 4` | ❌ W0 | ⬜ pending |
| 42-02-02 | 02 | 2 | MEMDSK-01 | — | Parse `/proc/meminfo` memoryAvailable/Buffers/Cached accurately | unit | `bash scripts/phase42-telemetry-services-assert.sh 5` | ❌ W0 | ⬜ pending |
| 42-03-01 | 03 | 3 | Stow Integrity | — | Stow symlinks clean, zero broken links, verify passes | smoke | `bash scripts/phase42-telemetry-services-assert.sh 6` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase42-telemetry-services-assert.sh` — automated verification harness covering Sections 1–6
- [ ] Test harness permissions set (`chmod +x scripts/phase42-telemetry-services-assert.sh`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live physical drive mount insertion / unmount dynamic reactivity | MEMDSK-02 | Requires physical hardware insertion or unmount | Plug/unplug USB or remount external drive, verify `StorageUsage.qml` model updates |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending 2026-09-25
