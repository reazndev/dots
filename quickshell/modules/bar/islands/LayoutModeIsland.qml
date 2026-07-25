import QtQuick
import "../../../services"
import "../../../components"

StyledText {
    readonly property var islandData: IslandManager.activeIsland ? IslandManager.activeIsland.data : {}

    text: islandData.label || ""
    role: "fg"
    font.family: Theme.fontFamilyUi
    font.pixelSize: Theme.fontSizeLarge
    font.bold: true
    horizontalAlignment: Text.AlignHCenter
}
