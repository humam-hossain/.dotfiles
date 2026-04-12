# PRD: Ping History Visualization — Multi-Target SQLite + Browser

## Overview

A lightweight, always-on ping monitoring stack integrated into Waybar. Pings one or more
configurable targets every 5 seconds, stores results in SQLite, and serves a pure-JS
Canvas visualization over HTTP. The browser view opens instantly and updates live.

---

## Goals

1. Click waybar ping module → browser opens in under 1 second
2. N configurable ping targets, all logged and visualized simultaneously
3. Per-target colored latency text in the waybar bar (Pango markup)
4. Per-target display label/icon co-located with host config in `ping.config`
5. 30 days of ping history as colored horizontal bars, side-by-side per target
6. Live update: today's bars refresh every 5s without page reload
7. Hover any segment → tooltip with target, time range, avg latency, quality tier
8. Quality tier thresholds are per-target, defined in `ping.config`, respected in both waybar and browser
9. Server RAM footprint under 30MB
10. Zero runtime dependencies beyond Python stdlib + sqlite3 CLI

---

## Non-Goals

- Historical data beyond 30 days in the UI (DB retains all data)
- Mobile layout
- Authentication
- Alerting / notifications
- Data export

---

## Architecture

```
data/ping.config  (source of truth: targets + per-target label + thresholds)
       │
ping.sh ['<fmt>']   (called by waybar every 5s, reads ping.config)
  └─ parallel ping -c3 each target
  └─ sqlite3 CLI INSERT (ts, target_host, ms) → data/pings.db
  └─ stdout → JSON {"text":"<pango markup>","class":"<worst-quality>"}

systemd user service
python3 analysis/server.py
  GET /          ──▶ data/ping_plot.html (static)
  GET /api/pings ──▶ SELECT N days → aggregate per target → JSON (includes thresholds)
  GET /api/today ──▶ SELECT today → aggregate per target → JSON + last_ping

Browser (JS + Canvas API)
  └─ sticky header: target names + per-column axes
  └─ N side-by-side bars per day row, one per target
  └─ per-target thresholds from API → correct ms ranges in tooltips
  └─ setInterval 5s → /api/today → redraw today's bars
```

---

## Data Model

### SQLite schema (`data/pings.db`)

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

- `ts` format: `YYYY-MM-DD HH:MM:SS` (space separator, SQLite datetime-compatible)
- `target_host`: resolved IP or hostname, e.g. `'8.8.8.8'`, `'192.168.0.1'`
- `ms = NULL` means ping failed (offline)
- Gaps > 60s between consecutive rows for a target = computer off / waybar stopped

### Offline detection (two sources, same treatment)

| Source | Condition |
|--------|-----------|
| Failed ping | `ms IS NULL` in DB |
| Gap in data | Consecutive rows for same target > 60s apart |

Both render as Offline segments.

---

## Quality Tiers

Per-target thresholds defined in `ping.config`. Defaults: `t1=40 t2=100 t3=200`.

| Tier | Condition | Bar color | Waybar text color |
|------|-----------|-----------|-------------------|
| Normal | `ms < t1` | `#00C853` | `#00C853` |
| Elevated | `t1 ≤ ms < t2` | `#FFD600` | `#FFD600` |
| High | `t2 ≤ ms < t3` | `#FF6D00` | `#FF6D00` |
| Critical | `ms ≥ t3` | `#D50000` | `#D50000` |
| Offline | `ms IS NULL` or gap > 60s | `#37474F` | `#37474F` |

Waybar CSS classes: `good` / `medium` / `bad` / `critical` / `dead`

---

## Target Configuration (`data/ping.config`)

One target per line: `host [label] t1 t2 t3`. Lines starting with `#` are comments.

```
# host                                           label  t1   t2   t3
8.8.8.8                                          󰒍      40  100  200
ip route | awk '/default/ {print $3; exit}'      GW:     2    5   10
192.168.0.104                                    PC:     2    5   10
# 1.1.1.1                                        DNS:   40  100  200
```

