---
phase: 01-shell-foundation-theme
extracted: 2026-07-21
sources:
  - 01-01-SUMMARY.md
  - 01-02-SUMMARY.md
  - 01-03-SUMMARY.md
  - 01-04-SUMMARY.md
  - 01-VERIFICATION.md
  - 01-UAT.md
  - 01-SECURITY.md
  - STATE.md
missing_artifacts: []
---

# Phase 01 Learnings

## Decisions

### Wholesale copy of dots-hyprland `ii` tree
- **What:** Replace prior Quickshell attempt with full `ii` tree (PanelLoader, families, services).
- **Why:** Clean architecture match to inspiration source; avoid iterating on deleted legacy bar.
- **Source:** 01-01-SUMMARY.md, STATE.md

### Theme deploy via SCSS→JSON converter
- **What:** `generate_colors_material.py` stdout SCSS piped to snake_case `colors.json`; `--cache` only stores seed hex.
- **Why:** `--cache` alone does not produce MaterialThemeLoader-compatible JSON.
- **Source:** 01-02-SUMMARY.md

### Scheme flag `scheme-vibrant`
- **What:** Pass `--scheme scheme-vibrant`, not bare `vibrant`.
- **Why:** Bare name falls through to tonal-spot.
- **Source:** 01-02-SUMMARY.md

### Font fallbacks + Material Symbols
- **What:** Default UI fonts to Noto Sans / JetBrainsMono Nerd Font; require Material Symbols Rounded for chrome icons.
- **Why:** Google Sans Flex / missing Material Symbols caused empty icons and broken metrics (UAT G-01-1).
- **Source:** 01-04-SUMMARY.md, 01-UAT.md

### Stock Hyprland workspace dispatch
- **What:** Use `workspace N` / `workspace r±1` instead of `hl.dsp.focus`.
- **Why:** Host has no Hyprland plugins; plugin dispatcher fails at runtime.
- **Source:** 01-04-SUMMARY.md

### Vendor shapes submodule content
- **What:** Copy rounded-polygon shapes into tree rather than nested git submodule.
- **Why:** Empty submodule blocked Configuration Loaded.
- **Source:** 01-03-SUMMARY.md

## Lessons

### Runtime fonts are hard dependencies for wholesale ii
- **What:** Material chrome icons are font glyphs (`MaterialSymbol.qml`), not PNGs.
- **Context:** Bar "looked broken" with missing icons until Material Symbols installed; provisioning scripts must include the font package.
- **Source:** 01-UAT.md, 01-04-SUMMARY.md, debug/bar-visual-icons-layout.md

### Persisted Config overrides QML defaults
- **What:** `~/.config/illogical-impulse/config.json` keeps old font family names after defaults change.
- **Context:** Fixing `Config.qml` alone did not change live fonts until the JSON was updated.
- **Source:** 01-04 execution notes

### Sudo may be unavailable during agent execution
- **What:** User-local font install under `~/.local/share/fonts` works when pacman needs a password.
- **Context:** Gap closure still succeeded; system package remains in scripts for next provision.
- **Source:** 01-04-SUMMARY.md

### Incomplete Appearance token map is non-fatal but noisy
- **What:** Generator emits `*_dim` keys; missing `m3*Dim` properties produce assign warnings.
- **Context:** Theme still applied (UAT Test 2 passed); declaring props cleans logs.
- **Source:** 01-VERIFICATION.md, 01-04-SUMMARY.md

## Patterns

### Hard-error fixes only at startup
- **Pattern:** Fix crashes that block `Configuration Loaded`; leave non-fatal FileView/missing-state warnings alone.
- **When to use:** Integrating large wholesale QML trees on a partial host setup.
- **Source:** 01-03-SUMMARY.md

### Gap-closure loop after UAT
- **Pattern:** UAT issue → diagnose → gap PLAN (`gap_closure: true`, `gap_ids`) → execute `--gaps-only` → re-UAT.
- **When to use:** Human visual failures after automated verification says "present".
- **Source:** 01-UAT.md, 01-04-PLAN.md

### Smoke criteria for shell changes
- **Pattern:** `timeout N quickshell` must show `Configuration Loaded` and must not reintroduce known WARN patterns (m3primaryDim, forceMonitor, hl.dsp.focus).
- **When to use:** After any theme/bar/Config change.
- **Source:** 01-04-SUMMARY.md

## Surprises

### shapes submodule arrived empty after wholesale copy
- **What:** Git submodule path was empty until vendored; shell would not load.
- **Impact:** Plan 01-03 had to vendor shapes and soften syntax-highlighting import.
- **Source:** 01-03-SUMMARY.md

### `hl.dsp.focus` is not stock Hyprland
- **What:** Workspace clicks logged Invalid dispatcher with zero plugins.
- **Impact:** Bar looked usable but workspace switching was broken until gap fix.
- **Source:** 01-UAT.md, 01-04-SUMMARY.md

### Waybar can coexist with quickshell:bar
- **What:** Both layers can be present; Waybar may still occupy the top strip.
- **Impact:** Cutover remains Phase 4; dual bars possible during development.
- **Source:** STATE.md concerns, session hyprctl layers
