# Roadmap: Quickshell Desktop Shell

## Milestones

- ✅ **v0.1 Core Framework & Basic Bar** — Phases 1–4 (shipped 2026-07-25)
- ✅ **v0.2 Adopt dots-hyprland** — Phases 5–9 (shipped 2026-08-02)

## Overview

Desktop shell delivery model: adopt [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) as a managed dependency (personal fork + `vendor/dots-hyprland` submodule + thin `arch/dots-hyprland.sh` wrapper). Live session dual-runs `qs -c ii` beside Waybar. Next milestone work is customization/parity (Waybar ports) and eventual cutover — define via `/gsd-new-milestone`.

**Phase numbering:** Continues after v0.2 (last phase **9**). Next milestone starts at **Phase 10**.

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

### Next milestone (not yet defined)

Define with `/gsd-new-milestone`. Expected direction from v0.2 future requirements:

- Waybar custom ports into ii (ping, weather, earthquake, machine overlays)
- Dual-run cutover once parity accepted
- Optional polish (wrapper verify, keybind/auto-start under upstream model)

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

**Coverage:** v0.1 shipped · v0.2 shipped (15/15 requirements) · next milestone TBD

---
*Last updated: 2026-08-02 — v0.2 milestone archived and closed*
