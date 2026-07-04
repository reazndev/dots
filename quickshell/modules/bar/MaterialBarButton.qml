import QtQuick
import "../../components"
import "../../services"

Item {
    id: root

    property string iconText: ""
    property string role: "fg"
    property bool active: false
    property var popup: null
    signal clicked()

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

    function colorForRole(roleName) {
        switch (roleName) {
        case "fgDim":
            return Theme.fgDim;
        case "accent":
            return Theme.accent;
        case "green":
            return Theme.green;
        case "yellow":
            return Theme.yellow;
        case "red":
            return Theme.red;
        case "blue":
            return Theme.blue;
        default:
            return Theme.mdOnSurface;
        }
    }

    implicitWidth: 28
    implicitHeight: 28
    scale: mouseArea.pressed ? 0.95 : (mouseArea.containsMouse ? 1.03 : 1.0)
    opacity: enabled ? 1.0 : 0.5

    Behavior on scale {
        NumberAnimation {
            duration: Theme.mdMotionShort
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
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

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.mdMotionShort
                easing.type: Easing.OutCubic
            }
        }
    }

    Icon {
        anchors.centerIn: parent
        text: root.iconText
        color: root.active ? Theme.mdOnPrimaryContainer : root.colorForRole(root.role)
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.openFloating()
        onExited: root.requestFloatingClose()
        onClicked: {
            root.togglePinned();
            root.clicked();
        }
    }
}
