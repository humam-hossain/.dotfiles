---
phase: "31"
slug: "overlay-infrastructure-pill-geometry-foundation"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-09-20"
---

# Phase 31 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Stow Overlay Linking → User Configuration Tree | GNU Stow linking leaf files into active user environment without folding ancestor directories or adopting foreign files | Symlinks to repository files |
| Test Assert Harness → Git Working Tree | Assertion scripts executing git status snapshots without creating uncommitted file churn | Porcelain snapshot diffs |
| Repository Packaging → Upstream Submodule | Personal modifications confined to restow/ without modifying vendor/dots-hyprland | Pristine vendor git state |
| QML Property Bindings → Quickshell QML Runtime | Dynamic width calculations evaluated by QML engine without layout overflows or infinite binding loops | Layout geometry signals |
| Live Reload Hook → Desktop Window Management | Signaling Quickshell without crashing Hyprland or disrupting user application windows | Process signals (SIGTERM / nohup) |
| Strict Repository Verifier → File System State | Verifying symlinks and permissions without modifying live dotfiles | Read-only audit assertions |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-31-01 | Tampering / Test Harness Churn | scripts/phase31-overlay-pill-assert.sh | medium | mitigate | Enforce two-phase porcelain snapshots comparing `$PORCELAIN_BEFORE` and `$PORCELAIN_AFTER` with cleanup traps on exit (D-08). | closed |
| T-31-02 | Tampering / Unintended Adoption | GNU Stow and live files | high | mitigate | Strictly ban `stow --adopt`; back up and remove existing regular files before running `stow --verbose=5 --no-folding -t ~ quickshell` (D-05, CAP-07). | closed |
| T-31-03 | Denial of Service / Directory Folding | GNU Stow directory hierarchy | high | mitigate | Enforce `--no-folding` universally and assert that `~/.config/quickshell` and all ancestor paths remain real directories (PILL-01). | closed |
| T-31-04 | Repudiation / Submodule Pollution | vendor/dots-hyprland | high | mitigate | Maintain personal overlays strictly under `restow/quickshell/` and assert `git -C vendor/dots-hyprland status --porcelain` is empty in Section 1. | closed |
| T-31-05 | Denial of Service / QML Layout Crash | BarContent.qml and BarGroup.qml | high | mitigate | Propagate implicit dimensions cleanly between MouseArea and inner BarGroup; avoid circular dependencies or undefined properties (D-01, PILL-02, PILL-03). | closed |
| T-31-06 | Denial of Service / Shell Reload Failure | Live Quickshell process reload | medium | mitigate | Use standard Hyprland reload sequence `killall qs quickshell 2>/dev/null || true; nohup qs -c ii >/dev/null 2>&1 &` matching `Ctrl+Super+R` binding without disrupting active desktop sessions (D-07). | closed |
| T-31-07 | Tampering / Layout Drift | BarGroup.qml visual tokens | medium | mitigate | Enforce exact upstream token names (`Appearance.rounding.small`, `padding: 5`, `colLayer1`) in assertions to prevent rogue CSS or style drift (D-03, PILL-04). | closed |

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
| 2026-09-20 | 7 | 7 | 0 | orchestrator / gsd-security-auditor (L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-20
