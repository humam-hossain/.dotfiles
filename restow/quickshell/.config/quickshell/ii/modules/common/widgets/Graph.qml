import QtQuick
import qs.modules.common
import qs.modules.common.functions

/*
 * Simple one value line graph with 10 FPS canvas paint throttling (D-50-05)
 */
Canvas {
    id: root

    enum Alignment { Left, Right }

    required property list<real> values
    property int points: values.length
    property color color: Appearance.colors.colPrimary
    property real fillOpacity: 0.5
    property var alignment: Graph.Alignment.Left

    property real lastPaintTime: 0
    property bool paintPending: false

    Timer {
        id: paintThrottleTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.paintPending = false;
            root.requestPaint();
        }
    }

    onValuesChanged: {
        const now = Date.now();
        if (now - lastPaintTime >= 100) {
            lastPaintTime = now;
            root.requestPaint();
        } else if (!paintPending) {
            paintPending = true;
            paintThrottleTimer.restart();
        }
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (!root.values || root.values.length < 2)
            return

        var n = root.points
        var dx = width / (n - 1)
        ctx.strokeStyle = root.color
        ctx.fillStyle = ColorUtils.transparentize(root.color, 1 - root.fillOpacity)
        ctx.lineWidth = 2
        ctx.beginPath()
        for (var i = 0; i < n; ++i) {
            var valueIndex = (root.alignment === Graph.Alignment.Right) ? root.values.length - n + i : i
            if (valueIndex < 0 || valueIndex >= root.values.length) {
                continue; // No data for this point
            }
            var x = i * dx
            var norm = root.values[valueIndex] // already in 0-1 range
            var y = height - norm * height
            if (valueIndex === 0) {
                ctx.moveTo(x, height)
                ctx.lineTo(x, y)
            } else {
                ctx.lineTo(x, y)
            }
        }
        ctx.stroke()
        ctx.lineTo(width, height)
        ctx.fill()
    }
}
