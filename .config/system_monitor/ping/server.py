#!/usr/bin/env python3
"""Ping visualization server and collector.

Routes:
  GET /           -> ping_plot.html
  GET /api/pings  -> aggregated segments JSON (multi-target)
                     ?days=N  (default 50)
                     ?from=YYYY-MM-DD&to=YYYY-MM-DD
                     Today always included as first entry regardless of range.
  GET /api/today  -> today's segments JSON + last_ping timestamp (live refresh)
  GET /api/status -> Waybar JSON {"text":"...","class":"..."}
                     optional ?format=<placeholder string>
"""

from __future__ import annotations

import json
import logging
import os
import re
import sqlite3
import subprocess
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta
from html import escape
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

BASE_DIR = Path(__file__).parent
DB_PATH = BASE_DIR / "data/pings.db"
HTML_PATH = BASE_DIR / "ping_plot.html"
CONFIG_PATH = BASE_DIR / "ping.config"
LOG_PATH = BASE_DIR / "logs/ping.log"
PORT = int(os.environ.get("PORT", "8765"))
BIND_HOST = os.environ.get("BIND_HOST", "127.0.0.1")
COLLECTION_INTERVAL = int(os.environ.get("COLLECTION_INTERVAL", "5"))
STALE_AFTER_SECONDS = int(os.environ.get("STALE_AFTER_SECONDS", "15"))
PING_ARGS = ("ping", "-c3", "-i0.3", "-W1")
DEFAULT_TARGET = {
    "host": "8.8.8.8",
    "label": "󰒍",
    "t1": 40,
    "t2": 100,
    "t3": 200,
}

_SHELL_META = re.compile(r"[ |$`()]")
_LABEL_SAFE = re.compile(r"^[^{}'\"|$`()/<>\\]+$")
_RTT_RE = re.compile(
    r"(?:rtt|round-trip) min/avg/max/(?:mdev|stddev) = "
    r"([0-9.]+)/([0-9.]+)/([0-9.]+)/([0-9.]+) ms"
)

_cfg_cache: list[dict[str, Any]] = []
_cfg_mtime: float | None = None
_status_lock = threading.Lock()
_latest_cycle: dict[str, Any] = {
    "generated_at": None,
    "targets": [],
    "overall_class": "dead",
}


def setup_logging() -> None:
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    
    # Format: [2026-04-14 10:00:00] [LEVEL] Message
    formatter = logging.Formatter("[%(asctime)s] [%(levelname)s] %(message)s", 
                                  datefmt="%Y-%m-%d %H:%M:%S")

    # Console handler for docker logs
    console = logging.StreamHandler()
    console.setFormatter(formatter)

    # File handler (10MB per file, keep 5 backups)
    file_handler = RotatingFileHandler(LOG_PATH, maxBytes=10*1024*1024, backupCount=5)
    file_handler.setFormatter(formatter)

    root = logging.getLogger()
    root.setLevel(logging.INFO)
    root.addHandler(console)
    root.addHandler(file_handler)


