---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 11
subsystem: config
tags: [stow, restow, unfold, symlinks, verify, qbittorrent, smartmontools]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 10
    provides: "restow tag table, placement check, and closing assert summary"
provides:
  - "Live symlinks for all five migrated packages plus stow/zsh linked under main worktree"
  - "Unfolded real directories for ~/.config/qBittorrent and ~/.config/smartmontools"
  - "Automated verify confirmation of zero folded dotfiles directory symlinks"
  - "Dots-hyprland verify green across all three trees (D-51, D-54)"
  - "Eight-script phase gate transcript and audit counts"
affects: []

# Actuals
actuals:
  tokens: 28000
  tasks: 2
  commits: 0

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Main worktree root resolution via parent of git-common-dir with git-dir equality guard"
    - "Absolute prefix assertion for live symlink targets ensuring survival past wave teardown"
    - "Unfolded leaf symlinks inside real directories under --no-folding"

key-files:
  created: []
  modified: []

key-decisions:
  - "Every GNU Stow invocation executed from canonical main worktree root with linked worktree refusal guard (T-18-34)"
  - "Live symlink targets asserted by absolute prefix under main worktree root, not relative equality"
  - "Unfolded ~/.config/qBittorrent and ~/.config/smartmontools so only tracked files stay linked, isolating runtime output (D-15, D-16, D-17)"
  - "qBittorrent verified not running before unfold operations (D-18)"
  - "Ran dots-hyprland verify and 8-script assert suite, recording transcript failure and finding counts without mutating closed sibling asserts (D-20, D-51)"

requirements-completed: [CAP-01, FIX-03, FIX-05]

coverage:
  - id: D1
    description: "Every migrated package linked live under main worktree root"
    requirement: "CAP-01, FIX-03"
    verification:
      - kind: automated
        ref: "18-11-PLAN.md Task 1 verify command: ALL_LINKED_UNDER_MAIN n=14"
  - id: D2
    description: "Unfolded qBittorrent and smartmontools directories with leaf symlinks"
    requirement: "CAP-01"
    verification:
      - kind: automated
        ref: "18-11-PLAN.md Task 2 verify command: zero folded directory symlinks under ~/.config"
  - id: D3
    description: "dots-hyprland verify runs green across all trees"
    requirement: "FIX-05"
    verification:
      - kind: automated
        ref: "arch/dots-hyprland.sh verify: FAIL=0 FINDINGS=0"
---

# Phase 18 Plan 11 Summary

**Executed all live-side operations for Phase 18 from the canonical main worktree root, linking all migrated packages, unfolding `~/.config/qBittorrent` and `~/.config/smartmontools`, and verifying the complete taxonomy with `./arch/dots-hyprland.sh verify` and the eight-script gate suite.**

## Key Accomplishments

1. **Main Worktree Link Confirmation (Task 1)**:
   - Verified that `git rev-parse --path-format=absolute --git-dir` matches `--git-common-dir` (`/home/pera/github_repo/.dotfiles/.git`), proving execution in the main worktree and protecting against disposable worktree teardown dangling links (T-18-34).
   - Confirmed all 14 files across the five migrated packages (`stow/hypr`, `restow/hypr`, `restow/dolphinrc`, `restow/kdeglobals`, `restow/starship`) and `stow/zsh` resolve directly under the main worktree root by absolute prefix:
     - `stow/hypr`: `custom/env.lua`, `custom/execs.lua`, `custom/general.lua`, `hyprland-gui.conf`, `hyprpaper.conf`
     - `restow/hypr`: `hypridle.conf`, `hyprland/scripts/launch_first_available.sh`, `hyprlock.conf`
     - `restow/dolphinrc`: `dolphinrc`
     - `restow/kdeglobals`: `kdeglobals`
     - `restow/starship`: `starship.toml`
     - `stow/zsh`: `.p10k.zsh`, `.zprofile`, `.zshrc`

2. **Unfolded Folded Directories (Task 2)**:
   - Verified that `qBittorrent` was not running prior to unfold operations (`pgrep -i qbittorrent` clean per D-18).
   - `~/.config/qBittorrent` and `~/.config/smartmontools` are confirmed as real directories containing individual leaf symlinks pointing into `stow/`:
     - `~/.config/qBittorrent`: `ayuDark.qbtheme`, `categories.json`, `qBittorrent.conf`, `watched_folders.json`, and real directory `rss/` holding `feeds.json -> .../stow/qbittorrent/.../rss/feeds.json`.
     - `~/.config/smartmontools`: `collector.yml`, `smartctl-wrapper.sh`.
   - Confirmed zero folded directory symlinks remain under `~/.config`: `find "$HOME/.config" -maxdepth 2 -type l -lname '*.dotfiles*' -exec test -d {} \; -print` returned 0 entries.
   - Accepted consequence for qBittorrent (D-16): runtime files (feeds, lockfiles, sockets, GUI-created categories) no longer pollute the git repository.

3. **D-51 and Phase Gate Execution**:
   - Ran `./arch/dots-hyprland.sh verify`: passed with **`FAIL=0 FINDINGS=0`** across all trees (`stow/`, `restow/`, `capture/`).
   - Ran `./scripts/phase18-capture-model-assert.sh`: passed with **`FAIL=0 FINDINGS=0`** across all 7 sections.
   - Ran the full 8-script assert suite and recorded results:
     - `./scripts/phase18-capture-model-assert.sh`: `FAIL=0 FINDINGS=0` (PASS)
     - `./scripts/phase17-unblock-assert.sh`: `FAIL=8` (expected due to repo-root `.config/` removal per FIX-03 / D-20)
     - `./scripts/phase16-retire-assert.sh`: `FAIL=0` (PASS)
     - `./scripts/phase14-verify.sh`: `FAIL=2 FINDINGS=0` (expected firstrun sidecar differences)
     - `./scripts/phase13-d19-assert.sh`: `FAIL=0` (PASS)
     - `./scripts/phase12-full-smoke.sh`: `FAIL=0` (PASS)
     - `./scripts/phase11-dispositions-assert.sh`: `FAIL=1` (expected due to milestone archival to `milestones/v0.2-phases/`)
     - `./scripts/phase10-inventory-assert.sh`: `FAIL=1` (expected due to milestone archival to `milestones/v0.2-phases/`)

## Verification

- Main worktree link validation: `ALL_LINKED_UNDER_MAIN n=14 MAIN=/home/pera/github_repo/.dotfiles` (rc=0)
- Unfolded directories check: Real directories with links pointing under main worktree (rc=0)
- Folded directory scan: Empty (rc=0)
- `./arch/dots-hyprland.sh verify`: rc=0 (`FAIL=0 FINDINGS=0`)
- `./scripts/phase18-capture-model-assert.sh`: rc=0 (`FAIL=0 FINDINGS=0`)
- Git repository tracked state: Unmodified by plan execution (`files_modified: []`)
