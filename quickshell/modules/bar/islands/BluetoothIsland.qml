import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    spacing: Theme.islandGap

    property var islandData: IslandManager.activeIsland ? IslandManager.activeIsland.data : {}
    property var device: islandData.device || BluetoothConnectionService.latestConnectedDevice

    Icon {
        text: "\uE05C"
        font.pixelSize: Theme.fontSizeLarge
        color: Theme.blue
    }

    StyledText {
        text: BluetoothConnectionService.deviceName(device)
        role: "fg"
        font.family: Theme.fontFamilyUi
        font.bold: true
        elide: Text.ElideRight
        Layout.maximumWidth: 190
    }

    StyledText {
        text: "connected"
        role: "green"
        font.pixelSize: Theme.fontSize - 1
    }
}
