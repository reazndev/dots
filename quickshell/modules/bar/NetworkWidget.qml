import QtQuick
import Quickshell.Networking
import "../../components"

Icon {
    id: icon
    role: "fg"

    property var popup: null
    property var netDevices: Networking.devices.values

    text: {
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

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (icon.popup)
                icon.popup.visible = !icon.popup.visible;
        }
    }
}
