# DEBUG: pavucontrol / volumeMixer never opens (G-03-8)

**Status:** root_cause_found  
**Phase:** 03-system-audio-modules  
**Gap:** G-03-8  
**Discovered:** UAT test 8

## Symptoms

- expected: Middle/right on mute or mic opens mixer; sidebar audio Details opens mixer
- actual: Neither path opens anything

## Root Cause

`Config.options.apps.volumeMixer` is:

```
~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"
```

That script path **does not exist** on disk. Both bar and sidebar invoke:

```
Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
```

→ bash exit 127, no window. `pavucontrol` itself is installed at `/usr/bin/pavucontrol`.

## Evidence

```
$ bash -c '~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"'
bash: …/launch_first_available.sh: No such file or directory
$ which pavucontrol
/usr/bin/pavucontrol
```

- `Config.qml` L163: default volumeMixer string
- Live config.json: same broken path
- `BarContent.qml` L274, L313: middle/right → volumeMixer
- `sidebarRight/volumeMixer/VolumeDialog.qml` L34: Details → same command

## Files Involved

- `.config/quickshell/modules/common/Config.qml`
- Live `~/.config/illogical-impulse/config.json` (apps.volumeMixer)
- `BarContent.qml` / `VolumeDialog.qml` (call sites — OK once config works)
- Missing: `~/.config/hypr/hyprland/scripts/launch_first_available.sh` (or equivalent in repo)

## Suggested Fix Direction

Either:
1. Ship `launch_first_available.sh` under the path Config expects and dual-write, or
2. Change `volumeMixer` default + live config to a working command, e.g.  
   `command -v pavucontrol-qt >/dev/null && pavucontrol-qt || pavucontrol`  
   (or simply `pavucontrol` on this host).
