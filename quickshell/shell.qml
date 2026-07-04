import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "modules/bar"
import "services"

ShellRoot {
    Bar {
        id: bar
        networkPopup: networkPopupWindow
        bluetoothPopup: bluetoothPopupWindow
        systemPopup: systemPopupWindow
        nightlightPopup: nightlightPopupWindow
    }

    HyprlandFocusGrab {
        windows: [bar]
        active: bar.islandExpanded
        onCleared: bar.islandExpanded = false
    }

    PopupWindow {
        id: systemPopupWindow
        anchor.window: bar
        anchor.rect.x: bar.width - 260 - Theme.barMargin
        anchor.rect.y: Theme.barHeight + 4
        implicitWidth: 260
        implicitHeight: 260
        visible: false
        grabFocus: pinned
        color: "transparent"
        property bool pinned: false
        property bool hovered: false
        property bool triggerHovered: false

        function requestClose() {
            systemCloseDelay.restart();
        }

        function closeFloating() {
            if (!pinned && !hovered && !triggerHovered)
                visible = false;
        }

        onVisibleChanged: {
            if (!visible) {
                pinned = false;
                hovered = false;
                triggerHovered = false;
            }
        }

        SystemPopup {
            popupWindow: systemPopupWindow
        }

        Timer {
            id: systemCloseDelay
            interval: 300
            repeat: false
            onTriggered: systemPopupWindow.closeFloating()
        }

        HyprlandFocusGrab {
            windows: [systemPopupWindow]
            active: systemPopupWindow.visible && systemPopupWindow.pinned
            onCleared: systemPopupWindow.visible = false
        }
    }

    PopupWindow {
        id: networkPopupWindow
        anchor.window: bar
        anchor.rect.x: bar.width - 260 - Theme.barMargin
        anchor.rect.y: Theme.barHeight + 4
        implicitWidth: 260
        implicitHeight: 340
        visible: false
        grabFocus: pinned
        color: "transparent"
        property bool pinned: false
        property bool hovered: false
        property bool triggerHovered: false

        function requestClose() {
            networkCloseDelay.restart();
        }

        function closeFloating() {
            if (!pinned && !hovered && !triggerHovered)
                visible = false;
        }

        onVisibleChanged: {
            if (!visible) {
                pinned = false;
                hovered = false;
                triggerHovered = false;
            }
        }

        NetworkPopup {
            popupWindow: networkPopupWindow
        }

        Timer {
            id: networkCloseDelay
            interval: 300
            repeat: false
            onTriggered: networkPopupWindow.closeFloating()
        }

        HyprlandFocusGrab {
            windows: [networkPopupWindow]
            active: networkPopupWindow.visible && networkPopupWindow.pinned
            onCleared: networkPopupWindow.visible = false
        }
    }

    PopupWindow {
        id: bluetoothPopupWindow
        anchor.window: bar
        anchor.rect.x: bar.width - 260 - Theme.barMargin
        anchor.rect.y: Theme.barHeight + 4
        implicitWidth: 260
        implicitHeight: 280
        visible: false
        grabFocus: pinned
        color: "transparent"
        property bool pinned: false
        property bool hovered: false
        property bool triggerHovered: false

        function requestClose() {
            bluetoothCloseDelay.restart();
        }

        function closeFloating() {
            if (!pinned && !hovered && !triggerHovered)
                visible = false;
        }

        onVisibleChanged: {
            if (!visible) {
                pinned = false;
                hovered = false;
                triggerHovered = false;
            }
        }

        BluetoothPopup {
            popupWindow: bluetoothPopupWindow
        }

        Timer {
            id: bluetoothCloseDelay
            interval: 300
            repeat: false
            onTriggered: bluetoothPopupWindow.closeFloating()
        }

        HyprlandFocusGrab {
            windows: [bluetoothPopupWindow]
            active: bluetoothPopupWindow.visible && bluetoothPopupWindow.pinned
            onCleared: bluetoothPopupWindow.visible = false
        }
    }

    PopupWindow {
        id: nightlightPopupWindow
        anchor.window: bar
        anchor.rect.x: bar.width - 260 - Theme.barMargin
        anchor.rect.y: Theme.barHeight + 4
        implicitWidth: 260
        implicitHeight: 220
        visible: false
        grabFocus: pinned
        color: "transparent"
        property bool pinned: false
        property bool hovered: false
        property bool triggerHovered: false

        function requestClose() {
            nightlightCloseDelay.restart();
        }

        function closeFloating() {
            if (!pinned && !hovered && !triggerHovered)
                visible = false;
        }

        onVisibleChanged: {
            if (!visible) {
                pinned = false;
                hovered = false;
                triggerHovered = false;
            }
        }

        NightlightPopup {
            popupWindow: nightlightPopupWindow
        }

        Timer {
            id: nightlightCloseDelay
            interval: 300
            repeat: false
            onTriggered: nightlightPopupWindow.closeFloating()
        }

        HyprlandFocusGrab {
            windows: [nightlightPopupWindow]
            active: nightlightPopupWindow.visible && nightlightPopupWindow.pinned
            onCleared: nightlightPopupWindow.visible = false
        }
    }

    IpcHandler {
        target: "bar"
        function toggleNotifications(): void {
            bar.toggleNotifications();
        }

        function toggleWorkspaceOverview(): void {
            bar.toggleWorkspaceOverview();
        }
    }
}
