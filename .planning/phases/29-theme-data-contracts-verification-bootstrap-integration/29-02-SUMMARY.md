---
phase: "29"
plan: "02"
subsystem: "bootstrap-integration"
tags: [bootstrap, verification, regression, theming, switchwall]
requires:
  - "29-01"
provides:
  - "Section 2 live zero git churn drill with race-free kdeglobals polling and monotonic mtime verification"
  - "Hardened bootstrap.sh with hierarchical prefix matching in is_guarded_path"
  - "Explicit legacy Catppuccin symlink pruning in bootstrap.sh run_destub"
  - "Sensitive parent directory pre-creation in bootstrap.sh run_stow_step"
  - "Initial theme generation with GTK 4 template sanitization and fail-soft color fallback in bootstrap.sh"
  - "Section 4 isolated scratch drill verifying destubbing, Catppuccin pruning, and fallback theming"
  - "Section 5 full v0.5 multi-phase regression sweep across Phases 25, 26, 27, and 28"
  - "Passing complete assertion suite bash scripts/phase29-theme-data-contracts-assert.sh with FAIL=0 FINDINGS=0"
  - "Passing strict repository verifier arch/dots-hyprland.sh verify --strict with FAIL=0 FINDINGS=0"
affects:
  - bootstrap.sh
  - scripts/phase29-theme-data-contracts-assert.sh
tech-stack:
  added: []
  patterns:
    - "Asynchronous background process mtime polling loop for kdeglobals"
    - "Fail-soft initial theme generation falling back to color seed #3f51b5 when wallpaper is absent"
    - "Hierarchical prefix walk for is_guarded_path in bootstrap.sh"
    - "Directory pre-creation to defeat GNU Stow directory folding"
    - "Multi-phase regression sweep harness verifying cross-milestone guarantees"
key-files:
  modified:
    - bootstrap.sh
    - scripts/phase29-theme-data-contracts-assert.sh
key-decisions:
  - "Polled kdeglobals mtime with a 3-second timeout to handle asynchronous handle_kde_material_you_colors execution in switchwall.sh without porcelain race conditions."
  - "Implemented ancestor traversal in bootstrap.sh is_guarded_path() ensuring parity with arch/dots-hyprland.sh."
  - "Added explicit Catppuccin symlink pruning in bootstrap.sh run_destub targeting /usr/share/themes/Catppuccin* while strictly protecting guarded gtk.css."
  - "Pre-created sensitive directories (.config/fuzzel, .config/kitty, .config/gtk-3.0, .config/gtk-4.0, .config/hypr/custom, .config/systemd/user) before running stow to prevent stow directory folding."
  - "Sanitized .boxed-list row:insensitive to .boxed-list row:disabled in matugen GTK 4 template and added color seed fallback #3f51b5 for headless or missing wallpaper deployments."
  - "Implemented Section 5 regression sweep running phase25, phase26, phase27, and phase28 suites with zero git churn."
requirements-completed: [INTG-01, INTG-02, INTG-03]
duration: "5 min"
completed: "2026-09-18T09:55:00Z"
coverage:
  - deliverable: "Section 2 live zero git churn drill with switchwall.sh and kdeglobals polling"
    verification:
      kind: command
      ref: "bash scripts/phase29-theme-data-contracts-assert.sh --section 2"
      status: pass
    human_judgment: false
  - deliverable: "Harden bootstrap orchestrator & Section 4 scratch isolation drill"
    verification:
      kind: command
      ref: "bash scripts/phase29-theme-data-contracts-assert.sh --section 4"
      status: pass
    human_judgment: false
  - deliverable: "Section 5 multi-phase regression sweep and full suite verification"
    verification:
      kind: command
      ref: "bash scripts/phase29-theme-data-contracts-assert.sh && ./arch/dots-hyprland.sh verify --strict"
      status: pass
    human_judgment: false
---

# Phase 29 Plan 02: Bootstrap Integration, Live Churn Drill & Regression Sweep Summary

Completed Plan 29-02 by implementing Section 2 live zero git churn drill with race-free asynchronous `kdeglobals` polling, hardening `bootstrap.sh` with hierarchical prefix guard matching, Catppuccin pruning, sensitive parent directory pre-creation, and fail-soft initial theme generation, verifying Section 4 in an isolated scratch environment, and implementing Section 5 full v0.5 multi-phase regression sweep across Phases 25–28.

