import Quickshell
import QtQuick
import "../services"

PanelWindow {
    id: panelWindow

    // Prefer the external monitor that Hyprland calls DP-1. If it is not
    // connected, fall back to the first available screen (normally the laptop
    // panel). The binding is re-evaluated as screens are added or removed.
    screen: {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === "DP-1")
                return Quickshell.screens[i];
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 5
        left: 5
        right: 5
    }
    implicitHeight: Theme.barHeight + extraHeight
    exclusiveZone: Theme.barHeight
    color: Theme.bgTransparent

    property int extraHeight: 0
    property real islandMaskX: 0
    property real islandMaskY: 0
    property real islandMaskWidth: 0
    property real islandMaskHeight: 0

    // Input mask: bar area + island expanded area.
    // The bar area is the root region; the island area is added below it.
    mask: Region {
        x: 0
        y: 0
        width: panelWindow.width
        height: Theme.barHeight
        intersection: Intersection.Combine

        Region {
            x: panelWindow.islandMaskX
            y: panelWindow.islandMaskY
            width: panelWindow.islandMaskWidth
            height: panelWindow.islandMaskHeight
            intersection: Intersection.Combine
        }
    }

    // Background only for the bar area; expanded island draws its own background
    Rectangle {
        id: bg
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.barHeight
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Theme.bgOpacity)
        border.color: Theme.border
        border.width: Theme.borderWidth
        radius: Theme.radius
    }

    // Anything placed inside PanelRoot becomes a child of the content container
    default property alias content: contentContainer.children

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}
