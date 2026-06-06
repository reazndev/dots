import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../../services"
import "../../../components"

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: Theme.islandPadding
    spacing: Theme.islandOverviewCellGap

    readonly property int rows: 2
    readonly property int columns: 5
    readonly property int workspacesShown: rows * columns
    readonly property int activeWorkspaceId: Math.max(1, HyprlandSnapshotService.activeWorkspaceId)
    readonly property int workspaceGroup: Math.floor((activeWorkspaceId - 1) / workspacesShown)

    function workspaceId(row, column) {
        return workspaceGroup * workspacesShown + row * columns + column + 1;
    }

    function windowTitle(client) {
        var value = client.title || client.class || client.initialClass || "";
        if (value.length > 24)
            return value.slice(0, 24) + "...";
        return value;
    }

    function focusWindow(client) {
        if (!client || !client.address)
            return;
        Hyprland.dispatch("focuswindow", "address:" + client.address);
    }

    Repeater {
        model: root.rows
        delegate: RowLayout {
            id: wsRow
            required property int index
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.islandOverviewCellGap

            Repeater {
                model: root.columns
                delegate: Rectangle {
                    id: cell
                    required property int index
                    readonly property int rowIndex: wsRow.index
                    readonly property int wsId: root.workspaceId(rowIndex, index)
                    readonly property var windows: HyprlandSnapshotService.windowsForWorkspace(wsId)
                    readonly property bool active: wsId === root.activeWorkspaceId
                    readonly property bool occupied: windows.length > 0

                    Layout.preferredWidth: Theme.islandOverviewCellWidth
                    Layout.preferredHeight: Theme.islandOverviewCellHeight
                    radius: Theme.radius + 6
                    color: mouseArea.containsMouse
                        ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)
                        : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, occupied ? 0.07 : 0.035)
                    border.width: active ? 2 : Theme.borderWidth
                    border.color: active ? Theme.blue : Theme.border
                    clip: true

                    Behavior on color { ColorAnimation { duration: Theme.islandAnimationDuration } }
                    Behavior on border.color { ColorAnimation { duration: Theme.islandAnimationDuration } }

                    StyledText {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: Theme.islandGap
                        anchors.topMargin: Math.round(Theme.islandGap / 2)
                        text: cell.wsId.toString()
                        role: cell.active ? "blue" : "fgDim"
                        font.family: Theme.fontFamilyUi
                        font.bold: true
                    }

                    Flow {
                        z: 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: Theme.islandGap
                        anchors.topMargin: Theme.islandGap + Theme.fontSize
                        spacing: Math.round(Theme.islandGap / 2)

                        Repeater {
                            model: cell.windows.slice(0, 4)
                            delegate: Rectangle {
                                required property var modelData
                                width: Math.max(42, (cell.width - Theme.islandGap * 3) / 2)
                                height: Math.max(18, Theme.fontSizeLarge + 4)
                                radius: Theme.radius - 3
                                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.72)
                                border.width: Theme.borderWidth
                                border.color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.65)

                                StyledText {
                                    anchors.fill: parent
                                    anchors.leftMargin: Math.round(Theme.islandGap / 2)
                                    anchors.rightMargin: Math.round(Theme.islandGap / 2)
                                    text: root.windowTitle(modelData)
                                    role: "fg"
                                    font.pixelSize: Theme.fontSize - 2
                                    font.family: Theme.fontFamilyUi
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.focusWindow(modelData)
                                }
                            }
                        }
                    }

                    StyledText {
                        z: 1
                        anchors.centerIn: parent
                        text: "empty"
                        role: "fgDim"
                        font.family: Theme.fontFamilyUi
                        visible: !cell.occupied
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        z: 0
                        onClicked: Hyprland.dispatch("workspace", cell.wsId.toString())
                    }
                }
            }
        }
    }
}
