# Debug: Workspaces show 10, user wants 4

**Gap:** G-02-14  
**Severity:** minor  
**Status:** diagnosed  
**Date:** 2026-07-23

## Symptoms

- Bar workspaces strip shows ~10 workspace indicators
- User: “only 4 would be enough”

## Root Cause

`Config.options.bar.workspaces.shown` is **10**, locked by Phase 2 decision **D-02** (match Hyprland workspaces 1–10 / dual-monitor split). Live config dual-wrote the same value.

```
Config.qml:          property int shown: 10
config.json:         "shown": 10
phase02-config-assert.py: assert shown == 10
WorkspaceModel.shownCount → binds Config.options.bar.workspaces.shown
Workspaces.qml → renders shownCount slots
```

Not a layout bug — intentional Phase 2 default. UAT preference now overrides D-02 to **4**.

## Fix direction

1. Dual-write `bar.workspaces.shown: 4` in `Config.qml` and live `config.json`
2. Update `scripts/phase02-config-assert.py` expected value to 4
3. Note D-02 override in plan/SUMMARY (UAT preference wins)
4. Dual-monitor test 9 (1–5 / 6–10) already skipped; grouping math still works with shown=4 (group size 4)

## Artifacts

| Path | Issue |
|------|--------|
| `.config/quickshell/modules/common/Config.qml` | default `shown: 10` |
| `~/.config/illogical-impulse/config.json` | live `shown: 10` |
| `scripts/phase02-config-assert.py` | asserts `shown == 10` |

## Missing

- [ ] Set `shown: 4` in Config.qml
- [ ] Set `shown: 4` in live config.json
- [ ] Assert script expects 4
