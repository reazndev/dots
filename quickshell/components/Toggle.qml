import QtQuick
import "../services"

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    width: 36
    height: 20
    radius: 10
    color: checked ? Theme.accent : Theme.fgDim

    Rectangle {
        x: checked ? parent.width - width - 2 : 2
        y: 2
        width: 16
        height: 16
        radius: 8
        color: Theme.fg

        Behavior on x {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
