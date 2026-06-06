import QtQuick
import "../services"

Item {
    id: root
    property real value: 0
    property color trackColor: Theme.fgDim
    property color fillColor: Theme.green
    property color thumbColor: Theme.fg

    signal seekRequested(real ratio)

    height: 6

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width * Math.min(Math.max(root.value, 0), 100) / 100
        radius: height / 2
        color: root.fillColor
    }

    Rectangle {
        x: (parent.width * Math.min(Math.max(root.value, 0), 100) / 100) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 10
        radius: 5
        color: root.thumbColor
        visible: root.value > 0 && root.value < 100
    }

    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -8
        anchors.bottomMargin: -8
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => {
            var ratio = Math.max(0, Math.min(1, mouse.x / root.width));
            root.seekRequested(ratio);
        }

        onPositionChanged: mouse => {
            if (!pressed)
                return;
            var ratio = Math.max(0, Math.min(1, mouse.x / root.width));
            root.seekRequested(ratio);
        }
    }
}
