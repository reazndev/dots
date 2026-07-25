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
        text: BrightnessService.displayText
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
        value: BrightnessService.percent
        icon: ""
        fgColor: Theme.yellow
        lineWidth: 3
    }
}
