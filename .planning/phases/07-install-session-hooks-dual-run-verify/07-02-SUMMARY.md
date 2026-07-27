---
phase: 07-install-session-hooks-dual-run-verify
plan: 02
subsystem: infra
tags: [quickshell, dots-hyprland, live-install, LIVE-01, wrapper]

requires:
  - phase: 07-install-session-hooks-dual-run-verify
    provides: pre-install path safety (qs stopped, live QS not symlink)
  - phase: 06-thin-setup-wrapper-safe-defaults
    provides: arch/dots-hyprland.sh with SAFE_DEFAULTS + backup_gate
provides:
  - LIVE-01 real installed tree at ~/.config/quickshell/ii/shell.qml
  - ~/.local/state/quickshell/.venv (ii Python venv)
  - illogical-impulse meta packages including illogical-impulse-quickshell-git
  - optional ~/ii-original-dots-backup from upstream backup gate
affects:
  - 07-03 (session hooks + dual-run verify need LIVE-01 tree + venv)

tech-stack:
  added:
    - illogical-impulse-quickshell-git 0.1.0.r1-8 (provides qs; replaces official quickshell)
    - remaining illogical-impulse-* meta packages via local PKGBUILDs
  patterns:
    - "D-06 dry-run first then live wrapper install"
    - "D-08 fix-and-re-run only (no automated rollback)"
    - "Wrapper-only first adoption (no raw ./setup)"

key-files:
  created:
    - ~/.config/quickshell/ii/shell.qml
    - ~/.local/state/quickshell/.venv
    - ~/ii-original-dots-backup
  modified: []

key-decisions:
  - "Used ./arch/dots-hyprland.sh install only (D-05); injected --core --skip-hyprland --skip-sysupdate"
  - "Operator typed yes at wrapper backup gate; did not pass --skip-backup (D-02)"
  - "Operator chose n (auto-execute) after greeting; preferred y-style progress through package steps"
  - "D-08: mid-install font conflict (ttf-material-symbols-variable vs -git) fixed by removing non-git package and re-running wrapper"
  - "D-08: official quickshell package conflicted with illogical-impulse-quickshell-git; resolved during re-run so meta package installed"
  - "Personal hyprland.conf preserved (no .old); --skip-hyprland held (T-7-02)"

patterns-established:
  - "Dry-run argv gate: printf yes | install --dry-run must show three SAFE_DEFAULTS + dry-run would-exec"
  - "Live install is interactive (sudo/yay/backup); D-08 re-run same wrapper after package conflict fix"
  - "LIVE-01 hard asserts: ! -L, -d, ii/shell.qml, not under .dotfiles, .venv present, repo product intact"

requirements-completed: [LIVE-01]

coverage:
  - id: D1
    description: "Dry-run proves SAFE_DEFAULTS argv before live mutation (D-06)"
    requirement: LIVE-01
    verification:
      - kind: other
        ref: "printf yes | ./arch/dots-hyprland.sh install --dry-run → /tmp/p7-dry.txt contains --core --skip-hyprland --skip-sysupdate and dry-run: would exec"
        status: pass
    human_judgment: false
  - id: D2
    description: "Live one-shot wrapper install completed (D-05/D-02/D-08)"
    requirement: LIVE-01
    verification:
      - kind: other
        ref: "./arch/dots-hyprland.sh install → [./setup]: Finished; operator yes + no --skip-backup"
        status: pass
    human_judgment: true
    rationale: "Interactive sudo/yay/backup gates require operator; D-08 conflict resolution was operator-mediated"
  - id: D3
    description: "LIVE-01 real dir + ii/shell.qml not under .dotfiles"
    requirement: LIVE-01
    verification:
      - kind: other
        ref: "test ! -L && -d && -f ii/shell.qml; readlink -f not under */.dotfiles/.config/quickshell"
        status: pass
    human_judgment: false
  - id: D4
    description: "ii Python venv present post-setups"
    requirement: LIVE-01
    verification:
      - kind: other
        ref: "test -d ~/.local/state/quickshell/.venv"
        status: pass
    human_judgment: false
  - id: D5
    description: "Personal hyprland.conf not renamed to .old"
    requirement: LIVE-01
    verification:
      - kind: other
        ref: "test -f ~/.config/hypr/hyprland.conf && test ! -e ~/.config/hypr/hyprland.conf.old"
        status: pass
    human_judgment: false

