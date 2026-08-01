---
phase: 06-thin-setup-wrapper-safe-defaults
plan: 02
subsystem: infra
tags: [bash, wrapper, safe-defaults, backup-gate, skip-backup, passthrough]

requires:
  - phase: 06-01
    provides: arch/dots-hyprland.sh scaffold with allowlist, preflight, dry-run
provides:
  - SAFE_DEFAULTS injection for install|install-files only
  - hard interactive backup gate (yes-token)
  - refuse bare --skip-backup unless --allow-skip-backup
  - WRAP-04 flag order: defaults then user flags
affects:
  - 06-03 full smoke
  - Phase 7 live install

tech-stack:
  added: []
  patterns:
    - "needs_safe_defaults for install|install-files"
    - "backup_gate with D-13 messaging + exact yes"
    - "dual-key --skip-backup + --allow-skip-backup (meta stripped)"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh

key-decisions:
  - "Yes-token is exact case-sensitive yes via read -r"
  - "Gate runs for dry-run too so smoke covers messaging"
  - "install -h / help-only flags skip the gate"

requirements-completed: [WRAP-02, WRAP-03, WRAP-04]
---

# Plan 06-02 Summary — Safe defaults + backup gate

**Completed:** 2026-07-26  
**Status:** Done

## What shipped

- `needs_safe_defaults()` injects `--core --skip-hyprland --skip-sysupdate` for `install` and `install-files` only
- `[CONFIG] safe defaults: …` + full `[INSTALL]` argv log before dry-run/exec
- Hard `backup_gate` with ii-original-dots-backup / Quickshell overwrite / skip-hyprland messaging
- Bare `--skip-backup` refused; with `--allow-skip-backup` only `--skip-backup` is forwarded
- User flags after defaults (e.g. `--exp-files`)

## Verification

All 06-02 automated verifies green (dry-run only; no live install).

## Next

06-03 full WRAP suite + phase closeout.