### Fields

- `host`: plain IP/hostname, or a shell command that resolves to one (detected by spaces, pipes, `$`, etc.)
- `label` *(optional)*: single display token shown in waybar before the ms value; must contain no shell metacharacters (`{ } ' " | $ \` ( ) / < > \`); must be specified alongside thresholds
- `t1/t2/t3`: ms thresholds for normal/elevated/high — above `t3` = critical

Targets are positional — `%1` = first uncommented line, `%2` = second, etc.  
Fallback if file missing or all lines commented: `8.8.8.8  󰒍  40  100  200`.

---

## Data Collection (`scripts/network/ping.sh`)

### Signature

```bash
ping.sh ['<format>']
```

- `format`: optional string with `%1`, `%2`, … placeholders (or `_` for default)
- No target args — all targets, labels, and thresholds come from `data/ping.config`

### Behavior

1. Reads `data/ping.config` → populates parallel arrays `HOSTS`, `LABELS`, `T1S`, `T2S`, `T3S`
2. Pings all targets **in parallel** (`ping -c3 -i0.3 -W1`)
3. For each target: classifies latency using that target's thresholds, builds Pango `<span color='…'>`
4. **Default format** (no arg): label and ms value wrapped together in one colored span per target: `<span color='#00C853'>󰒍 27ms</span>`
5. **Custom format** (arg supplied): replaces `%N` with colored ms span; literal label text in format string is uncolored
6. Logs each `(ts, target_host, ms)` row to SQLite
7. Outputs JSON: `{"text":"<pango markup>","class":"<worst-quality-class>"}`

### Example config.jsonc exec lines

```jsonc
// Default: labels + ms colored per target (recommended)
"exec": "~/.config/waybar/scripts/network/ping.sh"

// Custom format with literal labels between placeholders
"exec": "~/.config/waybar/scripts/network/ping.sh '󰒍 %1 ISP: %2'"
```

Targets not referenced in a custom format string are still pinged and logged to DB.

---

## Server (`analysis/server.py`)

**Port:** 8765 (bound to `127.0.0.1`)  
**Dependencies:** Python stdlib only (`http.server`, `sqlite3`, `json`, `datetime`, `subprocess`, `re`)

### Routes

| Route | Response |
|-------|----------|
| `GET /` | Serves `data/ping_plot.html` as `text/html` |
| `GET /api/pings` | Multi-target aggregated segments JSON (includes per-target thresholds) |
| `GET /api/today` | Today's segments JSON + `last_ping` timestamp (live refresh) |

### `/api/pings` query params

| Param | Default | Description |
|-------|---------|-------------|
| `days` | `30` | Last N calendar days |
| `from` | — | Start date `YYYY-MM-DD` (use with `to`) |
| `to` | — | End date `YYYY-MM-DD` (use with `from`) |

Today is always included as the first entry regardless of range.

### `/api/pings` response shape

```json
{
  "now": "2026-04-12 14:30:00",
  "targets": ["192.168.0.1", "192.168.0.104", "8.8.8.8"],
  "thresholds": {
    "8.8.8.8":       [40, 100, 200],
    "192.168.0.1":   [2,  5,   10],
    "192.168.0.104": [2,  5,   10]
  },
  "days": [
    {
      "date": "2026-04-12",
      "bars": {
        "8.8.8.8": [
          { "start": "00:00:00", "end": "14:30:00", "avg_ms": 23.4, "quality": "normal" }
        ],
        "192.168.0.1": [ … ]
      }
    }
  ]
}
```

### `/api/today` response shape

```json
{
  "now": "2026-04-12 14:30:00",
  "date": "2026-04-12",
  "targets": ["192.168.0.1", "8.8.8.8"],
  "bars": {
    "8.8.8.8": [ … ],
    "192.168.0.1": [ … ]
  },
  "last_ping": "2026-04-12 14:30:00"
}
```

### Config parsing (`load_config`)

Server reads `ping.config` with mtime-based caching (reloads on file change). Shell-command
host lines are resolved via `subprocess.run(shell=True, timeout=3)`. Returns
`{resolved_host: (t1, t2, t3)}` used for both classification and the `thresholds` response field.

### Aggregation logic

```
for each target independently (using that target's t1/t2/t3):
  for each row (ts, ms):
      quality = classify(ms, t1, t2, t3)
      if gap since prev row > 60s:
          close current segment at prev_ts
          emit offline segment [prev_ts → ts]
          reset
      if quality != current segment quality:
          close current segment at ts
          start new segment
      accumulate ms sum/count
  close final segment:
      today → end at now
      past days → end at last ping ts

  post-process fill_day_boundaries():
      leading gap (midnight → first ping > 60s) → offline segment
      trailing gap (last ping → midnight > 60s, historical only) → offline segment
```

Midnight splitting: segments spanning midnight are split into two — ending `24:00:00`,
starting `00:00:00` next day.

Targets are auto-discovered via `SELECT DISTINCT target_host FROM pings`.

---

## Frontend (`data/ping_plot.html`)

**Dependencies:** None (pure JS + Canvas API)

### Layout

```
[h1: Ping History]
[subtitle: N days / last ping timestamp]
[filter: Last [N] days [Apply] | From [date] To [date] [Apply]]
[fetch time]
[legend: color swatches — tier names only, no hardcoded ms values]

[sticky header]
  [96px spacer] [target1] [target2] [target3]    ← target names
  [96px spacer] [axis   ] [axis   ] [axis   ]    ← 24h axes

[day rows]
  [today      ] [canvas ] [canvas ] [canvas ]
  [2026-04-11 ] [canvas ] [canvas ] [canvas ]
  …
```

### Key behaviors

- **Multi-target columns**: N equal-width canvases per row, one per target, 4px gap
- **Sticky header**: target name row + axis row stick to top on scroll
- **Canvas sizing**: `ResizeObserver` sets `canvas.width` to pixel-accurate content width, redraws on resize
- **Axis**: 2-hour tick marks with AM/PM labels (12am, 2am … 12pm … 12am), one per target column
- **Date labels**: full `yyyy-mm-dd`; today shown as `today` (bold)
- **Tooltip**: `qualityLabel(target, quality)` uses per-target thresholds from API response to show correct ms ranges (e.g. `Normal (<2 ms)` for gateway vs `Normal (<40 ms)` for 8.8.8.8)
- **Live update**: `setInterval(5000)` → `/api/today` → redraw all today canvases
- **Fetch timing**: `performance.now()` measures round-trip; shown as `fetched in X.XXs`
- **Loading state**: Apply button shows `…` and is disabled during fetch

---

## Systemd Service

**File:** `~/.config/systemd/user/ping-viz.service`

```ini
[Unit]
Description=Ping visualization server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/pera/.config/waybar/analysis/server.py
WorkingDirectory=/home/pera/.config/waybar/data
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

---

## Files

| File | Role |
|------|------|
| `data/ping.config` | Target list — hosts, per-target labels, per-target thresholds |
| `scripts/network/ping.sh` | Data collection — reads ping.config, logs to SQLite, outputs Pango JSON |
| `analysis/server.py` | HTTP server — serves HTML + JSON API; reads ping.config for per-target thresholds |
| `analysis/migrate_add_target_host.py` | One-time migration — adds `target_host` column |
| `analysis/migrate_csv_to_sqlite.py` | One-time migration — historical CSV → SQLite |
| `data/pings.db` | SQLite database |
| `data/ping_plot.html` | Browser frontend |
| `~/.config/systemd/user/ping-viz.service` | Systemd unit for HTTP server |
| `config.jsonc` | Waybar config — display format string only |
| `style.css` | Waybar CSS — quality class colors |

---

## Status

**Implemented and verified** — 2026-04-12.  
DB: 1,027,776+ rows. Add targets by editing `data/ping.config` — no restarts needed.
