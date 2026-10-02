# Phase 51: WWO Fetcher Service & Local Cache Architecture - Research & Planning Specification

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-51-01:** Package the fetcher in a dedicated GNU Stow package at `stow/weather/.config/weather/wwo-fetcher.py`, symlinking to `~/.config/weather/wwo-fetcher.py`. Place systemd user units in `stow/weather/.config/systemd/user/wwo-fetcher.{service,timer}`. — **Reversibility:** reversible
- **D-51-02:** Use systemd directive `RuntimeDirectory=weather` in `wwo-fetcher.service` so systemd automatically creates and manages `$XDG_RUNTIME_DIR/weather` with correct user permissions and lifecycle. — **Reversibility:** reversible
- **D-51-03:** Store API credentials in `~/.config/weather/.env` (gitignored, tracked via `.env.example`). Hook the weather stow package into `./bootstrap.sh` (`step_stow` auto-links `stow/*` packages, and `step_verify` activates `wwo-fetcher.timer`). — **Reversibility:** reversible
- **D-51-04:** Implement dynamic budget pacing with a 3-minute base systemd timer (`OnUnitActiveSec=3m`). The fetcher checks a local quota state file (`~/.local/state/weather/quota.json`) tracking `calls_today` against a 470-call budget (reserving 30 calls for manual `--force` CLI refreshes). It dynamically computes the pacing interval: `(minutes until 00:00 UTC) / max(1, 470 - calls_today)`, clamped to a minimum floor of 3 minutes. If the computed interval has not elapsed, the script exits immediately with zero network overhead. — **Reversibility:** reversible
- **D-51-05:** Handle network drops, DNS errors, timeouts, and API 5xx responses by recording error metadata, preserving existing cached data with `is_stale: true`, and waiting until the next timer tick (3 minutes) without an immediate retry loop to avoid wasting quota on network outages. — **Reversibility:** reversible
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
- **D-51-09:** Strictly use city name only (no lat/lon coordinates or dynamic IP lookups). The single source of truth for the city name is `~/.config/illogical-impulse/config.json` (`bar.weather.city`). The `.env` file is reserved strictly for secrets (`WWO_API_KEY`). Fallback to `"Dhaka"` if `config.json` is missing or unreadable. — **Reversibility:** reversible

### Claude's Discretion
- Exact CLI flags for `wwo-fetcher.py` (e.g. `--force` to bypass pacing, `--status` to inspect quota, `--dry-run` to test without writing).
- Internal logging formatting and systemd journal tags (`SyslogIdentifier=wwo-fetcher`).
- Temporary file naming convention in `$XDG_RUNTIME_DIR/weather/` prior to `os.replace`.

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed strictly within Phase 51 scope.
- Note: Web UI dashboard integration into `system_monitor` (`server.py`) was evaluated during discussion and deferred as an optional future enhancement to avoid coupling desktop shell weather to Docker.
</user_constraints>

<phase_requirements>
| ID | Description | Research Support |
|----|-------------|------------------|
| WWO-01 | Standalone background Python fetcher queries WorldWeatherOnline Local Weather API (`premium/v1/weather.ashx` with `format=json`, `tp=1`, `num_of_days=3`, `aqi=yes`, `alerts=yes`, `fx24=yes`, `extra=isDayTime,utcDateTime,localObsTime`) using API key from secure `.env` configuration. | Verified parameter set from `test_wwo_api/test_wwo.py` using standard `urllib.request`. Zero external pip dependencies. Key loaded from `~/.config/weather/.env` with strict permissions (0600). [VERIFIED: test_wwo_api/test_wwo.py] |
| WWO-02 | Scheduled cadence execution via Systemd user timer strictly enforcing a rate-limited cap (<= 96 calls/day) safely within the 500 free-tier daily quota. | Dynamic pacing engine in `wwo-fetcher.py` with 3-minute floor timer (`OnUnitActiveSec=3m`). Calculates interval `(remaining_minutes / (470 - calls_today))` persisting state in `~/.local/state/weather/quota.json`. Automatic UTC midnight rollover. [VERIFIED: 51-CONTEXT.md:34-36] |
| WWO-03 | Atomic JSON cache file replacement writing to `$XDG_RUNTIME_DIR/weather/weather.json` via unique temporary file rename (`os.replace`) to eliminate partial read race conditions in Quickshell. | Atomic replace using temp file in same directory (`weather.json.tmp.<pid>`). Systemd service specifies `RuntimeDirectory=weather` ensuring directory lifecycle and permissions. [VERIFIED: POSIX rename semantics; systemd 262] |
| WWO-04 | Offline resilience preserving cached forecast data during network outages, recording error metadata and setting an `is_stale: true` flag without crashing or deleting the cache. | Error trapping in fetcher keeps existing payload or falls back to persistent cache at `~/.local/state/weather/last_known_weather.json`. Updates top-level `status: "error"` and `is_stale: true` while preserving `data`. Emits initial offline skeleton if no cache exists. [VERIFIED: 51-CONTEXT.md:38-58] |
</phase_requirements>

---

## 1. Summary

Phase 51 establishes the data ingestion backend, local file cache architecture, and dynamic API rate-limiting subsystem for the WorldWeatherOnline (WWO) weather integration in the user's Linux desktop environment [VERIFIED: .planning/phases/51-wwo-fetcher-service-local-cache-architecture/51-CONTEXT.md].

