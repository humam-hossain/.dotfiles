---
phase: 09-workflow-documentation-update-contract
plan: 03
subsystem: docs
tags: [dots-hyprland, README, PROJECT, DOC-01, DOC-02, discovery]

requires:
  - phase: 09-workflow-documentation-update-contract
    provides: 09-01/09-02 playbook Install + Update + Non-goals
provides:
  - README discovery link to playbook
  - PROJECT workflow doc item closed
  - DOC-01/DOC-02 marked complete with playbook path
  - See also cross-links
affects:
  - verify-work / phase complete for v0.2 docs

tech-stack:
  added: []
  patterns:
    - "Thin README pointer; playbook owns full contract"

key-files:
  created: []
  modified:
    - README.md
    - .planning/PROJECT.md
    - .planning/REQUIREMENTS.md
    - docs/dots-hyprland-workflow.md

key-decisions:
  - "README Desktop shell section before Neovim/Tmux"
  - "DOC-01/DOC-02 checkboxes flipped after greps green"
  - "arch/quickshell.sh only as retired framing on product paths"

patterns-established:
  - "Discovery = README link; depth = docs/ playbook"

requirements-completed: [DOC-01, DOC-02]

coverage:
  - id: D1
    description: "README links docs/dots-hyprland-workflow.md"
    requirement: DOC-01
    verification:
      - kind: other
        ref: "rg dots-hyprland-workflow README.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "PROJECT workflow doc item closed with playbook path"
    requirement: DOC-02
    verification:
      - kind: other
        ref: "rg dots-hyprland-workflow .planning/PROJECT.md"
        status: pass
    human_judgment: false
  - id: D3
    description: "Full DOC suite greps green; no instructional quickshell.sh"
    requirement: DOC-01
    verification:
      - kind: other
        ref: "full suite + git grep arch/quickshell.sh on README/docs/arch"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-08-01
status: complete
---

# Phase 09: Plan 03 — Discovery Cross-links Summary

**Cold clone can find install+update contracts from README → playbook; PROJECT doc task closed.**

## Accomplishments

- Root README: Desktop shell section → `docs/dots-hyprland-workflow.md`
- PROJECT: workflow documentation checkbox done + last updated
- Playbook See also: PROJECT, REQUIREMENTS, ROADMAP, README
- REQUIREMENTS: DOC-01/DOC-02 checked with playbook path; trace table Complete
- Full DOC suite greps green; product-facing `arch/quickshell.sh` only retired framing

## Task Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 README link | `d0cb248` | docs(09-03): link dots-hyprland playbook from root README |
| 2–3 PROJECT/See also/suite | `b6a5f94` | docs(09-03): close PROJECT doc item and cross-link playbook |

## Deviations from Plan

None material — Task 3 greps run at close-out; no product-facing instructional quickshell.sh to fix.

## Self-Check: PASSED

- Full suite automated greps — pass
- `test ! -e arch/quickshell.sh` — pass
- Neovim/Tmux sections preserved — pass
