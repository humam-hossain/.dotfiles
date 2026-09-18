# Roadmap: Quickshell Desktop Shell

## Milestones

- ✅ **v0.1 Core Framework & Basic Bar** — Phases 1–4 (shipped 2026-07-25)
- ✅ **v0.2 Adopt dots-hyprland** — Phases 5–9 (shipped 2026-08-02)
- ✅ **v0.3 Full ii install** — Phases 10–16 (shipped 2026-09-09)
- ✅ **v0.4 Personal config layer** — Phases 17–24 (shipped 2026-09-16)
- 🟡 **v0.5 System-wide Material You theming** — Phases 25–30 (in progress)

## Phases

<details>
<summary>✅ v0.1 Core Framework & Basic Bar (Phases 1-4) — SHIPPED 2026-07-25</summary>

- [x] Phase 1: Shell Foundation & Theme (4/4 plans) — completed 2026-07-21
- [x] Phase 2: Core Bar Modules (13/13 plans) — completed 2026-07-23
- [x] Phase 3: System & Audio Modules (10/10 plans) — completed 2026-07-24
- [x] Phase 4: IPC, Keybinds & Integration (4/4 plans) — completed 2026-07-25

Full phase details: [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)  
Requirements archive: [milestones/v0.1-REQUIREMENTS.md](milestones/v0.1-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.1-phases/](milestones/v0.1-phases/)

</details>

<details>
<summary>✅ v0.2 Adopt dots-hyprland (Phases 5-9) — SHIPPED 2026-08-02</summary>

- [x] Phase 5: Fork & Submodule Pin (3/3 plans) — completed 2026-07-25
- [x] Phase 6: Thin Setup Wrapper & Safe Defaults (3/3 plans) — completed 2026-07-26
- [x] Phase 7: Install, Session Hooks & Dual-Run Verify (3/3 plans) — completed 2026-07-27
- [x] Phase 8: Retire Local Quickshell Product (3/3 plans) — completed 2026-07-28
- [x] Phase 9: Workflow Documentation & Update Contract (3/3 plans) — completed 2026-08-01

Full phase details: [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)  
Requirements archive: [milestones/v0.2-REQUIREMENTS.md](milestones/v0.2-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.2-phases/](milestones/v0.2-phases/)

</details>

<details>
<summary>✅ v0.3 Full ii install (Phases 10-16) — SHIPPED 2026-09-09</summary>

- [x] Phase 10: Full-install impact inventory (5/5 plans) — completed 2026-08-07
- [x] Phase 11: Disposition decisions (4/4 plans) — completed 2026-08-10
- [x] Phase 12: Wrapper full-profile (4/4 plans) — completed 2026-08-18
- [x] Phase 13: Personal hypr/custom overlays (2/2 plans) — completed 2026-08-31
- [x] Phase 14: Live full adopt & verify (2/2 plans) — completed 2026-09-05
- [x] Phase 15: Playbook safe vs full (6/6 plans) — completed 2026-09-06
- [x] Phase 16: Retire the safe profile (10/10 plans) — completed 2026-09-08

Full phase details: [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)  
Requirements archive: [milestones/v0.3-REQUIREMENTS.md](milestones/v0.3-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.3-phases/](milestones/v0.3-phases/)  
Milestone audit: [milestones/v0.3-MILESTONE-AUDIT.md](milestones/v0.3-MILESTONE-AUDIT.md)

</details>

<details>
<summary>✅ v0.4 Personal config layer (Phases 17-24) — SHIPPED 2026-09-16</summary>

- [x] Phase 17: Unblock stow and restore the session target (7/7 plans) — completed 2026-09-13
- [x] Phase 18: Capture model — three trees and the collision map (11/11 plans) — completed 2026-09-14
- [x] Phase 19: Link-aware `verify` (5/5 plans) — completed 2026-09-14
- [x] Phase 20: hypr/custom overlays and startup restore (5/5 plans) — completed 2026-09-14
- [x] Phase 21: ii bar config capture (3/3 plans) — completed 2026-09-15
- [x] Phase 22: KDE and GTK capture (4/4 plans) — completed 2026-09-15
- [x] Phase 23: One-command bootstrap (3/3 plans) — completed 2026-09-15
- [x] Phase 24: Address tech debt: bookkeeping and validation cleanup (3/3 plans) — completed 2026-09-16