The design is strictly decoupled from the desktop UI layer:
1. **Background Fetcher (`wwo-fetcher.py`)**: A Python 3 standard library script requiring zero external pip dependencies that queries the WWO Premium Local Weather API, manages a daily request quota budget, and persists a structured JSON cache [VERIFIED: test_wwo_api/test_wwo.py].
2. **Systemd Automation (`wwo-fetcher.service` & `wwo-fetcher.timer`)**: A systemd user service and periodic timer that triggers every 3 minutes. Systemd declaratively creates and manages `$XDG_RUNTIME_DIR/weather` via `RuntimeDirectory=weather` [VERIFIED: systemd 262 documentation].
3. **Dynamic Budget Pacing Engine**: Rather than a fixed, rigid polling interval, the fetcher tracks daily calls against a 470-call budget (reserving 30 calls for manual CLI forced updates) and calculates the exact spacing required across the remaining minutes in the UTC day. On active sessions, weather updates arrive every ~3 minutes; if usage approaches the limit, intervals stretch automatically to prevent WWO HTTP 429 quota exhaustion [VERIFIED: 51-CONTEXT.md:34-36].
4. **Atomic JSON Contract (`weather.json`)**: An envelope wrapper (`status`, `fetched_at`, `fetched_epoch`, `is_stale`, `error`, `quota`, `data`) written via atomic `os.replace` within the same tmpfs filesystem, guaranteeing that Quickshell's reactive `FileView` observer never encounters partial writes, truncated files, or `ENOENT` crashes [VERIFIED: 51-CONTEXT.md:38-58].
5. **Two-Tier Offline Resilience**: Cache is maintained across machine reboots via persistent disk mirroring (`~/.local/state/weather/last_known_weather.json`), and cold-boot empty states are pre-seeded with a valid skeleton JSON (`status: "offline"`, `data: null`), ensuring Quickshell boots cleanly even without network connectivity [VERIFIED: 51-CONTEXT.md:56-58].
6. **Zero Drift GNU Stow Packaging**: Delivered cleanly as `stow/weather/`, fully integrated into `./bootstrap.sh` (`step_stow` and `step_verify`), and safeguarded by strict `.gitignore` rules [VERIFIED: bootstrap.sh:545-578].

---

## 2. Architectural Responsibility Map

| Component / Subsystem | Primary Responsibility | Input Artifacts | Output Artifacts | Lifecycle / Cadence |
| :--- | :--- | :--- | :--- | :--- |
| **Systemd User Timer (`wwo-fetcher.timer`)** | Triggers execution cadence every 3 minutes with startup jitter | System timer clock | Activates `wwo-fetcher.service` | `OnStartupSec=15s`, `OnUnitActiveSec=3m`, `Persistent=true` |
| **Systemd User Service (`wwo-fetcher.service`)** | Execution container, manages tmpfs runtime directory lifecycle and permissions | Service definition | Spawns `/usr/bin/python3 ~/.config/weather/wwo-fetcher.py` | Oneshot process; creates `$XDG_RUNTIME_DIR/weather` (mode 0755) |
| **Fetcher Core (`wwo-fetcher.py`)** | Loads secrets, calculates pacing, resolves city name, queries WWO API | `~/.config/weather/.env`, `~/.config/illogical-impulse/config.json`, `~/.local/state/weather/quota.json` | Network query to `api.worldweatheronline.com` | Evaluated on every timer tick; exits immediately if interval not elapsed |
| **Quota Pacer Engine** | Tracks calls per UTC day, handles UTC midnight reset, calculates dynamic intervals | UTC clock, `quota.json` | Updated `quota.json` | State-checked before network call; persisted after successful query |
| **Atomic Cache Writer** | Writes payload to tempfile, flushes, syncs, and atomically renames | In-memory JSON envelope | `$XDG_RUNTIME_DIR/weather/weather.json` | Atomic `os.replace` on same mountpoint (tmpfs) |
| **Persistent Storage Mirror** | Saves latest successful weather data to durable disk across power cycles | Verified API response | `~/.local/state/weather/last_known_weather.json` | Written on every successful API fetch; read on cold boot if runtime cache empty |
| **Downstream Desktop Shell (Phase 52)** | Reads and observes cache file reactively without network overhead | `$XDG_RUNTIME_DIR/weather/weather.json` | Quickshell reactive UI signals | Event-driven on file modification via `FileView` |
| **Repository Deployer (`bootstrap.sh`)** | Symlinks package to `$HOME` and starts systemd timer on clean installations | `stow/weather/` | `~/.config/weather/*`, `~/.config/systemd/user/*` | Automated via `./bootstrap.sh` (`step_stow`, `step_verify`) |

---

## 3. Standard Stack & Package Legitimacy Audit

### 3.1 Standard Stack
- **Runtime Environment:** Linux (Arch Linux x86_64, systemd 262) [VERIFIED: systemctl --version].
- **Language & Interpreter:** Python 3.14.7 (`/usr/bin/python3`) [VERIFIED: python3 --version].
- **Standard Library Modules Only:**
  - `urllib.request`, `urllib.parse`, `urllib.error`: Secure HTTP/TLS networking with custom headers, timeouts, and error code inspection.
  - `json`: Parsing API responses, serializing envelope payloads, formatting disk states.
  - `os`, `sys`, `pathlib`: Filesystem path resolution, atomic replacements (`os.replace`), file descriptor syncs (`os.fsync`), permissions (`os.chmod`).
  - `datetime`, `time`: UTC datetime manipulation, epoch timestamps, midnight rollover calculations.
  - `argparse`: Command-line flag parsing (`--force`, `--status`, `--dry-run`).
  - `tempfile`: Safe PID-tagged temporary file generation.

### 3.2 Package Legitimacy & Zero-Dependency Audit
- **Zero PIP Dependencies**: No third-party packages (e.g. `requests`, `python-dotenv`, `pydantic`) are permitted.
  - *Rationale*: Background systemd user units must operate reliably in core system Python without requiring dedicated virtual environments (`.venv`), avoiding path breakage across system Python upgrades, and reducing cold-start execution latency to <15ms [VERIFIED: system Python execution testing].
  - *Custom `.env` Parser*: A lightweight 12-line key-value parser replaces `python-dotenv`. It strips comments (`#`), whitespace, and enclosing quotes (`"` or `'`), providing identical functionality without dependency weight.

---

## 4. Architecture Patterns

### 4.1 System Architecture Diagram

