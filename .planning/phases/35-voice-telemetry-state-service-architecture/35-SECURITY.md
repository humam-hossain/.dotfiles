---
phase: "35"
slug: "voice-telemetry-state-service-architecture"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-09-21"
---

# Phase 35 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| External processes → `$XDG_RUNTIME_DIR/voice-stt/` | Untrusted or corrupt runtime state files written to local user tmpfs | PID and state strings |
| Linux OS Kernel → Procfs (`/proc/<pid>/`) | Virtual filesystem process state and command line buffers | Command line tokens, process status, uptime |
| Quickshell Engine → execDetached Subprocess | Subprocess execution for stale PID cleanup | Arguments `["rm", "-f", path]` |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-35-01 | Tampering / DoS | Voice.qml (FileView recorder.pid / tts.pid) | medium | mitigate | Sanitize parsed PID with `parseInt(parts[0])`, enforce `pid > 0`, and reject non-numeric strings with fail-soft fallback to `idle` state. | closed |
| T-35-02 | Tampering | Voice.qml (Process Liveness) | medium | mitigate | Verify `/proc/<pid>/cmdline` contains `"voice"` or `"voicemode"` before trusting process liveness; never rely on bare PID existence to prevent PID recycling hijacking. | closed |
| T-35-03 | Elevation of Privilege | Voice.qml (Quickshell.execDetached) | high | mitigate | Strictly pass command arguments as array literals `["rm", "-f", path]`; never invoke `bash -c` or pass concatenated shell strings. | closed |
| T-35-04 | Denial of Service | Voice.qml (Polling Loop) | medium | mitigate | Use native C++ `Quickshell.Io.FileView` with `blockLoading: true` and `printErrors: false` over Linux RAM tmpfs; dynamic QML Timer throttles to 500ms on idle without child process forks. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-21 | 4 | 4 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-21
