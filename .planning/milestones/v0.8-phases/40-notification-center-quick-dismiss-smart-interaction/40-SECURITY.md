---
phase: "40"
slug: "notification-center-quick-dismiss-smart-interaction"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-24"
---

# Phase 40 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| FreeDesktop Notification Text Ingestion | Untrusted notification body and summary strings originating from arbitrary third-party D-Bus applications. | Plaintext strings, HTML markup, and URLs |
| Regex Execution Engine | String parsing executed synchronously in Quickshell JavaScript environment. | Regex evaluation time and memory allocation |
| Browser / External URL Dispatch | External URL strings passed to system handler via `Qt.openUrlExternally()`. | Sanitized HTTP/HTTPS URLs passed to portal |
| System Clipboard Interface | Writing sensitive credentials (OTP / 2FA codes) into the system clipboard via `Quickshell.clipboardText`. | Extracted code digits only |
| Stow Deployment | Leaf symlinks deployed by GNU Stow from `restow/quickshell/` to `~/.config/quickshell/`. | Overlay files only |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-40-01 | Denial of Service | `NotificationUtils.extractOtpCode` regex engine | high | mitigate | Eliminated nested unbounded quantifiers; implemented bounded quantifiers (`\d{4,8}`, `{0,30}?`, `{1,60}?`) with negative lookarounds `(?<![-/0-9])` and `(?![-/0-9])` guaranteeing linear execution time. Verified by 19-case test matrix in Section 3 of test harness. | closed |
| T-40-02 | Information Disclosure / Clipboard Access | `NotificationItem.qml` OTP chip | medium | mitigate | Copies strictly extracted code digits/string to `Quickshell.clipboardText` without surrounding context, body text, or sender metadata; provides immediate 1.5s visual confirmation ("Copied!") to user without navigating away. Verified in Section 2 AST checks. | closed |
| T-40-03 | Elevation of Privilege / Command Injection | `NotificationUtils.extractUrl` URL handler | high | mitigate | Enforced strict protocol whitelist (`http://` or `https://` only); explicitly rejected dangerous URI schemes (`javascript:`, `file:`, `data:`, `sh:`) before returning URL for external launching. Verified in Section 4 test suite. | closed |
| T-40-04 | Tampering | Submodule drift in `vendor/dots-hyprland` | high | mitigate | Authored all modifications exclusively in `restow/quickshell/`; verified zero submodule drift via `arch/dots-hyprland.sh verify --strict` reporting `FAIL=0 FINDINGS=0` in Section 5. | closed |

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
| 2026-09-24 | 4 | 4 | 0 | execute-phase orchestrator (ASVS L1, register authored in 40-01-PLAN.md and 40-02-PLAN.md) |

L1 short-circuit applied after classification: `threats_open: 0`, threat register present in plan, `workflow.security_asvs_level` is 1. Each mitigation was verified in the overlay sources and in the harness output before this file was written.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-24
