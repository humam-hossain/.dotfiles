import Quickshell

Scope {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            BarContent {
                required property var modelData
                screen: modelData
            }
        }
    }
}