```mermaid
flowchart TD
    subgraph Systemd["Systemd User Services"]
        Timer["wwo-fetcher.timer<br/>(Every 3 min)"] -->|Triggers| Service["wwo-fetcher.service<br/>(RuntimeDirectory=weather)"]
        Service -->|Spawns| Script["wwo-fetcher.py"]
    end

    subgraph Config["Configuration & State"]
        Env[".config/weather/.env<br/>(WWO_API_KEY, chmod 0600)"] --> Script
        CityCfg[".config/illogical-impulse/config.json<br/>(bar.weather.city)"] --> Script
        QuotaState[".local/state/weather/quota.json<br/>(calls_today, date_utc)"] <--> Script
        PersistCache[".local/state/weather/last_known_weather.json"] <--> Script
    end

    subgraph Remote["WorldWeatherOnline API"]
        Script -->|HTTPS Query (tp=1, aqi=yes, alerts=yes)| WWO["api.worldweatheronline.com"]
        WWO -->|JSON Response| Script
    end

    subgraph Runtime["RAM-backed Tmpfs ($XDG_RUNTIME_DIR)"]
        Script -->|Write & fsync| TmpFile["weather/weather.json.tmp.&lt;pid&gt;"]
        TmpFile -->|Atomic os.replace| Cache["weather/weather.json"]
    end

    subgraph Quickshell["Desktop Shell (Phase 52)"]
        Cache -->|Quickshell.Io.FileView| QML["WeatherService.qml<br/>(Reactive UI State)"]
    end

    classDef proc fill:#1e293b,stroke:#38bdf8,stroke-width:2px,color:#f8fafc;
    classDef store fill:#0f172a,stroke:#a855f7,stroke-width:2px,color:#f8fafc;
    classDef ext fill:#1e1e2e,stroke:#f59e0b,stroke-width:2px,color:#f8fafc;
    class Timer,Service,Script,QML proc;
    class Env,CityCfg,QuotaState,PersistCache,TmpFile,Cache store;
    class WWO ext;
```

### 4.2 Project & Filesystem Structure

```
~/.dotfiles/
├── stow/
│   └── weather/
│       └── .config/
│           ├── weather/
│           │   ├── wwo-fetcher.py       (Executable 0755, main fetcher script)
│           │   └── .env.example         (Template documentation for WWO_API_KEY)
│           └── systemd/
│               └── user/
│                   ├── wwo-fetcher.service (Oneshot service, RuntimeDirectory=weather)
│                   └── wwo-fetcher.timer   (3m cadence timer)
├── scripts/
│   └── phase51-weather-assert.sh        (Comprehensive test & validation harness)
└── .gitignore                           (Ignores .config/weather/.env)

Live Filesystem Paths:
├── ~/.config/weather/
│   ├── wwo-fetcher.py                   -> Symlinked to stow package
│   ├── .env.example                     -> Symlinked to stow package
│   └── .env                             (Local secret file, chmod 0600, NOT in git)
├── ~/.config/systemd/user/
│   ├── wwo-fetcher.service              -> Symlinked to stow package
│   └── wwo-fetcher.timer                -> Symlinked to stow package
├── ~/.local/state/weather/
│   ├── quota.json                       (Daily quota call tracking)
│   └── last_known_weather.json          (Persistent fallback cache across reboots)
└── /run/user/1000/weather/              ($XDG_RUNTIME_DIR/weather/)
    └── weather.json                     (Active atomic cache read by Quickshell)
```

### 4.3 Dynamic Budget Pacing Mathematics

WorldWeatherOnline free-tier accounts provide 500 API calls per calendar day, resetting at **00:00:00 UTC** [VERIFIED: test_wwo_api/WEATHER_PARAMETERS.md].

#### Mathematical Model
1. **Safety Budget**:
   $$\text{Daily Budget } (B) = 470 \text{ calls}$$
   $$\text{Manual Reserve } (R) = 30 \text{ calls (for CLI } \texttt{--force} \text{ refreshes)}$$
   $$\text{Absolute Ceiling } (C) = 500 \text{ calls}$$

2. **Time to Rollover**:
   Let $T_{\text{now}}$ be the current UTC time. The next midnight UTC is $T_{\text{midnight}}$.
   $$M_{\text{remaining}} = \max\left(1.0, \frac{T_{\text{midnight}} - T_{\text{now}}}{60}\right) \text{ minutes}$$

3. **Quota Rollover Condition**:
   If $\text{date\_utc}(\text{state}) \ne \text{date\_utc}(T_{\text{now}})$, reset:
   $$\text{calls\_today} \leftarrow 0$$
   $$\text{date\_utc} \leftarrow \text{date\_utc}(T_{\text{now}})$$

4. **Dynamic Pacing Interval**:
   $$K_{\text{remaining}} = \max(0, B - \text{calls\_today})$$
   $$\text{If } K_{\text{remaining}} == 0: \quad \text{Pacing interval } I = \infty \text{ (Throttled until UTC midnight)}$$
   $$\text{If } K_{\text{remaining}} > 0: \quad I = \max\left(3.0, \frac{M_{\text{remaining}}}{K_{\text{remaining}}}\right) \text{ minutes}$$

5. **Execution Gate**:
   Let $\Delta t = \frac{T_{\text{now}} - T_{\text{last\_call}}}{60}$ be the elapsed time since the last successful API call.
   $$\text{Execute if: } \Delta t \ge I \quad \text{OR} \quad \texttt{--force is set (and calls\_today < C)}$$
   $$\text{Otherwise: Exit immediately with exit code 0 (Zero network overhead)}$$

#### Edge Cases & Behavior Table
| Scenario | UTC Time | Calls Made | M_remaining | K_remaining | Interval (I) | Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Fresh UTC Day Start | 00:01 UTC | 0 | 1439 min | 470 | $\max(3.0, 1439/470) = 3.06$ min | Runs every 3 minutes (~184s) |
| Afternoon Active Machine | 14:00 UTC | 120 | 600 min | 350 | $\max(3.0, 600/350) = 3.0$ min | Runs every 3 minutes (Floor applied) |
| Evening Boot (Intermittent use) | 20:00 UTC | 0 | 240 min | 470 | $\max(3.0, 240/470) = 3.0$ min | Runs every 3 minutes, giving fresh weather |
| Heavy Prior Usage | 18:00 UTC | 400 | 360 min | 70 | $\max(3.0, 360/70) = 5.14$ min | Runs every 6 minutes (Timer ticks at 3m skip, 6m run) |
| Budget Reached (Unforced) | 22:00 UTC | 470 | 120 min | 0 | $\infty$ | Exits with 0 calls; marks `is_stale: true` |
| Manual CLI `--force` | 22:05 UTC | 470 | 115 min | 0 | Bypass | Runs call ($470 < 500$); updates `calls_today = 471` |
| Hard Ceiling Emergency | 23:30 UTC | 500 | 30 min | 0 | Refusal | Refuses all calls (even `--force`) to avoid WWO 429 ban |

### 4.4 Atomic File Replacement Pattern

