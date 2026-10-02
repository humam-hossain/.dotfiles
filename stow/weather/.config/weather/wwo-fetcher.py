#!/usr/bin/env python3
"""
WorldWeatherOnline (WWO) background weather telemetry fetcher and local cache service.
Enforces dynamic budget pacing, atomic tmpfs caching, and offline resilience.
Zero third-party pip dependencies; pure Python standard library.
"""

import sys
import os
import json
import argparse
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime, timezone, timedelta

DAILY_BUDGET = 470
ABSOLUTE_CEILING = 500
MIN_INTERVAL_MINUTES = 3.0
TIMEOUT_SECONDS = 25
USER_AGENT = "Dotfiles-Weather-Fetcher/1.0 (Arch Linux; Python 3)"
API_ENDPOINT = "https://api.worldweatheronline.com/premium/v1/weather.ashx"


def get_runtime_dir() -> str:
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not xdg_runtime:
        xdg_runtime = f"/run/user/{os.getuid()}"
    target_dir = os.path.join(xdg_runtime, "weather")
    os.makedirs(target_dir, exist_ok=True)
    return target_dir


def get_state_dir() -> str:
    state_home = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    target_dir = os.path.join(state_home, "weather")
    os.makedirs(target_dir, exist_ok=True)
    return target_dir


def get_config_dir() -> str:
    config_home = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return os.path.join(config_home, "weather")


def load_env_file(filepath: str) -> dict:
    env_vars = {}
    if not os.path.isfile(filepath):
        return env_vars
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" in line:
                    k, v = line.split("=", 1)
                    env_vars[k.strip()] = v.strip().strip("\"'")
    except Exception:
        pass
    return env_vars


def resolve_api_key() -> str:
    # 1. Environment variable
    key = os.environ.get("WWO_API_KEY", "").strip()
    if key:
        return key
    # 2. ~/.config/weather/.env
    env_path = os.path.join(get_config_dir(), ".env")
    env_vars = load_env_file(env_path)
    return env_vars.get("WWO_API_KEY", "").strip()


