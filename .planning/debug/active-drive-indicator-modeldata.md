# Debug Session: Active Drive Indicator ModelData

## ROOT CAUSE FOUND

**Debug Session:** .planning/debug/active-drive-indicator-modeldata.md

**Root Cause:**
In `MemoryStoragePopup.qml` line 113:
```qml
visible: StorageUsage.activeDisk === driveRow.modelData.mount && StorageUsage.diskIoPercentage > 0
```
Because `driveRow.modelData` evaluated to `undefined` due to the Repeater delegate self-binding issue (diagnosed in `storage-column-undefined-modeldata.md`), evaluating `driveRow.modelData.mount` threw `TypeError: Cannot read property 'mount' of undefined`, causing the active drive indicator visibility expression to error and fail to render.

**Evidence Summary:**
- Quickshell log: `WARN scene: @modules/ii/bar/MemoryStoragePopup.qml[113:-1]: TypeError: Cannot read property 'mount' of undefined`
- Line 113 directly relies on `driveRow.modelData.mount`.
- With `modelData` undefined, the indicator dot is never rendered.

**Files Involved:**
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml`: Line 113 visibility binding crashes on unverified property access.

**Suggested Fix Direction:**
Fix the `modelData` delegation bug in `MemoryStoragePopup.qml` and add safe navigation (`driveRow.modelData?.mount`) to the active drive indicator visibility binding.
