# Waybar Ping Monitor

Ping latency monitor for Waybar. Logs per-target ping history to SQLite and serves
a live browser visualization. Supports multiple targets with per-target labels,
per-target quality thresholds, and Pango-colored text in the status bar.

---

## Requirements

- `waybar`
- `python3` (stdlib only — no pip packages)
- `sqlite3` CLI
- `ping` (iputils)
- `systemd` (user session)

---

## Setup

### 1. Create directories

```bash
mkdir -p ~/.config/waybar/{data,logs,analysis,scripts/network}
```

### 2. Copy files

Place these files from this repo into the correct locations:

| Source | Destination |
|--------|-------------|
| `scripts/network/ping.sh` | `~/.config/waybar/scripts/network/ping.sh` |
| `analysis/server.py` | `~/.config/waybar/analysis/server.py` |
| `data/ping_plot.html` | `~/.config/waybar/data/ping_plot.html` |
| `data/ping.config` | `~/.config/waybar/data/ping.config` |

```bash
chmod +x ~/.config/waybar/scripts/network/ping.sh
```

### 3. Install the systemd service

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/ping-viz.service << 'EOF'
[Unit]
Description=Ping visualization server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/YOUR_USERNAME/.config/waybar/analysis/server.py
WorkingDirectory=/home/YOUR_USERNAME/.config/waybar/data
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
```

Replace `YOUR_USERNAME` with your actual username (`echo $USER`).

Enable and start:

```bash
systemctl --user enable --now ping-viz
systemctl --user status ping-viz   # should show: active (running)
```

### 4. Configure Waybar

In `~/.config/waybar/config.jsonc`, add the `custom/ping` module definition:

```jsonc
"custom/ping": {
  "interval": 5,
  "exec": "~/.config/waybar/scripts/network/ping.sh",
  "return-type": "json",
  "markup": true,
  "exec-if": "command -v ping",
  "on-click": "xdg-open http://localhost:8765/"
},
```

Add `"custom/ping"` to your bar's `modules-left`, `modules-center`, or `modules-right`.

Add CSS classes to `~/.config/waybar/style.css`:

```css
#custom-ping.good     { color: #00C853; }
#custom-ping.medium   { color: #FFD600; }
#custom-ping.bad      { color: #FF6D00; }
#custom-ping.critical { color: #D50000; }
#custom-ping.dead     { color: #37474F; }
```

### 5. Reload Waybar

```bash
killall -SIGUSR2 waybar
```

### 6. Verify

```bash
# Script outputs valid JSON
~/.config/waybar/scripts/network/ping.sh

# DB is being written to
sqlite3 ~/.config/waybar/data/pings.db "SELECT COUNT(*) FROM pings;"

# Server is responding
curl http://localhost:8765/api/pings?days=1 | python3 -m json.tool | head -30

# Open browser
xdg-open http://localhost:8765/
```

---

## Migrating from CSV history

If you have a legacy `data/ping_history.csv` (format: `YYYY-MM-DD_HH:MM:SS,ping_ms`):

```bash
python3 ~/.config/waybar/analysis/migrate_csv_to_sqlite.py
```

This deduplicates and imports all rows into SQLite.

---

## Adding and configuring ping targets

Edit `~/.config/waybar/data/ping.config`. One target per line.

### Format

```
host  [label]  t1  t2  t3
```

| Field | Required | Description |
|-------|----------|-------------|
| `host` | yes | Plain IP/hostname, or a shell command that resolves to one |
| `label` | no | Single display token shown in waybar before the ms value (icon or short word) |
| `t1 t2 t3` | no* | ms thresholds for normal/elevated/high; above `t3` = critical. *Required if specifying a label |

Lines starting with `#` are ignored.

### Example

```
# host                                           label    t1   t2   t3
8.8.8.8                                          󰒍        40  100  200
ip route | awk '/default/ {print $3; exit}'      ROUTER:   2    5   10
192.168.0.104                                    PC:       2    5   10
# 1.1.1.1                                        DNS:     40  100  200
```

