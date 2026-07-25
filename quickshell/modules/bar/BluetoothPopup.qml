import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../components"
import "../../services"

Rectangle {
    anchors.fill: parent
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth
    radius: Theme.radius

    function stateText(state) {
        switch (state) {
        case BluetoothDeviceState.Connected:
            return "connected";
        case BluetoothDeviceState.Connecting:
            return "connecting...";
        case BluetoothDeviceState.Disconnecting:
            return "disconnecting...";
        default:
            return "";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Bluetooth"
                font.pixelSize: Theme.fontSizeLarge
            }
            Item {
                Layout.fillWidth: true
            }
            Toggle {
                checked: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                onToggled: {
                    if (Bluetooth.defaultAdapter)
                        Bluetooth.defaultAdapter.enabled = checked;
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
            visible: Bluetooth.devices.values.length > 0
        }

        // Device list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: Bluetooth.devices.values

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 36
                radius: 6
                color: mouseArea.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    StyledText {
                        text: modelData.name || modelData.address
                        role: modelData.connected ? "accent" : "fg"
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: stateText(modelData.state)
                        role: modelData.connected ? "green" : "fgDim"
                        font.pixelSize: 11
                        visible: text !== ""
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.connected)
                            modelData.connected = false;
                        else
                            modelData.connected = true;
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: Bluetooth.devices.values.length === 0
        }

        StyledText {
            visible: Bluetooth.devices.values.length === 0
            text: "No devices"
            role: "fgDim"
            Layout.alignment: Qt.AlignHCenter
        }

        // Scan button
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 6
            visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
            color: mouseAreaScan.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)

            StyledText {
                anchors.centerIn: parent
                text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "Scanning..." : "Scan Devices"
                role: "fgDim"
            }

            MouseArea {
                id: mouseAreaScan
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Bluetooth.defaultAdapter)
                        Bluetooth.defaultAdapter.discovering = true;
                }
            }
        }
    }
}