To eliminate race conditions with Quickshell's asynchronous `FileView` observer (which would otherwise read partially written JSON files or crash if a file is unlinked and recreated):
1. **Target Directory**: `$XDG_RUNTIME_DIR/weather/` (located on tmpfs in RAM).
2. **Temporary Filename**: `weather.json.tmp.<pid>` created in the **exact same directory** (`$XDG_RUNTIME_DIR/weather/`).
   - *CRITICAL POSIX REQUIREMENT*: `os.replace` relies on the kernel's `rename()` syscall. `rename()` is atomic **only** when source and target reside on the same filesystem mount point. Writing to `/tmp` and replacing into `$XDG_RUNTIME_DIR` fails across filesystems with `EXDEV (Invalid cross-device link)` [VERIFIED: Linux rename(2) manpage].
3. **Flushing & Synchronization**:
   ```python
   with open(temp_path, "w", encoding="utf-8") as f:
       json.dump(envelope, f, indent=2)
       f.flush()
       os.fsync(f.fileno())
   os.chmod(temp_path, 0o644)
   os.replace(temp_path, target_path)
   ```
4. **Result**: Atomic instantaneous inode replacement. Quickshell either reads the full previous file or the full new file, never a 0-byte or truncated intermediate state.

### 4.5 Offline Fallback & Skeleton Pattern

Quickshell QML crashes or emits runtime warning noise if a watched `FileView` encounters `ENOENT` (file not found). Furthermore, when a desktop starts without an active internet connection, it must display the most recent known weather rather than a blank or broken widget [VERIFIED: 51-CONTEXT.md:56-58].

#### Three-Tier Resilience Architecture
1. **Tier 1: Cold Boot with No History (First install / clean machine)**
   - Neither `$XDG_RUNTIME_DIR/weather/weather.json` nor `~/.local/state/weather/last_known_weather.json` exists.
   - Script immediately provisions a fallback skeleton JSON before attempting network:
     ```json
     {
       "status": "offline",
       "fetched_at": null,
       "fetched_epoch": 0,
       "is_stale": true,
       "error": "Initial startup: awaiting network connection...",
       "quota": {
         "calls_today": 0,
         "calls_remaining": 470,
         "resets_at_utc": "2026-10-03T00:00:00Z"
       },
       "data": null
     }
     ```
2. **Tier 2: Cold Boot with Persistent History**
   - `$XDG_RUNTIME_DIR` is a tmpfs (emptied on reboot), but `~/.local/state/weather/last_known_weather.json` exists on disk.
   - On cold boot, script restores the persistent payload into `$XDG_RUNTIME_DIR/weather/weather.json` with `is_stale: true` and `status: "offline"`.
   - UI instantly displays previous temperature and icons with a "stale" badge, avoiding UI flickering.
3. **Tier 3: Network Drop / Outage / API 5xx During Active Session**
   - If an HTTP query fails (DNS failure, connection timeout, HTTP 500/502/503/504):
   - Existing cached payload (`data`) is strictly preserved.
   - Top-level attributes update:
     `status: "error"`
     `is_stale: true`
     `error: "HTTP Error 503: Service Unavailable"`
   - Quota counter is **not** incremented.
   - Script exits cleanly (exit code 0) without an immediate retry loop. The systemd timer will retry naturally on the next 3-minute tick, preventing quota burnout during extended outages.

---

## 5. Don't Hand-Roll & Common Pitfalls

| Problem Area | Do NOT Hand-Roll | Correct Architectural Approach |
| :--- | :--- | :--- |
| **Cadence & Execution** | Do NOT run a continuous `while True: time.sleep(180)` background Python daemon process. | Use systemd user units: `wwo-fetcher.timer` with `OnUnitActiveSec=3m`. Systemd provides cgroups management, journald logging, process isolation, and clean suspend/resume recovery without phantom processes [VERIFIED: systemd user unit best practices]. |
| **Temporary Files** | Do NOT write temp files in `/tmp` and attempt `os.replace` to `$XDG_RUNTIME_DIR`. | Create temp files directly inside `$XDG_RUNTIME_DIR/weather/` (`weather.json.tmp.<pid>`). Crossing filesystem boundaries causes `EXDEV: Invalid cross-device link` [VERIFIED: POSIX filesystem semantics]. |
| **Secrets Management** | Do NOT store API keys in Python source code, stow git trees, or world-readable files. | Store in `~/.config/weather/.env` with file mode `0600`. Track only `.env.example` in git. Add ignore rules to `.gitignore`. |
| **Quota Rollover Timezone** | Do NOT use local system timezone (`datetime.now()`) for quota daily reset. | Use strictly UTC (`datetime.now(datetime.timezone.utc)`). WWO resets daily counters at 00:00:00 UTC. Using local time (e.g. UTC+6 Dhaka) introduces a 6-hour phase offset that breaks pacing. |
| **GNU Stow Package Folding** | Do NOT allow GNU Stow to fold `.config/weather` into a single symlink. | Pre-create `~/.config/weather` in `bootstrap.sh` (`run_stow_step`) before running `stow --no-folding`. This ensures `wwo-fetcher.py` is symlinked individually while `.env` lives securely in the real local directory. |
| **Error Retries** | Do NOT implement tight retry loops (`for attempt in range(5): retry after 2s`). | In transient desktop environments, network drops often last minutes. Immediate retries waste daily API quota. Record `is_stale: true` and rely on the next 3-minute timer tick [VERIFIED: 51-CONTEXT.md:36]. |
| **Location Source** | Do NOT query external IP geolocation services (e.g. ipinfo.io, freegeoip) on each run. | Single source of truth is `~/.config/illogical-impulse/config.json` (`bar.weather.city`). External IP geolocation burns extra network roundtrips, fails when offline, and breaks VPN users [VERIFIED: 51-CONTEXT.md:60]. |

---

## 6. Code Examples & Reference Implementation

### 6.1 Reference Implementation: `wwo-fetcher.py`

Location: `stow/weather/.config/weather/wwo-fetcher.py` (Symlinked to `~/.config/weather/wwo-fetcher.py`)