- **Labels** must be a single token with no shell metacharacters (`{ } ' " | $ \` ( ) / < > \`). They're colored in waybar alongside the ms value using that target's quality color.
- **Shell commands** as host values are detected by spaces, pipes, `$`, etc. and evaluated. The resolved IP is what gets stored in the DB.
- **Thresholds** are per-target — the browser visualization also respects them for segment classification and tooltip ms ranges.
- **Targets are positional**: first uncommented line = `%1`, second = `%2`, etc.

No restarts needed — ping.sh re-reads the config every 5 seconds. New targets appear in the browser automatically once the first ping is logged.

### Waybar display modes

**Default (recommended)** — label and ms wrapped in one colored span per target:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping.sh"
// → 󰒍 27ms  ROUTER: 2ms  PC: 1ms   (each unit colored by its quality tier)
```

**Custom format** — you control the layout with `%N` placeholders; only the ms value is colored:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping.sh '󰒍 %1 ISP: %2'"
// → 󰒍 27ms  ISP: 2ms   (literal text uncolored, ms values colored)
```

Targets not referenced in a custom format string are still pinged and logged.

---

## Quality tiers

| Tier | Latency | Bar color | Waybar CSS class |
|------|---------|-----------|-----------------|
| Normal | `< t1` | green `#00C853` | `good` |
| Elevated | `t1 – t2` | yellow `#FFD600` | `medium` |
| High | `t2 – t3` | orange `#FF6D00` | `bad` |
| Critical | `≥ t3` | red `#D50000` | `critical` |
| Offline | failed / gap > 60s | dark `#37474F` | `dead` |

Default thresholds (when omitted): `t1=40 t2=100 t3=200`.

---

## Browser visualization

Open: **http://localhost:8765/**

- **Rows**: one row per calendar day, newest first
- **Columns**: one canvas bar per ping target, side-by-side
- **Colors**: match quality tier table above, using each target's own thresholds
- **Tooltip**: hover any segment — shows target, date, time range, quality with correct ms ranges for that target, avg latency
- **Live**: today's bars update every 5 seconds automatically
- **Filters**:
  - *Last N days* — enter a number, click Apply
  - *Date range* — pick From / To dates, click Apply

### Offline detection

Two conditions both render as offline (dark grey):
1. `ms = NULL` — ping failed while computer was running
2. Gap > 60s between consecutive rows — computer was off or waybar stopped

---

## Troubleshooting

**Waybar shows no text / dead class immediately:**
```bash
~/.config/waybar/scripts/network/ping.sh
# Should print JSON within ~3 seconds
```

**Pango tags rendered as literal text:**  
Make sure `"markup": true` is set in the `custom/ping` module definition in `config.jsonc`.

**Browser shows "Failed to load":**
```bash
systemctl --user status ping-viz
systemctl --user restart ping-viz
curl http://localhost:8765/
```

**DB not growing:**
```bash
sqlite3 ~/.config/waybar/data/pings.db "SELECT MAX(ts) FROM pings;"
# Should be within last 10 seconds if waybar is running
```

**Check ping.sh logs:**
```bash
tail -f ~/.config/waybar/logs/ping.log
```

---

## File reference

```
~/.config/waybar/
├── config.jsonc                          # Waybar bar config
├── style.css                             # Waybar CSS (quality classes)
├── scripts/
│   └── network/
│       └── ping.sh                       # Data collection script
├── analysis/
│   ├── server.py                         # HTTP visualization server
│   ├── migrate_csv_to_sqlite.py          # One-time CSV → SQLite migration
│   └── migrate_add_target_host.py        # One-time schema migration (add target_host)
├── data/
│   ├── ping.config                       # Target list (hosts + labels + thresholds)
│   ├── pings.db                          # SQLite database
│   └── ping_plot.html                    # Browser frontend
└── logs/
    └── ping.log                          # ping.sh runtime log

~/.config/systemd/user/
└── ping-viz.service                      # Systemd unit for HTTP server
```
