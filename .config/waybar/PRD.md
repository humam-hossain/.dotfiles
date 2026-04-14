# PRD: Waybar Ping Integration

## Overview

Waybar fetches pre-computed ping status from the ping monitor server and
displays it in the bar. The server runs independently as a Docker container.

## Prerequisites

Ping monitor must be running at `http://127.0.0.1:8765/`.
See `.config/system_monitor/ping/` for setup.

## Goals

1. Waybar displays the latest server-computed status without doing ping work itself
2. Clicking the widget opens the browser history UI
3. Display is configurable via a format string with per-target placeholders

## Non-Goals

- Ping collection or storage (handled by the server)
- Browser history UI (served by the server)

## Waybar

### Responsibilities

- call `ping_status.sh` every 5 seconds
- display the latest status as colored Pango markup
- open the web UI on click

### Runtime path

`config.jsonc` module:

```jsonc
"custom/ping": {
  "interval": 5,
  "exec": "~/.config/waybar/scripts/network/ping_status.sh",
  "return-type": "json",
  "markup": true,
  "exec-if": "command -v curl && command -v python3",
  "on-click": "xdg-open http://127.0.0.1:8765/"
},
```

### Fetcher script (`ping_status.sh`)

- calls `GET /api/status` (optional `?format=<template>`)
- returns fallback `{"text":"ping down","class":"dead"}` if server is unavailable or returns invalid JSON
- 2-second curl timeout

### Display modes

Default — label + latency per target, each in one colored span:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping_status.sh"
```

Custom format — caller controls layout; only substituted values are colored:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping_status.sh '󰒍 %1 ISP: %2'"
```

Rules:

- `%1`, `%2`, ... map to targets by position in `ping.config`
- default mode wraps `label + value` in one `<span color='...'>` per target
- custom mode wraps only the substituted latency value in a span

### CSS classes

| Class | Meaning |
|-------|---------|
| `good` | all targets normal |
| `medium` | worst target elevated |
| `bad` | worst target high |
| `critical` | worst target critical |
| `dead` | server unavailable or stale |

## Files

- `.config/waybar/scripts/network/ping_status.sh` — fetcher script
- `.config/waybar/config.jsonc` — Waybar module definition
- `.config/waybar/style.css` — base styles
- `.config/waybar/mocha.css` — catppuccin mocha color overrides

## Install Scripts

- `arch/waybar.sh` — deploy Waybar UI files and packages

## Status

Implemented and verified on 2026-04-14.
