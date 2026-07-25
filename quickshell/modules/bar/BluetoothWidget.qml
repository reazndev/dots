import QtQuick
import Quickshell.Bluetooth
import "../../components"

Icon {
    id: icon
    role: "fg"

    property var popup: null
    visible: Bluetooth.defaultAdapter !== null
    text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "\uE05C" : "\uE1B9"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (icon.popup)
                icon.popup.visible = !icon.popup.visible;
        }
    }
}