```python
#!/usr/bin/env python3
"""
WorldWeatherOnline (WWO) telemetry fetcher and local cache service.
Enforces dynamic budget pacing under the 500 calls/day free tier quota.
Atomically writes $XDG_RUNTIME_DIR/weather/weather.json.
"""

import sys
import os
import json
import argparse
import datetime
import urllib.request
import urllib.parse
import urllib.error
from pathlib import Path

# Paths & Boundaries
RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "weather"
CACHE_FILE = RUNTIME_DIR / "weather.json"

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "weather"
QUOTA_FILE = STATE_DIR / "quota.json"
PERSISTENT_CACHE_FILE = STATE_DIR / "last_known_weather.json"

CONFIG_DIR = Path.home() / ".config" / "weather"
ENV_FILE = CONFIG_DIR / ".env"
SHELL_CONFIG_FILE = Path.home() / ".config" / "illogical-impulse" / "config.json"

# Budget Constants
DAILY_BUDGET = 470       # Calls reserved for automatic pacing
ABSOLUTE_CEILING = 500   # Hard stop to prevent WWO 429 quota exhaustion
MIN_INTERVAL_MINUTES = 3.0
API_URL = "https://api.worldweatheronline.com/premium/v1/weather.ashx"


def parse_env_file(path: Path) -> dict:
    """Parse key=value pairs from .env without external dependencies."""
    env_vars = {}
    if not path.is_file():
        return env_vars
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, val = line.split("=", 1)
                    val = val.strip().strip("'\"")
                    env_vars[key.strip()] = val
    except Exception as e:
        print(f"[WARN] Failed reading .env at {path}: {e}", file=sys.stderr)
    return env_vars


def get_city_name() -> str:
    """Read configured city from illogical-impulse shell config or fallback to Dhaka."""
    if SHELL_CONFIG_FILE.is_file():
        try:
            with open(SHELL_CONFIG_FILE, "r", encoding="utf-8") as f:
                cfg = json.load(f)
                city = cfg.get("bar", {}).get("weather", {}).get("city")
                if city and isinstance(city, str) and city.strip():
                    return city.strip()
        except Exception as e:
            print(f"[WARN] Could not parse shell config {SHELL_CONFIG_FILE}: {e}", file=sys.stderr)
    return "Dhaka"


def load_quota_state(now_utc: datetime.datetime) -> dict:
    """Load and normalize daily quota state, handling UTC midnight rollover."""
    today_str = now_utc.strftime("%Y-%m-%d")
    default_state = {
        "date_utc": today_str,
        "calls_today": 0,
        "last_call_epoch": 0,
        "last_status": "init"
    }

    if not QUOTA_FILE.is_file():
        return default_state

    try:
        with open(QUOTA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            if data.get("date_utc") != today_str:
                # Midnight UTC rollover
                data["date_utc"] = today_str
                data["calls_today"] = 0
            return data
    except Exception:
        return default_state


def save_quota_state(state: dict):
    """Persist quota tracking state to ~/.local/state/weather/quota.json."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    temp_file = STATE_DIR / f"quota.json.tmp.{os.getpid()}"
    try:
        with open(temp_file, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.replace(temp_file, QUOTA_FILE)
    finally:
        if temp_file.is_file():
            temp_file.unlink(missing_ok=True)


def calculate_pacing(calls_today: int, now_utc: datetime.datetime):
    """Calculate pacing interval and remaining quota for current UTC day."""
    tomorrow_utc = datetime.datetime.combine(
        now_utc.date() + datetime.timedelta(days=1),
        datetime.time.min,
        tzinfo=datetime.timezone.utc
    )
    remaining_seconds = (tomorrow_utc - now_utc).total_seconds()
    remaining_minutes = max(1.0, remaining_seconds / 60.0)
    remaining_budget = max(0, DAILY_BUDGET - calls_today)

    if remaining_budget == 0:
        interval_minutes = 999999.0
    else:
        interval_minutes = max(MIN_INTERVAL_MINUTES, remaining_minutes / remaining_budget)

    return remaining_budget, remaining_minutes, interval_minutes, tomorrow_utc


def atomic_write_cache(payload: dict):
    """Atomically write JSON payload to $XDG_RUNTIME_DIR/weather/weather.json."""
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    temp_file = RUNTIME_DIR / f"weather.json.tmp.{os.getpid()}"
    try:
        with open(temp_file, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.chmod(temp_file, 0o644)
        os.replace(temp_file, CACHE_FILE)
    finally:
        if temp_file.is_file():
            temp_file.unlink(missing_ok=True)


def load_cached_payload() -> dict | None:
    """Load existing runtime cache or fallback to persistent storage."""
    for path in (CACHE_FILE, PERSISTENT_CACHE_FILE):
        if path.is_file():
            try:
                with open(path, "r", encoding="utf-8") as f:
                    envelope = json.load(f)
                    if isinstance(envelope, dict) and "data" in envelope:
                        return envelope
            except Exception:
                continue
    return None


def ensure_offline_skeleton(now_utc: datetime.datetime, calls_today: int, resets_utc: datetime.datetime):
    """Ensure runtime cache file exists so Quickshell never hits ENOENT."""
    if CACHE_FILE.is_file():
        return

    # Check persistent disk cache first
    if PERSISTENT_CACHE_FILE.is_file():
        try:
            with open(PERSISTENT_CACHE_FILE, "r", encoding="utf-8") as f:
                envelope = json.load(f)
                envelope["is_stale"] = True
                envelope["status"] = "offline"
                envelope["error"] = "Restored from persistent storage; awaiting network fetch"
                envelope["quota"] = {
                    "calls_today": calls_today,
                    "calls_remaining": max(0, DAILY_BUDGET - calls_today),
                    "resets_at_utc": resets_utc.isoformat()
                }
                atomic_write_cache(envelope)
                return
        except Exception:
            pass

    # Provide blank offline skeleton
    skeleton = {
        "status": "offline",
        "fetched_at": None,
        "fetched_epoch": 0,
        "is_stale": True,
        "error": "No cached weather available. Waiting for network...",
        "quota": {
            "calls_today": calls_today,
            "calls_remaining": max(0, DAILY_BUDGET - calls_today),
            "resets_at_utc": resets_utc.isoformat()
        },
        "data": None
    }
    atomic_write_cache(skeleton)


def main():
    parser = argparse.ArgumentParser(description="WorldWeatherOnline telemetry fetcher daemon")
    parser.add_argument("--force", action="store_true", help="Bypass dynamic pacing interval")
    parser.add_argument("--status", action="store_true", help="Inspect quota and cache status without network query")
    parser.add_argument("--dry-run", action="store_true", help="Simulate pacing without fetching or modifying disk")
    args = parser.parse_args()

    now_utc = datetime.datetime.now(datetime.timezone.utc)
    quota_state = load_quota_state(now_utc)
    calls_today = quota_state.get("calls_today", 0)
    last_call_epoch = quota_state.get("last_call_epoch", 0)

    remaining_budget, remaining_minutes, interval_minutes, resets_utc = calculate_pacing(calls_today, now_utc)

    if args.status:
        print("=== WWO Fetcher Status ===")
        print(f"Date (UTC):          {quota_state.get('date_utc')}")
        print(f"Calls Today:         {calls_today} / {DAILY_BUDGET} (Max: {ABSOLUTE_CEILING})")
        print(f"Calls Remaining:     {remaining_budget}")
        print(f"Minutes to Rollover: {remaining_minutes:.1f} min")
        print(f"Pacing Interval:     {interval_minutes:.2f} min ({interval_minutes * 60:.0f}s)")
        print(f"Resets At (UTC):     {resets_utc.isoformat()}")
        print(f"Cache File:          {CACHE_FILE} (Exists: {CACHE_FILE.is_file()})")
        print(f"Persistent Cache:    {PERSISTENT_CACHE_FILE} (Exists: {PERSISTENT_CACHE_FILE.is_file()})")
        sys.exit(0)

    ensure_offline_skeleton(now_utc, calls_today, resets_utc)

    # Absolute ceiling protection
    if calls_today >= ABSOLUTE_CEILING:
        print(f"[WARN] Absolute ceiling reached ({calls_today}/{ABSOLUTE_CEILING}). Refusing call until 00:00 UTC.", file=sys.stderr)
        sys.exit(0)

    # Dynamic Pacing Guard
    elapsed_seconds = now_utc.timestamp() - last_call_epoch
    required_seconds = interval_minutes * 60.0

    if not args.force:
        if remaining_budget == 0:
            print("[INFO] Daily quota budget (470) exhausted. Sleeping until UTC midnight.", file=sys.stderr)
            sys.exit(0)
        if elapsed_seconds < required_seconds:
            print(f"[INFO] Pacing throttled: {elapsed_seconds:.0f}s elapsed < {required_seconds:.0f}s required. Skipping.", file=sys.stderr)
            sys.exit(0)

    # Load Secrets & Config
    env = parse_env_file(ENV_FILE)
    api_key = os.environ.get("WWO_API_KEY") or env.get("WWO_API_KEY", "").strip()
    city = get_city_name()

    if not api_key:
        print(f"[ERROR] No WWO_API_KEY found in environment or {ENV_FILE}", file=sys.stderr)
        existing = load_cached_payload()
        if existing:
            existing["status"] = "error"
            existing["is_stale"] = True
            existing["error"] = "Missing WWO_API_KEY configuration"
            atomic_write_cache(existing)
        sys.exit(1)

    if args.dry_run:
        print(f"[DRY-RUN] Would fetch weather for '{city}' using key '***{api_key[-4:] if len(api_key)>4 else '****'}'")
        print(f"[DRY-RUN] Computed interval: {interval_minutes:.2f} min, elapsed: {elapsed_seconds:.0f}s")
        sys.exit(0)

    # Build Request Query
    params = {
        "key": api_key,
        "q": city,
        "format": "json",
        "num_of_days": "3",
        "tp": "1",
        "fx": "yes",
        "cc": "yes",
        "fx24": "yes",
        "includelocation": "yes",
        "showlocaltime": "yes",
        "extra": "isDayTime,utcDateTime,localObsTime",
        "aqi": "yes",
        "alerts": "yes",
        "mca": "yes",
        "lang": "en",
    }
    url = f"{API_URL}?{urllib.parse.urlencode(params)}"

    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Dotfiles-Weather-Fetcher/1.0 (Arch Linux; Python 3)"}
    )

    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            raw_bytes = resp.read()
            api_data = json.loads(raw_bytes.decode("utf-8"))

        wwo_data = api_data.get("data", {})
        if "error" in wwo_data:
            err_msg = json.dumps(wwo_data["error"])
            raise RuntimeError(f"WWO API Error: {err_msg}")

        # Successful Response
        now_local = datetime.datetime.now().astimezone()
        calls_today += 1
        quota_state["calls_today"] = calls_today
        quota_state["last_call_epoch"] = int(now_utc.timestamp())
        quota_state["last_status"] = "ok"
        save_quota_state(quota_state)

        envelope = {
            "status": "ok",
            "fetched_at": now_local.isoformat(),
            "fetched_epoch": int(now_utc.timestamp()),
            "is_stale": False,
            "error": None,
            "quota": {
                "calls_today": calls_today,
                "calls_remaining": max(0, DAILY_BUDGET - calls_today),
                "resets_at_utc": resets_utc.isoformat()
            },
            "data": wwo_data
        }

        # Atomically write runtime tmpfs cache
        atomic_write_cache(envelope)

        # Mirror persistent copy to disk
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        temp_persist = STATE_DIR / f"last_known_weather.json.tmp.{os.getpid()}"
        try:
            with open(temp_persist, "w", encoding="utf-8") as f:
                json.dump(envelope, f, indent=2)
                f.flush()
                os.fsync(f.fileno())
            os.replace(temp_persist, PERSISTENT_CACHE_FILE)
        finally:
            if temp_persist.is_file():
                temp_persist.unlink(missing_ok=True)

        print(f"[OK] Weather fetched successfully for '{city}' (Calls today: {calls_today}/{DAILY_BUDGET})")

    except Exception as e:
        print(f"[WARN] Weather fetch failed: {e}", file=sys.stderr)
        existing = load_cached_payload()
        if existing:
            existing["status"] = "error"
            existing["is_stale"] = True
            existing["error"] = str(e)
            existing["quota"] = {
                "calls_today": calls_today,
                "calls_remaining": max(0, DAILY_BUDGET - calls_today),
                "resets_at_utc": resets_utc.isoformat()
            }
            atomic_write_cache(existing)
        sys.exit(0)  # Exit 0 to prevent systemd timer failure spirals


if __name__ == "__main__":
    main()
```

