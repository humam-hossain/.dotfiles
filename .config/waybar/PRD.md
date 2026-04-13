# PRD: Waybar Ping Monitor

## Overview

This setup is split into three parts with clear ownership:

- `server`: collects ping samples, stores history, serves APIs
- `web`: renders historical data in the browser
- `waybar`: displays the latest computed status from the server

The main goal is to keep ping history independent from Waybar itself. If Waybar
is not running, the server should still continue collecting and storing data.

## Goals

1. Ping collection continues independently of Waybar
2. Waybar displays the latest available status without doing ping work itself
3. Browser history stays live and uses the same stored data as Waybar
4. Per-target labels and thresholds stay defined in one place: `monitor/ping.config`
5. Configuration changes apply without restarting the service

## Non-Goals

- Authentication
- Mobile-first web layout
- Alerting or notifications
- Exporting history

## Server

### Responsibilities

- read `monitor/ping.config`
- resolve plain hosts or shell-command hosts
- ping all configured targets every 5 seconds in parallel
- classify latency using per-target thresholds
- write one aggregated row per target per cycle to SQLite
- keep an in-memory snapshot for the latest Waybar status
- serve the browser HTML and JSON APIs

### Inputs

- `monitor/ping.config`

Format:

```text
host  [label]  t1  t2  t3
```

Example:

```text
8.8.8.8                                          󰒍        40  100  200
ip route | awk '/default/ {print $3; exit}'      ROUTER:   2    5   10
192.168.0.104                                    PC:       2    5   10
```

### Storage

SQLite database: `data/pings.db`

Schema:

```sql
CREATE TABLE IF NOT EXISTS pings (
    ts          TEXT NOT NULL,
    target_host TEXT NOT NULL DEFAULT '8.8.8.8',
    ms          REAL,
    PRIMARY KEY (ts, target_host)
);
CREATE INDEX IF NOT EXISTS idx_ts     ON pings(ts);
CREATE INDEX IF NOT EXISTS idx_target ON pings(target_host);
```

Rules:

- `ts` uses `YYYY-MM-DD HH:MM:SS`
- `ms = NULL` means ping failure
- gaps greater than 60 seconds are treated as offline in history rendering

### APIs

- `GET /` → serves `monitor/ping_plot.html`
- `GET /api/status` → latest Waybar JSON: `text` + `class`
- `GET /api/today` → today’s aggregated segments + `last_ping`
- `GET /api/pings` → historical aggregated segments

### Freshness and failure behavior

- the in-memory Waybar snapshot is considered stale after 15 seconds
- stale status returns `dead`
- one target failing does not fail the whole collection cycle
- if a client disconnects during response writing, the server ignores the broken pipe and continues running

## Web

### Responsibilities

- fetch aggregated data from the server
- render one row per day and one column per target
- update today’s row every 5 seconds
- show per-target threshold-aware tooltips

### Data sources

- initial/history load: `/api/pings`
- live refresh for today: `/api/today`

### UI behavior

- newest day first
- target columns side by side
- sticky header for target names and axes
- last-N-days and date-range filters
- tooltip shows target, time range, quality, and average latency

### Quality tiers

| Tier | Condition | Color |
|------|-----------|-------|
| Normal | `ms < t1` | `#00C853` |
| Elevated | `t1 <= ms < t2` | `#FFD600` |
| High | `t2 <= ms < t3` | `#FF6D00` |
| Critical | `ms >= t3` | `#D50000` |
| Offline | failed ping or gap > 60s | `#37474F` |

## Waybar

### Responsibilities

- call a small local fetcher script
- display the latest server-computed status
- open the web UI on click

### Runtime path

Waybar module:

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

Fetcher script:

- calls `GET /api/status`
- returns fallback JSON `{"text":"ping down","class":"dead"}` if the server is unavailable or returns invalid JSON

### Display modes

Default:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping_status.sh"
```

Custom:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping_status.sh '󰒍 %1 ISP: %2'"
```

Rules:

- `%1`, `%2`, ... follow target order in `ping.config`
- default mode renders label + latency together in one colored span
- custom mode colors only the substituted latency values

### CSS classes

- `good`
- `medium`
- `bad`
- `critical`
- `dead`

## Files

- `monitor/server.py` — collector + HTTP server
- `monitor/ping.config` — targets, labels, thresholds
- `data/pings.db` — SQLite history
- `monitor/ping_plot.html` — browser frontend
- `scripts/network/ping_status.sh` — Waybar fetcher
- `config.jsonc` — Waybar module config
- `style.css` — Waybar colors
- `~/.config/systemd/user/ping-viz.service` — user service

## Status

Implemented and verified on 2026-04-13.
