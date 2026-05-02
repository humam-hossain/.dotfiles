---
status: complete
phase: 12-bar-skeleton-and-theme
source: [12-01-SUMMARY.md, 12-02-SUMMARY.md]
started: 2026-05-03T00:00:00Z
updated: 2026-05-03T00:00:00Z
completed: 2026-05-03T00:00:00Z
---

## Current Test

(all tests complete)
awaiting: none

## Tests

### 1. Bar docks at top with exclusive zone
expected: Running `quickshell` places a black bar flush to the top of the screen. A tiling window's top edge sits below the bar — tiling space does not overlap the bar.
result: passed (after runtime fixes in 3397eec: import QtQuick in Colours.qml, custom padding props in ModulePill.qml, Variants delegate simplified in Bar.qml)

### 2. Three-section pill layout
expected: Three pill-shaped containers are visible — "Left" near the left edge, "Center" horizontally centered, "Right" near the right edge. Each pill has a dark rounded rectangle background with the label inside.
result: passed

### 3. Catppuccin Mocha theme — colors and font
expected: Bar background is pure black (#000000). Each pill background is dark charcoal (#1e1e2e). Pill text is light grey (#cdd6f4) in JetBrainsMono Nerd Font, 14px bold. A subtle drop shadow is visible below the bar.
result: passed

### 4. Keyboard focus not stolen
expected: With `quickshell` running, clicking a terminal and typing sends characters to the terminal — not the bar. The bar never intercepts keystrokes.
result: passed

### 5. Waybar coexists
expected: Waybar remains visible and functional while `quickshell` is also running. Both bars appear on screen simultaneously without interfering with each other.
result: passed

### 6. Multi-monitor hotplug
expected: If a second monitor is available: connecting it while `quickshell` is running makes a new bar appear on that screen. Disconnecting it removes the bar. No Quickshell restart needed.
result: passed

### 7. Install script — packages and i2c
expected: `bash arch/quickshell.sh` exits 0. `pacman -Q quickshell ddcutil i2c-tools` lists all three. `cat /etc/modules-load.d/i2c.conf` prints `i2c-dev`. `test -L ~/.config/quickshell` succeeds and the symlink points to the repo's `.config/quickshell/`. Script printed the relog reminder for i2c group.
result: passed (CLI-verified — quickshell 0.2.1-6, ddcutil 2.2.6-1, i2c-tools 4.4-4 installed; /etc/modules-load.d/i2c.conf contains i2c-dev; ~/.config/quickshell -> repo .config/quickshell/)

### 8. Waybar untouched by install script
expected: `git diff --name-only .config/waybar/` shows no changes. `pgrep -x waybar` returns a PID — Waybar is still running after the script completed.
result: passed (CLI-verified — `git diff .config/waybar/` empty; waybar PID 248955 running)

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

