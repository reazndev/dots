import QtQuick
import "../services"

Item {
    id: root
    property real value: 0
    property color bgColor: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.25)
    property color fgColor: Theme.accent
    property real lineWidth: 1.5
    property string icon: ""

    width: 22
    height: 22

    onValueChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var cx = width / 2;
            var cy = height / 2;
            var r = Math.min(cx, cy) - lineWidth / 2;

            // Background ring
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.strokeStyle = root.bgColor;
            ctx.lineWidth = root.lineWidth;
            ctx.stroke();

            // Foreground arc
            ctx.beginPath();
            var start = -Math.PI / 2;
            var end = start + (2 * Math.PI * Math.min(root.value, 100) / 100);
            ctx.arc(cx, cy, r, start, end);
            ctx.strokeStyle = root.fgColor;
            ctx.lineWidth = root.lineWidth;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }

    Text {
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        text: root.icon
        font.family: Theme.iconFontFamily
        font.pixelSize: 10
        color: Theme.fg
    }
}
