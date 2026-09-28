# Debug Session: Storage Column Undefined ModelData

## ROOT CAUSE FOUND

**Debug Session:** .planning/debug/storage-column-undefined-modeldata.md

**Root Cause:**
In `MemoryStoragePopup.qml` lines 395-397 and 421-423, the `Repeater` delegates for `StorageUsage.physicalDisks` and `StorageUsage.cloudDisks` instantiate `StorageDriveRow` with explicit self-binding `modelData: modelData`. In QtQuick with `pragma ComponentBehavior: Bound`, writing `modelData: modelData` causes self-referential property lookup on the uninitialized delegate instance instead of accessing the Repeater's injected model item, resulting in `driveRow.modelData` evaluating to `undefined`. This triggers runtime exceptions (`TypeError: Cannot read property 'fs' of undefined`, `TypeError: Cannot read property 'usePercent' of undefined`), crashing the delegate bindings, preventing drive labels from rendering, and defaulting progress bars to 0.

**Evidence Summary:**
- Quickshell log contains repeated runtime errors:
  `WARN scene: @modules/ii/bar/MemoryStoragePopup.qml[117:-1]: TypeError: Cannot read property 'fs' of undefined`
  `WARN scene: @modules/ii/bar/MemoryStoragePopup.qml[129:-1]: TypeError: Cannot read property 'usePercent' of undefined`
  `WARN scene: @modules/ii/bar/MemoryStoragePopup.qml[128:-1]: TypeError: Cannot read property 'usePercent' of undefined`
  `WARN scene: @modules/ii/bar/MemoryStoragePopup.qml[125:-1]: TypeError: Cannot read property 'usedKb' of undefined`
  `WARN scene: @modules/ii/bar/MemoryStoragePopup.qml[113:-1]: TypeError: Cannot read property 'mount' of undefined`
- In `MemoryStoragePopup.qml`:
  ```qml
  Repeater {
      model: StorageUsage.physicalDisks
      delegate: StorageDriveRow {
          modelData: modelData // Self-reference bug under Bound ComponentBehavior
      }
  }
  ```
- Because `StorageDriveRow` declares `required property var modelData`, QtQuick's Repeater automatically injects `modelData` if the delegate is simply `StorageDriveRow {}` or if bound via `modelData: (typeof model !== "undefined" && model ? (model.modelData ?? model) : undefined)`.

**Files Involved:**
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml`: Repeater delegates pass `modelData: modelData` causing circular undefined resolution.

**Suggested Fix Direction:**
In `MemoryStoragePopup.qml`, change the Repeater delegates to `delegate: StorageDriveRow {}` (or use `modelData: modelData` correctly scoped with explicit delegate property definition/safe accessor), and ensure null checks in `StorageDriveRow` before accessing `modelData.fs`, `modelData.mount`, etc.
