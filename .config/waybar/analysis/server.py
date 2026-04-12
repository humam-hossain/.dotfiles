#!/usr/bin/env python3
"""Ping visualization server.
Serves static HTML and aggregated ping data from SQLite.
Routes:
  GET /           → ping_plot.html
  GET /api/pings  → aggregated segments JSON (multi-target)
                    ?days=N  (default 30)
                    ?from=YYYY-MM-DD&to=YYYY-MM-DD
                    Today always included as first entry regardless of range.
  GET /api/today  → today's segments JSON + last_ping timestamp (live refresh)
"""

import json
import os
import re
import sqlite3
import subprocess
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

DB_PATH     = os.path.expanduser("~/.config/waybar/data/pings.db")
HTML_PATH   = os.path.expanduser("~/.config/waybar/data/ping_plot.html")
CONFIG_PATH = os.path.expanduser("~/.config/waybar/data/ping.config")
PORT        = 8765

_SHELL_META  = re.compile(r'[ |$`()]')
_LABEL_SAFE  = re.compile(r"^[^{}'\"|$`()/<>\\]+$")

# Cache: thresholds dict + config file mtime
_cfg_cache: dict = {}
_cfg_mtime: float | None = None


def load_config() -> dict:
    """Returns {resolved_host: (t1, t2, t3)} from ping.config.
    Result is mtime-cached — reloads automatically when the file changes.
    Shell-command host lines are resolved via subprocess (timeout 3s).
    """
    global _cfg_cache, _cfg_mtime
    try:
        mtime = os.path.getmtime(CONFIG_PATH)
    except OSError:
        return {}
    if _cfg_cache and mtime == _cfg_mtime:
        return _cfg_cache

    thresholds: dict = {}
    try:
        with open(CONFIG_PATH) as f:
            lines = f.readlines()
    except FileNotFoundError:
        _cfg_cache, _cfg_mtime = {}, mtime
        return {}

    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue

        parts = line.split()
        n = len(parts)

        if n >= 4 and all(p.isdigit() for p in parts[-3:]):
            t1, t2, t3 = int(parts[-3]), int(parts[-2]), int(parts[-1])
            host_expr  = ' '.join(parts[:-3])
            # Strip label: last token with no shell metacharacters is a display label
            hp = host_expr.split()
            if len(hp) >= 2 and _LABEL_SAFE.match(hp[-1]):
                host_expr = ' '.join(hp[:-1])
        else:
            t1, t2, t3 = 40, 100, 200
            host_expr  = line

        if _SHELL_META.search(host_expr):
            try:
                r = subprocess.run(
                    host_expr, shell=True, capture_output=True, text=True, timeout=3
                )
                host = r.stdout.strip().split()[0] if r.stdout.strip() else ''
            except Exception:
                host = ''
        else:
            host = host_expr.strip()

        if host:
            thresholds[host] = (t1, t2, t3)

    _cfg_cache, _cfg_mtime = thresholds, mtime
    return thresholds


def classify(ms, t1=40, t2=100, t3=200):
    if ms is None:
        return 'offline'
    if ms < t1:
        return 'normal'
    if ms < t2:
        return 'elevated'
    if ms < t3:
        return 'high'
    return 'critical'


def parse_ts(s):
    return datetime.strptime(s, '%Y-%m-%d %H:%M:%S')


def add_segment(days, start_dt, end_dt, quality, avg_ms):
    """Append segment to days dict, splitting at midnight boundaries."""
    cursor = start_dt
    while True:
        day_str  = cursor.strftime('%Y-%m-%d')
        midnight = datetime(cursor.year, cursor.month, cursor.day) + timedelta(days=1)
        seg_end  = end_dt if end_dt < midnight else midnight

        days.setdefault(day_str, []).append({
            'start':  cursor.strftime('%H:%M:%S'),
            'end':    '24:00:00' if seg_end == midnight else seg_end.strftime('%H:%M:%S'),
            'avg_ms': round(avg_ms, 1) if avg_ms is not None else None,
            'quality': quality,
        })

        if seg_end >= end_dt:
            break
        cursor = midnight


