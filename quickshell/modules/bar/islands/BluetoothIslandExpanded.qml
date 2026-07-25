import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: Theme.islandPadding
    spacing: Theme.islandGap

    property var islandData: IslandManager.activeIsland ? IslandManager.activeIsland.data : {}
    property var device: islandData.device || BluetoothConnectionService.latestConnectedDevice
    readonly property bool batteryAvailable: !!(device && device.batteryAvailable)
    readonly property real batteryRawValue: batteryAvailable ? Math.max(0, Number(device.battery) || 0) : -1
    readonly property int batteryPercent: batteryAvailable ? Math.max(0, Math.min(100, Math.round(batteryRawValue <= 1 ? batteryRawValue * 100 : batteryRawValue))) : -1

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.islandGap

        Icon {
            text: "\uE05C"
            font.pixelSize: Theme.fontSizeLarge + 16
            color: Theme.blue
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(Theme.islandGap / 3)

            StyledText {
                Layout.fillWidth: true
                text: BluetoothConnectionService.deviceName(root.device)
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                text: "Connected"
                role: "green"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSize - 1
            }
        }

        StyledText {
            text: root.batteryAvailable ? root.batteryPercent + "%" : "--"
            role: root.batteryAvailable ? "fg" : "fgDim"
            font.family: Theme.fontFamilyUi
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(7, Math.round(Theme.islandGap * 0.8))
        radius: height / 2
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * (root.batteryAvailable ? root.batteryPercent / 100 : 0)
            radius: parent.radius
            color: root.batteryPercent <= 20 ? Theme.yellow : Theme.green

            Behavior on width {
                NumberAnimation {
                    duration: Theme.islandAnimationDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
