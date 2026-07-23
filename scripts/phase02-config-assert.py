#!/usr/bin/env python3
"""Phase 2 Wave 0 live-config asserts for BAR-01..04 keys.

Reads ~/.config/illogical-impulse/config.json and asserts Phase 2 decisions
(D-01..D-03, D-05, D-13, D-14, D-16). Stdlib only. Exit 0 only when all pass.

Expected to FAIL until plan 02-02 dual-writes Config defaults into live config.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "illogical-impulse" / "config.json"


def main() -> int:
    if not CONFIG_PATH.is_file():
        print(f"error: missing config file: {CONFIG_PATH}", file=sys.stderr)
        return 1

    try:
        config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"error: failed to load {CONFIG_PATH}: {exc}", file=sys.stderr)
        return 1

    try:
        workspaces = config["bar"]["workspaces"]
        assert workspaces["shown"] == 4, f"bar.workspaces.shown={workspaces.get('shown')!r} want 4"
        assert workspaces["showAppIcons"] is True, (
            f"bar.workspaces.showAppIcons={workspaces.get('showAppIcons')!r} want True"
        )
        assert workspaces["monochromeIcons"] is True, (
            f"bar.workspaces.monochromeIcons={workspaces.get('monochromeIcons')!r} want True"
        )

        weather = config["bar"]["weather"]
        assert weather["enable"] is False, f"bar.weather.enable={weather.get('enable')!r} want False"

        time_cfg = config["time"]
        assert time_cfg["secondPrecision"] is True, (
            f"time.secondPrecision={time_cfg.get('secondPrecision')!r} want True"
        )
        fmt = time_cfg.get("format", "")
        assert isinstance(fmt, str) and "ss" in fmt, (
            f"time.format={fmt!r} must contain 'ss' (seconds)"
        )
        assert "AP" in fmt or "ap" in fmt, (
            f"time.format={fmt!r} must contain 'AP' or 'ap' (AM/PM)"
        )

        tray = config["tray"]
        assert tray["monochromeIcons"] is False, (
            f"tray.monochromeIcons={tray.get('monochromeIcons')!r} want False"
        )
        assert tray["invertPinnedItems"] is True, (
            f"tray.invertPinnedItems={tray.get('invertPinnedItems')!r} want True"
        )
        pinned = tray.get("pinnedItems", [])
        assert "Fcitx" in pinned, f"tray.pinnedItems={pinned!r} must contain 'Fcitx'"
    except KeyError as exc:
        print(f"config assert FAIL: missing key {exc}", file=sys.stderr)
        return 1
    except AssertionError as exc:
        print(f"config assert FAIL: {exc}", file=sys.stderr)
        return 1

    print("config asserts OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
