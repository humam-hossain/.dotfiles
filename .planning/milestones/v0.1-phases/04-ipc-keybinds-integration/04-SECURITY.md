---
phase: 04
slug: ipc-keybinds-integration
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-25
verified: 2026-07-25
register_authored_at_plan_time: true
---

# Phase 04 — Security

> Per-phase security contract from plan threat models (04-01..04-04). ASVS L1.
> This pass is verify/UAT of stock IPC + soft reload — no new IPC targets, no Hyprland product edits.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| External CLI → QS IPC socket | Local user session processes may call stock `qs ipc` if they can reach `$XDG_RUNTIME_DIR` | `bar` open/close/toggle (no args) |
| Assert script → filesystem | Wave 0 harness reads QML and briefly probes `shell.qml` with try/finally restore | Probe comment line only |
| Watched QML → soft reload | User-owned config executes as shell on content change | Trusted user QML tree |
| Post-reload SNI / tray | StatusNotifier rebind in user session | Tray icons |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-04-01 | Tampering | Unexpected IPC target abuse | high | mitigate | Stock target `bar` only (D-04); assert + no new handlers | closed |
| T-04-02 | Elevation of privilege | Cross-user IPC | medium | mitigate | Socket remains under `$XDG_RUNTIME_DIR`; no `/tmp` socket | closed |
| T-04-03 | Availability | Auto-relaunch after crash/failed reload | medium | mitigate | D-12 manual only; no daemon; deferred hard-restart keybind | closed |
| T-04-04 | Tampering | Soft-reload probe leaves dirty shell.qml | medium | mitigate | try/finally restore in phase04 assert | closed |
| T-04-05 | Information disclosure | IPC surface enumeration | low | accept | `qs ipc show` local-user only; bar handlers take no args | closed |
| T-04-06 | Tampering | Malicious QML on reload | medium | accept | Config is trusted user code; no remote QML load | closed |
| T-04-SC | Tampering | npm/pip/cargo installs | high | accept | No package installs this phase | closed |

*Severity: critical > high > medium > low*  
*Disposition: mitigate · accept · transfer*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-04-01 | T-04-05 | Local IPC enumeration is expected for desktop shells | phase 04 plans | 2026-07-25 |
| AR-04-02 | T-04-06 | User-owned QML is the product surface | phase 04 research | 2026-07-25 |
| AR-04-03 | T-04-SC | No third-party installs in verify-only pass | phase 04 plans | 2026-07-25 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-25 | 7 | 7 | 0 | orchestrator-inline (plan STRIDE + execute evidence) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter
- [x] No new IPC targets or Hyprland product edits introduced this pass

**Approval:** verified 2026-07-25
