import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

ColumnLayout {
    anchors.fill: parent
    anchors.margins: Theme.islandPadding
    spacing: Math.round(Theme.islandGap / 2)

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: TimeService.shortText
        role: "fg"
        font.family: Theme.fontFamilyUi
        font.pixelSize: Theme.fontSizeLarge + 10
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: TimeService.dateText
        role: "fgDim"
        font.family: Theme.fontFamilyUi
    }
}
