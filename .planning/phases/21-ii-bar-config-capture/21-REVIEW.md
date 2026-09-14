---
phase: 21-ii-bar-config-capture
reviewed: 2026-09-15T05:42:00+06:00
depth: standard
files_reviewed: 6
files_reviewed_list:
  - arch/dots-hyprland.sh
  - arch/hyprland.sh
  - capture/ii/.config/illogical-impulse/config.json
  - scripts/phase21-ii-bar-config-capture-assert.sh
  - stow/systemd/.config/systemd/user/dotfiles-capture.service
  - stow/systemd/.config/systemd/user/dotfiles-capture.timer
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: clean
---

# Phase 21: Code Review Report

**Reviewed:** 2026-09-15T05:42:00+06:00  
**Depth:** standard  
**Files Reviewed:** 6  
**Status:** clean  

## Summary

Code review for Phase 21 ("Quickshell ii bar configuration capture"). Source files reviewed:
- `arch/dots-hyprland.sh`: `run_capture` implementation with `--quiet` and `--notify` flags, `cmp -s` change detection, format validation (`jq empty` + non-zero size), atomic replace via temporary rename (`cp -p` + `mv -f`), and desktop notifications.
- `arch/hyprland.sh`: Integration of `dotfiles-capture.timer` enablement and start in session bootstrap.
- `stow/systemd/.config/systemd/user/dotfiles-capture.service`: Oneshot service configuration with low priority (`Nice=19`), display bus environment passing, and clean journal logging.
- `stow/systemd/.config/systemd/user/dotfiles-capture.timer`: Monotonic user timer configured for 2m startup and 15m active recurrence.
- `capture/ii/.config/illogical-impulse/config.json`: Tracked JSON baseline configuration for Quickshell ii bar components.
- `scripts/phase21-ii-bar-config-capture-assert.sh`: 451-line assertion test suite across Sections 1 through 7.

The implementation is defensive, compliant with repo standards, and avoids pitfalls:
- File replace is strictly atomic via temporary file on the same filesystem.
- JSON verification guards against zero-byte corruption or truncated writes before mirror overwrite.
- Change detection evaluates prior to repo mirror capturability tests, eliminating false dirty-mirror warnings on repeat runs.
- Unit files follow systemd user service best practices without hardcoded user IDs.

## Critical Issues

*No critical issues found.*

## Warnings

*No warnings found.*

## Info

### IN-01: Guard `notify-send` with `command -v` to prevent stderr noise in headless/minimal setups

**File:** `arch/dots-hyprland.sh:1555-1557`  
**Issue:** `notify-send` is invoked with `|| true`, which prevents script termination under `set -e`. However, in an environment where `notify-send` is absent (such as minimal chroot or headless test runs), the shell will emit a `notify-send: command not found` message to stderr.  
**Suggestion:** Check for command availability before dispatching:
```bash
if ((notify == 1 && captured_count > 0)) && command -v notify-send >/dev/null 2>&1; then
  notify-send "Dotfiles Capture" "Captured updates to repository" -a "Shell" -u low || true
fi
```

---

### IN-02: Expand signal trap in assert script for interrupt robustness

**File:** `scripts/phase21-ii-bar-config-capture-assert.sh:36`  
**Issue:** The assertion script sets `trap cleanup EXIT`. When interrupted via `SIGINT` (Ctrl+C) or `SIGTERM`, temporary files under `/tmp/p21-assert-*` could occasionally remain if subshells abort without invoking the EXIT handler.  
**Suggestion:** Expand trap signals:
```bash
trap cleanup EXIT INT TERM
```

---

_Reviewed: 2026-09-15T05:42:00+06:00_  
_Reviewer: Antigravity (gsd-code-reviewer)_  
_Depth: standard_  
