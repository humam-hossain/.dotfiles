# Waybar Ping Integration

Waybar module that displays ping status fetched from the ping monitor server.

## Prerequisites

The ping monitor must be running at `http://127.0.0.1:8765/`.

```bash
cd /home/pera/github_repo/.dotfiles
bash arch/system_monitor.sh   # Arch
# or
bash debian/monitor_system.sh  # Debian/Ubuntu
```

See `.config/system_monitor/ping/README.md` for full server setup.

## Setup

```bash
cd /home/pera/github_repo/.dotfiles
bash arch/waybar.sh
```

## `config.jsonc`

Add this module to your Waybar config:

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

## CSS classes

```css
#custom-ping.good     { color: #00C853; }
#custom-ping.medium   { color: #FFD600; }
#custom-ping.bad      { color: #FF6D00; }
#custom-ping.critical { color: #D50000; }
#custom-ping.dead     { color: #37474F; }
```

## Display modes

Default — label + latency per target in one colored span each:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping_status.sh"
```

Custom format — control layout; only the latency values are colored:

```jsonc
"exec": "~/.config/waybar/scripts/network/ping_status.sh '󰒍 %1 ISP: %2'"
```

`%1`, `%2`, ... map to targets by position in `ping.config`.

## Reload

```bash
killall -SIGUSR2 waybar
```

## Troubleshooting

**Waybar shows `ping down`:**

```bash
curl http://127.0.0.1:8765/api/status
docker compose -f ~/.config/system_monitor/ping/docker-compose.yml ps
docker compose -f ~/.config/system_monitor/ping/docker-compose.yml logs --tail=20
```

**Quick script test:**

```bash
~/.config/waybar/scripts/network/ping_status.sh
~/.config/waybar/scripts/network/ping_status.sh '󰒍 %1 ISP: %2'
```
