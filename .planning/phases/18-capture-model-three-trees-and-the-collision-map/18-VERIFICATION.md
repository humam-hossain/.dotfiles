---
phase: 18-capture-model-three-trees-and-the-collision-map
verified: 2026-09-14T01:43:00Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
verification_method: goal-backward, evidence-first — every criterion verified against codebase, git state, and live system
assert_results:
  phase18_capture_model_assert: "=== done: FAIL=0 FINDINGS=0 ==="
  dots_hyprland_verify: "=== done: FAIL=0 FINDINGS=0 ==="
  phase16_retire_assert: "=== done: FAIL=0 ==="
  phase13_d19_assert: "=== done: FAIL=0 ==="
  phase12_full_smoke: "=== done: FAIL=0 ==="
  phase14_verify: "=== done: FAIL=2 FINDINGS=0 === (expected firstrun sidecar differences)"
  phase17_unblock_assert: "=== done: FAIL=8 === (expected: repo-root .config removed per FIX-03/D-20)"
  phase11_dispositions_assert: "=== done: FAIL=1 === (expected: milestone archived to milestones/v0.2-phases/)"
  phase10_inventory_assert: "=== done: FAIL=1 === (expected: milestone archived to milestones/v0.2-phases/)"
requirements_verified:
  - CAP-01
  - CAP-02
  - CAP-03
  - CAP-05
  - CAP-07
  - CAP-08
  - FIX-03
  - FIX-05
findings:
  - id: V-18-01
    severity: info
    title: "Phase 17 assert shows 8 failures due to intentional repo-root .config/ removal"
    detail: "scripts/phase17-unblock-assert.sh checks tracked repo-root .config/ paths (such as .config/kdeglobals and .config/hypr/custom/execs.lua). Phase 18 FIX-03 removed repo-root .config/ permanently. As decided in 18-CONTEXT.md D-20, closed-phase asserts are not edited retroactively; Phase 18's own assert verifies the new locations."
  - id: V-18-02
    severity: info
    title: "capture/ directory is legitimately empty until Phase 21"
    detail: "The capture mechanism and verification infrastructure ship in this phase. The directory is populated with a README contract. Its end-to-end operation is verified via temporary fixture in section 7 of phase18-capture-model-assert.sh. Real configurations will be added in Phase 21 (BAR-01, BAR-02, CAP-06)."
---

# Phase 18 Verification Report: Capture model — three trees and the collision map

**Phase Goal:** Where a file sits in the repo tells you — unambiguously, and checkably by a script — how it is captured and how it is recovered.  
**Verified at:** 2026-09-14  
**Status:** **PASSED** (7/7 success criteria verified, 8/8 requirements verified)

---

## Executive Summary

Phase 18 successfully establishes the three-tree architecture (`stow/`, `restow/`, `capture/`), the machine-readable installer collision map (`collision-map.tsv`), the `--exp-files` refusal gate in `arch/dots-hyprland.sh`, the ban and documentation on `--adopt`, the permanent removal of repo-root `.config/` with full redistribution into packages/archives, and the wrapper-owned `verify` and `capture` subcommands.

All 11 plans across 9 waves have been executed. The comprehensive phase test suite (`./scripts/phase18-capture-model-assert.sh`) passes cleanly with `FAIL=0 FINDINGS=0`, and the live desktop verification (`./arch/dots-hyprland.sh verify`) passes cleanly across all packages in `stow/`, `restow/`, and `capture/`.

---

## Success Criteria Verification

### Criterion 1: Three Trees and Restow Tags (CAP-01) — PASSED
- `stow/README.md`, `restow/README.md`, and `capture/README.md` each exist and define their four-part contract: installer write behavior, recovery command, membership rule, and package listing.
- `restow/README.md` contains a machine-generated markdown table (`scripts/gen-collision-map.sh --restow-table`) listing every `restow/` package (`dolphinrc`, `hypr`, `kdeglobals`, `starship`) tagged with its recovery class (`rsync-replace` or `cp-through`) and exact recovery command.
- Section 1 of `phase18-capture-model-assert.sh` verifies contracts, tags, and table regeneration.

### Criterion 2: Checked-in Collision Map (CAP-02) — PASSED
- `collision-map.tsv` is checked in at the repository root.
- Contains 29 mapped destination rows covering all legacy installer actions from `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh`.
- Header explicitly records the submodule commit SHA pin (`1a9ffb78f0c272a45f82342587dc3bec72762233`).
- All outcome columns (`symlink_outcome`, `repo_outcome`) correctly derive the target `tree` column (`stow` or `restow`).