## Key Changes

1. **Section 2 Live Zero Git Churn Drill (`scripts/phase29-theme-data-contracts-assert.sh`):**
   - Implemented Section 2 asserting monotonic mtime advancement across all 5 dynamic theme outputs (`fuzzel_theme.ini`, `kitty-theme.conf`, `gtk.css`, `colors.lua`, `kdeglobals`).
   - Integrated race-free polling for `kdeglobals` mtime (up to 15 iterations $\times$ 0.2s) to accommodate the background `handle_kde_material_you_colors &` dispatch in `switchwall.sh`.
   - Captured pre- and post-drill git status porcelain snapshots, confirming byte-identical repository state with zero git churn.

2. **Bootstrap Orchestrator Hardening (`bootstrap.sh`):**
   - **Hierarchical Prefix Matching (D-02):** Replaced flat lookup in `is_guarded_path()` with an ancestor directory traversal up to root, matching nested guarded outputs like `Kvantum/` and `kde-material-you-colors/`.
   - **Legacy Catppuccin Pruning (D-11):** Updated `run_destub()` to inspect `gtk-3.0` and `gtk-4.0` for symlinks pointing to `/usr/share/themes/Catppuccin*` and safely unlink them while keeping guarded `gtk.css` intact.
   - **Parent Directory Pre-Creation (D-10):** Updated `run_stow_step()` to create physical directories (`.config/fuzzel`, `.config/kitty`, `.config/gtk-3.0`, `.config/gtk-4.0`, `.config/hypr/custom`, `.config/systemd/user`) prior to running GNU Stow, preventing directory folding.
   - **Fail-Soft Initial Theme Generation (D-12, D-13):** Created `generate_initial_theme()` in Step 6 to sanitize `.boxed-list row:insensitive` into `.boxed-list row:disabled` in the Matugen GTK 4 template, check for wallpaper presence via `jq`, and fall back to `switchwall.sh --color "#3f51b5"` if wallpaper is missing or if theme generation encounters errors.
   - **Strict Verification Integration:** In Step 7 `step_verify()`, enabled `dotfiles-capture.timer` and bound exit status 1:1 to `arch/dots-hyprland.sh verify --strict`.

3. **Section 4 Scratch Isolation Drill (`scripts/phase29-theme-data-contracts-assert.sh`):**
   - Implemented an isolated scratch harness (`$S4_ROOT` with mock `$MOCK_HOME` and `$MOCK_REPO`) asserting nested guard recognition, Catppuccin symlink pruning without touching guarded files, directory pre-creation, and fail-soft color fallback theme generation.

4. **Section 5 Multi-Phase Regression Sweep (`scripts/phase29-theme-data-contracts-assert.sh`):**
   - Implemented sequential execution of all prior Milestone v0.5 test suites:
     - `scripts/phase25-gtk-material-you-assert.sh` (GTK theming & Catppuccin de-linking)
     - `scripts/phase26-qt-kde-material-you-assert.sh` (Qt & KDE harmonization)
     - `scripts/phase27-accent-coordination-assert.sh` (Hyprland & Quickshell accent coordination)
     - `scripts/phase28-terminal-fuzzel-assert.sh` (Terminal & Fuzzel dynamic palette)
   - Validated that all four milestone suites execute cleanly with zero failures and maintain zero git working tree churn.

5. **Complete Suite Sign-off:**
   - Executed `bash scripts/phase29-theme-data-contracts-assert.sh && ./arch/dots-hyprland.sh verify --strict`, achieving `FAIL=0 FINDINGS=0` across all 5 sections and the strict repository verifier.

## Self-Check: PASSED

- All 3 plan tasks completed and committed atomically
- All acceptance criteria satisfied
- Full assertion harness (`phase29-theme-data-contracts-assert.sh`) passed with `FAIL=0 FINDINGS=0`
- Strict repository verifier (`arch/dots-hyprland.sh verify --strict`) passed with `FAIL=0 FINDINGS=0`
- Zero uncommitted working tree churn
