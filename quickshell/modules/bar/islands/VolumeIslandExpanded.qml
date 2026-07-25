import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    anchors.centerIn: parent
    spacing: Theme.islandGap

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: VolumeService.displayText
        role: "fg"
        font.family: Theme.fontFamilyUi
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
    }

    DonutChart {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        value: VolumeService.displayPercent
        icon: ""
        fgColor: Theme.blue
        lineWidth: 3
    }
}
