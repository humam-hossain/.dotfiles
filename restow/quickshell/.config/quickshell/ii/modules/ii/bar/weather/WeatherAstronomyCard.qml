import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    property var model: Weather.astronomy

    icon: "nights_stay"
    Layout.fillWidth: true
    title: "Astronomy"

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // Solar Telemetry (Left)
        ColumnLayout {
            spacing: 4

            RowLayout {
                spacing: 6

                MaterialSymbol {
                    color: Appearance.m3colors.m3primary
                    fill: 0
                    iconSize: 16
                    text: "wb_twilight"
                }

                StyledText {
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: `Sunrise: ${root.model?.sunrise || "--:--"}`
                }
            }

            RowLayout {
                spacing: 6

                MaterialSymbol {
                    color: Appearance.m3colors.m3secondary
                    fill: 0
                    iconSize: 16
                    text: "bedtime"
                }

                StyledText {
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: `Sunset: ${root.model?.sunset || "--:--"}`
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Lunar Telemetry & Dynamic Canvas 2D Disc (Right) (POPUP-06, D-54-28, D-54-29)
        RowLayout {
            spacing: 8

            Canvas {
                id: moonCanvas

                implicitHeight: 36
                implicitWidth: 36
                renderStrategy: Canvas.Immediate
                renderTarget: Canvas.FramebufferObject

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    const cx = width / 2;
                    const cy = height / 2;
                    const radius = 15;

                    // 1. Base dark unlit circle
                    ctx.save();
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
                    ctx.fillStyle = Appearance.colors.colOutlineVariant || "#333333";
                    ctx.fill();

                    // 2. Parse illumination and phase name
                    const rawIllum = parseInt(root.model?.moonIllumination ?? 0, 10);
                    const illumFraction = Math.max(0, Math.min(100, isNaN(rawIllum) ? 0 : rawIllum)) / 100.0;
                    const phase = String(root.model?.moonPhase ?? "").toLowerCase();

                    if (illumFraction > 0.01) {
                        const isWaxing = phase.includes("waxing") || phase.includes("first");
                        const k = 2 * illumFraction - 1; // [-1, 1]

                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, -Math.PI / 2, Math.PI / 2, !isWaxing);

                        const termRadiusX = Math.max(0.1, Math.abs(k) * radius);
                        ctx.ellipse(cx, cy, termRadiusX, radius, 0, Math.PI / 2, -Math.PI / 2, k < 0 ? isWaxing : !isWaxing);

                        ctx.fillStyle = Appearance.colors.colOnSurface || "#ffffff";
                        ctx.fill();
                    }
                    ctx.restore();
                }

                Connections {
                    function onAstronomyChanged() {
                        moonCanvas.requestPaint();
                    }
                    target: Weather
                }

                Component.onCompleted: moonCanvas.requestPaint()
            }

            ColumnLayout {
                spacing: 2

                StyledText {
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    text: root.model?.moonPhase || "Moon"
                }

                StyledText {
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    text: `${root.model?.moonIllumination ?? "--"}% Illuminated`
                }
            }
        }
    }
}
