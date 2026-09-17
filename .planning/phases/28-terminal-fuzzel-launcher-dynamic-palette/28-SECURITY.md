---
phase: "28"
slug: "terminal-fuzzel-launcher-dynamic-palette"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-17"
---

# Phase 28 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Assert Harness Execution → Git Working Tree State | Verification script execution mutating git tracked files or leaving temporary artifacts | Git working tree, config files |
| Stow Symlink Management → User Home Directory | Creating symlinks without overwriting or adopting foreign host state | File links, target directories |
| Python Script Execution (`kitty +runpy`) → Terminal Process Engine | Evaluating configuration options in a headless Python interpreter | Terminal options, Python bytecode |
| Local Theme Files (`kitty-theme.conf`, `fuzzel_theme.ini`) → UI Launchers | Ingesting dynamically generated hex color strings into terminal and app launcher configs | Color strings, INI sections |
| Process Signaling (`kill -SIGUSR1`) → Host Desktop Sessions | Dispatching signals to process IDs matching running terminal emulators | UNIX signals (SIGUSR1, 0) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-28-01 | Tampering / Accidental Git Churn | `guard-paths.tsv` & porcelain checks | high | mitigate | Enforce git status porcelain snapshot comparison before and after harness execution, and assert `$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini` is strictly registered in `guard-paths.tsv` to prevent repository tracking of dynamic launcher theme state (D-16, D-19, INTG-01) | closed |
| T-28-02 | Elevation of Privilege / Insecure Package Linking | GNU Stow invocation | medium | mitigate | Prohibit `stow --adopt` strictly; unlink known regular files manually before running `stow --no-folding` to prevent pulling foreign files into git tracking (CAP-07) | closed |
| T-28-03 | Denial of Service / UI Render Failure via Corrupted Hex Tokens | Fuzzel & Kitty theme parser | high | mitigate | Validate all color tokens strictly against hex regex patterns (8-digit hex for Fuzzel, 6-digit hex for Kitty) before runtime acceptance (D-11, D-13) | closed |
| T-28-04 | Information Disclosure / Shell Hijacking via Config Drift | Kitty shell configuration | medium | mitigate | Enforce `opts.shell == 'zsh'` assertion to prevent accidental adoption of upstream fish shell or unintended binary execution (D-02) | closed |
| T-28-05 | Denial of Service / Process Termination | Terminal process signaling | high | mitigate | Scope `kill -SIGUSR1` strictly to user-owned `$(pidof kitty)`, check process liveness with `kill -0` post-signal, and provide graceful headless bypass if kitty is not running (D-05, D-18) | closed |
| T-28-06 | Repudiation / Repository Pollution | Dynamic theme reload drill | medium | mitigate | Enforce git status porcelain snapshot comparison before and after execution to guarantee zero untracked or modified repository files across runs (D-19, INTG-02) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-28-01 | T-28-05 | Kitty process signaling is conditioned on active process detection, with graceful static syntax fallback for headless and CI environments | security-auditor | 2026-09-17 |

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
