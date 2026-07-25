import QtQuick
import Quickshell.Hyprland
import "../../services"
import "../../components"

Row {
    id: root
    spacing: 8

    property var allWorkspaces: HyprlandSnapshotService.workspaces

    function findWorkspace(id) {
        for (var i = 0; i < allWorkspaces.length; i++) {
            if (allWorkspaces[i].id === id)
                return allWorkspaces[i];
        }
        return null;
    }

    function isSpecialActive(name) {
        var monitors = HyprlandSnapshotService.monitors || [];
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].specialWorkspace && monitors[i].specialWorkspace.name === name)
                return true;
        }
        return false;
    }

    function isSpecialOccupied(name) {
        var workspaces = HyprlandSnapshotService.workspaces || [];
        for (var i = 0; i < workspaces.length; i++) {
            if (workspaces[i].name === name)
                return true;
        }
        return false;
    }

    // Workspaces 1-5
    Repeater {
        model: 5
        delegate: Rectangle {
            id: wsRect
            property var ws: findWorkspace(index + 1)
            property bool isFocused: HyprlandSnapshotService.activeWorkspaceId === index + 1
            property bool hasItems: ws ? ws.windows > 0 : false

            width: 24
            height: 12
            radius: 6
            color: isFocused ? Theme.blue : (hasItems ? Theme.fg : Theme.fgDim)
            opacity: isFocused ? 1.0 : (hasItems ? 0.8 : 0.35)

            Behavior on color { ColorAnimation { duration: 75 } }
            Behavior on opacity { NumberAnimation { duration: 75 } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace", (index + 1).toString())
            }
        }
    }

    // Separator
    Item {
        width: 16
        height: 1
    }

    // Special: messenger
    Rectangle {
        id: messengerRect
        property bool isActive: isSpecialActive("special:messenger")
        property bool hasItems: isSpecialOccupied("special:messenger")

        width: 24
        height: 12
        radius: 6
        color: isActive ? Theme.blue : (hasItems ? Theme.fg : Theme.fgDim)
        opacity: isActive ? 1.0 : (hasItems ? 0.8 : 0.35)

        Behavior on color { ColorAnimation { duration: 75 } }
        Behavior on opacity { NumberAnimation { duration: 75 } }

        Icon {
            anchors.centerIn: parent
            text: "\uE565"
            font.pixelSize: 8
            color: Theme.bg
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("togglespecialworkspace", "messenger")
        }
    }

    // Special: music
    Rectangle {
        id: musicRect
        property bool isActive: isSpecialActive("special:music")
        property bool hasItems: isSpecialOccupied("special:music")

        width: 24
        height: 12
        radius: 6
        color: isActive ? Theme.blue : (hasItems ? Theme.fg : Theme.fgDim)
        opacity: isActive ? 1.0 : (hasItems ? 0.8 : 0.35)

        Behavior on color { ColorAnimation { duration: 75 } }
        Behavior on opacity { NumberAnimation { duration: 75 } }

        Icon {
            anchors.centerIn: parent
            text: "\uE122"
            font.pixelSize: 8
            color: Theme.bg
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("togglespecialworkspace", "music")
        }
    }

    // Special: dev
    Rectangle {
        id: devRect
        property bool isActive: isSpecialActive("special:dev")
        property bool hasItems: isSpecialOccupied("special:dev")

        width: 24
        height: 12
        radius: 6
        color: isActive ? Theme.blue : (hasItems ? Theme.fg : Theme.fgDim)
        opacity: isActive ? 1.0 : (hasItems ? 0.8 : 0.35)

        Behavior on color { ColorAnimation { duration: 75 } }
        Behavior on opacity { NumberAnimation { duration: 75 } }

        Icon {
            anchors.centerIn: parent
            text: "\uE093"
            font.pixelSize: 8
            color: Theme.bg
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("togglespecialworkspace", "dev")
        }
    }
}
