import Quickshell
import Quickshell.Hyprland
import "modules/bar"
import "services"

ShellRoot {
    Bar {
        id: bar
        networkPopup: networkPopupWindow
        bluetoothPopup: bluetoothPopupWindow
        systemPopup: systemPopupWindow
    }

    PopupWindow {
        id: systemPopupWindow
        anchor.window: bar
        anchor.rect.x: bar.width - 260 - Theme.barMargin
        anchor.rect.y: bar.height + 4
        implicitWidth: 220
        implicitHeight: 240
        visible: false
        grabFocus: true
        color: "transparent"

        SystemPopup {}

        HyprlandFocusGrab {
            windows: [systemPopupWindow]
            active: systemPopupWindow.visible
            onCleared: systemPopupWindow.visible = false
        }
    }

    PopupWindow {
        id: networkPopupWindow
        anchor.window: bar
        anchor.rect.x: bar.width - 260 - Theme.barMargin
        anchor.rect.y: bar.height + 4
        implicitWidth: 260
        implicitHeight: 340
        visible: false
        grabFocus: true
        color: "transparent"

        NetworkPopup {}

        HyprlandFocusGrab {
            windows: [networkPopupWindow]
            active: networkPopupWindow.visible
            onCleared: networkPopupWindow.visible = false
        }
    }

    PopupWindow {
        id: bluetoothPopupWindow
        anchor.window: bar
        anchor.rect.x: bar.width - 260 - Theme.barMargin
        anchor.rect.y: bar.height + 4
        implicitWidth: 260
        implicitHeight: 280
        visible: false
        grabFocus: true
        color: "transparent"

        BluetoothPopup {}

        HyprlandFocusGrab {
            windows: [bluetoothPopupWindow]
            active: bluetoothPopupWindow.visible
            onCleared: bluetoothPopupWindow.visible = false
        }
    }

}