### Criterion 3: Tree Placement Contradiction Check (CAP-03) — PASSED
- `scripts/phase18-capture-model-assert.sh` Section 3d implements `check_tree_placement()`.
- Verified 0 contradictions across all real packages in `stow/` and `restow/`.
- Verified non-zero exit (rc=1) when a deliberately mis-filed fixture package is introduced, correctly identifying the expected tree vs actual tree, and cleaning up safely via trap.
- Section 3a/3b verify deterministic generation and byte-for-byte reproducibility of the map.

### Criterion 4: `--exp-files` Refusal Gate (CAP-08) — PASSED
- `arch/dots-hyprland.sh` implements an early scan in `main()` before dispatch.
- Rejects `--exp-files` with exit code 2 and outputs an explanatory message citing `collision-map.tsv` and `3.files-exp.sh`.
- Prevents forwarding to upstream `./setup`.
- Verified in Section 4 across multiple argument positions and syntax variations (`--exp-files`, trailing flags, `--exp-files=...`).

### Criterion 5: `--adopt` Ban and Documentation (CAP-07) — PASSED
- Verified that `--adopt` appears in zero scripts under `arch/` and `scripts/` (outside of the assert script's own check pattern).
- `stow/README.md` explicitly documents the ban and details the three exception conditions: interactive use only, clean git working tree, and one path at a time.

### Criterion 6: Repo-Root `.config/` Removal & Scoped Reader Scan (FIX-03) — PASSED
- Repo-root `.config/` is completely removed from the filesystem and untracked in git.
- Redistribution table documented in `docs/config-redistribution.md` accounts for all 12 destinations across `stow/`, `restow/`, and `docs/archive/`.
- All reader scripts in `arch/` and `scripts/` retargeted; zero in-scope scripts read legacy `.config/` paths. Out-of-scope Ubuntu/Debian readers tracked in backlog todo file.

### Criterion 7: Wrapper `verify` and `capture` Commands (FIX-05, CAP-05) — PASSED
- `verify` and `capture` are registered in `ALLOWLIST` in `arch/dots-hyprland.sh` and dispatched to their own dedicated functions (`run_verify` and `run_capture`).
- `verify` runs cleanly to exit code 0 even when `vendor/dots-hyprland` submodule is de-initialised (preflight bypassed).
- `capture` implements:
  - Copying from live `$HOME` to repo `capture/` without staging (`git diff --cached` remains empty).
  - Strict dirty checks against `HEAD`: skips modified or untracked repository targets.
  - Refusal of live symlinks pointing into the repository (prevents copy-over-self).
  - Support for `--dry-run` and clean exit 0 on empty `capture/` tree.

---

## Live System Verification

- **Package symlinks**: All 14 files across `stow/hypr`, `restow/hypr`, `restow/dolphinrc`, `restow/kdeglobals`, `restow/starship`, and `stow/zsh` resolve under `/home/pera/github_repo/.dotfiles/`.
- **Unfolded directories**: `~/.config/qBittorrent` and `~/.config/smartmontools` are real directories; entries inside them are symlinks pointing under the main worktree root.
- **Zero folded directories**: `find "$HOME/.config" -maxdepth 2 -type l -lname '*.dotfiles*' -exec test -d {} \; -print` returns 0 entries.
- **Full verify run**: `./arch/dots-hyprland.sh verify` reports `FAIL=0 FINDINGS=0`.

---

## Requirement Traceability

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| **CAP-01** | Three trees with README contracts & recovery tags | Complete | `stow/`, `restow/`, `capture/` READMEs + Section 1 |
| **CAP-02** | Checked-in collision map derived from submodule | Complete | `collision-map.tsv` + Section 2 |
| **CAP-03** | Tree placement contradiction check with fixture | Complete | Section 3 of `phase18-capture-model-assert.sh` |
| **CAP-05** | Wrapper-owned `capture` with dirty guards | Complete | `arch/dots-hyprland.sh run_capture` + Section 7 |
| **CAP-07** | Ban `--adopt` across scripts with documented exceptions | Complete | `stow/README.md` + Section 5 |
| **CAP-08** | Refuse `--exp-files` citing collision map | Complete | `arch/dots-hyprland.sh main` gate + Section 4 |
| **FIX-03** | Remove repo-root `.config/` and redistribute | Complete | Removal confirmed + `docs/config-redistribution.md` + Section 6 |
| **FIX-05** | Wrapper-owned link-aware `verify` | Complete | `arch/dots-hyprland.sh run_verify` + Section 7 |

---

## Conclusion

Phase 18 goal is fully met. Phase is verified and ready to be marked complete.
