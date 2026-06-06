import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    // TODO: Connect to LocalSend / file transfer service
    // Show active transfers with progress bars

    StyledText {
        text: "LocalSend"
        font.pixelSize: Theme.fontSizeLarge
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.border
    }

    StyledText {
        text: "No active transfers"
        role: "fgDim"
        Layout.alignment: Qt.AlignHCenter
    }
}
