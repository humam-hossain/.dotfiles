# Phase 51: WWO Fetcher Service & Local Cache Architecture - Context

**Gathered:** 2026-10-02T22:20:00+06:00
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 51 delivers the backend data ingestion, dynamic rate-limiting, and local caching engine for WorldWeatherOnline (WWO) weather telemetry. It builds a decoupled background Python fetcher and systemd user timer that queries the WWO API under a strict daily quota budget and atomically writes `$XDG_RUNTIME_DIR/weather/weather.json`.

**In scope:**
- Dedicated `stow/weather/` package containing `wwo-fetcher.py`, `.env.example`, and user systemd units (`wwo-fetcher.service`, `wwo-fetcher.timer`).
- Dynamic rate-limit budgeting engine tracking daily API calls against the 500-call quota (resetting at 00:00 UTC) with a 3-minute minimum polling floor and 30-call safety buffer.
- Atomic file caching using `os.replace` to `$XDG_RUNTIME_DIR/weather/weather.json` to eliminate partial read race conditions in Quickshell.
- Offline resilience preserving previous forecast data with `is_stale: true` during network drops or API errors without burning retries.
- Cold-boot offline skeleton provisioning and persistent cache mirroring to `~/.local/state/weather/last_known_weather.json` to survive offline reboots.
- Reading query location directly from dots-hyprland's `~/.config/illogical-impulse/config.json` (`bar.weather.city`).
- Automation in `./bootstrap.sh` (`step_stow` and `step_verify`) for fresh machine setups.

**Out of scope:**
- Any QML UI, widgets, status bar pills, or Material glyph mapping (Phases 52–55).
- Web application dashboard or Docker integration in `system_monitor` (evaluated and deferred).

</domain>

<decisions>
## Implementation Decisions

### 1. Script & Config Location
- **D-51-01:** Package the fetcher in a dedicated GNU Stow package at `stow/weather/.config/weather/wwo-fetcher.py`, symlinking to `~/.config/weather/wwo-fetcher.py`. Place systemd user units in `stow/weather/.config/systemd/user/wwo-fetcher.{service,timer}`. — **Reversibility:** reversible
- **D-51-02:** Use systemd directive `RuntimeDirectory=weather` in `wwo-fetcher.service` so systemd automatically creates and manages `$XDG_RUNTIME_DIR/weather` with correct user permissions and lifecycle. — **Reversibility:** reversible
- **D-51-03:** Store API credentials in `~/.config/weather/.env` (gitignored, tracked via `.env.example`). Hook the weather stow package into `./bootstrap.sh` (`step_stow` auto-links `stow/*` packages, and `step_verify` activates `wwo-fetcher.timer`). — **Reversibility:** reversible

### 2. Cadence & Dynamic Rate-Limit Safety Guards
- **D-51-04:** Implement dynamic budget pacing with a 3-minute base systemd timer (`OnUnitActiveSec=3m`). The fetcher checks a local quota state file (`~/.local/state/weather/quota.json`) tracking `calls_today` against a 470-call budget (reserving 30 calls for manual `--force` CLI refreshes). It dynamically computes the pacing interval: $\frac{\text{minutes until 00:00 UTC}}{\max(1, 470 - \text{calls\_today})}$, clamped to a minimum floor of 3 minutes. If the computed interval has not elapsed, the script exits immediately with zero network overhead. — **Reversibility:** reversible
- **D-51-05:** Handle network drops, DNS errors, timeouts, and API 5xx responses by recording error metadata, preserving existing cached data with `is_stale: true`, and waiting until the next timer tick (3 minutes) without an immediate retry loop to avoid wasting quota on network outages. — **Reversibility:** reversible

### 3. Cache Schema & Offline Resilience
- **D-51-06:** Format `$XDG_RUNTIME_DIR/weather/weather.json` using an envelope wrapper separating operational metadata from the raw WWO API payload:
  ```json
  {
    "status": "ok",
    "fetched_at": "2026-10-02T22:20:00+06:00",
    "fetched_epoch": 1727886000,
    "is_stale": false,
    "error": null,
    "quota": {
      "calls_today": 42,
      "calls_remaining": 428,
      "resets_at_utc": "2026-10-03T00:00:00Z"
    },
    "data": { ... raw WWO response ... }
  }
  ```
  — **Reversibility:** costly — Downstream QML services (Phase 52 `WeatherService.qml`) depend directly on this schema contract.
