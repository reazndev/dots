import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    // TODO: Connect to messaging service
    // Show conversation list or unread messages

    StyledText {
        text: "Messages"
        font.pixelSize: Theme.fontSizeLarge
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.border
    }

    StyledText {
        text: "No messages"
        role: "fgDim"
        Layout.alignment: Qt.AlignHCenter
    }
}
