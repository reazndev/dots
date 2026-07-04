import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Layouts
import "../../components"
import "../../services"

Item {
    id: root
    implicitWidth: container.implicitWidth
    implicitHeight: container.implicitHeight
    property var popup: null
    readonly property color statColor: Theme.blue
    readonly property color statBgColor: Qt.rgba(statColor.r, statColor.g, statColor.b, 0.25)
    readonly property bool active: popup && popup.visible

    function openFloating() {
        if (!popup)
            return;
        popup.triggerHovered = true;
        popup.visible = true;
    }

    function requestFloatingClose() {
        if (!popup)
            return;
        popup.triggerHovered = false;
        popup.requestClose();
    }

    function togglePinned() {
        if (!popup)
            return;
        if (popup.visible && popup.pinned) {
            popup.pinned = false;
            popup.visible = false;
        } else {
            popup.pinned = true;
            popup.visible = true;
        }
    }

    scale: mouseArea.pressed ? 0.97 : (mouseArea.containsMouse ? 1.02 : 1.0)

    Behavior on scale {
        NumberAnimation {
            duration: Theme.mdMotionShort
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: container
        implicitWidth: row.implicitWidth + 14
        implicitHeight: 28
        radius: height / 2
        color: root.active
            ? Theme.mdPrimaryContainer
            : (mouseArea.pressed
                ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdPressedState)
                : (mouseArea.containsMouse
                    ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdHoverState)
                    : Theme.mdSurfaceContainer))
        border.width: root.active || mouseArea.containsMouse ? 1 : 0
        border.color: root.active ? Theme.mdPrimary : Theme.mdOutlineVariant

        Behavior on color {
            ColorAnimation {
                duration: Theme.mdMotionShort
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            DonutChart {
                width: 20
                height: 20
                value: SystemMonitorService.cpuUsage
                icon: "\uE0A9"
                fgColor: root.active ? Theme.mdOnPrimaryContainer : root.statColor
                bgColor: root.active ? Qt.rgba(Theme.mdOnPrimaryContainer.r, Theme.mdOnPrimaryContainer.g, Theme.mdOnPrimaryContainer.b, 0.28) : root.statBgColor
            }

            DonutChart {
                width: 20
                height: 20
                value: SystemMonitorService.ramUsage
                icon: "\uE445"
                fgColor: root.active ? Theme.mdOnPrimaryContainer : root.statColor
                bgColor: root.active ? Qt.rgba(Theme.mdOnPrimaryContainer.r, Theme.mdOnPrimaryContainer.g, Theme.mdOnPrimaryContainer.b, 0.28) : root.statBgColor
            }

            DonutChart {
                width: 20
                height: 20
                value: SystemMonitorService.gpuUsage
                icon: "\uE66A"
                fgColor: root.active ? Theme.mdOnPrimaryContainer : root.statColor
                bgColor: root.active ? Qt.rgba(Theme.mdOnPrimaryContainer.r, Theme.mdOnPrimaryContainer.g, Theme.mdOnPrimaryContainer.b, 0.28) : root.statBgColor
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: root.openFloating()
        onExited: root.requestFloatingClose()
        onClicked: {
            root.togglePinned();
        }
    }
}