def aggregate(rows, now_dt, t1=40, t2=100, t3=200):
    """
    rows    : list of (ts_str, ms_float_or_None), sorted ascending
    now_dt  : current datetime — caps today's last segment
    t1/t2/t3: per-target ms thresholds
    Returns : dict {date_str: [segment, ...]}

    Offline triggers:
      1. ms is None  — internet down (computer running, ping failed)
      2. gap > 60s   — computer off / waybar stopped (no rows logged)
    """
    days = {}
    cur_start = cur_quality = prev_ts = None
    cur_sum = 0.0
    cur_cnt = 0

    for ts_str, ms in rows:
        ts_dt   = parse_ts(ts_str)
        quality = classify(ms, t1, t2, t3)

        if prev_ts is not None:
            gap = (ts_dt - prev_ts).total_seconds()
            if gap > 60:
                if cur_start is not None:
                    avg = cur_sum / cur_cnt if cur_cnt else None
                    add_segment(days, cur_start, prev_ts, cur_quality, avg)
                add_segment(days, prev_ts, ts_dt, 'offline', None)
                cur_start = cur_quality = None
                cur_sum = 0.0
                cur_cnt = 0

        if cur_start is None:
            cur_start   = ts_dt
            cur_quality = quality
        elif quality != cur_quality:
            avg = cur_sum / cur_cnt if cur_cnt else None
            add_segment(days, cur_start, ts_dt, cur_quality, avg)
            cur_start   = ts_dt
            cur_quality = quality
            cur_sum = 0.0
            cur_cnt = 0

        if ms is not None:
            cur_sum += ms
            cur_cnt += 1

        prev_ts = ts_dt

    if cur_start is not None and prev_ts is not None:
        end_dt = now_dt if prev_ts.date() == now_dt.date() else prev_ts
        avg    = cur_sum / cur_cnt if cur_cnt else None
        add_segment(days, cur_start, end_dt, cur_quality, avg)

    return days


def _secs(t):
    """'14:30:00' → 52200, '24:00:00' → 86400"""
    h, m, s = map(int, t.split(':'))
    return h * 3600 + m * 60 + s


def fill_day_boundaries(days, today_str):
    """
    Fill leading/trailing gaps on each day with offline segments (> 60s threshold).
    - Leading : midnight → first ping  (all days)
    - Trailing: last ping → midnight   (historical days only; today keeps background)
    """
    for date, segs in days.items():
        if not segs:
            continue
        if _secs(segs[0]['start']) > 60:
            segs.insert(0, {
                'start': '00:00:00', 'end': segs[0]['start'],
                'avg_ms': None, 'quality': 'offline',
            })
        if date != today_str and (86400 - _secs(segs[-1]['end'])) > 60:
            segs.append({
                'start': segs[-1]['end'], 'end': '24:00:00',
                'avg_ms': None, 'quality': 'offline',
            })


def query_targets():
    conn = sqlite3.connect(DB_PATH)
    try:
        rows = conn.execute(
            "SELECT DISTINCT target_host FROM pings ORDER BY target_host"
        ).fetchall()
        return [r[0] for r in rows]
    finally:
        conn.close()


def query_rows(cutoff_str, end_str=None, target=None):
    conn = sqlite3.connect(DB_PATH)
    try:
        if end_str and target:
            return conn.execute(
                "SELECT ts, ms FROM pings WHERE ts >= ? AND ts <= ? AND target_host = ? ORDER BY ts",
                (cutoff_str, end_str, target)
            ).fetchall()
        elif end_str:
            return conn.execute(
                "SELECT ts, ms FROM pings WHERE ts >= ? AND ts <= ? ORDER BY ts",
                (cutoff_str, end_str)
            ).fetchall()
        elif target:
            return conn.execute(
                "SELECT ts, ms FROM pings WHERE ts >= ? AND target_host = ? ORDER BY ts",
                (cutoff_str, target)
            ).fetchall()
        else:
            return conn.execute(
                "SELECT ts, ms FROM pings WHERE ts >= ? ORDER BY ts",
                (cutoff_str,)
            ).fetchall()
    finally:
        conn.close()