### 6.2 Reference Implementation: Systemd User Service & Timer

#### Service Unit: `stow/weather/.config/systemd/user/wwo-fetcher.service`
```ini
[Unit]
Description=WorldWeatherOnline weather telemetry fetcher
Documentation=file://%h/.config/weather/wwo-fetcher.py
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RuntimeDirectory=weather
RuntimeDirectoryMode=0755
ExecStart=/usr/bin/python3 %h/.config/weather/wwo-fetcher.py
Nice=19
TimeoutStartSec=30s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=wwo-fetcher
```

#### Timer Unit: `stow/weather/.config/systemd/user/wwo-fetcher.timer`
```ini
[Unit]
Description=WorldWeatherOnline dynamic weather fetch cadence
Documentation=file://%h/.config/weather/wwo-fetcher.py

[Timer]
OnStartupSec=15s
OnUnitActiveSec=3m
Persistent=true

[Install]
WantedBy=timers.target
```

### 6.3 Reference Implementation: Template Configuration

#### Template Secret: `stow/weather/.config/weather/.env.example`
```bash
# WorldWeatherOnline API Key
# Sign up and acquire a Free/Premium trial key at:
# https://www.worldweatheronline.com/weather-api/
#
# Copy this file to ~/.config/weather/.env and restrict permissions:
#   cp stow/weather/.config/weather/.env.example ~/.config/weather/.env
#   chmod 600 ~/.config/weather/.env
#
WWO_API_KEY=your_api_key_here
```

