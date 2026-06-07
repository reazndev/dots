import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    id: root
    spacing: Theme.islandGap
    implicitWidth: amountText.implicitWidth + levelDonut.implicitWidth + spacing
    implicitHeight: Math.max(amountText.implicitHeight, levelDonut.implicitHeight)

    StyledText {
        id: amountText
        Layout.alignment: Qt.AlignVCenter
        text: VolumeService.displayText
        role: "fg"
        font.family: Theme.fontFamilyUi
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
    }

    DonutChart {
        id: levelDonut
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        value: VolumeService.displayPercent
        icon: ""
        fgColor: Theme.blue
        lineWidth: 3
    }
}
