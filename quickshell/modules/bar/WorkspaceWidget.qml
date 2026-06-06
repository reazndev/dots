import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../../services"
import "../../components"

Row {
    id: root
    spacing: 8

    property var allWorkspaces: Hyprland.workspaces.values
    property var activeSpecials: []

    Process {
        running: true
        command: ["bash", "-c", "while true; do hyprctl monitors -j | python3 -c 'import sys,json; print(json.dumps([m.get(\\\"specialWorkspace\\\",{}).get(\\\"name\\\",\\\"\\\") for m in json.load(sys.stdin)]))'; sleep 1; done"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.activeSpecials = JSON.parse(data.trim());
                } catch (e) {
                    root.activeSpecials = [];
                }
            }
        }
    }

    function findWorkspace(id) {
        for (var i = 0; i < allWorkspaces.length; i++) {
            if (allWorkspaces[i].id === id)
                return allWorkspaces[i];
        }
        return null;
    }

    function circleColor(ws) {
        if (!ws)
            return Theme.fgDim;
        if (ws.focused)
            return Theme.accent;
        if (ws.lastIpcObject && ws.lastIpcObject["windows"] > 0)
            return Theme.fg;
        return Theme.fgDim;
    }

    function specialColor(name) {
        for (var i = 0; i < activeSpecials.length; i++) {
            if (activeSpecials[i] === name)
                return Theme.accent;
        }
        return Theme.fgDim;
    }

    // Workspaces 1-5
    Repeater {
        model: 5
        delegate: Rectangle {
            width: 12
            height: 12
            radius: 6
            color: circleColor(findWorkspace(index + 1))

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
        width: 14
        height: 14
        radius: 7
        color: specialColor("special:messenger")

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
        width: 14
        height: 14
        radius: 7
        color: specialColor("special:music")

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
}