Full phase details: [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)  
Requirements archive: [milestones/v0.4-REQUIREMENTS.md](milestones/v0.4-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.4-phases/](milestones/v0.4-phases/)  
Milestone audit: [milestones/v0.4-MILESTONE-AUDIT.md](milestones/v0.4-MILESTONE-AUDIT.md)

</details>

### v0.5 System-wide Material You theming (Phases 25-30)

- [x] **Phase 25: GTK Material You Theming & Catppuccin De-linking** (0/3 plans) — Retire legacy Catppuccin assets/symlinks from `~/.config/gtk-4.0/` and `stow/gtk/`, configure `adw-gtk3` base theme, and wire Matugen dynamic GTK-3/4 CSS generation from wallpaper. (completed 2026-09-16)
- [x] **Phase 26: Qt & KDE Apps Material You Harmonization** — Align Qt 5/6, Kvantum, and KDE applications (Dolphin, Kate) with Material You color palette and dynamic wallpaper updates. (completed 2026-09-17)
- [x] **Phase 27: Hyprland & Quickshell ii Accent Coordination** — Coordinate Hyprland window decorations, active/inactive borders, and Quickshell ii widget accents with Matugen generated colors and wallpaper reload. (completed 2026-09-17)
- [x] **Phase 28: Terminal & Fuzzel Launcher Dynamic Palette** — Extend dynamic Material You styling to Fuzzel app launcher and terminal emulators. (completed 2026-09-17)
- [x] **Phase 29: Theme Data Contracts, Verification & Bootstrap Integration** (0/2 plans) — Reconcile `guard-paths.tsv`, update `collision-map.tsv`, verify zero git churn on theme generation, and validate `./bootstrap.sh`. (completed 2026-09-18)
- [x] **Phase 30: Address tech debt: v0.5 cleanup and validation sign-off** — Address tech debt, reconcile validation gaps, and complete validation sign-off for milestone v0.5. (completed 2026-09-18)

## Phase Details

### Phase 25: GTK Material You Theming & Catppuccin De-linking

- **Goal:** Retire legacy Catppuccin assets/symlinks from `~/.config/gtk-4.0/` and `stow/gtk/`, configure `adw-gtk3` base theme, and wire Matugen dynamic GTK-3/4 CSS generation from wallpaper.
- **Requirements:** GTK-01, GTK-02, GTK-03, GTK-04
- **Success Criteria:**
  1. Legacy Catppuccin symlinks in `~/.config/gtk-4.0/` are safely unlinked and replaced with upstream libadwaita styling.
  2. `stow/gtk/.config/gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` specify `adw-gtk3` / dark theme without Catppuccin references.
  3. Running Matugen generates valid `~/.config/gtk-3.0/gtk.css` with colors derived from the active wallpaper.
  4. GNOME gsettings interface keys (`gtk-theme`, `color-scheme`) are aligned to dark Material You theme.
- **Plans:** 4/4 plans complete

Plans:

- [x] 25-04-PLAN.md

**Wave 1**

- [x] 25-01-PLAN.md — tracer: Phase 25 assertion harness scaffolding and safe Catppuccin symlink de-linking in `~/.config/gtk-4.0/`

**Wave 2**

- [x] 25-02-PLAN.md — repository GTK 3/4 settings alignment in `stow/gtk/` and GNOME desktop interface GSettings synchronization

**Wave 3**

- [x] 25-03-PLAN.md — dynamic Matugen GTK CSS generation, strict repository verification, and validation sign-off

### Phase 26: Qt & KDE Apps Material You Harmonization

- **Goal:** Align Qt 5/6, Kvantum, and KDE applications (Dolphin, Kate) with Material You color palette and dynamic wallpaper updates.
- **Requirements:** QT-01, QT-02, QT-03
- **Success Criteria:**
  1. Qt applications load Kvantum engine configured with dots-hyprland Material theme.
  2. `kde-material-you-colors` script executes on wallpaper update, refreshing `~/.config/kdeglobals` color tokens without manual file edits.
  3. Dolphin and KDE file dialogs render consistently with the dark dynamic Material palette.
