---
phase: 06-thin-setup-wrapper-safe-defaults
plan: 03
subsystem: infra
tags: [bash, smoke, wrap-01, wrap-02, wrap-03, wrap-04, dry-run]

requires:
  - phase: 06-02
    provides: policy-complete arch/dots-hyprland.sh
provides:
  - Full WRAP-01..04 dry/help suite green
  - Preflight fail-closed with setup +x restored
  - Evidence that Phase 6 success criteria hold without machine mutation
affects:
  - Phase 7 live install via wrapper

tech-stack:
  added: []
  patterns:
    - "Non-mutating Phase 6 validation via --dry-run + help + preflight trap"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh

requirements-completed: [WRAP-01, WRAP-02, WRAP-03, WRAP-04]
---

# Plan 06-03 Summary — Full WRAP smoke suite

**Completed:** 2026-07-26  
**Status:** Done

## Suite results (all green)

| Check | Result |
|-------|--------|
| bash -n + bare help exit 0 | pass |
| uninstall / exp-merge refused | pass |
| install --dry-run defaults (--core, --skip-hyprland, --skip-sysupdate) | pass |
| install-files --dry-run defaults | pass |
| install-deps --dry-run no injected --skip-hyprland | pass |
| Gate messaging (backup dir, quickshell, skip-hyprland) | pass |
| Gate abort on `no` | pass |
| --skip-backup refuse / dual-key allow | pass |
| --exp-files after defaults | pass |
| install -h passthrough | pass |
| Preflight non-executable setup (restored +x) | pass |
| No package arrays / no entry-only default | pass |

## Phase success criteria mapping

1. Wrapper invokes `./setup` for four subcommands (dry-run argv) — **TRUE**  
2. Defaults `--core --skip-hyprland` (+ `--skip-sysupdate`) on install paths — **TRUE**  
3. Backup gate + no default skip-backup — **TRUE**  
4. Extra flags reach setup after defaults — **TRUE**

## Out of scope (confirmed)

- Live install-deps/files — Phase 7  
- Session hooks / qs -c ii — Phase 7  
- verify subcommand — POLISH-01  
