# Phase 51: WWO Fetcher Service & Local Cache Architecture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-02T22:20:00+06:00
**Phase:** 51-WWO Fetcher Service & Local Cache Architecture
**Areas discussed:** Script & config location, Cadence & rate-limit safety guards, Cache schema & offline resilience, Location configuration

---

## Architecture Strategy: System Monitor vs Standalone Fetcher

| Option | Description | Selected |
|--------|-------------|----------|
| Option A: `system_monitor` daemon | Integrate WWO fetching into containerized Python server on port 8765 with browser web UI | |
| Option B: Standalone script + Systemd timer | Standalone Python fetcher and systemd user timer writing directly to `$XDG_RUNTIME_DIR/weather/weather.json` | ✓ |
| Option C: Hybrid architecture | Standalone systemd fetcher writing atomic JSON cache + `system_monitor` serving/consuming it for web UI | |

**User's choice:** Option B (stick to original plan).
**Notes:** Evaluated the trade-offs of embedding into the Docker `system_monitor` server. User decided to stick with the standalone systemd timer to ensure the desktop shell remains decoupled from Docker with zero idle CPU overhead.

---

## Script & Config Location

| Option | Description | Selected |
|--------|-------------|----------|
| `scripts/weather/wwo-fetcher.py` | In dotfiles root, directly invoked by systemd (%h/github_repo/.dotfiles/scripts/weather/wwo-fetcher.py) and testable via CLI | |
| `restow/quickshell/.../wwo-fetcher.py` | Symlinked via Stow into ~/.config/quickshell/ii/scripts/ | |
| `stow/systemd/.../wwo-fetcher.py` | Co-located inside the stow/systemd package alongside units | |
| `stow/weather/` dedicated package | Dedicated package under stow/ linked to ~/.config/weather/ with units in ~/.config/systemd/user/ | ✓ |

**User's choice:** Dedicated `stow/weather/` package.
**Notes:** User questioned why the script wouldn't be stowed. The stow architecture was reviewed, confirming that stowing `weather` guarantees clean `$HOME` symlinks and portability on clean installs.

| Option | Description | Selected |
|--------|-------------|----------|
| Systemd `RuntimeDirectory=weather` | Systemd automatically manages and creates `$XDG_RUNTIME_DIR/weather` with correct permissions | ✓ |
| Manual `os.makedirs` in script | Python script handles creating the runtime directory | |

**User's choice:** Systemd `RuntimeDirectory=weather`.

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh install bootstrap integration | Handled automatically via `bootstrap.sh` (`step_stow` and `step_verify`) | ✓ |
| Dedicated installer script `arch/weather.sh` | Separate installer script | |

**User's choice:** Install automatically as part of fresh machine setup via `bootstrap.sh`.

---

## Cadence & Rate-Limit Safety Guards

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic budget pacing (3m floor, 30-call buffer) | 3-minute base timer calculating calls remaining vs minutes left in 24h window (470 budget limit) | ✓ |
| Fixed 15-minute interval (96 calls/day) | Fixed interval consuming under 20% of 500-call quota | |
| Fixed 20-minute interval (72 calls/day) | Conservative fixed interval | |

**User's choice:** Dynamic budget pacing with a 3-minute floor and 30-call reserve.
**Notes:** User proposed calculating calls dynamically based on remaining time in the 24h window to allow faster updates when the machine is active.

| Option | Description | Selected |
|--------|-------------|----------|
| Wait until next timer tick (3m) | No immediate retry loop; preserve existing cache with `is_stale: true` and error metadata | ✓ |
| Single immediate retry after 5s | Retry once on failure | |
| Exponential backoff retry | Multiple retries before waiting for timer | |

**User's choice:** Wait until next timer tick (3m). Avoids wasting API quota during network outages.

---

## Cache Schema & Offline Resilience

| Option | Description | Selected |
|--------|-------------|----------|
| Envelope wrapper with metadata header | `{ status, fetched_at, is_stale, error, quota, data: {...} }` | ✓ |
| Direct WWO payload with injected keys | Raw data with `_is_stale` injected | |

**User's choice:** Envelope wrapper. Cleanly isolates operational telemetry from raw meteorological objects.

| Option | Description | Selected |
|--------|-------------|----------|
| Fallback skeleton JSON on cold boot | Write minimal valid JSON on cold boot so Quickshell `FileView` never hits `ENOENT` | ✓ |
| Wait for first successful fetch | Do not write file until verified response | |

**User's choice:** Provision fallback skeleton JSON.

| Option | Description | Selected |
|--------|-------------|----------|
| Persistent fallback in `~/.local/state/weather/` | Mirror cache to persistent disk; restore into `$XDG_RUNTIME_DIR` on cold boot if offline | ✓ |
| Pure `$XDG_RUNTIME_DIR` only | Ephemeral in-memory tmpfs only | |

**User's choice:** Persistent fallback in `~/.local/state/weather/`.

---

## Location Configuration

| Option | Description | Selected |
|--------|-------------|----------|
| City name only | Pass city name directly to WWO query 'q' without coordinates or external IP lookup | ✓ |
| Lat/Lon coordinates | Require latitude and longitude in config | |
| Automatic IP geolocation | Fallback to IP geolocation service | |

**User's choice:** Strictly city name only.

| Option | Description | Selected |
|--------|-------------|----------|
| Read from `config.json` only | Always read `bar.weather.city` from `~/.config/illogical-impulse/config.json` | ✓ |
| 3-tier resolution order | `.env` override → `config.json` → default fallback | |

**User's choice:** Strictly use `config.json` only (`bar.weather.city`). Keeps `.env` strictly for secrets (`WWO_API_KEY`).

---

## the agent's Discretion

- CLI helper flags for manual execution (e.g. `--force` to bypass dynamic pacing, `--status` to check quota, `--dry-run`).
- Temp file naming strategy in `$XDG_RUNTIME_DIR/weather/` prior to atomic `os.replace`.
- Internal logging formatting and systemd journal tags (`SyslogIdentifier=wwo-fetcher`).

---

## Deferred Ideas

- Optional future integration with `system_monitor` (`server.py`) to expose a web browser dashboard at `http://127.0.0.1:8765/weather`.