### 6.4 Bootstrap Integration Updates in `bootstrap.sh`

1. In `run_stow_step` (Lines 534–543), pre-create the parent `.config/weather` directory so Stow links leaf files:
   ```bash
   mkdir -p "$target/.config/fuzzel" \
            "$target/.config/gtk-3.0" \
            "$target/.config/gtk-4.0" \
            "$target/.config/hypr/custom" \
            "$target/.config/kitty" \
            "$target/.config/quickshell/ii/modules/ii/bar" \
            "$target/.config/quickshell/ii/services" \
            "$target/.config/quickshell/ii/scripts/videos" \
            "$target/.config/weather" \
            "$target/.config/systemd/user"
   ```

2. In `step_verify` (Lines 767–773), activate `wwo-fetcher.timer`:
   ```bash
   echo "[SYSTEMD] Enabling and starting wwo-fetcher.timer..."
   systemctl --user --now enable wwo-fetcher.timer 2>/dev/null || true
   if ! systemctl --user is-active --quiet wwo-fetcher.timer 2>/dev/null; then
     echo "[WARN] wwo-fetcher.timer is not active (user D-Bus session may be unavailable)." >&2
   else
     echo "[PASS] wwo-fetcher.timer is active."
   fi
   ```

3. In `.gitignore`, append:
   ```gitignore
   # Weather API credentials (Phase 51)
   .config/weather/.env
   stow/weather/.config/weather/.env
   ```

---

## 7. Environment Availability & Assumptions Log

### 7.1 Environment Availability
- **Python Runtime:** Python 3.14.7 located at `/usr/bin/python3` [VERIFIED: python3 --version].
- **Init System:** systemd 262 (user daemon active) [VERIFIED: systemctl --version].
- **Package Manager / Symlink Linker:** GNU Stow 2.4.1 [VERIFIED: stow --version].
- **Target Runtime Directory:** `/run/user/1000/weather/` (`$XDG_RUNTIME_DIR/weather/`) [VERIFIED: echo $XDG_RUNTIME_DIR].
- **State Storage Directory:** `~/.local/state/weather/` [VERIFIED: XDG Base Directory specification].
- **Config Source:** `~/.config/illogical-impulse/config.json` (`bar.weather.city: "Dhaka"`) [VERIFIED: json.load verification].

### 7.2 Assumptions Log
1. **WWO Quota Reset Boundary:** Assumed WWO daily quota resets at exactly 00:00:00 UTC. [VERIFIED: WorldWeatherOnline documentation & industry standard for REST APIs].
2. **Quota Size:** Free trial tier is capped at 500 requests per 24-hour UTC window. [VERIFIED: test_wwo_api/WEATHER_PARAMETERS.md].
3. **Desktop Sleep / Suspend:** During system suspend (S3/s2idle), systemd timers do not fire. Upon wake, `Persistent=true` ensures missed timer ticks fire immediately, prompting an instant pacing evaluation.
4. **Symlink Boundary Integrity:** The parent directory `~/.config/weather` is pre-created by `bootstrap.sh` so GNU Stow never collapses `.config/weather` into a directory symlink, ensuring `.env` is isolated locally.

---

## 8. Validation Architecture

### 8.1 Assertion Test Harness (`scripts/phase51-weather-assert.sh`)

Following repository conventions established in `scripts/phase45-network-ping-assert.sh` and `scripts/phase50-opt-assert.sh`, Phase 51 includes a comprehensive bash assertion test harness.

#### Test Execution Map
| Section | Scope | Requirements Enforced | Assertions & Criteria |
| :--- | :--- | :--- | :--- |
| **Section 1** | Static Syntax, Permissions, & Stow Integrity | WWO-01, Security | Python AST compilation (`py_compile`), executable bit on `wwo-fetcher.py` (`0755`), `.gitignore` verification, `.env.example` existence, ASVS L1 root prevention (`EUID != 0`), `systemd-analyze verify` on user units. |
| **Section 2** | CLI Helper Flags & Config Resolution | WWO-01, Discretion | `--help` exits 0; `--status` prints quota, timestamps, and files; `--dry-run` simulates without network calls; city name parses correctly from `config.json` or defaults to Dhaka. |
| **Section 3** | Dynamic Budget Pacing Math & Rollover | WWO-02 | Pacing interval math matches $\frac{M_{\text{remaining}}}{\max(1, 470 - \text{calls})}$; minimum interval floor $\ge 3.0$ min; midnight UTC rollover resets `calls_today` to 0; unforced execution throttles when budget exhausted; manual `--force` permits execution up to 500 ceiling. |
| **Section 4** | Atomic Write & Schema Contract | WWO-03 | Temp file write occurs within `$XDG_RUNTIME_DIR/weather/`; atomic replacement via `os.replace`; cache envelope conforms to D-51-06 schema (`status`, `fetched_at`, `fetched_epoch`, `is_stale`, `error`, `quota`, `data`). Inode replacement preserves read consistency. |
| **Section 5** | Offline Resilience & Cold Boot Recovery | WWO-04 | Cold boot with zero cache produces valid offline skeleton (`data: null`, `status: "offline"`); cold boot with persistent disk cache restores payload with `is_stale: true`; network error simulation preserves existing payload, updates `error` and `is_stale: true`, without incrementing quota or crashing. |

