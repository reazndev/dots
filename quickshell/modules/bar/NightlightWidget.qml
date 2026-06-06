import QtQuick
import "../../components"
import "../../services"

Icon {
    id: icon

    property var popup: null

    role: NightlightService.enabled ? "yellow" : "fgDim"
    text: NightlightService.enabled ? "" : ""

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (icon.popup)
                icon.popup.visible = !icon.popup.visible;
        }
    }
}
