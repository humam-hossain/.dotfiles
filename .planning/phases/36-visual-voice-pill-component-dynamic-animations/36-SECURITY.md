---
phase: "36"
slug: "visual-voice-pill-component-dynamic-animations"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-09-21"
---

# Phase 36 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Voice.qml Singleton Service -> VoicePill.qml UI bindings | Untrusted or malformed string data from overallState or formattedDuration | State strings, duration text |
| Appearance.qml / Matugen -> VoicePill.qml color tokens | Dynamic palette token shifts during wallpaper reload | Color token values |
| QtQuick SceneGraph -> QML UI animation thread | Animation loops, timer intervals, and CPU execution | Frame timing, opacity values |
| GNU Stow / bash scripts -> Filesystem links | Leaf symlink deployment and test script execution | Filesystem paths, symlinks |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-36-01 | Denial of Service | VoicePill.qml (pulseAnimation & timers) | medium | mitigate | Constrain pulseAnimation strictly to effectiveState === "recording", reset opacity on stop, use hardware-accelerated scene graph animations, and configure wrapUpTimer as single-shot (repeat: false, 1500ms interval). | closed |
| T-36-02 | Spoofing / Tampering | VoicePill.qml (overallState binding) | medium | mitigate | Implement exhaustive switch statements with default fallbacks returning safe tokens (Appearance.colors.colOnLayer1, "") so malformed or unexpected states fail soft without QML script errors. | closed |
| T-36-03 | Elevation of Privilege | scripts/phase36-voice-pill-assert.sh | high | mitigate | Enforce bash strict mode (set -euo pipefail), refuse execution if run as root (EUID != 0), quote all filesystem paths and variables, and execute commands directly without eval or unescaped shell strings. | closed |
| T-36-04 | Information Disclosure | VoicePill.qml (status labels) | low | mitigate | Component displays strictly generic lifecycle state badges ("Transcribing...", "Typing...") and duration numbers (M:SS); zero raw transcript text or user clipboard data is rendered in the bar widget. | closed |

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
| 2026-09-21 | 4 | 4 | 0 | orchestrator (L1 verification) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-21
