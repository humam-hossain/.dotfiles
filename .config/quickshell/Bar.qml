import Quickshell

Scope {
    Variants {
        model: Quickshell.screens

        delegate: BarContent {
            required property var modelData
            screen: modelData
        }
    }
}
