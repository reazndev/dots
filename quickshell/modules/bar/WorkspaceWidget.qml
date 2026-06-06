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
    property var occupiedSpecials: []

    Process {
        running: true
        command: ["python3", "-c", "import subprocess, json, time\nwhile True:\n    try:\n        monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j']))\n        active = [m.get('specialWorkspace', {}).get('name', '') for m in monitors]\n    except Exception:\n        active = []\n    try:\n        workspaces = json.loads(subprocess.check_output(['hyprctl', 'workspaces', '-j']))\n        occupied = [w.get('name', '') for w in workspaces if w.get('name', '').startswith('special:')]\n    except Exception:\n        occupied = []\n    print(json.dumps({'active': active, 'occupied': occupied}), flush=True)\n    time.sleep(0.1)"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data.trim());
                    root.activeSpecials = parsed.active || [];
                    root.occupiedSpecials = parsed.occupied || [];
                } catch (e) {
                    root.activeSpecials = [];
                    root.occupiedSpecials = [];
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

    function isSpecialActive(name) {
        for (var i = 0; i < activeSpecials.length; i++) {
            if (activeSpecials[i] === name)
                return true;
        }
        return false;
    }

    function isSpecialOccupied(name) {
        for (var i = 0; i < occupiedSpecials.length; i++) {
            if (occupiedSpecials[i] === name)
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
            property bool isFocused: ws ? ws.focused : false
            property bool hasItems: ws ? (ws.lastIpcObject && ws.lastIpcObject["windows"] > 0) : false

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
