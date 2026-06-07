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
    readonly property color statColor: Theme.blue
    readonly property color statBgColor: Qt.rgba(statColor.r, statColor.g, statColor.b, 0.25)

    Row {
        id: row
        spacing: 10

        DonutChart {
            value: SystemMonitorService.cpuUsage
            icon: "\uE0A9"
            fgColor: root.statColor
            bgColor: root.statBgColor
        }

        DonutChart {
            value: SystemMonitorService.ramUsage
            icon: "\uE445"
            fgColor: root.statColor
            bgColor: root.statBgColor
        }

        DonutChart {
            value: SystemMonitorService.gpuUsage
            icon: "\uE66A"
            fgColor: root.statColor
            bgColor: root.statBgColor
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
