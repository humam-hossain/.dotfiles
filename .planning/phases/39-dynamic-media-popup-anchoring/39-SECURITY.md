---
phase: "39"
slug: "dynamic-media-popup-anchoring"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-23"
---

# Phase 39 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Layer-shell positioning | Margin math stays inside Quickshell layout. No IPC command injection and no privilege change. | Screen coordinates and gap sizes only |
| `GlobalStates.qml` singleton | `mediaPillCenterX`, `mediaPillCenterY`, and `mediaPillScreen` are read by bar and popup components in the user session. | Layout numbers and a screen reference |
| Stow deployment | Leaf symlinks under `restow/quickshell/` land in `~/.config/quickshell/`. `vendor/dots-hyprland` stays read-only. | Overlay files only |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-39-01 | Denial of Service | `MediaControls.qml` coordinate clamping | medium | mitigate | `margins.left` and vertical `margins.top` use `(max < min) ? min : Math.max(min, Math.min(target, max))` plus `Math.round`. Confirmed in `MediaControls.qml` and by harness section 3 (narrow-display guard returns 5). | closed |
| T-39-02 | Information Disclosure | `GlobalStates.qml` state bridge | low | mitigate | Bridge properties are `real` coordinates and a screen reference. The singleton file contains no track title, MPRIS metadata, or credentials. | closed |
| T-39-03 | Denial of Service | `BarContent.qml` multi-monitor coordinate race | low | mitigate | `onMediaControlsOpenChanged` updates coordinates only when `mediaHoverHandler.hovered` (vertical bar: `verticalMediaHoverHandler.hovered`). Dismissal resets X/Y to -1 and screen to null only for the matching screen. Harness section 4 passed the set/reset lifecycle. | closed |
| T-39-04 | Tampering | Submodule drift in `vendor/dots-hyprland` | high | mitigate | `git -C vendor/dots-hyprland status --porcelain` was empty (0 lines). `./arch/dots-hyprland.sh verify --strict` reported `FAIL=0 FINDINGS=0` inside the phase 39 harness. | closed |

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
| 2026-09-23 | 4 | 4 | 0 | execute-phase orchestrator (ASVS L1, register authored in 39-01-PLAN.md) |

L1 short-circuit applied after classification: `threats_open: 0`, threat register present in the plan, `workflow.security_asvs_level` is 1. Each mitigation was checked in the overlay sources and in the harness output before this file was written.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-23
