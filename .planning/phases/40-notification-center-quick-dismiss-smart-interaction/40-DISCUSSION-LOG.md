# Phase 40: Notification Center Quick-Dismiss & Smart Interaction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-24  
**Phase:** 40-Notification Center Quick-Dismiss & Smart Interaction  
**Areas discussed:** Header Close Button, Smart Body Click Navigation, OTP / 2FA Action Chip, OTP Detection Heuristics  

---

## Header 'X' Close Button

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated right-aligned close icon alongside expand button | Keep 'X' always visible on the far right of the header | |
| Conditional single vs group header | For single notifications, show 'X'; for groups, keep upstream default UI | ✓ |
| Subtle hover-reveal button | Position 'X' in top-right corner, only visible on hover | |

**User's choice:** Conditional single vs group header — strictly single notification cards receive the 'X' button; multi-notification groups and toast popups retain 100% upstream default UI and behavior.  
**Notes:** User specifically clarified: "when a single notification comes I have to like tick for each notification that is annoying for multi notification group card so I don't wanna do that... I want it for only single notification not for the group for the group I don't want that I don't need that so just do it for the everything is needed to be done for the single notification every other things are default like I like default I like keeping it default". Toast popups keep their upstream hover-to-dismiss behavior untouched.

---

## Smart Body Click Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| URL first, D-Bus fallback | If notification contains a web link, open it in browser; otherwise invoke D-Bus default action | |
| D-Bus first, URL fallback | Attempt the app's default D-Bus action first; fallback to URL opening if no actions registered | ✓ |
| Dedicated link chip | Only open URLs when clicking explicitly detected links | |

**User's choice:** D-Bus first, URL fallback.  
**Notes:** User chose: "i would like d-bus first". Clicking the card body invokes the sending application's `default` action to focus the window, falling back to opening extracted URLs (Chromium, YouTube, WhatsApp, raw links) in default browser via `xdg-open` (`Qt.openUrlExternally`). Body click dismisses the notification and closes the right sidebar.

---

## OTP / 2FA Action Chip

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated accent pill chip directly below the text | Display a prominent styled pill directly beneath the body text | ✓ |
| Inline action button in existing bottom action bar | Add the OTP action alongside existing close/copy buttons at the bottom of the card | |
| Auto-copy with toast notification | Automatically copy detected OTP code immediately upon arrival | |

**User's choice:** Dedicated accent pill chip directly below the text, with **no icons**.  
**Notes:** User chose: "i think option 2 is better" (pill chip directly beneath text so you can copy without expanding the action bar). User further specified: "in 3. don't use icon of key, no need any icon". Clean text pill: `Copy [Code]` and `Copied!`.

---

## OTP Detection Heuristics

| Option | Description | Selected |
|--------|-------------|----------|
| Pure digits + prefixed codes | Support 4–8 digits, hyphenated codes (123-456), and service prefixes (G-123456) anchored to security keywords | ✓ |
| Strict 4–8 digits only | Match strictly 4 to 8 consecutive digits anchored to security keywords | |
| Broad pattern match | Match any isolated 4–8 character token near verification keywords | |

**User's choice:** Pure digits + prefixed codes anchored to security keywords.  
**Notes:** Supports standard 4–8 digits, hyphenated formats, and Google/service prefixes (`G-123456`) near keywords (`code`, `otp`, `verify`, `pin`, `auth`, `2fa`, `password`).

---

## the agent's Discretion

- Regex boundary lookaheads and negative matches preventing timestamps, phone numbers, and color hex codes from false matching.
- Exact Material 3 token styling and micro-spacing for the OTP action pill.

## Deferred Ideas

- None — discussion stayed strictly within phase scope.
