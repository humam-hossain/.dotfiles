#!/usr/bin/env python3
"""One-time migration: add target_host column to pings table.
Existing rows are backfilled with '8.8.8.8'.
Run once: python3 analysis/migrate_add_target_host.py
"""
import os
import sqlite3

DB_PATH = os.path.expanduser("~/.config/waybar/data/pings.db")


def migrate():
    conn = sqlite3.connect(DB_PATH)
    try:
        cols = [r[1] for r in conn.execute("PRAGMA table_info(pings)").fetchall()]
        if 'target_host' in cols:
            print("Already migrated — target_host column exists.")
            return

        before = conn.execute("SELECT COUNT(*) FROM pings").fetchone()[0]
        print(f"Rows before migration: {before:,}")

        conn.executescript("""
            BEGIN;
            CREATE TABLE pings_new (
                ts          TEXT NOT NULL,
                target_host TEXT NOT NULL DEFAULT '8.8.8.8',
                ms          REAL,
                PRIMARY KEY (ts, target_host)
            );
            INSERT INTO pings_new SELECT ts, '8.8.8.8', ms FROM pings;
            DROP TABLE pings;
            ALTER TABLE pings_new RENAME TO pings;
            CREATE INDEX IF NOT EXISTS idx_ts     ON pings(ts);
            CREATE INDEX IF NOT EXISTS idx_target ON pings(target_host);
            COMMIT;
        """)

        after = conn.execute("SELECT COUNT(*) FROM pings").fetchone()[0]
        print(f"Rows after  migration: {after:,}")
        if before == after:
            print("Migration successful — no data loss.")
        else:
            print(f"WARNING: row count changed! before={before} after={after}")
    finally:
        conn.close()


if __name__ == '__main__':
    migrate()
