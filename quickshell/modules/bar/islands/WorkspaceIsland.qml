import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    id: root
    spacing: Theme.islandGap
    clip: true
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    readonly property var islandData: IslandManager.activeIsland ? IslandManager.activeIsland.data : {}
    readonly property string specialName: islandData.specialName || HyprlandSnapshotService.activeSpecialWorkspaceName
    readonly property int workspaceId: islandData.workspaceId || HyprlandSnapshotService.activeWorkspaceId
    readonly property bool hasSpecial: specialName !== ""

    function specialLabel(name) {
        var shortName = HyprlandSnapshotService.specialWorkspaceShortName(name);
        switch (shortName) {
        case "messenger":
            return "MSG";
        case "music":
            return "SPOT";
        case "dev":
            return "DEV";
        default:
            return shortName.toUpperCase();
        }
    }

    StyledText {
        id: label
        text: root.hasSpecial
            ? "WS " + root.specialLabel(root.specialName)
            : "WS " + root.workspaceId
        role: "fg"
        font.family: Theme.fontFamilyUi
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
    }
}
