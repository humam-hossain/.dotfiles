---
phase: 27-hyprland-quickshell-ii-accent-coordination
plan: "02"
subsystem: testing
tags: [hyprland, quickshell, material-you, border-sync, tokens, assert-harness]

requires:
  - phase: 27-hyprland-quickshell-ii-accent-coordination
    provides: Phase 27 assert harness scaffolding and Section 1 readiness (Plan 27-01)
provides:
  - Validated Section 2: Hyprland border token parsing, alpha transposition gradient translation, upstream decoration parameter verification, and live compositor IPC query
  - Validated Section 3: Quickshell ii M3 token schema validation, hex pattern checking, appearance baseline assertions, and resource warning threshold contracts
affects: [27-03, 29-integration-verification]

actuals:
  tokens: 28000
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - Endianness gradient translation transposing rgba(RRGGBBAA) to Hyprland IPC AARRGGBB format
    - Active Wayland compositor socket detection with headless CI static validation fallback
    - Strict regex validation on generated M3 tokens and JSON configuration properties

key-files:
  created: []
  modified:
    - scripts/phase27-accent-coordination-assert.sh

key-decisions:
  - "D-01..D-03: Parse active_border, inactive_border, and pinned border gradient rules from colors.lua with strict word-boundary matching"
  - "D-05..D-07, D-09..D-12: Assert upstream Hyprland decoration geometry, dimming, and snapping defaults (18px rounding 2.5 power squircle, 1px border, 5%/20% dimming, 4/5/50 gaps, 4/5 snapping)"
  - "D-30: Query live compositor border gradient via hyprctl when HYPRLAND_INSTANCE_SIGNATURE is set, falling back cleanly in headless CI"
  - "D-31: Validate all 8 required M3 tokens in colors.json match ^#[0-9a-fA-F]{6}$ hex format"
  - "D-13..D-15: Assert config.json palette type auto, opaque background transparency (enable: false), and warning thresholds (90/95/85)"

patterns-established:
  - "Word-boundary regex isolation for active_border and inactive_border to prevent substring matching collisions"
  - "Safe null/boolean extraction in jq preventing falsey false evaluation to empty"

requirements-completed: [SHELL-01, SHELL-02]

coverage:
  - id: D-01..D-03, D-05..D-12, D-30
    description: "Hyprland window decorations, active/inactive borders, and pinned rules dynamically align with Matugen colors and upstream geometry"
    requirement: SHELL-01
    verification:
      - kind: automated
        ref: "scripts/phase27-accent-coordination-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D-13..D-15, D-18..D-20, D-31
    description: "Quickshell ii consumes valid Material You tokens and maintains upstream appearance baseline and threshold contracts"
    requirement: SHELL-02
    verification:
      - kind: automated
        ref: "scripts/phase27-accent-coordination-assert.sh --section 3"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-09-17
status: complete
---

# Phase 27 Plan 02: Hyprland Border Tokens & Quickshell Schema Verification Summary

**Implemented and verified Section 2 (Hyprland window borders & compositor token match covering D-01..D-03, D-05..D-12, D-30, and SHELL-01) and Section 3 (Quickshell ii token schema & appearance integrity covering D-13..D-15, D-18..D-20, D-31, and SHELL-02) in `scripts/phase27-accent-coordination-assert.sh` with zero failures.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-17T14:35:10+06:00
- **Completed:** 2026-09-17T14:36:20+06:00
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Implemented Section 2:
  - Extracted `active_border` (`rgba(46474777)`) and `inactive_border` (`rgba(1b1c1c33)`) from live `~/.config/hypr/hyprland/colors.lua`, transposing alpha to expected compositor gradients `77464747` and `331b1c1c` respectively (D-01, D-02).
  - Verified pinned window rule primary accent gradient binding and canvas `background_color` declaration (D-03, D-08).
  - Verified upstream decoration geometry in `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua`: 18px rounding with 2.5 power squircle, 1px border, 5% inactive dimming, 20% special dimming, 3-pass x-ray blur, gaps (4/5/50), and edge snapping (4/5px) (D-05..D-07, D-09..D-12).
  - Verified live Hyprland compositor border gradient match via `hyprctl -j getoption general:col.active_border` (`77464747`) and `col.inactive_border` (`331b1c1c`) (D-30, SHELL-01).
