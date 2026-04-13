# Waybar Ping Monitor

Ping monitoring split into three parts:

- `server`: collects ping data every 5 seconds, writes SQLite history, serves HTTP APIs
- `web`: renders history in the browser from the server APIs
- `waybar`: fetches the latest computed status from the server and displays it in the bar

## Setup

Fast path on Arch:

```bash
cd /home/pera/github_repo/.dotfiles
bash arch/waybar.sh
```

The script installs the packages required by the tracked Waybar setup, syncs the
managed Waybar files, installs `ping-viz.service`, removes stale managed files,
and restarts/verifies the ping server.

### Requirements

- `waybar`
- `curl`
- `python3`
- `ping` (iputils)
- `systemd` user session

### Server

Create directories:

```bash
mkdir -p ~/.config/waybar/{analysis,data,logs,scripts/network}
mkdir -p ~/.config/systemd/user
```

Copy files:

| Source | Destination |
|--------|-------------|
| `monitor/server.py` | `~/.config/waybar/monitor/server.py` |
| `monitor/ping.config` | `~/.config/waybar/monitor/ping.config` |
| `monitor/ping_plot.html` | `~/.config/waybar/monitor/ping_plot.html` |
| `scripts/network/ping_status.sh` | `~/.config/waybar/scripts/network/ping_status.sh` |

Make the Waybar fetcher executable:

```bash
chmod +x ~/.config/waybar/scripts/network/ping_status.sh
```

Install the user service:

```bash
cp /home/pera/github_repo/.dotfiles/.config/systemd/user/ping-viz.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now ping-viz
systemctl --user status ping-viz
```

If you use `bash arch/waybar.sh`, this service setup is done automatically.

### Web

The web UI is served by the same server at:

```bash
http://127.0.0.1:8765/
```

No extra setup is required once the server is running.

### Waybar

In `~/.config/waybar/config.jsonc`, configure the module:

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

Add `"custom/ping"` to one of your module lists.

Add CSS classes in `~/.config/waybar/style.css`:

```css
#custom-ping.good     { color: #00C853; }
#custom-ping.medium   { color: #FFD600; }
#custom-ping.bad      { color: #FF6D00; }
#custom-ping.critical { color: #D50000; }
#custom-ping.dead     { color: #37474F; }
```

Reload Waybar:

```bash
killall -SIGUSR2 waybar
```

## Usage

### Server

Edit targets in `~/.config/waybar/monitor/ping.config`:

```text
host  [label]  t1  t2  t3
```

Example:

```text
8.8.8.8                                          󰒍        40  100  200
ip route | awk '/default/ {print $3; exit}'      ROUTER:   2    5   10
192.168.0.104                                    PC:       2    5   10
```

Notes:

- `host` can be a plain host/IP or a shell command that resolves to one
- `label` is optional and shown in Waybar
- `t1 t2 t3` are per-target thresholds
- config changes are picked up automatically on the next collection cycle

Useful checks:

```bash
systemctl --user status ping-viz
curl http://127.0.0.1:8765/api/status
sqlite3 ~/.config/waybar/data/pings.db "SELECT MAX(ts), COUNT(*) FROM pings;"
tail -f ~/.config/waybar/logs/ping.log
```

### Web

Open the history page:

```bash
xdg-open http://127.0.0.1:8765/
```

Available API routes:

- `GET /api/status` → latest Waybar JSON
- `GET /api/today` → today’s aggregated bars + `last_ping`
- `GET /api/pings?days=30` → historical aggregated bars

The page supports:

- last-N-days filtering
- date range filtering
- live refresh of today’s row every 5 seconds
- per-target thresholds in tooltips

### Waybar

Default display:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping_status.sh"
```

Custom format with placeholders:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping_status.sh '󰒍 %1 ISP: %2'"
```

Notes:

- `%1`, `%2`, ... map to targets by position in `ping.config`
- default mode renders `label + value` in one colored span
- custom mode colors only the substituted latency values

Quick checks:

```bash
~/.config/waybar/scripts/network/ping_status.sh
~/.config/waybar/scripts/network/ping_status.sh '󰒍 %1 ISP: %2'
```

### Troubleshooting

Waybar shows `ping down`:

```bash
curl http://127.0.0.1:8765/api/status
systemctl --user status ping-viz
```

History page fails to load:

```bash
curl http://127.0.0.1:8765/api/today | python3 -m json.tool | head -40
```

DB is not advancing:

```bash
watch -n 5 'sqlite3 ~/.config/waybar/data/pings.db "SELECT MAX(ts), COUNT(*) FROM pings;"'
```
