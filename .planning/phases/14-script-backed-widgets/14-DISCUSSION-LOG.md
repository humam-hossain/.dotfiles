# Phase 14: Script-Backed Widgets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the discussion history.

**Date:** 2026-05-21
**Phase:** 14-script-backed-widgets
**Mode:** discuss
**Areas discussed:** CPU, Network, Volume OSD, Notification, Center layout, Backlight, Scripts, Weather, Memory, Disk, Ping, Click actions, Tooltips, Error states, Thresholds, Poll intervals, Clock format, Colours, Notification format, OSD dimensions

---

## CPU Widget

| Question | Selected |
|----------|----------|
| Service vs inline? | Full service singleton (CpuService.qml) |
| Poll interval? | 3s |
| Click action? | None |
| Color thresholds? | ≥50% warning, ≥90% critical |

## Network Widget

| Question | Selected |
|----------|----------|
| Data source? | nmcli Process via NetworkService.qml service singleton |
| Poll interval? | 10s |
| Click action? | nmtui in kitty per SYS-04 |

## Volume OSD

| Question | Selected |
|----------|----------|
| Placement? | PopupWindow anchored below VolumeWidget |
| Visual style? | Horizontal progress bar in a pill (~150x8px) |
| Trigger? | Any AudioService.volumePercent change |
| Auto-hide timer? | 1.5s per AUDIO-02 |

## Notification Widget

| Question | Selected |
|----------|----------|
| Polling vs streaming? | Polling via swaync-client -c on 5s Timer |
| Service singleton? | Yes (NotificationService.qml) |
| Display format? | Bell icon (󰂚) + unread count |

## Center BarGroup

| Question | Selected |
|----------|----------|
| Widget order? | WeatherWidget → ClockWidget → ForecastWidget |
| One pill or three? | Each widget in its own ModulePill |
| Clock format? | Same as Waybar: `{:%a %Y-%m-%d %I:%M:%S %p}` |

## Backlight Widget

| Question | Selected |
|----------|----------|
| Poll interval? | 30s per CTRL-01 requirement |
| Service singleton? | Yes (BacklightService.qml) |
| Write debounce? | 300ms |

## Scripts Strategy

| Question | Selected |
|----------|----------|
| Approach? | Call waybar scripts in-place via $HOME path |
| Scripts directory? | Not created |

## Weather Widgets

| Question | Selected |
|----------|----------|
| One service or two? | Two separate: WeatherService.qml + ForecastService.qml |
| Poll interval? | 200s (matches Waybar) |

## Memory Widget

| Question | Selected |
|----------|----------|
| Approach? | Reuse memory.sh via MemoryService.qml |
| Poll interval? | 5s |
| Click? | None (Waybar had btop; user opted out) |

## Disk Widget

| Question | Selected |
|----------|----------|
| Approach? | DiskService.qml singleton, inline df -h |
| Poll interval? | 30s |
| Click? | Opens nautilus |
| Threshold colors? | Same as CPU: ≥50% warning, ≥90% critical |

## Ping Widget

| Question | Selected |
|----------|----------|
| Approach? | PingService.qml singleton, reuse ping_status.sh |
| Click? | Opens localhost:8765 |

## General

| Question | Selected |
|----------|----------|
| Error state? | Show error glyph + "err" in red |
| Tooltips? | Same coverage as Waybar |
| Colours.qml aliases? | Add per-widget semantic colors |
| Lock/Power widgets? | Explicitly dropped |

## Poll Intervals Summary

| Widget | Interval |
|--------|----------|
| CPU | 3s |
| Memory | 5s |
| Disk | 30s |
| Network | 10s |
| Ping | 5s |
| Weather (both) | 200s |
| Clock | 1s |
| Backlight | 30s |
| Notification | 5s |

---

*Discussion completed: 2026-05-21*