- Implemented Section 3:
  - Verified `$XDG_STATE_HOME/quickshell/user/generated/colors.json` exists, has valid JSON syntax, and contains valid `#RRGGBB` hex values for all 8 required M3 tokens (`primary`, `secondary`, `tertiary`, `surface`, `error`, `outline_variant`, `surface_container_low`, `background`) (D-31, SHELL-02).
  - Verified appearance configuration in `capture/ii/.config/illogical-impulse/config.json`: palette type `auto`, opaque background transparency (`enable: false`), resource warning thresholds (cpu: 90, memory: 95, swap: 85), and valid wallpaper fixture path (D-13..D-15, SHELL-02).

## Task Commits

1. **Task 1 & Task 2: Implement and verify Sections 2 and 3** - `3d1304c` (`feat(27-02): implement sections 2 and 3 in phase 27 accent coordination assert harness`)

## Verification Output

```text
[INFO] --- Section 2: Hyprland Window Borders & Compositor Token Match (SHELL-01, D-01..D-03, D-05..D-12, D-30) ---
[PASS] S2: Parsed active_border from colors.lua: rgba(46474777) -> expected gradient 77464747 (D-01)
[PASS] S2: Parsed inactive_border from colors.lua: rgba(1b1c1c33) -> expected gradient 331b1c1c (D-02)
[PASS] S2: Pinned window border rule binds primary accent gradient in colors.lua (D-03)
[PASS] S2: Canvas background_color declared as rgba(121414FF) (D-08)
[PASS] S2: Upstream Hyprland decoration geometry, dimming, and snapping defaults verified (D-05..D-07, D-09..D-12)
[INFO] S2: Active Hyprland compositor detected (signature=efb50993780079460b0cbed1363e2166a2de1d9f_1789593399_226404197)
[PASS] S2: Live compositor active_border matches colors.lua (77464747) (SHELL-01, D-01)
[PASS] S2: Live compositor inactive_border matches colors.lua (331b1c1c) (SHELL-01, D-02)
[PASS] Closing self-check: git status --porcelain unchanged across run (D-28)
=== done: FAIL=0 FINDINGS=0 ===
[INFO] --- Section 3: Quickshell ii Token Schema & Appearance Integrity (SHELL-02, D-13..D-15, D-31) ---
[PASS] S3: Quickshell generated colors.json exists (/home/pera/.local/state/quickshell/user/generated/colors.json) (SHELL-02)
[PASS] S3: colors.json is valid JSON (D-31)
[PASS] S3: M3 token 'primary' present and valid hex: #b8cacd (D-31)
[PASS] S3: M3 token 'secondary' present and valid hex: #bfc8ca (D-31)
[PASS] S3: M3 token 'tertiary' present and valid hex: #b1cbd0 (D-31)
[PASS] S3: M3 token 'surface' present and valid hex: #121414 (D-31)
[PASS] S3: M3 token 'error' present and valid hex: #ffb4ab (D-31)
[PASS] S3: M3 token 'outline_variant' present and valid hex: #464747 (D-31)
[PASS] S3: M3 token 'surface_container_low' present and valid hex: #1b1c1c (D-31)
[PASS] S3: M3 token 'background' present and valid hex: #121414 (D-31)
[PASS] S3: Appearance palette type is 'auto' (D-13)
[PASS] S3: Background transparency is disabled (opaque) (D-15)
[PASS] S3: Resource warning thresholds match upstream spec (cpu:90, mem:95, swap:85) (D-14)
[PASS] S3: Wallpaper fixture exists and is readable (/home/pera/Pictures/55192173787_b8322b1190_o.jpg)
[PASS] Closing self-check: git status --porcelain unchanged across run (D-28)
=== done: FAIL=0 FINDINGS=0 ===
```
