<Phase 1 Pattern Map>
## File Classification

| File | Role | Analog | Pattern |
|------|------|--------|---------|
| .config/quickshell/shell.qml | entry point | `dots-hyprland/dots/.config/quickshell/ii/shell.qml` | Quickshell Bootstrap |
| .config/quickshell/panelFamilies/PanelLoader.qml | component | `dots-hyprland/dots/.config/quickshell/ii/panelFamilies/PanelLoader.qml` | LazyLoader wrapper |
| .config/quickshell/services/MaterialThemeLoader.qml | singleton | `dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml` | JSON FileView reader |
| .config/quickshell/modules/common/Appearance.qml | singleton | `dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | m3colors exposure |
| .config/quickshell/panelFamilies/IllogicalImpulseFamily.qml | component | `dots-hyprland/dots/.config/quickshell/ii/panelFamilies/IllogicalImpulseFamily.qml` | Panel family structure |
| .config/quickshell/**/qmldir | manifest | `.config/quickshell/theme/qmldir` (old attempt) | Explicit module & singleton manifest |
| arch/quickshell.sh | script | `arch/quickshell.sh` | Symlink deploy pattern |

## Analog Excerpts

### .config/quickshell/shell.qml
**Analog:** `dots-hyprland/dots/.config/quickshell/ii/shell.qml`
**Pattern:** Quickshell Bootstrap
```qml
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }
```

### .config/quickshell/panelFamilies/PanelLoader.qml
**Analog:** `dots-hyprland/dots/.config/quickshell/ii/panelFamilies/PanelLoader.qml`
**Pattern:** LazyLoader Wrapper
```qml
import QtQuick
import Quickshell

import qs.modules.common

LazyLoader {
    property bool extraCondition: true
    active: Config.ready && extraCondition
}
```

### .config/quickshell/services/MaterialThemeLoader.qml
**Analog:** `dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml`
**Pattern:** JSON FileView reader
```qml
    function applyColors(fileContent) {
        const json = JSON.parse(fileContent)
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                // Convert snake_case to CamelCase
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                Appearance.m3colors[m3Key] = json[key]
            }
        }
        
        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
    }

	FileView { 
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
```

### .config/quickshell/modules/common/Appearance.qml
**Analog:** `dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml`
**Pattern:** m3colors exposure
```qml
    m3colors: QtObject {
        property bool darkmode: true
        property bool transparent: false
        property color m3background: "#141313"
        property color m3onBackground: "#e6e1e1"
        // ... (other colors)
    }

    colors: QtObject {
        property color colSubtext: m3colors.m3outline
        // Layer 0
        property color colLayer0Base: ColorUtils.mix(m3colors.m3background, m3colors.m3primary, Config.options.appearance.extraBackgroundTint ? 0.99 : 1)
        property color colLayer0: ColorUtils.transparentize(colLayer0Base, root.backgroundTransparency)
        // ...
    }
```

### .config/quickshell/panelFamilies/IllogicalImpulseFamily.qml
**Analog:** `dots-hyprland/dots/.config/quickshell/ii/panelFamilies/IllogicalImpulseFamily.qml`
**Pattern:** Panel family structure
```qml
Scope {
    PanelLoader { extraCondition: !Config.options.bar.vertical; component: Bar {} }
    PanelLoader { component: Background {} }
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
    // ... loads all screens and bar components
}
```

### .config/quickshell/**/qmldir
**Analog:** `.config/quickshell/theme/qmldir` (from previous attempt, to enforce explicit manifests per user directive D-16, since `dots-hyprland` natively relied on auto-loading)
**Pattern:** Singleton Manifest
```text
singleton MaterialThemeLoader MaterialThemeLoader.qml
singleton Appearance Appearance.qml
```

### arch/quickshell.sh
**Analog:** `arch/quickshell.sh`
**Pattern:** Symlink deploy pattern
```bash
symlink_config() {
  echo "[CONFIG] symlink $QS_DST -> $QS_SRC"
  mkdir -p "$(dirname "$QS_DST")"
  rm -rf "$QS_DST"
  ln -s "$QS_SRC" "$QS_DST"
}
```

## Data Flow
1. **Bootstrapping**: `quickshell` executes `shell.qml`.
2. **Service Initialization**: `shell.qml` calls `.load()` or `.reapplyTheme()` on various singletons (like `MaterialThemeLoader`).
3. **Theme Delivery**: `MaterialThemeLoader` watches `material_colors.json` via `FileView`. When loaded, it parses the JSON, camelCases the keys, and populates the global `Appearance.m3colors` object.
4. **Panel Assembly**: `shell.qml` evaluates `Config.options.panelFamily` and triggers `PanelFamilyLoader` for `ii`.
5. **Component Loading**: `IllogicalImpulseFamily.qml` orchestrates all screen components (Bar, Background, Dock) using `PanelLoader`. `PanelLoader` internally uses Quickshell's `LazyLoader` bound to `Config.ready`.
6. **Rendering**: The active modules draw on the screen, reacting to `Appearance.m3colors` dynamically when the theme JSON changes.

## PATTERN MAPPING COMPLETE
</Phase 1 Pattern Map>