def ensure_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS pings (
                ts          TEXT NOT NULL,
                target_host TEXT NOT NULL DEFAULT '8.8.8.8',
                ms          REAL,
                PRIMARY KEY (ts, target_host)
            );
            CREATE INDEX IF NOT EXISTS idx_ts     ON pings(ts);
            CREATE INDEX IF NOT EXISTS idx_target ON pings(target_host);
            """
        )
        conn.commit()
    finally:
        conn.close()


def _resolve_host(host_expr: str) -> str:
    if _SHELL_META.search(host_expr):
        try:
            result = subprocess.run(
                host_expr,
                shell=True,
                capture_output=True,
                text=True,
                timeout=3,
                check=False,
            )
            stdout = result.stdout.strip()
            return stdout.split()[0] if stdout else ""
        except Exception as exc:  # pragma: no cover - defensive
            logging.error(f"failed to resolve host_expr={host_expr!r}: {exc}")
            return ""
    return host_expr.strip()


def load_config() -> list[dict[str, Any]]:
    """Return configured targets in display order."""
    global _cfg_cache, _cfg_mtime

    try:
        mtime = CONFIG_PATH.stat().st_mtime
    except OSError:
        _cfg_cache = [DEFAULT_TARGET.copy()]
        _cfg_mtime = None
        return [DEFAULT_TARGET.copy()]

    if _cfg_cache and mtime == _cfg_mtime:
        return [target.copy() for target in _cfg_cache]

    logging.info(f"reloading config from {CONFIG_PATH}")
    targets: list[dict[str, Any]] = []
    try:
        lines = CONFIG_PATH.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        lines = []

    for raw_line in lines:
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue

        parts = line.split()
        if len(parts) >= 4 and all(re.fullmatch(r"[0-9.]+", p) for p in parts[-3:]):
            t1, t2, t3 = (float(parts[-3]), float(parts[-2]), float(parts[-1]))
            pre = parts[:-3]
            label = ""
            if len(pre) >= 2 and _LABEL_SAFE.fullmatch(pre[-1]):
                label = pre[-1]
                host_expr = " ".join(pre[:-1])
            else:
                host_expr = " ".join(pre)
        else:
            host_expr = line
            label = ""
            t1, t2, t3 = 40.0, 100.0, 200.0

        host = _resolve_host(host_expr)
        if not host:
            logging.warning(f"skipping unresolved target from config line: {raw_line}")
            continue

        targets.append(
            {
                "host": host,
                "label": label,
                "t1": t1,
                "t2": t2,
                "t3": t3,
            }
        )

    if not targets:
        targets = [DEFAULT_TARGET.copy()]

    _cfg_cache = [target.copy() for target in targets]
    _cfg_mtime = mtime
    return [target.copy() for target in targets]


def classify(ms: float | None, t1: float = 40, t2: float = 100, t3: float = 200) -> str:
    if ms is None:
        return "offline"
    if ms < t1:
        return "normal"
    if ms < t2:
        return "elevated"
    if ms < t3:
        return "high"
    return "critical"


def quality_to_waybar_class(quality: str) -> str:
    return {
        "normal": "good",
        "elevated": "medium",
        "high": "bad",
        "critical": "critical",
        "offline": "dead",
    }.get(quality, "dead")


def quality_rank(waybar_class: str) -> int:
    return {
        "good": 1,
        "medium": 2,
        "bad": 3,
        "critical": 4,
        "dead": 5,
    }.get(waybar_class, 5)


def color_of(waybar_class: str) -> str:
    return {
        "good": "#00C853",
        "medium": "#FFD600",
        "bad": "#FF6D00",
        "critical": "#D50000",
        "dead": "#37474F",
    }.get(waybar_class, "#37474F")


def parse_ts(ts_str: str) -> datetime:
    return datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")


def add_segment(
    days: dict[str, list[dict[str, Any]]],
    start_dt: datetime,
    end_dt: datetime,
    quality: str,
    avg_ms: float | None,
) -> None:
    cursor = start_dt
    while True:
        day_str = cursor.strftime("%Y-%m-%d")
        midnight = datetime(cursor.year, cursor.month, cursor.day) + timedelta(days=1)
        seg_end = end_dt if end_dt < midnight else midnight

        days.setdefault(day_str, []).append(
            {
                "start": cursor.strftime("%H:%M:%S"),
                "end": "24:00:00" if seg_end == midnight else seg_end.strftime("%H:%M:%S"),
                "avg_ms": round(avg_ms, 1) if avg_ms is not None else None,
                "quality": quality,
            }
        )

        if seg_end >= end_dt:
            break
        cursor = midnight


def aggregate(
    rows: list[tuple[str, float | None]],
    now_dt: datetime,
    t1: float = 40,
    t2: float = 100,
    t3: float = 200,
) -> dict[str, list[dict[str, Any]]]:
    days: dict[str, list[dict[str, Any]]] = {}
    cur_start = cur_quality = prev_ts = None
    cur_sum = 0.0
    cur_cnt = 0

    for ts_str, ms in rows:
        ts_dt = parse_ts(ts_str)
        quality = classify(ms, t1, t2, t3)

        if prev_ts is not None:
            gap = (ts_dt - prev_ts).total_seconds()
            if gap > 60:
                if cur_start is not None:
                    avg = cur_sum / cur_cnt if cur_cnt else None
                    add_segment(days, cur_start, prev_ts, cur_quality, avg)
                add_segment(days, prev_ts, ts_dt, "offline", None)
                cur_start = cur_quality = None
                cur_sum = 0.0
                cur_cnt = 0

        if cur_start is None:
            cur_start = ts_dt
            cur_quality = quality
        elif quality != cur_quality:
            avg = cur_sum / cur_cnt if cur_cnt else None
            add_segment(days, cur_start, ts_dt, cur_quality, avg)
            cur_start = ts_dt
            cur_quality = quality
            cur_sum = 0.0
            cur_cnt = 0

        if ms is not None:
            cur_sum += ms
            cur_cnt += 1

        prev_ts = ts_dt

    if cur_start is not None and prev_ts is not None:
        end_dt = now_dt if prev_ts.date() == now_dt.date() else prev_ts
        avg = cur_sum / cur_cnt if cur_cnt else None
        add_segment(days, cur_start, end_dt, cur_quality, avg)

    return days


def _secs(value: str) -> int:
    hours, minutes, seconds = map(int, value.split(":"))
    return hours * 3600 + minutes * 60 + seconds


def fill_day_boundaries(days: dict[str, list[dict[str, Any]]], today_str: str) -> None:
    for date, segs in days.items():
        if not segs:
            continue
        if _secs(segs[0]["start"]) > 60:
            segs.insert(
                0,
                {
                    "start": "00:00:00",
                    "end": segs[0]["start"],
                    "avg_ms": None,
                    "quality": "offline",
                },
            )
        if date != today_str and (86400 - _secs(segs[-1]["end"])) > 60:
            segs.append(
                {
                    "start": segs[-1]["end"],
                    "end": "24:00:00",
                    "avg_ms": None,
                    "quality": "offline",
                }
            )


def configured_targets() -> list[dict[str, Any]]:
    cfg_targets = load_config()
    seen = {target["host"] for target in cfg_targets}
    conn = sqlite3.connect(DB_PATH)
    try:
        rows = conn.execute(
            "SELECT DISTINCT target_host FROM pings ORDER BY target_host"
        ).fetchall()
    finally:
        conn.close()

    for (host,) in rows:
        if host not in seen:
            cfg_targets.append(
                {
                    "host": host,
                    "label": "",
                    "t1": 40.0,
                    "t2": 100.0,
                    "t3": 200.0,
                }
            )
    return cfg_targets


def query_rows(cutoff_str: str, end_str: str | None = None, target: str | None = None):
    conn = sqlite3.connect(DB_PATH)
    try:
        if end_str and target:
            return conn.execute(
                "SELECT ts, ms FROM pings WHERE ts >= ? AND ts <= ? AND target_host = ? ORDER BY ts",
                (cutoff_str, end_str, target),
            ).fetchall()
        if end_str:
            return conn.execute(
                "SELECT ts, ms FROM pings WHERE ts >= ? AND ts <= ? ORDER BY ts",
                (cutoff_str, end_str),
            ).fetchall()
        if target:
            return conn.execute(
                "SELECT ts, ms FROM pings WHERE ts >= ? AND target_host = ? ORDER BY ts",
                (cutoff_str, target),
            ).fetchall()
        return conn.execute(
            "SELECT ts, ms FROM pings WHERE ts >= ? ORDER BY ts",
            (cutoff_str,),
        ).fetchall()
    finally:
        conn.close()


def query_last_pings(targets: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    conn = sqlite3.connect(DB_PATH)
    try:
        result: dict[str, dict[str, Any]] = {}
        for target in targets:
            host = target["host"]
            row = conn.execute(
                "SELECT ts, ms FROM pings WHERE target_host = ? ORDER BY ts DESC LIMIT 1",
                (host,),
            ).fetchone()
            if row:
                ts, ms = row
                if ms is None:
                    text_value = "offline"
                elif ms < 10:
                    text_value = f"{ms:.2f}ms"
                else:
                    text_value = f"{round(ms):.0f}ms"
                result[host] = {"ts": ts, "ms": ms, "text_value": text_value}
        return result
    finally:
        conn.close()


def probe_target(target: dict[str, Any]) -> dict[str, Any]:
    host = target["host"]
    try:
        result = subprocess.run(
            [*PING_ARGS, host],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        output = result.stdout + ("\n" + result.stderr if result.stderr else "")
    except Exception as exc:  # pragma: no cover - defensive
        logging.error(f"ping failed for host={host}: {exc}")
        output = ""

    match = _RTT_RE.search(output)
    ms = float(match.group(2)) if match else None
    quality = classify(ms, target["t1"], target["t2"], target["t3"])
    waybar_class = quality_to_waybar_class(quality)

    if ms is None:
        text_value = "offline"
    elif ms < 10:
        text_value = f"{ms:.2f}ms"
    else:
        text_value = f"{round(ms):.0f}ms"

    return {
        **target,
        "ms": ms,
        "quality": quality,
        "class": waybar_class,
        "text_value": text_value,
        "color": color_of(waybar_class),
    }


def store_cycle(ts: str, target_rows: list[dict[str, Any]]) -> None:
    conn = sqlite3.connect(DB_PATH)
    try:
        rows_to_insert = [(ts, row["host"], row["ms"]) for row in target_rows]
        cursor = conn.executemany(
            "INSERT OR IGNORE INTO pings (ts, target_host, ms) VALUES (?, ?, ?)",
            rows_to_insert,
        )
        conn.commit()
        logging.info(f"saved ts={ts} rows={cursor.rowcount}/{len(rows_to_insert)}")
    finally:
        conn.close()


def render_status(target_rows: list[dict[str, Any]], fmt: str | None) -> dict[str, str]:
    if not target_rows:
        return {"text": "ping down", "class": "dead"}

    if fmt:
        result = fmt
        for index, row in enumerate(target_rows, start=1):
            span = f"<span color='{row['color']}'>{escape(row['text_value'])}</span>"
            result = result.replace(f"%{index}", span)
        text = result
    else:
        parts = []
        for row in target_rows:
            prefix = f"{escape(row['label'])} " if row["label"] else ""
            value = escape(row["text_value"])
            parts.append(f"<span color='{row['color']}'>{prefix}{value}</span>")
        text = " ".join(parts)

    worst_class = max(target_rows, key=lambda row: quality_rank(row["class"]))["class"]
    return {"text": text, "class": worst_class}


def stale_status() -> dict[str, str]:
    return {"text": "ping stale", "class": "dead"}


def update_latest_cycle(target_rows: list[dict[str, Any]], generated_at: datetime) -> None:
    worst_class = "dead"
    if target_rows:
        worst_class = max(
            target_rows, key=lambda row: quality_rank(row["class"])
        )["class"]

    payload = {
        "generated_at": generated_at,
        "targets": [
            {
                "host": row["host"],
                "label": row["label"],
                "ms": row["ms"],
                "quality": row["quality"],
                "class": row["class"],
                "text_value": row["text_value"],
                "color": row["color"],
            }
            for row in target_rows
        ],
        "overall_class": worst_class,
    }
    with _status_lock:
        _latest_cycle.clear()
        _latest_cycle.update(payload)


def get_latest_cycle() -> dict[str, Any]:
    with _status_lock:
        return {
            "generated_at": _latest_cycle.get("generated_at"),
            "targets": [row.copy() for row in _latest_cycle.get("targets", [])],
            "overall_class": _latest_cycle.get("overall_class", "dead"),
        }


def collector_loop() -> None:
    while True:
        started = time.monotonic()
        now_dt = datetime.now()
        ts = now_dt.strftime("%Y-%m-%d %H:%M:%S")

        try:
            targets = load_config()
            rows: list[dict[str, Any]] = []
            max_workers = max(1, len(targets))
            with ThreadPoolExecutor(max_workers=max_workers) as pool:
                futures = {pool.submit(probe_target, target): target for target in targets}
                for future in as_completed(futures):
                    rows.append(future.result())

            order = {target["host"]: index for index, target in enumerate(targets)}
            rows.sort(key=lambda row: order.get(row["host"], len(order)))
            store_cycle(ts, rows)
            update_latest_cycle(rows, now_dt)

            for row in rows:
                ms_text = "inf" if row["ms"] is None else f"{row['ms']:.3f}"
                logging.debug(
                    f"host={row['host']} ms={ms_text} "
                    f"quality={row['quality']} class={row['class']}"
                )
        except Exception as exc:  # pragma: no cover - defensive
            logging.exception(f"collector cycle failed: {exc}")

        elapsed = time.monotonic() - started
        time.sleep(max(0.0, COLLECTION_INTERVAL - elapsed))


def api_status(params: dict[str, list[str]]) -> dict[str, str]:
    fmt = params.get("format", [None])[0]
    cycle = get_latest_cycle()
    generated_at = cycle["generated_at"]
    if not generated_at:
        return stale_status()

    age = (datetime.now() - generated_at).total_seconds()
    if age > STALE_AFTER_SECONDS:
        return stale_status()

    return render_status(cycle["targets"], fmt)


def api_pings(params: dict[str, list[str]]) -> dict[str, Any]:
    now_dt = datetime.now()
    today_str = now_dt.strftime("%Y-%m-%d")

    from_p = params.get("from", [None])[0]
    to_p = params.get("to", [None])[0]
    days_p = params.get("days", ["50"])[0]

    if (from_p and to_p):
        cutoff = f"{from_p} 00:00:00"
        end_str = f"{to_p} 23:59:59"
    else:
        try:
            days_count = max(1, int(days_p))
        except (TypeError, ValueError):
            days_count = 50
        cutoff = (now_dt - timedelta(days=days_count)).strftime("%Y-%m-%d %H:%M:%S")
        end_str = None

    logging.info(f"API /api/pings: cutoff={cutoff} end_str={end_str}")
    targets = configured_targets()
    all_days: dict[str, dict[str, list[dict[str, Any]]]] = {}
    thresholds: dict[str, list[float]] = {}

    for target in targets:
        host = target["host"]
        thresholds[host] = [target["t1"], target["t2"], target["t3"]]
        rows = query_rows(cutoff, end_str, target=host)
        days = aggregate(rows, now_dt, target["t1"], target["t2"], target["t3"])
        fill_day_boundaries(days, today_str)

        if today_str not in days:
            today_rows = query_rows(f"{today_str} 00:00:00", target=host)
            today_days = aggregate(
                today_rows, now_dt, target["t1"], target["t2"], target["t3"]
            )
            fill_day_boundaries(today_days, today_str)
            days[today_str] = today_days.get(today_str, [])

        for date, segs in days.items():
            all_days.setdefault(date, {})[host] = segs

    sorted_dates = sorted(all_days.keys(), reverse=True)
    labels = {target["host"]: target["label"] for target in targets}
    return {
        "now": now_dt.strftime("%Y-%m-%d %H:%M:%S"),
        "targets": [target["host"] for target in targets],
        "thresholds": thresholds,
        "labels": labels,
        "days": [{"date": date, "bars": all_days[date]} for date in sorted_dates],
    }


def api_today() -> dict[str, Any]:
    now_dt = datetime.now()
    today = now_dt.strftime("%Y-%m-%d")
    cutoff = f"{today} 00:00:00"
    targets = configured_targets()
    bars: dict[str, list[dict[str, Any]]] = {}

    for target in targets:
        rows = query_rows(cutoff, target=target["host"])
        days = aggregate(rows, now_dt, target["t1"], target["t2"], target["t3"])
        bars[target["host"]] = days.get(today, [])

    return {
        "now": now_dt.strftime("%Y-%m-%d %H:%M:%S"),
        "date": today,
        "targets": [target["host"] for target in targets],
        "bars": bars,
        "last_pings": query_last_pings(targets),
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args: Any) -> None:
        logging.info(f"HTTP {self.address_string()} {fmt % args}")

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        path = parsed.path

        if path == "/":
            self._file(HTML_PATH, "text/html; charset=utf-8")
        elif path == "/api/pings":
            self._json(api_pings(params))
        elif path == "/api/today":
            self._json(api_today())
        elif path == "/api/status":
            self._json(api_status(params))
        else:
            self.send_error(404)

    def _file(self, file_path: Path, content_type: str) -> None:
        try:
            data = file_path.read_bytes()
        except FileNotFoundError:
            self.send_error(404)
            return

        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            return

    def _json(self, payload: dict[str, Any]) -> None:
        body = json.dumps(payload).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            return

def main() -> None:
    setup_logging()
    ensure_db()
    collector = threading.Thread(target=collector_loop, name="ping-collector", daemon=True)
    collector.start()

    logging.info(f"Ping viz server on http://{BIND_HOST}:{PORT}/")
    server = ThreadingHTTPServer((BIND_HOST, PORT), Handler)
    server.serve_forever()


if __name__ == "__main__":
    main()
