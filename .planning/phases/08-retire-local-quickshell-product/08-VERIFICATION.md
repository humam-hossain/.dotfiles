---
phase: 08-retire-local-quickshell-product
verified: 2026-07-28
status: passed
verifier: orchestrator-inline
---

# Phase 8 Verification Report

## Goal-backward result: PASSED

Phase goal: *Single product path — remove the v0.1 in-repo Quickshell tree and old installer.*

| Success criterion | Result | Evidence |
|-------------------|--------|----------|
| 1. `.dotfiles` no longer ships the v0.1 `.config/quickshell` product tree as an installable source | PASS | `test ! -e REPO/.config/quickshell`; commit `fb91789` (933 files / 77826 deletions) |
| 2. `arch/quickshell.sh` is gone or is only a deprecation stub pointing at the new wrapper | PASS | Hard-deleted (no stub): `test ! -e arch/quickshell.sh`; commit `81ac1e0`; sole entry `arch/dots-hyprland.sh` executable |
| 3. Live session still runs ii from installed `~/.config/quickshell` after retirement (no symlink-at-repo) | PASS | `! -L`, `-f ii/shell.qml`, `readlink -f` → `/home/pera/.config/quickshell` (not under `.dotfiles`); venv present; repo hypr still has `qs -c ii` |

## Requirements

| ID | Result |
|----|--------|
| RET-01 | PASS — in-repo product tree removed; live home path untouched |
| RET-02 | PASS — installer hard-deleted; zero active refs under arch/scripts/.config; Pattern comment reworded |

## Plan summaries

| Plan | Self-Check | Spot-check |
|------|------------|------------|
| 08-01 | PASSED | All hard live-health asserts green; reinstall SKIPPED; in-repo tree still present pre-delete |
| 08-02 | PASSED | `git rm -rf` 933 files; live hold green; installer still present until 08-03; D-04 expected red noted |
| 08-03 | PASSED | Installer gone; Pattern reword `cb4f6a0`; full post-retirement assert set green |

### Note on automated verify-summary

`gsd-tools verify-summary` reported false missing files for 08-02/08-03 because SUMMARY `key-files` listed home paths (`~/.config/...`) and intentionally **absent** artifacts (`arch/quickshell.sh` after delete). Orchestrator re-checked:

- `$HOME/.config/quickshell/ii/shell.qml` **exists** (tilde not expanded by tool)
- `arch/quickshell.sh` **must be absent** for RET-02 (tool treated as required present)

Self-check markers and goal-backward asserts override those false negatives.

## Locked decisions honored (highlights)

| Decision | Honored |
|----------|---------|
| D-01 live health before delete | yes (08-01) |
| D-02 reinstall only via wrapper if needed | yes (skipped — health green) |
| D-03 no phase08 smoke; phase07 not Phase 8 gate | yes |
| D-04 hard-delete installer, no stub | yes (08-03) |
| D-05 no package uninstall | yes |
| D-07 full tree remove via git | yes (08-02) |
| D-08 discard WIP without salvage | yes (3 dirty QML files force-removed) |
| D-09 separate atomic commits | yes (tree / installer / comment) |
| D-10 no recovery tag | yes |
| D-11 minimal ref cleanup only | yes (Pattern reword; zero product-path hits) |
| D-12 leave historical scripts | yes (phase07/phase04 untouched) |
| D-13 wrapper sole install entry | yes |
| D-14 never delete live home as retirement | yes (REPO-scoped only) |
| D-15 never re-symlink live→repo | yes |

## Prohibitions honored

- No recursive remove of `$HOME/.config/quickshell` as retirement
- No re-symlink live QS into repo
- No execution of `arch/quickshell.sh` before or during delete
- No bare `--skip-backup` reinstall
- No `scripts/phase08*` smoke harness
- No rewrite of `scripts/phase07-live-smoke.sh` / phase04 asserts
- No annotated recovery tag
- No package uninstalls

## Human verification

| Item | Result |
|------|--------|
| Live chrome still visible after tree delete | Soft: `qs -c ii` was running at 08-01; no formal LIVE-04 re-ceremony required (D-03). Operator may spot-check bar/chrome if desired. |

No blocking human-verify checkpoints remained mid-phase (health green → no reinstall gate).

## Gaps

None blocking.

**Expected red (non-gap):** `./scripts/phase07-live-smoke.sh` D-04 fails after RET-01 because in-repo `.config/quickshell` is intentionally gone. Leave frozen (D-03/D-11/D-12).

## Commits (phase execution)

| SHA | Role |
|-----|------|
| `2b1177d` | docs 08-01 SUMMARY |
| `fb91789` | RET-01 tree delete |
| `8742353` | docs 08-02 SUMMARY |
| `81ac1e0` | RET-02 installer delete |
| `cb4f6a0` | Pattern comment reword |
| `f3e3c3c` | docs 08-03 SUMMARY |

## Verdict

**Phase 8 complete.** Single product path achieved: live installed ii under home; in-repo v0.1 tree and old installer retired. Ready for Phase 9 (Workflow Documentation & Update Contract).
