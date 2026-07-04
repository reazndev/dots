import QtQuick
import Quickshell.Networking
import "../../components"

MaterialBarButton {
    id: button

    property var netDevices: Networking.devices.values

    active: popup && popup.visible
    iconText: {
        for (var i = 0; i < netDevices.length; i++) {
            var dev = netDevices[i];
            if (dev.connected) {
                if (dev.type === DeviceType.Wifi)
                    return "\uE1AE";
                if (dev.type === DeviceType.Wired)
                    return "\uE125";
            }
        }
        return "\uE1AF";
    }
}
