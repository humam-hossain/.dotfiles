pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property Item hoverTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0

    // Seamless cursor tracking (D-18, Pitfall 2)
    property bool popupHovered: false
    readonly property bool hovered: (hoverTarget && hoverTarget.containsMouse) || popupHovered
    property bool shouldBeActive: false

    Timer {
        id: closeTimer
        interval: 200 // 200ms grace period across window bounds
        repeat: false
        onTriggered: {
            if (!root.hovered) {
                root.shouldBeActive = false;
            }
        }
    }

    onHoveredChanged: {
        if (hovered) {
            closeTimer.stop();
            shouldBeActive = true;
        } else {
            closeTimer.restart();
        }
    }

    active: shouldBeActive

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        // Screen Boundary Clamping Math (D-19, Pitfall 4)
        margins {
            left: {
                if (!Config.options.bar.vertical) {
                    const screenWidth = root.QsWindow?.screen?.width ?? 1920;
                    const targetX = root.QsWindow?.mapFromItem(
                        root.hoverTarget, 
                        (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
                    ).x ?? 0;
                    const gap = Appearance.sizes.hyprlandGapsOut;
                    const minX = gap;
                    const maxX = screenWidth - popupBackground.implicitWidth - gap;
                    if (maxX < minX) return minX;
                    return Math.round(Math.max(minX, Math.min(targetX, maxX)));
                }
                return Appearance.sizes.verticalBarWidth;
            }
            top: {
                if (!Config.options.bar.vertical) return Appearance.sizes.barHeight;
                const screenHeight = root.QsWindow?.screen?.height ?? 1080;
                const targetY = root.QsWindow?.mapFromItem(
                    root.hoverTarget, 
                    0, (root.hoverTarget.height - popupBackground.implicitHeight) / 2
                ).y ?? 0;
                const gap = Appearance.sizes.hyprlandGapsOut;
                const minY = gap;
                const maxY = screenHeight - popupBackground.implicitHeight - gap;
                if (maxY < minY) return minY;
                return Math.round(Math.max(minY, Math.min(targetY, maxY)));
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }

        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        // Track hover inside the popup window to bridge cursor across gap (D-18)
        HoverHandler {
            id: windowHoverHandler
            onHoveredChanged: {
                root.popupHovered = hovered;
            }
        }

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }
            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            transform: Translate {
                id: entranceTranslate
                y: 0
            }

            // Material 3 Expressive Entrance Transition (D-20)
            ParallelAnimation {
                running: true
                NumberAnimation {
                    target: popupBackground
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 150
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
                NumberAnimation {
                    target: entranceTranslate
                    property: "y"
                    from: -4
                    to: 0
                    duration: 150
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }
        }
    }
}
