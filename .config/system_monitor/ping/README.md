# Ping Monitor

Docker-based ping collector with SQLite history and a browser UI.

## Setup

| Script | Platform | Bind host |
|--------|----------|-----------|
| `arch/system_monitor.sh` | Arch Linux | `127.0.0.1` (loopback) |
| `debian/monitor_system.sh` | Debian / Ubuntu | `0.0.0.0` (LAN-exposed) |

```bash
# Arch
cd /home/pera/github_repo/.dotfiles
bash arch/system_monitor.sh

# Debian/Ubuntu — all interfaces
bash debian/monitor_system.sh

# Debian/Ubuntu — specific interface
BIND_HOST=192.168.1.10 bash debian/monitor_system.sh
```

## Environment

Configuration is managed via `~/.config/system_monitor/ping/.env`. Copy `.env.example` to get started:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|----------|---------|-------------|
| `BIND_HOST` | `127.0.0.1` | IP address to bind (use `0.0.0.0` for LAN) |
| `PORT` | `8765` | HTTP server port |
| `COLLECTION_INTERVAL` | `5` | Seconds between ping cycles |
| `STALE_AFTER_SECONDS` | `15` | Seconds before Waybar shows "stale" |

## `ping.config`

Edit targets at `~/.config/system_monitor/ping/ping.config`:

```text
host  [label]  t1  t2  t3
```

```text
8.8.8.8                                          󰒍        40  100  200
ip route | awk '/default/ {print $3; exit}'      󰀂         2    5   10
192.168.0.104                                             2    5   10
```

- `host` — plain IP/hostname or shell command that resolves to one
- `label` — optional single token shown in Waybar
- `t1 t2 t3` — ms thresholds: normal / elevated / high; `>= t3` = critical
- config is reloaded each cycle; no restart needed

## API routes

- `GET /api/status` → Waybar JSON `{"text":"...","class":"..."}`
- `GET /api/today` → today's aggregated bars + `last_pings` per target
- `GET /api/pings?days=50` → historical aggregated bars
- `GET /` → browser history UI

## Useful checks

```bash
# Container status
docker compose -f ~/.config/system_monitor/ping/docker-compose.yml ps

# Latest Waybar status
curl http://127.0.0.1:8765/api/status # (default port)

# Most recent DB row
sqlite3 ~/.config/system_monitor/ping/data/pings.db "SELECT MAX(ts), COUNT(*) FROM pings;"

# Follow logs
docker compose -f ~/.config/system_monitor/ping/docker-compose.yml logs -f

# Open browser UI
xdg-open http://127.0.0.1:8765/ # (default port)
```

## Troubleshooting

**Container not running:**

```bash
docker compose -f ~/.config/system_monitor/ping/docker-compose.yml ps
docker compose -f ~/.config/system_monitor/ping/docker-compose.yml logs --tail=20
```

**DB not advancing:**

```bash
watch -n 5 'sqlite3 ~/.config/system_monitor/ping/data/pings.db "SELECT MAX(ts), COUNT(*) FROM pings;"'
```

**Gateway target not resolving** (`WARN skipping unresolved target`):
Container must have `iproute2` installed — already in the Dockerfile. Rebuild:

```bash
bash arch/system_monitor.sh
```