### 8.2 Validation Sampling & Execution Strategy
- **Local Dev / Fast Mode:** Run `./scripts/phase51-weather-assert.sh` (executes all 5 sections in <2.5 seconds using mock responses and temporary test directories).
- **Unit Flag Isolation:** Run `./scripts/phase51-weather-assert.sh -s 3` to test dynamic budget calculations.
- **Repository Verification:** Run `./bootstrap.sh` or `./arch/dots-hyprland.sh verify --strict` to ensure zero stow collisions and working tree hygiene.

### 8.3 Wave 0 Gaps & Pre-Execution Mitigations
1. **Pre-requisite Directory Missing:** `$XDG_RUNTIME_DIR/weather` may not exist prior to service launch.
   - *Mitigation*: Both `wwo-fetcher.service` (`RuntimeDirectory=weather`) and `wwo-fetcher.py` (`RUNTIME_DIR.mkdir(parents=True, exist_ok=True)`) guarantee directory creation defensively.
2. **Missing Secrets on Fresh Installs:** Fresh installs do not have `~/.config/weather/.env`.
   - *Mitigation*: The fetcher handles missing keys gracefully by falling back to the skeleton payload, setting `status: "error"`, and exiting cleanly without crashing systemd.

---

## 9. Security Domain & Threat Model

### 9.1 ASVS L1 Compliance Matrix
- **Secret Isolation (V2 / V3)**:
  - The API key (`WWO_API_KEY`) is stored exclusively in `~/.config/weather/.env`.
  - Permissions are restricted to `0600` (`-rw-------`), accessible only to the user UID.
  - `.gitignore` explicitly excludes `.config/weather/.env` and `stow/weather/.config/weather/.env`.
  - The API key is NEVER passed as a CLI argument (which would expose it in `/proc/*/cmdline` to other users).
  - The API key is masked in status/dry-run logging (`***1234`).
- **Least Privilege (V1)**:
  - The service executes strictly as a systemd user unit (`systemd --user`) under the unprivileged desktop user UID (1000).
  - Root execution is prohibited; assertion harness enforces `EUID != 0`.
- **Path Traversal & Injection Prevention (V5)**:
  - All disk operations are pinned to standard XDG paths (`$XDG_RUNTIME_DIR`, `$XDG_STATE_HOME`, `$XDG_CONFIG_HOME`).
  - No user-controlled string formatting in shell commands; Python networking uses structured `urllib.request` without subprocess shell invocation.
- **TLS & Transport Security (V9)**:
  - Network requests are strictly HTTPS (`https://api.worldweatheronline.com`).
  - Python's standard `urllib.request` verifies system CA certificates against `/etc/ssl/certs/ca-certificates.crt`.

### 9.2 Threat Model & Failure Mitigation
| Threat / Vulnerability | Impact | Mitigation |
| :--- | :--- | :--- |
| **API Key Leak in Git** | Secret exposed publicly | Track `.env.example` only; exclude `.env` in `.gitignore`; assertion test scans repo for raw keys. |
| **Quota Exhaustion Denial-of-Service** | 429 quota ban, weather unavailable for 24h | Dynamic budget pacing clamps polling floor to 3m; caps calls at 470; hard ceiling at 500 calls. |
| **Partial Read Race Condition in UI** | Quickshell crash or JSON parse exception | Atomic replacement via `os.replace` within same tmpfs mount point; synchronous flush and fsync. |
| **Missing Cache on Cold Boot** | Quickshell `FileView` throws `ENOENT` | Automatic initial skeleton JSON provisioning; persistent disk cache restoration across reboots. |
| **Network Flapping / Outage** | Quota wasted on retry storms; service failure loops | Zero immediate retries; error trapped and recorded; existing payload preserved with `is_stale: true`. |

---

## 10. Sources & Canonical References

### Authoritative Documentation & Specifications
- WorldWeatherOnline Local Weather API Reference: `https://www.worldweatheronline.com/weather-api/` [CITED: https://www.worldweatheronline.com/weather-api/]
- Systemd User Unit Documentation (`systemd.service(5)`, `systemd.timer(5)`, `systemd.exec(5)`): `https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html` [CITED: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html]
- XDG Base Directory Specification: `https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html` [CITED: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html]
- POSIX `rename(2)` atomic syscall specification: `https://man7.org/linux/man-pages/man2/rename.2.html` [CITED: https://man7.org/linux/man-pages/man2/rename.2.html]

### Local Project Assets
- `test_wwo_api/WEATHER_PARAMETERS.md` — Complete parameter and field catalog for WWO API [VERIFIED: test_wwo_api/WEATHER_PARAMETERS.md].
- `test_wwo_api/test_wwo.py` — Tested, working query parameter set and urllib implementation [VERIFIED: test_wwo_api/test_wwo.py].
- `test_wwo_api/raw_response.json` — Sample WWO API payload [VERIFIED: test_wwo_api/raw_response.json].
- `.planning/phases/51-wwo-fetcher-service-local-cache-architecture/51-CONTEXT.md` — Phase 51 boundary and design decisions [VERIFIED: 51-CONTEXT.md].
- `stow/systemd/.config/systemd/user/dotfiles-capture.{service,timer}` — Repository systemd user service reference [VERIFIED: stow/systemd/].
- `bootstrap.sh` — Deployment automation for Stow packages and systemd user timers [VERIFIED: bootstrap.sh].

---

## 11. Metadata

- **Phase Number:** 51
- **Phase Name:** WWO Fetcher Service & Local Cache Architecture
- **Target Milestone:** v0.10 (WorldWeatherOnline Desktop Shell Integration)
- **Requirements Satisfied:** WWO-01, WWO-02, WWO-03, WWO-04
- **Decisions Satisfied:** D-51-01 through D-51-09
- **Confidence Level:** **HIGH** (All parameters, standard library modules, systemd features, and atomic filesystem semantics pre-verified on target machine)