duration: ~45min
completed: 2026-07-27
status: complete
---

# Phase 7 Plan 02: Live Wrapper Install Summary

**One-shot `arch/dots-hyprland.sh install` completed; LIVE-01 real QS tree and venv on host; personal hyprland.conf untouched.**

## Performance

- **Duration:** ~45 min wall (includes D-08 conflict fix + full deps rebuild of quickshell-git)
- **Started:** 2026-07-27 (after 07-01 approval)
- **Completed:** 2026-07-27
- **Tasks:** 3/3
- **Files modified:** 0 in-repo product (host-only install; SUMMARY only)

## Accomplishments

- Dry-run (`/tmp/p7-dry.txt`) showed `./setup install --core --skip-hyprland --skip-sysupdate` with `dry-run: would exec` (D-06)
- Live install via wrapper only; operator typed exact `yes` at backup gate; no `--skip-backup` (D-02)
- Upstream backup created at `~/ii-original-dots-backup` (clashing paths including hypr conf copy)
- D-08 mid-install: Material Symbols package conflict fixed (`ttf-material-symbols-variable` → `-git`); re-ran wrapper
- D-08 mid-install: official `quickshell` conflicted with `illogical-impulse-quickshell-git`; resolved on re-run — meta package installed
- `rsync_dir__sync dots/.config/quickshell → ~/.config/quickshell` produced real directory (not symlink)
- uv venv at `~/.local/state/quickshell/.venv` (Python 3.12) + requirements installed
- `hyprland.conf.old` absent; personal conf preserved (`--skip-hyprland`)
- In-repo `.config/quickshell` product still present (D-04 / Phase 8)

## Task Results

### Task 1: Dry-run safe defaults (D-06)

- Preconditions: no qs; live path not symlink
- `printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run` exit 0
- Evidence in `/tmp/p7-dry.txt`: `--core`, `--skip-hyprland`, `--skip-sysupdate`, `dry-run: would exec`

### Task 2: Live one-shot install (D-05, D-02, D-07, D-08)

- Command: `./arch/dots-hyprland.sh install` (interactive)
- Operator: wrapper `yes`; auto-execute `n`; package prompts approved as needed
- First attempt aborted on font conflict → D-08 re-run after package fix
- Second run completed: `[./setup]: Finished`
- Meta packages installed including `illogical-impulse-quickshell-git 0.1.0.r1-8`
- Setups: venv, groups, ydotool, bluetooth, fonts, firstrun marker
- Files: real `~/.config/quickshell` from vendor dots rsync

### Task 3: LIVE-01 hard asserts

| Assert | Result |
|--------|--------|
| `! -L ~/.config/quickshell` | pass |
| `-d ~/.config/quickshell` | pass |
| `-f .../ii/shell.qml` | pass |
| `readlink -f` not under `.dotfiles/.config/quickshell` | pass (`/home/pera/.config/quickshell`) |
| `-d ~/.local/state/quickshell/.venv` | pass |
| repo `.config/quickshell` still present | pass |
| `hyprland.conf` present, no `.old` | pass |

`[VERIFY] OK LIVE-01`

## Deviations / D-08 notes

1. **ttf-material-symbols-variable** vs **ttf-material-symbols-variable-git** — removed non-git, re-ran install.
2. **quickshell 0.3.0-2** (official) vs **illogical-impulse-quickshell-git** — install stalled on `makepkg -i` failure prompt; fixed by resolving conflict and re-running; final state is meta package only providing `qs`.
3. OOM killed chrome during quickshell-git cmake build (kernel log); build still completed on re-run path.

## Self-Check: Requirements Coverage

| ID | Status |
|----|--------|
| LIVE-01 | **met** — real installed tree, not symlink into git |

## Ready for 07-03

- LIVE-01 green → personal hypr hooks (`env` + `exec-once = qs -c ii`) + dual-run LIVE-02..04
- Do not run `arch/quickshell.sh` (would re-symlink)
- Do not install full ii hypr tree (D-09; keep `--skip-hyprland` posture)