def resolve_city() -> str:
    config_home = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    config_path = os.path.join(config_home, "illogical-impulse", "config.json")
    if os.path.isfile(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                city = data.get("bar", {}).get("weather", {}).get("city")
                if city and isinstance(city, str) and city.strip():
                    return city.strip()
        except Exception:
            pass
    return "Dhaka"


def load_quota_state(state_file: str) -> dict:
    now_utc = datetime.now(timezone.utc)
    today_utc_str = now_utc.strftime("%Y-%m-%d")
    default_state = {
        "date_utc": today_utc_str,
        "calls_today": 0,
        "last_call_epoch": 0,
        "last_status": "none"
    }

    if not os.path.isfile(state_file):
        return default_state

    try:
        with open(state_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            if data.get("date_utc") != today_utc_str:
                # Midnight UTC rollover
                return default_state
            return data
    except Exception:
        return default_state


def atomic_write_json(target_path: str, data: dict):
    dir_name = os.path.dirname(target_path)
    os.makedirs(dir_name, exist_ok=True)
    tmp_path = os.path.join(dir_name, f"{os.path.basename(target_path)}.tmp.{os.getpid()}")
    try:
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.chmod(tmp_path, 0o644)
        os.replace(tmp_path, target_path)
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except OSError:
                pass


def save_quota_state(state_file: str, state: dict):
    atomic_write_json(state_file, state)


def compute_pacing(calls_today: int, now_utc: datetime) -> tuple[float, float, datetime]:
    tomorrow_utc = (now_utc + timedelta(days=1)).date()
    midnight_utc = datetime(tomorrow_utc.year, tomorrow_utc.month, tomorrow_utc.day, tzinfo=timezone.utc)
    seconds_to_midnight = (midnight_utc - now_utc).total_seconds()
    minutes_to_midnight = max(1.0, seconds_to_midnight / 60.0)

    remaining_budget = max(0, DAILY_BUDGET - calls_today)
    if remaining_budget == 0:
        pacing_interval = float("inf")
    else:
        pacing_interval = max(MIN_INTERVAL_MINUTES, minutes_to_midnight / remaining_budget)

    return pacing_interval, minutes_to_midnight, midnight_utc


def build_quota_dict(calls_today: int, midnight_utc: datetime) -> dict:
    return {
        "calls_today": calls_today,
        "calls_remaining": max(0, DAILY_BUDGET - calls_today),
        "resets_at_utc": midnight_utc.strftime("%Y-%m-%dT00:00:00Z")
    }


def ensure_fallback_cache(cache_path: str, persist_path: str, quota_info: dict):
    if os.path.isfile(cache_path):
        return

    # Try restoring persistent cache
    if os.path.isfile(persist_path):
        try:
            with open(persist_path, "r", encoding="utf-8") as f:
                saved = json.load(f)
            saved["status"] = "offline"
            saved["is_stale"] = True
            saved["error"] = "Restored from persistent storage on startup"
            saved["quota"] = quota_info
            atomic_write_json(cache_path, saved)
            return
        except Exception:
            pass

    # Cold boot skeleton
    skeleton = {
        "status": "offline",
        "fetched_at": None,
        "fetched_epoch": 0,
        "is_stale": True,
        "error": "Initial startup: awaiting network connection...",
        "quota": quota_info,
        "data": None
    }
    atomic_write_json(cache_path, skeleton)


def fetch_wwo_api(api_key: str, city: str) -> dict:
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
        "lang": "en"
    }

    url = f"{API_ENDPOINT}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

    with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as resp:
        content = resp.read().decode("utf-8")
        parsed = json.loads(content)
        return parsed.get("data", parsed)


def main():
    parser = argparse.ArgumentParser(
        description="WorldWeatherOnline background telemetry fetcher and local cache service."
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Bypass pacing interval check (still constrained by absolute ceiling)."
    )
    parser.add_argument(
        "--status",
        action="store_true",
        help="Display current quota, pacing calculations, and cache state then exit 0."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate execution without making network requests."
    )

    args = parser.parse_args()

    runtime_dir = get_runtime_dir()
    state_dir = get_state_dir()

    cache_path = os.path.join(runtime_dir, "weather.json")
    state_file = os.path.join(state_dir, "quota.json")
    persist_path = os.path.join(state_dir, "last_known_weather.json")

    now_utc = datetime.now(timezone.utc)
    quota_state = load_quota_state(state_file)
    calls_today = quota_state.get("calls_today", 0)
    last_call_epoch = quota_state.get("last_call_epoch", 0)

    pacing_interval, minutes_to_midnight, midnight_utc = compute_pacing(calls_today, now_utc)
    quota_info = build_quota_dict(calls_today, midnight_utc)

    # Ensure runtime cache file exists before attempting network (avoids UI ENOENT)
    ensure_fallback_cache(cache_path, persist_path, quota_info)

    if args.status:
        elapsed_min = (now_utc.timestamp() - last_call_epoch) / 60.0 if last_call_epoch > 0 else float("inf")
        print("=== WWO Weather Fetcher Status ===")
        print(f"Date (UTC):             {quota_state.get('date_utc')}")
        print(f"Calls Today:            {calls_today} / {DAILY_BUDGET} (Ceiling: {ABSOLUTE_CEILING})")
        print(f"Calls Remaining:        {quota_info['calls_remaining']}")
        print(f"Minutes to Rollover:    {minutes_to_midnight:.1f} min")
        print(f"Dynamic Pacing Interval: {pacing_interval:.2f} min" if pacing_interval != float("inf") else "Dynamic Pacing Interval: Throttled (Budget reached)")
        print(f"Elapsed Since Last Call:{elapsed_min:.2f} min" if last_call_epoch > 0 else "Elapsed Since Last Call: None")
        print(f"Location Configured:    {resolve_city()}")
        print(f"Cache File:             {cache_path} ({'Exists' if os.path.exists(cache_path) else 'Missing'})")
        print(f"Persistent Mirror:      {persist_path} ({'Exists' if os.path.exists(persist_path) else 'Missing'})")
        sys.exit(0)

    city = resolve_city()

    if args.dry_run:
        print("[DRY-RUN] Simulating weather fetch:")
        print(f"[DRY-RUN] Target city: {city}")
        print(f"[DRY-RUN] Pacing interval required: {pacing_interval:.2f} min")
        print(f"[DRY-RUN] Calls today: {calls_today}")
        sys.exit(0)

    # Absolute ceiling protection (T-51-02)
    if calls_today >= ABSOLUTE_CEILING:
        sys.stderr.write(f"Warning: Absolute quota ceiling of {ABSOLUTE_CEILING} calls reached. Throttling all requests.\n")
        sys.exit(0)

    # Dynamic pacing interval check
    if not args.force:
        if calls_today >= DAILY_BUDGET:
            # Daily budget reached, wait for midnight UTC
            sys.exit(0)

        if last_call_epoch > 0:
            elapsed_min = (now_utc.timestamp() - last_call_epoch) / 60.0
            if elapsed_min < pacing_interval:
                # Pacing interval not yet elapsed — exit cleanly with 0 network calls
                sys.exit(0)

    # Resolve API Key
    api_key = resolve_api_key()
    if not api_key:
        sys.stderr.write("Error: WWO_API_KEY not found in environment or ~/.config/weather/.env\n")
        # Update cache with missing credentials error
        err_envelope = {
            "status": "error",
            "fetched_at": datetime.now().astimezone().isoformat(),
            "fetched_epoch": int(now_utc.timestamp()),
            "is_stale": True,
            "error": "Missing WWO_API_KEY in ~/.config/weather/.env",
            "quota": quota_info,
            "data": None
        }
        atomic_write_json(cache_path, err_envelope)
        sys.exit(1)

    # Fetch from API
    try:
        wwo_data = fetch_wwo_api(api_key, city)
        now_epoch = int(now_utc.timestamp())
        now_local_iso = datetime.now().astimezone().isoformat()

        # Update quota
        calls_today += 1
        quota_state["calls_today"] = calls_today
        quota_state["last_call_epoch"] = now_epoch
        quota_state["last_status"] = "ok"
        save_quota_state(state_file, quota_state)

        updated_quota_info = build_quota_dict(calls_today, midnight_utc)

        envelope = {
            "status": "ok",
            "fetched_at": now_local_iso,
            "fetched_epoch": now_epoch,
            "is_stale": False,
            "error": None,
            "quota": updated_quota_info,
            "data": wwo_data
        }

        # Atomic writes to runtime cache and persistent mirror
        atomic_write_json(cache_path, envelope)
        atomic_write_json(persist_path, envelope)

    except Exception as e:
        # Network outage / API error resilience (D-51-05)
        # Preserve existing forecast data with is_stale: true without burning quota
        existing_data = None
        if os.path.isfile(cache_path):
            try:
                with open(cache_path, "r", encoding="utf-8") as f:
                    prev = json.load(f)
                    existing_data = prev.get("data")
            except Exception:
                pass

        if existing_data is None and os.path.isfile(persist_path):
            try:
                with open(persist_path, "r", encoding="utf-8") as f:
                    prev = json.load(f)
                    existing_data = prev.get("data")
            except Exception:
                pass

        err_envelope = {
            "status": "error",
            "fetched_at": datetime.now().astimezone().isoformat(),
            "fetched_epoch": int(now_utc.timestamp()),
            "is_stale": True,
            "error": str(e),
            "quota": quota_info,
            "data": existing_data
        }
        atomic_write_json(cache_path, err_envelope)
        quota_state["last_status"] = "error"
        save_quota_state(state_file, quota_state)
        # Exit 0 cleanly to let systemd timer retry on next 3m tick
        sys.exit(0)


if __name__ == "__main__":
    main()
