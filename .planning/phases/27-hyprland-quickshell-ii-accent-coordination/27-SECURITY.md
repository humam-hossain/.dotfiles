---
phase: "27"
slug: "hyprland-quickshell-ii-accent-coordination"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-17"
---

# Phase 27 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Assert Harness Execution → Git Working Tree State | Verification script execution mutating git tracked files or leaving temporary artifacts | Git working tree, config files |
| Upstream Template Files → Live Shell Configuration | Matugen reading templates to generate live Lua configuration | Template strings, palette tokens |
| Compositor IPC Socket (`$HYPRLAND_INSTANCE_SIGNATURE`) | Communicating with the Wayland compositor via hyprctl to query runtime options | JSON IPC queries, gradient tokens |
| Local Filesystem State (`colors.json`) | Parsing generated theme tokens consumed by desktop shell widgets | JSON state, hex strings |
| Process Execution (`switchwall.sh`) → Downstream Subsystems | Invoking desktop services, terminal sequences, and theme wrappers | CLI arguments, image file paths |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-27-01 | Tampering / Accidental Git Churn | `guard-paths.tsv` & porcelain checks | high | mitigate | Enforce git status porcelain snapshot comparison before and after harness execution, and assert `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` is strictly registered in `guard-paths.tsv` to prevent repository tracking of dynamic theme state (D-28, INTG-01) | closed |
| T-27-02 | Configuration Injection via Untrusted Templates | Matugen templates | medium | mitigate | Matugen templates are read strictly from tracked repository vendor sources (`vendor/dots-hyprland/dots/.config/matugen/templates/`); no user-provided strings are evaluated as executable Lua code without template sanitization (D-01..D-04) | closed |
| T-27-03 | Denial of Service / UI Breakage via Corrupted Palette Tokens | `colors.json` & Appearance Singleton | high | mitigate | Validate syntactic validity via `jq empty` and enforce strict regex validation (`^#[0-9a-fA-F]{6}$`) on all required M3 tokens before propagation (D-31) | closed |
| T-27-04 | False Failure in Non-Interactive / Headless Environments | Compositor IPC Query | low | accept | Condition live compositor query on active `$HYPRLAND_INSTANCE_SIGNATURE` presence with clean static validation fallback in headless CI (D-30) | closed |
| T-27-05 | Elevation of Privilege / Command Injection via Wallpaper Path | `switchwall.sh` CLI invocation | high | mitigate | `switchwall.sh` strictly quotes `$imgpath` and validates file existence; test harness verifies wallpaper fixture path before drill execution (D-26) | closed |
| T-27-06 | Repudiation / Git Repository Churn | Test drill & verification engine | medium | mitigate | Porcelain snapshot comparison before and after test execution ensures zero untracked or modified repository files across runs (D-28, INTG-02) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-27-01 | T-27-04 | Compositor IPC query is conditioned on active HYPRLAND_INSTANCE_SIGNATURE presence, with safe static fallback for headless and CI environments | security-auditor | 2026-09-17 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-17 | 6 | 6 | 0 | gsd-secure-phase |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-17
