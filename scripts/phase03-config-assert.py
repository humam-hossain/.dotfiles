#!/usr/bin/env python3
"""Phase 3 Wave 0 live-config asserts for BAR-05..08 keys.

Reads ~/.config/illogical-impulse/config.json and asserts Phase 3 dual-write
targets (D-04, D-05, D-07, D-08, D-13, D-14, D-22). Stdlib only. Exit 0 only
when all pass.

Expected to FAIL until plan 03-02 dual-writes Config defaults into live config.
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
        resources = config["bar"]["resources"]
        assert resources["cpuWarningThreshold"] == 40, (
            f"bar.resources.cpuWarningThreshold={resources.get('cpuWarningThreshold')!r} want 40"
        )
        assert resources["cpuErrorThreshold"] == 80, (
            f"bar.resources.cpuErrorThreshold={resources.get('cpuErrorThreshold')!r} want 80"
        )
        assert resources["memoryWarningThreshold"] == 75, (
            f"bar.resources.memoryWarningThreshold={resources.get('memoryWarningThreshold')!r} want 75"
        )
        assert resources["memoryErrorThreshold"] == 95, (
            f"bar.resources.memoryErrorThreshold={resources.get('memoryErrorThreshold')!r} want 95"
        )
        assert resources["diskWarningThreshold"] == 80, (
            f"bar.resources.diskWarningThreshold={resources.get('diskWarningThreshold')!r} want 80"
        )
        assert resources["diskErrorThreshold"] == 95, (
            f"bar.resources.diskErrorThreshold={resources.get('diskErrorThreshold')!r} want 95"
        )
        assert resources["alwaysShowCpu"] is True, (
            f"bar.resources.alwaysShowCpu={resources.get('alwaysShowCpu')!r} want True"
        )
        assert resources["alwaysShowSwap"] is False, (
            f"bar.resources.alwaysShowSwap={resources.get('alwaysShowSwap')!r} want False"
        )

        res_svc = config["resources"]
        assert res_svc["updateInterval"] == 1000, (
            f"resources.updateInterval={res_svc.get('updateInterval')!r} want 1000"
        )
        assert res_svc["memoryUpdateInterval"] == 3000, (
            f"resources.memoryUpdateInterval={res_svc.get('memoryUpdateInterval')!r} want 3000"
        )
        assert res_svc["diskUpdateInterval"] == 10000, (
            f"resources.diskUpdateInterval={res_svc.get('diskUpdateInterval')!r} want 10000"
        )

        max_allowed = config["audio"]["protection"]["maxAllowed"]
        assert max_allowed >= 130, (
            f"audio.protection.maxAllowed={max_allowed!r} want >= 130"
        )
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
