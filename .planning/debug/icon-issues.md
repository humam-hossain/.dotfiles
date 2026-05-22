# Debug Session: Icon Issues

## Root Cause A: Memory double icon (Test 3)
`memory.sh:53` embeds `` in JSON text output. `MemoryWidget.qml:21` prepends `" "` → double icon.

## Root Cause B: Disk wrong icon (Test 4)
Uses `` (folder icon). User wants disk-specific glyph.

## Root Cause C: Ping unnecessary icon (Test 6)
Icon `󰀶` adds no value over existing color-coded status.

## Files Involved
- `.config/quickshell/widgets/MemoryWidget.qml:21` — prepends icon when script provides one
- `.config/quickshell/widgets/DiskWidget.qml:21` — wrong icon choice
- `.config/quickshell/widgets/PingWidget.qml:26` — redundant icon

## Fix Direction
1. MemoryWidget: Remove icon prefix (script provides icon already)
2. DiskWidget: Replace with `` (hdd-o) or `󰋊` (harddisk)
3. PingWidget: Remove `"󰀶 "` prefix, rely on color only
