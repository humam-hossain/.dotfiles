#!/usr/bin/env python3
"""One-time migration: ping_history.csv → pings.db (SQLite)."""

import csv
import os
import sqlite3
import sys

CSV_PATH = os.path.expanduser("~/.config/waybar/data/ping_history.csv")
DB_PATH  = os.path.expanduser("~/.config/waybar/data/pings.db")


def init_db(conn):
    conn.execute("""
        CREATE TABLE IF NOT EXISTS pings (
            ts   TEXT NOT NULL,
            ms   REAL,
            PRIMARY KEY (ts)
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_ts ON pings(ts)")
    conn.commit()


def migrate():
    if not os.path.exists(CSV_PATH):
        print(f"CSV not found: {CSV_PATH}", file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(DB_PATH)
    init_db(conn)

    existing = conn.execute("SELECT COUNT(*) FROM pings").fetchone()[0]
    print(f"Existing rows in DB: {existing:,}")

    total = 0
    batch = []
    BATCH_SIZE = 5000

    def flush(b):
        conn.executemany("INSERT OR IGNORE INTO pings VALUES (?, ?)", b)
        conn.commit()

    with open(CSV_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            ts_raw = row['date']     # '2025-10-27_05:12:48'
            ms_raw = row['ping_ms']  # '27' or 'inf'

            # Underscore → space so SQLite datetime() functions work natively
            ts = ts_raw.replace('_', ' ')

            if ms_raw in ('inf', ''):
                ms = None
            else:
                try:
                    ms = float(ms_raw)
                except ValueError:
                    ms = None

            batch.append((ts, ms))
            total += 1

            if len(batch) >= BATCH_SIZE:
                flush(batch)
                batch.clear()
                print(f"\rProcessed {total:,} rows…", end='', flush=True)

    if batch:
        flush(batch)

    print(f"\nDone. Processed {total:,} rows from CSV.")
    final = conn.execute("SELECT COUNT(*) FROM pings").fetchone()[0]
    print(f"DB now has {final:,} rows.")
    conn.close()


if __name__ == '__main__':
    migrate()
