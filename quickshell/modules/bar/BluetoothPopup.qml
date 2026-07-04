import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../components"
import "../../services"

Rectangle {
    id: root

    anchors.fill: parent
    color: Theme.mdSurface
    border.color: Theme.mdOutlineVariant
    border.width: Theme.borderWidth
    radius: 24
    clip: true
    opacity: parent && parent.visible ? 1 : 0
    scale: parent && parent.visible ? 1 : 0.96

    property var popupWindow: null

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.mdMotionMedium
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.mdMotionMedium
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (!root.popupWindow)
                return;
            root.popupWindow.hovered = hovered;
            if (!hovered)
                root.popupWindow.requestClose();
        }
    }

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
        anchors.margins: 14
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: Theme.mdPrimaryContainer

                StyledText {
                    anchors.centerIn: parent
                    text: "\uE05C"
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 16
                    color: Theme.mdOnPrimaryContainer
                }
            }

            StyledText {
                text: "Bluetooth"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.mdOnSurface
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
            color: Theme.mdOutlineVariant
            opacity: 0.55
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
                height: 42
                radius: 16
                color: modelData.connected
                    ? Theme.mdPrimaryContainer
                    : (mouseArea.pressed
                        ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdPressedState)
                        : (mouseArea.containsMouse
                            ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdHoverState)
                            : Theme.mdSurfaceContainer))

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.mdMotionShort
                        easing.type: Easing.OutCubic
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    StyledText {
                        text: modelData.name || modelData.address
                        font.family: Theme.fontFamilyUi
                        color: modelData.connected ? Theme.mdOnPrimaryContainer : Theme.mdOnSurface
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: stateText(modelData.state)
                        font.family: Theme.fontFamilyUi
                        color: modelData.connected ? Theme.mdOnPrimaryContainer : Theme.mdOnSurfaceVariant
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
            font.family: Theme.fontFamilyUi
            color: Theme.mdOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }

        // Scan button
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 16
            visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
            color: mouseAreaScan.pressed
                ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdPressedState)
                : (mouseAreaScan.containsMouse
                    ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdHoverState)
                    : Theme.mdSurfaceContainerHigh)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.mdMotionShort
                    easing.type: Easing.OutCubic
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "Scanning..." : "Scan Devices"
                font.family: Theme.fontFamilyUi
                color: Theme.mdOnSurfaceVariant
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
