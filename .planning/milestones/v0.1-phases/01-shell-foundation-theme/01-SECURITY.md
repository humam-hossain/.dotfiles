---
phase: 01
slug: shell-foundation-theme
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-21
verified: 2026-07-21
register_authored_at_plan_time: false
---

# Phase 01 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Retroactive STRIDE (no `<threat_model>` in PLAN.md at plan time).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Local user session | Quickshell runs as the logged-in user on Hyprland | QML config, theme JSON, IPC |
| Host filesystem | Config symlink + generated theme under `$HOME` | colors.json, illogical-impulse config |
| Optional external tools | ddcutil / brightnessctl / notify-send | Monitor brightness, notifications |
| Optional network (vendored) | Booru and AI modules present in wholesale tree | HTTP (not Phase 1 goal surface) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-01-01 | Tampering | `arch/quickshell.sh` symlink_config | medium | accept | Script assumes single-dir symlink; live path is symlink to repo. Guard (`-L` check) deferred — documented in 01-REVIEW warning #1 | closed |
| T-01-02 | Elevation / DoS | Brightness.qml + ddcutil package | medium | accept | PROJECT.md documents ddcutil iGPU risk; brightness not a Phase 1 success criterion. Package install remains for compatibility; user can avoid DDC monitors | closed |
| T-01-03 | Injection | MessageCodeBlock.qml `bash -c` save | medium | accept | Wholesale AI chat code; phase softens syntax-highlighting hard fail only. Uses shellSingleQuoteEscape; AI chat not Phase 1 UX goal | closed |
| T-01-04 | Information disclosure | MaterialThemeLoader + colors.json | low | mitigate | Theme JSON is local user state only; no secrets. Loader assigns known Appearance properties only (m3*Dim map completed in 01-04) | closed |
| T-01-05 | Spoofing | Local IPC (IpcHandler on shell/services) | low | mitigate | Quickshell IPC is session-local; no remote bind in Phase 1 entry path | closed |
| T-01-06 | Denial of service | Theme generate_theme python pipeline | low | mitigate | Fails closed under `set -e` if materialyoucolor missing; no elevated install beyond package manager | closed |

*Status: open · closed · open — below high threshold (non-blocking)*  
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` (high) count toward threats_open*  
*Disposition: mitigate · accept · transfer*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01-01 | T-01-01 | Symlink-only deploy is current invariant; destructive rm only if misconfigured non-symlink path | UAT complete / phase 01 | 2026-07-21 |
| AR-01-02 | T-01-02 | ddcutil host risk known; not exercised by Phase 1 success criteria | PROJECT.md + phase 01 | 2026-07-21 |
| AR-01-03 | T-01-03 | AI code-block shell save is pre-existing wholesale surface; out of Phase 1 bar/theme scope | phase 01 security review | 2026-07-21 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-21 | 6 | 6 | 0 | orchestrator-inline (retroactive STRIDE, ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-21
