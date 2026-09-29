---
phase: "46"
slug: "left-zone-integration-verification-repository-integrity"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-29"
---

# Phase 46 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Shell Bar Flex RowLayout → Component Z-Ordering | Left zone status bar row layout coordinating pill stacking and mouse interception | Pointer events and layout geometry |
| QML Scenegraph → User Pointer Events | Status bar inert MouseAreas capturing clicks without letting them bleed to background toggles | Click and hover pointer events |
| Test Harness Process → System Environment | Assertion script execution validating local file contents and AST structures | Process execution, exit codes, stdout/stderr |
| GNU Stow Symlink Farm → Live Home Directory (`$HOME/.config/`) | File system symlink mapping linking repository overlays to runtime desktop environment | Filesystem inodes and leaf symlinks |
| Sub-Harness Execution → OS Process Boundary | Invocation of auxiliary assertion scripts (`phase42`, `phase43`, `phase44`, `phase45`) | Script execution and subprocess return codes |
| Local HTTP Loopback → Ping Client Bridge | Polling system monitor daemon at `http://127.0.0.1:8765` | HTTP / XMLHttpRequest JSON loopback payloads |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-46-01 | Tampering | Test harness execution (`phase46-telemetry-assert.sh`) | low | mitigate | Script executes with `set -euo pipefail`, traps cleanup on `EXIT INT TERM`, enforces non-root execution (`EUID != 0`), and validates paths strictly within `$REPO_ROOT`. | closed |
| T-46-02 | Denial of Service | QML Scenegraph layout churn | medium | mitigate | Fixed 320px column widths (`Layout.preferredWidth: 320`) and explicit column height spacers (`Item { Layout.fillHeight: true }`) prevent layout calculation cycles or geometry thrashing during dynamic metric updates. | closed |
| T-46-03 | UI Spoofing / Click Misdirection | Status bar pill click handling | medium | mitigate | Re-parented inert `MouseArea { parent: root; anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: event => event.accepted = true }` in `MemoryStoragePill` prevents click bleed to underlying status bar toggles or sidebar triggers. | closed |
| T-46-04 | Elevation of Privilege / Tampering | Symlink hijacking / Path traversal (ASVS V14.2) | high | block | All overlays are deployed as leaf symlinks strictly pointing to repository paths under `restow/quickshell/`. `./arch/dots-hyprland.sh verify --strict` enforces canonical resolution and fails if any symlink points outside the repo or is dangling. | closed |
| T-46-05 | Information Disclosure | Working tree pollution & secret leakage | medium | mitigate | Harness execution runs non-destructively, traps temporary files in `/tmp`, and records git porcelain snapshots before and after execution to assert zero working tree drift. | closed |
| T-46-06 | Denial of Service | Stale attack surface & broken symlinks (ASVS V14.1) | medium | mitigate | Complete removal of legacy `Resources.qml` and `Resource.qml` from git accompanied by live symlink unlinking and `.bak` file restoration eliminates dead code and prevents broken symlink crashes. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*  
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*  

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-46-01 | T-46-01 | Test script root execution prevention and pipefail traps accepted as sufficient safeguard | Orchestrator | 2026-09-29 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-29 | 6 | 6 | 0 | Antigravity Orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-29
