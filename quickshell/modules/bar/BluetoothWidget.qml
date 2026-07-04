import QtQuick
import Quickshell.Bluetooth
import "../../components"

MaterialBarButton {
    id: button

    visible: Bluetooth.defaultAdapter !== null
    active: popup && popup.visible
    role: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "fg" : "fgDim"
    iconText: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "\uE05C" : "\uE1B9"
}