def query_last_ping():
    conn = sqlite3.connect(DB_PATH)
    try:
        row = conn.execute("SELECT MAX(ts) FROM pings").fetchone()
        return row[0] if row else None
    finally:
        conn.close()


def api_pings(params):
    now_dt    = datetime.now()
    today_str = now_dt.strftime('%Y-%m-%d')

    from_p = params.get('from', [None])[0]
    to_p   = params.get('to',   [None])[0]
    days_p = params.get('days', ['30'])[0]

    if from_p and to_p:
        cutoff  = from_p + ' 00:00:00'
        end_str = to_p   + ' 23:59:59'
    else:
        try:
            n = max(1, int(days_p))
        except (TypeError, ValueError):
            n = 30
        cutoff  = (now_dt - timedelta(days=n)).strftime('%Y-%m-%d %H:%M:%S')
        end_str = None

    targets    = query_targets()
    cfg        = load_config()
    all_days   = {}  # {date: {target: [segments]}}
    thresholds = {}  # {target: [t1, t2, t3]}

    for target in targets:
        t1, t2, t3 = cfg.get(target, (40, 100, 200))
        thresholds[target] = [t1, t2, t3]

        rows = query_rows(cutoff, end_str, target=target)
        days = aggregate(rows, now_dt, t1, t2, t3)
        fill_day_boundaries(days, today_str)

        if today_str not in days:
            today_rows = query_rows(today_str + ' 00:00:00', target=target)
            today_days = aggregate(today_rows, now_dt, t1, t2, t3)
            fill_day_boundaries(today_days, today_str)
            days[today_str] = today_days.get(today_str, [])

        for date, segs in days.items():
            all_days.setdefault(date, {})[target] = segs

    sorted_dates = sorted(all_days.keys(), reverse=True)
    return {
        'now':        now_dt.strftime('%Y-%m-%d %H:%M:%S'),
        'targets':    targets,
        'thresholds': thresholds,
        'days':       [{'date': d, 'bars': all_days[d]} for d in sorted_dates],
    }


def api_today():
    now_dt  = datetime.now()
    today   = now_dt.strftime('%Y-%m-%d')
    cutoff  = today + ' 00:00:00'
    targets = query_targets()
    cfg     = load_config()
    bars    = {}

    for target in targets:
        t1, t2, t3 = cfg.get(target, (40, 100, 200))
        rows = query_rows(cutoff, target=target)
        days = aggregate(rows, now_dt, t1, t2, t3)
        bars[target] = days.get(today, [])

    return {
        'now':       now_dt.strftime('%Y-%m-%d %H:%M:%S'),
        'date':      today,
        'targets':   targets,
        'bars':      bars,
        'last_ping': query_last_ping(),
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass  # suppress access logs

    def do_GET(self):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        path   = parsed.path
        if path == '/':
            self._file(HTML_PATH, 'text/html; charset=utf-8')
        elif path == '/api/pings':
            self._json(api_pings(params))
        elif path == '/api/today':
            self._json(api_today())
        else:
            self.send_error(404)

    def _file(self, fpath, ctype):
        try:
            with open(fpath, 'rb') as f:
                data = f.read()
            self.send_response(200)
            self.send_header('Content-Type', ctype)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except FileNotFoundError:
            self.send_error(404)

    def _json(self, obj):
        body = json.dumps(obj).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)


if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', PORT), Handler)
    print(f'Ping viz server on http://localhost:{PORT}/')
    server.serve_forever()