- **Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 26-01-PLAN.md — tracer: Guard path registration and Phase 26 assertion harness scaffolding with virtualenv & environment assertions (Sections 1 & 2)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 26-02-PLAN.md — Qt style engine alignment and dynamic Material You color generation pipeline verification (Sections 3 & 4)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 26-03-PLAN.md — Desktop file picker portal integration, KDE applications verification, strict repository verification, and validation sign-off (Section 5)

### Phase 27: Hyprland & Quickshell ii Accent Coordination

- **Goal:** Coordinate Hyprland window decorations, active/inactive borders, and Quickshell ii widget accents with Matugen generated colors and wallpaper reload.
- **Requirements:** SHELL-01, SHELL-02, SHELL-03
- **Success Criteria:**
  1. Hyprland active border colors bind directly to Matugen `colors.lua` palette values.
  2. Quickshell ii top bar icons, metric rings, and active states reflect Material You palette tokens.
  3. Invoking `switchwall.sh` triggers wallpaper transition and propagates palette updates to Hyprland borders, Quickshell, GTK, and Qt in one coordinated flow.
- **Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 27-01-PLAN.md — tracer: Phase 27 assertion harness scaffolding, template & config readiness, and upstream overlay purity (Section 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 27-02-PLAN.md — Hyprland window borders & compositor token match and Quickshell ii token schema & appearance integrity (Sections 2 & 3)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 27-03-PLAN.md — Live coordinated wallpaper reload probe, strict repository verification, zero git drift, and validation sign-off (Sections 4 & 5)

### Phase 28: Terminal & Fuzzel Launcher Dynamic Palette

- **Goal:** Extend dynamic Material You styling to Fuzzel app launcher and terminal emulators.
- **Requirements:** TERM-01, TERM-02
- **Success Criteria:**
  1. Fuzzel launcher sources `~/.config/fuzzel/fuzzel_theme.ini` generated by Matugen on wallpaper change.
  2. Primary terminal emulator (Foot, Kitty, or Alacritty) dynamically reloads colors to match the active wallpaper palette.

### Phase 29: Theme Data Contracts, Verification & Bootstrap Integration

- **Goal:** Reconcile `guard-paths.tsv`, update `collision-map.tsv`, verify zero git churn on theme generation, and validate `./bootstrap.sh`.
- **Requirements:** INTG-01, INTG-02, INTG-03
- **Success Criteria:**
  1. `guard-paths.tsv` accurately includes all dynamic outputs (`kdeglobals`, `gtk-3.0/gtk.css`, `hyprland/colors.lua`, `fuzzel_theme.ini`, etc.) and prevents repository churn.
  2. `arch/dots-hyprland.sh verify --strict` exits 0 with 0 findings.
  3. `./bootstrap.sh` runs cleanly without manual interventions or conflicting legacy stubs.
- **Plans:** 2/2 plans complete

Plans:

**Wave 1**

- [x] 29-01-PLAN.md — tracer: Data contracts, .gitignore parity, three-tree taxonomy reconciliation (relocate fuzzel & kitty to restow/), arch/kitty.sh update, live symlink re-pointing, and verifier hierarchical prefix matching (INTG-01, INTG-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 29-02-PLAN.md — Bootstrap orchestrator enhancements (destub Catppuccin pruning, parent dir pre-creation, fallback theme generation) and authoring 5-section test suite scripts/phase29-theme-data-contracts-assert.sh with full v0.5 regression sweep (INTG-01, INTG-02, INTG-03)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Shell Foundation & Theme | v0.1 | 4/4 | Complete | 2026-07-21 |
| 2. Core Bar Modules | v0.1 | 13/13 | Complete | 2026-07-23 |
| 3. System & Audio Modules | v0.1 | 10/10 | Complete | 2026-07-24 |
| 4. IPC, Keybinds & Integration | v0.1 | 4/4 | Complete | 2026-07-25 |
| 5. Fork & Submodule Pin | v0.2 | 3/3 | Complete | 2026-07-25 |
| 6. Thin Setup Wrapper & Safe Defaults | v0.2 | 3/3 | Complete | 2026-07-26 |
| 7. Install, Session Hooks & Dual-Run Verify | v0.2 | 3/3 | Complete | 2026-07-27 |
| 8. Retire Local Quickshell Product | v0.2 | 3/3 | Complete | 2026-07-28 |
| 9. Workflow Documentation & Update Contract | v0.2 | 3/3 | Complete | 2026-08-01 |
| 10. Full-install impact inventory | v0.3 | 5/5 | Complete | 2026-08-07 |
| 11. Disposition decisions | v0.3 | 4/4 | Complete | 2026-08-10 |
| 12. Wrapper full-profile | v0.3 | 4/4 | Complete | 2026-08-18 |
| 13. Personal hypr/custom overlays | v0.3 | 2/2 | Complete | 2026-08-31 |
| 14. Live full adopt & verify | v0.3 | 2/2 | Complete | 2026-09-05 |
| 15. Playbook safe vs full | v0.3 | 6/6 | Complete | 2026-09-06 |
| 16. Retire the safe profile | v0.3 | 10/10 | Complete | 2026-09-08 |
| 17. Unblock stow and restore the session target | v0.4 | 7/7 | Complete | 2026-09-13 |
| 18. Capture model — three trees and the collision map | v0.4 | 11/11 | Complete | 2026-09-14 |
| 19. Link-aware `verify` | v0.4 | 5/5 | Complete | 2026-09-14 |
| 20. hypr/custom overlays and startup restore | v0.4 | 5/5 | Complete | 2026-09-14 |
| 21. ii bar config capture | v0.4 | 3/3 | Complete | 2026-09-15 |
| 22. KDE and GTK capture | v0.4 | 4/4 | Complete | 2026-09-15 |
| 23. One-command bootstrap | v0.4 | 3/3 | Complete | 2026-09-15 |
| 24. Address tech debt: bookkeeping and validation cleanup | v0.4 | 3/3 | Complete | 2026-09-16 |
| 25. GTK Material You Theming & Catppuccin De-linking | v0.5 | 4/4 | Complete    | 2026-09-17 |
| 26. Qt & KDE Apps Material You Harmonization | v0.5 | 3/3 | Complete    | 2026-09-17 |
| 27. Hyprland & Quickshell ii Accent Coordination | v0.5 | 3/3 | Complete    | 2026-09-17 |
| 28. Terminal & Fuzzel Launcher Dynamic Palette | v0.5 | 3/3 | Complete    | 2026-09-17 |
| 29. Theme Data Contracts, Verification & Bootstrap Integration | v0.5 | 2/2 | Complete    | 2026-09-18 |
| 30. Address tech debt: v0.5 cleanup and validation sign-off | v0.5 | 2/2 | Complete    | 2026-09-18 |

**Coverage:** v0.1–v0.4 shipped · v0.5 in progress — 19/19 requirements mapped across Phases 25–30, 0 unmapped

### Phase 30: Address tech debt: v0.5 cleanup and validation sign-off

- **Goal:** Address accumulated technical debt, visual polish preferences, environment fallback robustness, and validation coverage gaps from Milestone v0.5 audit, establishing 100% Nyquist compliance and multi-phase regression coverage.
- **Requirements:** DEBT-05, DEBT-06, DEBT-07, DEBT-08
- **Depends on:** Phase 29
- **Success Criteria:**
  1. Kitty background opacity is set to 0.90 in restow and asserted with tolerance in phase28 test harness.
  2. Bootstrap exports virtualenv fallback and applies idempotent sanitization for template wrapper and applycolor signaling.
  3. Phase 29 validation sign-off is completed with 100% Nyquist compliance across all Milestone v0.5 phases (25–30).
  4. Phase 30 assert harness passes all 5 sections, strict repository verification passes with 0 findings, and git working tree remains byte-identical clean.
- **Plans:** 2/2 plans complete

Plans:

**Wave 1**

- [x] 30-01-PLAN.md — Visual polish, environment fallback, and script signaling robustness (DEBT-05, DEBT-06)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 30-02-PLAN.md — Validation sign-off, Phase 30 assert harness, full regression sweep, and milestone closeout readiness (DEBT-07, DEBT-08)

---
*Last updated: 2026-09-18 during Phase 30 tech debt execution*
