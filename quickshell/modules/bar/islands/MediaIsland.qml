import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    id: root
    spacing: Theme.islandGap

    RoundedImage {
        id: albumArt
        Layout.preferredWidth: Theme.islandCompactHeight - 6
        Layout.preferredHeight: Theme.islandCompactHeight - 6
        maskSource: "file:///home/reazn/.config/quickshell/assets/mask_compact.png"
        source: MediaService.artUrl

        Icon {
            anchors.centerIn: parent
            text: "\uE122"
            font.pixelSize: Theme.fontSize - 2
            color: Theme.bg
            visible: albumArt.status !== Image.Ready
        }
    }

    StyledText {
        text: TimeService.text
        role: "fg"
        font.family: Theme.fontFamilyUi
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
    }

    DonutChart {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        value: MediaService.progress * 100
        icon: ""
        fgColor: Theme.green
        lineWidth: 2
    }
}
