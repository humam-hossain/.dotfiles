---
phase: "51"
slug: "wwo-fetcher-service-local-cache-architecture"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-03"
updated: "2026-10-03"
---

# Phase 51 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| External Network → Python Fetcher | WorldWeatherOnline HTTPS REST API (`weather.ashx`) telemetry ingestion | API credentials (outbound query param), JSON forecast payload (inbound) |
| Local Filesystem → Credential Storage | Unprivileged user environment reading `~/.config/weather/.env` | `WWO_API_KEY` plaintext secret (mode 0600) |
| Fetcher Service → Shared Tmpfs Cache | Atomic write to `$XDG_RUNTIME_DIR/weather/weather.json` | Quickshell UI consumer JSON envelope stream |
| Fetcher Service → Persistent State | State tracking at `~/.local/state/weather/{quota,last_known_weather}.json` | Daily quota counters, persistent backup cache |
| Systemd User Manager → User Process | Timed execution of `wwo-fetcher.service` | Unprivileged user process lifecycle, systemd journal logs |
| GNU Stow Symlink Farm → Home Directory | Deployment of `stow/weather` package to `$HOME` | Discrete configuration leaf symlinks |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-51-01 | Information Disclosure | Credential Management (`.config/weather/.env`) | critical | mitigate | Explicitly gitignored `.config/weather/.env` and `stow/weather/.config/weather/.env`. Only `.env.example` template tracked in repository. Tested in Section 1. | closed |
| T-51-02 | Privilege Escalation | Process Execution Boundaries (Root Safety) | high | block | Test harness enforces EUID != 0 fail-closed; systemd user manager executes fetcher as unprivileged user. Tested in Section 1. | closed |
| T-51-03 | Denial of Service | Quota Management (`wwo-fetcher.py`) | high | mitigate | Dynamic budget pacing $(M_{\text{remaining}} / \max(1, 470 - \text{calls})) \ge 3.0$ min with UTC midnight rollover and 500-call absolute ceiling protects against WWO 429 quota exhaustion. Tested in Section 3. | closed |
| T-51-04 | Data Integrity | Cache Inode Replacement (`weather.json`) | high | mitigate | Atomic temporary file replacement via `os.replace` within same tmpfs directory (`weather.json.tmp.<pid>`), flushed and fsynced. Tested in Section 4. | closed |
| T-51-05 | Availability | UI Cold Boot Lifecycle (`weather.json`) | medium | mitigate | Cold-boot offline skeleton (`status: "offline"`, `data: null`, `is_stale: true`) and persistent disk mirror restoration prevent UI `ENOENT` exceptions. Tested in Section 5. | closed |
| T-51-06 | Denial of Service | Network Failure Handling (`wwo-fetcher.py`) | medium | mitigate | Network errors trapped without retry loops; preserves existing cached data with `is_stale: true` and exits 0 to await next timer tick. Tested in Section 5. | closed |
| T-51-07 | Configuration Integrity | GNU Stow Deployment (`stow/weather`) | high | block | Explicit pre-creation of target directory `~/.config/weather` in `bootstrap.sh` prevents directory folding into symlinks. Tested in Section 1. | closed |
| T-51-08 | Resource Exhaustion | Systemd Service Execution (`wwo-fetcher.service`) | low | mitigate | `Nice=19`, `TimeoutStartSec=30s`, `RuntimeDirectory=weather`, `RuntimeDirectoryMode=0755`, logging tagged `SyslogIdentifier=wwo-fetcher`. Tested in Section 1. | closed |

*Status: closed (8/8 threats resolved)*  
*Severity: critical > high > medium > low*  
*Disposition: mitigate (implementation required) · accept (documented risk) · block (strict gate)*  

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-51-01 | T-51-01 | Storing API key in 0600 `.env` file under user home directory is standard practice for local desktop telemetry scripts without system-wide keyring complexity | Orchestrator | 2026-10-03 |
| R-51-02 | T-51-08 | 3-minute minimum polling interval imposes negligible CPU overhead (<10ms execution time per invocation) | Orchestrator | 2026-10-03 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-03 | 8 | 8 | 0 | Antigravity Orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / block)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-03
