import QtQuick
import "../../components"
import "../../services"

MaterialBarButton {
    id: button

    active: popup && popup.visible
    role: NightlightService.enabled ? "yellow" : "fgDim"
    iconText: NightlightService.enabled ? "" : ""
}
