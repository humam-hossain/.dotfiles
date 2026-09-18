---
phase: "26"
slug: "qt-kde-apps-material-you-harmonization"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-17"
---

# Phase 26 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| User Script Execution → Python Virtual Environment (`~/.local/state/quickshell/.venv`) | Calling external Python binary inside virtual environment with shell-interpolated arguments | CLI flags, paths |
| Wallpaper Seed Color → Generator CLI Arguments | Parsing hex color strings from user state files and passing as command line flags to `kde-material-you-colors` | Color strings, path arguments |
| Upstream Generator Script → Hyprland Session DBus | Execution of KDE Plasma utility under Hyprland compositor attempting KWin DBus reloads | DBus messages, signals |
| Desktop Applications → XDG Desktop Portal Router (`xdg-desktop-portal`) | Sandboxed flatpaks and unprivileged GUI applications calling session DBus portal interfaces | File picker portal invocations |
| Test Harness Execution → Git Working Tree State | Verification script execution mutating git tracked files or leaving temporary artifacts | Git working tree, config files |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-26-01 | Tampering / Denial of Service | `kde-material-you-colors` CLI & assert harness | high | mitigate | Strictly quote and sanitize all file paths and seed colors (`"$SEED_COLOR"`); catch non-fatal KWin DBus exceptions with `\|\| true`; restrict execution to user-owned `$XDG_STATE_HOME/quickshell/.venv/bin/kde-material-you-colors` (D-08, D-09, D-16) | closed |
| T-26-02 | Accidental Secret or Git Churn Exposure | `guard-paths.tsv` & git working tree | medium | mitigate | Enforce git status porcelain snapshot comparisons before and after harness execution; register `$XDG_CONFIG_HOME/kde-material-you-colors` in `guard-paths.tsv` to exclude generator state from tracking (D-02, D-04, INTG-01, INTG-02) | closed |
| T-26-03 | Elevation of Privilege | `xdg-desktop-portal-kde` portal integration | low | accept | Portal communicates over unprivileged user session DBus via standard Freedesktop specifications; runs entirely within user session permissions (D-12) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-26-01 | T-26-03 | Portal communicates over unprivileged user session DBus via standard Freedesktop specifications; runs entirely within user session permissions | security-auditor | 2026-09-17 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-17 | 3 | 3 | 0 | gsd-secure-phase |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-17
