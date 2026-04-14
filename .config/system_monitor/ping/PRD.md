# PRD: Ping Monitor

## Overview

Standalone Docker service that collects ping history and serves it over HTTP.
Split into three concerns:

- `server`: collects ping samples, stores history, serves APIs
- `web`: renders historical data in the browser
- `waybar`: separate — fetches pre-computed status from this service (see `.config/waybar/`)

The server runs independently of Waybar. If Waybar is not running, the server
still collects and stores data.

## Goals

1. Ping collection continues independently of any display layer
2. Browser history uses the same stored data as Waybar
3. Per-target labels and thresholds defined in one place: `ping.config`
4. Configuration changes apply without restarting the service
5. Timezone matches the host (container mounts host `/etc/localtime`)

## Non-Goals

- Authentication
- Mobile-first web layout
- Alerting or notifications
- Exporting history

## Server

### Responsibilities

- read `ping.config`
- resolve plain hosts or shell-command hosts (e.g. `ip route | awk ...`)
- ping all configured targets every 5 seconds in parallel
- classify latency using per-target thresholds
- write one row per target per cycle to SQLite
- keep an in-memory snapshot for the latest Waybar status
- serve the browser HTML and JSON APIs
- log DB saves, HTTP requests, and errors using Python's `logging` module (INFO/DEBUG/ERROR levels)
- log output to both stdout (docker logs) and `logs/ping.log`
- use `RotatingFileHandler` to manage log file size (10MB, 5 backups)

### Inputs

- `ping.config`

Format:

```text
host  [label]  t1  t2  t3
```

Example:

```text
8.8.8.8                                          󰒍        40  100  200
ip route | awk '/default/ {print $3; exit}'      󰀂         2    5   10
192.168.0.104                                             2    5   10
```

Notes:

- `host` can be a plain IP/hostname or a shell command that resolves to one
- shell commands are detected by spaces, pipes, `$`, etc. and evaluated at runtime
- `label` is optional; must be a single token with no shell metacharacters
- `t1 t2 t3` are ms thresholds for normal/elevated/high; `>= t3` is critical
- blank lines and `#` comments are ignored
- config is reloaded on every collection cycle (no restart needed)

### Storage

SQLite database: `data/pings.db` (bind-mounted to host at `~/.config/system_monitor/ping/data/pings.db`)

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

- `ts` uses `YYYY-MM-DD HH:MM:SS` in host local time
- `ms = NULL` means ping failure
- gaps greater than 60 seconds are treated as offline in history rendering

### APIs

- `GET /` → serves `ping_plot.html`
- `GET /api/status` → latest Waybar JSON: `text` + `class`; optional `?format=<template>`
- `GET /api/today` → today's aggregated segments + `last_pings` (per-target dict)
- `GET /api/pings` → historical aggregated segments; `?days=N` (default 50) or `?from=YYYY-MM-DD&to=YYYY-MM-DD`

### Freshness and failure behavior

- the in-memory Waybar snapshot is considered stale after 15 seconds
- stale status returns `{"text":"ping stale","class":"dead"}`
- one target failing does not fail the whole collection cycle
- if a client disconnects during response writing, the server ignores the broken pipe

## Web

### Responsibilities

- fetch aggregated data from the server
- render one row per day and one column per target
- refresh per-target last pings in subtitle every 10 seconds
- show per-target threshold-aware tooltips

### Data sources

- initial/history load: `/api/pings`
- live refresh for subtitle: `/api/today`

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

## Files

- `.config/system_monitor/ping/server.py` — collector + HTTP server
- `.config/system_monitor/ping/ping.config` — targets, labels, thresholds
- `.config/system_monitor/ping/ping_plot.html` — browser frontend
- `.config/system_monitor/ping/Dockerfile` — container image (`python:3.12-slim` + `iputils-ping` + `iproute2`)
- `.config/system_monitor/ping/docker-compose.yml` — service definition (host network, timezone mounts)
- `~/.config/system_monitor/ping/data/pings.db` — SQLite DB (bind-mounted host directory)

## Install Scripts

- `arch/system_monitor.sh` — deploy via Docker on Arch (loopback, `BIND_HOST=127.0.0.1`)
- `debian/monitor_system.sh` — deploy via Docker on Debian/Ubuntu (LAN-exposed, `BIND_HOST=0.0.0.0`)

## Status

Implemented and verified on 2026-04-14.
