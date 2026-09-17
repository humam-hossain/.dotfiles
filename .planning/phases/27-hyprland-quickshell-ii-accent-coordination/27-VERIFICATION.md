---
phase: 27
status: passed
automated_checks: 29
human_verification:
  - "Visual inspection of border color transition during wallpaper change: Trigger switchwall.sh and visually confirm window borders update cleanly without visible lag or redraw glitch."
requirements_verified: [SHELL-01, SHELL-02, SHELL-03, INTG-01, INTG-02]
verified: "2026-09-17"
---

# Phase 27 — Verification Report

## Goal Achievement

**Phase Goal:** Hyprland window borders, decorations, and Quickshell ii widgets coordinated with dynamic Material You accents extracted from active wallpaper.

**Verdict: READY FOR HUMAN VERIFICATION.** All automated criteria are met across all 3 plans:

1. ✅ Hyprland window decorations dynamically reflect Material You accent colors from active wallpaper, with active border bound to `outline_variant` (77% alpha) and inactive border to `surface_container_low` (33% alpha), and pinned windows displaying a primary accent gradient (SHELL-01, D-01..D-03, D-08).
2. ✅ Upstream Hyprland decoration geometry, dimming, and snapping defaults (18px rounding with 2.5 power squircle, 1px border, 5%/20% dimming, 4/5/50 gaps, 4/5 snapping) are verified without local overrides in `custom/general.lua` (SHELL-01, D-04..D-07, D-09..D-12).
3. ✅ Quickshell ii consumes generated `colors.json` providing valid hex tokens for all 8 required Material 3 palette colors, with palette scheme type `auto`, opaque container background (`transparency.enable: false`), and warning thresholds (cpu: 90, mem: 95, swap: 85) (SHELL-02, D-13..D-15, D-18..D-20, D-31).
4. ✅ Wallpaper switching via `switchwall.sh --noswitch` runs Matugen synchronously with strictly monotonic mtime advancement on `colors.lua` and `colors.json`, updating Hyprland border gradients live via compositor inotify without restarting the compositor or Quickshell (SHELL-03, D-16, D-21..D-27, D-32).
5. ✅ `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` is strictly guarded in `guard-paths.tsv` as `generated_theme`, packaging trees remain 100% clean, and `arch/dots-hyprland.sh verify --strict` passes with 0 findings and zero git drift (INTG-01, INTG-02, D-28, D-29).

## Requirement Traceability

| Requirement | Description | Plan | Status |
|---|---|---|---|
| **SHELL-01** | Hyprland window borders & decorations coordinated with Material You accents | 27-01 Task 2, 27-02 Task 1 | ✅ Verified (automated) |
| **SHELL-02** | Quickshell ii token schema & appearance integrity | 27-02 Task 2 | ✅ Verified (automated) |
| **SHELL-03** | Live coordinated wallpaper reload pipeline via switchwall.sh | 27-03 Task 1 | ⏳ Ready for UAT |
| **INTG-01** | Guard path registration for colors.lua | 27-01 Task 2 | ✅ Verified (automated) |
| **INTG-02** | Strict verification engine & zero git drift compliance | 27-03 Task 2 | ✅ Verified (automated) |

All 5 requirement IDs from PLAN frontmatter are accounted for in REQUIREMENTS.md.

## Automated Verification Results

### Assert Harness: `scripts/phase27-accent-coordination-assert.sh`

Full 5-section run: **29 checks, 0 failures, 0 findings.**

| Section | Requirement | Checks | Result |
|---------|------------|--------|--------|
| 1 — Template & Config Readiness | INTG-01, SHELL-01, D-01..D-04, D-08 | 5 | ✅ PASS |
| 2 — Hyprland Window Borders & Compositor Match | SHELL-01, D-01..D-03, D-05..D-12, D-30 | 7 | ✅ PASS |
| 3 — Quickshell ii Token Schema & Appearance | SHELL-02, D-13..D-15, D-31 | 12 | ✅ PASS |
| 4 — Live Coordinated Reload Probe | SHELL-03, D-21..D-24, D-26, D-32 | 5 | ✅ PASS |
| 5 — Strict Verification Engine & Zero Drift | INTG-01, INTG-02, D-28, D-29 | 2 | ✅ PASS |
| Closing self-check | D-28 | 1 | ✅ PASS |

Exit: `=== done: FAIL=0 FINDINGS=0 ===`

### Strict Verification Engine: `arch/dots-hyprland.sh verify --strict`

Exit code: 0, FAIL=0, FINDINGS=0.
`$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` recognized as `[PASS] guard path excluded`.

### Regression Gate: Prior Phases

- Phase 25 assertion suite (`scripts/phase25-gtk-material-you-assert.sh`): **43 checks, 0 failures, 0 findings.**
- Phase 26 assertion suite (`scripts/phase26-qt-kde-material-you-assert.sh`): **23 checks, 0 failures, 0 findings.**

## Must-Have Verification

### Plan 27-01 Must-Haves

| Truth | Status |
|-------|--------|
| `scripts/phase27-accent-coordination-assert.sh` exists at 0755 with fail-closed structure | ✅ |
| `guard-paths.tsv` guards `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` with strict tab separation | ✅ |
| Upstream Matugen template binds required border and background color tokens | ✅ |
| Live `~/.config/hypr/hyprland/colors.lua` exists and is non-empty with valid syntax | ✅ |
| `stow/hypr/.config/hypr/custom/general.lua` preserves upstream overlay purity with zero border overrides | ✅ |
| Section 1 passes with FAIL=0 | ✅ |

### Plan 27-02 Must-Haves

| Truth | Status |
|-------|--------|
| `colors.lua` declares active/inactive borders, background, and pinned rule tokens | ✅ |
| Endianness gradient translation transposes `rgba(RRGGBBAA)` to `AARRGGBB` | ✅ |
| Live compositor border gradient matches expected gradient from `colors.lua` (`77464747` / `331b1c1c`) | ✅ |
| Upstream Hyprland decoration geometry, dimming, and snapping defaults verified | ✅ |
| `colors.json` contains valid hex colors for all 8 required M3 tokens | ✅ |
| `config.json` configures palette type auto, opaque background, and warning thresholds 90/95/85 | ✅ |
| Sections 2 and 3 pass with FAIL=0 | ✅ |

### Plan 27-03 Must-Haves

| Truth | Status |
|-------|--------|
| `switchwall.sh` exists and is executable | ✅ |
| `switchwall.sh --noswitch` runs synchronously and completes with exit 0 | ✅ |
| File modification timestamps on `colors.lua` and `colors.json` advance monotonically | ✅ |
| Compositor inotify re-evaluates `col.active_border` live without restart | ✅ |
| Packaging directories remain 100% clean | ✅ |
| `arch/dots-hyprland.sh verify --strict` exits 0 with 0 findings | ✅ |
| Full 5-section suite passes with `FAIL=0 FINDINGS=0` | ✅ |
| `27-VALIDATION.md` signed off with `status: validated` and `nyquist_compliant: true` | ✅ |
