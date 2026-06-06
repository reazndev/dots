import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../components"
import "../../services"

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    property var popup: null

    Row {
        id: row
        spacing: 10

        DonutChart {
            value: SystemMonitorService.cpuUsage
            icon: "\uE0A9"
            fgColor: Theme.accent
        }

        DonutChart {
            value: SystemMonitorService.ramUsage
            icon: "\uE445"
            fgColor: Theme.green
        }

        DonutChart {
            value: SystemMonitorService.gpuUsage
            icon: "\uE66A"
            fgColor: Theme.blue
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            if (root.popup)
                root.popup.visible = !root.popup.visible;
        }
    }
}