- **D-51-07:** Provision a fallback skeleton JSON (`status: "offline"`, `is_stale: true`, `data: null`) if the system starts with no cache present, ensuring Quickshell `FileView` never throws `ENOENT` (file not found) errors. — **Reversibility:** reversible
- **D-51-08:** Maintain a persistent copy of the latest successful payload in `~/.local/state/weather/last_known_weather.json`. On cold boot without network connectivity, restore this payload into `$XDG_RUNTIME_DIR/weather/weather.json` with `is_stale: true` so the previous forecast remains visible with a stale badge across reboots. — **Reversibility:** reversible

### 4. Location Configuration
- **D-51-09:** Strictly use city name only (no lat/lon coordinates or dynamic IP lookups). The single source of truth for the city name is `~/.config/illogical-impulse/config.json` (`bar.weather.city`). The `.env` file is reserved strictly for secrets (`WWO_API_KEY`). Fallback to `"Dhaka"` if `config.json` is missing or unreadable. — **Reversibility:** reversible

### the agent's Discretion
- Exact CLI flags for `wwo-fetcher.py` (e.g. `--force` to bypass pacing, `--status` to inspect quota, `--dry-run` to test without writing).
- Internal logging formatting and systemd journal tags (`SyslogIdentifier=wwo-fetcher`).
- Temporary file naming convention in `$XDG_RUNTIME_DIR/weather/` prior to `os.replace`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Weather API & Parameters
- `test_wwo_api/WEATHER_PARAMETERS.md` — Comprehensive parameter reference and JSON field mapping for WorldWeatherOnline API.
- `test_wwo_api/test_wwo.py` — Tested, working Python reference script demonstrating WWO query parameters and parsing.
- `test_wwo_api/raw_response.json` — Real sample payload returned by WWO API.

### Project Architecture & Requirements
- `.planning/REQUIREMENTS.md` § v0.10 Requirements (WWO-01 through WWO-04) — Core milestone requirements.
- `.planning/ROADMAP.md` § Phase 51 — Phase scope, success criteria, and dependency chain.
- `stow/README.md` — GNU Stow package structure and non-colliding installer conventions.
- `bootstrap.sh` — Step 5 (`step_stow`) and Step 7 (`step_verify`) system bootstrap orchestrator.

### Configuration Source of Truth
- `~/.config/illogical-impulse/config.json` § `bar.weather.city` — Authoritative desktop shell location configuration.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test_wwo_api/test_wwo.py`: Complete query parameter dictionary (`tp=1`, `num_of_days=3`, `aqi=yes`, `alerts=yes`, `fx24=yes`, `extra=isDayTime,utcDateTime,localObsTime`), urllib request handling, and error trapping.
- `stow/systemd/.config/systemd/user/dotfiles-capture.{service,timer}`: Reference implementation of oneshot user services and periodic timers.
- `bootstrap.sh`: Iterates all packages in `stow/` during `step_stow` and enables user timers during `step_verify`.

### Established Patterns
- **Pure Python Standard Library:** Uses standard `urllib.request`, `json`, `os`, `pathlib` with zero pip dependencies, eliminating virtualenv requirements for background systemd jobs.
- **Atomic Cache Replacement:** Writes to a unique temp file (`weather.json.tmp.<pid>`) in the target directory and replaces via `os.replace` to guarantee atomicity on POSIX filesystems.
- **Systemd Managed Runtime Directory:** Declares `RuntimeDirectory=weather` in unit file, delegating directory creation and permissions to systemd.

### Integration Points
- `$XDG_RUNTIME_DIR/weather/weather.json`: The primary interface contract between the Python fetcher and Quickshell desktop shell (`WeatherService.qml` in Phase 52).
- `~/.local/state/weather/quota.json`: Local state tracking daily quota usage.
- `~/.local/state/weather/last_known_weather.json`: Persistent disk fallback across machine reboots.
- `~/.config/illogical-impulse/config.json`: Read-only config source for `bar.weather.city`.

</code_context>

<specifics>
## Specific Ideas
- Dynamic budget pacing math: Paces 470 calls across remaining minutes in the UTC day, ensuring users get rapid updates (~3m) when the computer is actively running while strictly preventing WWO 429 quota exhaustion.
- Decoupled from Docker: Evaluated moving into `system_monitor` container, but rejected in favor of a lean standalone systemd service to keep desktop shell performance decoupled from Docker.

</specifics>

<deferred>
## Deferred Ideas
- None — discussion stayed strictly within Phase 51 scope.
- Note: Web UI dashboard integration into `system_monitor` (`server.py`) was evaluated during discussion and deferred as an optional future enhancement to avoid coupling desktop shell weather to Docker.

</deferred>

---

*Phase: 51-WWO Fetcher Service & Local Cache Architecture*
*Context gathered: 2026-10-02T22:20:00+06:00*
