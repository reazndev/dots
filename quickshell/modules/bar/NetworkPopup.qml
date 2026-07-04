import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
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

    property var wifiDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi)
                return devs[i];
        }
        return null;
    }
    property var currentNetwork: {
        if (!wifiDevice)
            return null;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected)
                return nets[i];
        }
        return null;
    }
    property var selectedNetwork: null
    property string passwordText: ""

    function needsPassword(net) {
        return net && net.security !== WifiSecurityType.Open && !net.known;
    }

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
                    text: "\uE1AE"
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 16
                    color: Theme.mdOnPrimaryContainer
                }
            }

            StyledText {
                text: "Wi-Fi"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.mdOnSurface
            }
            Item {
                Layout.fillWidth: true
            }
            Toggle {
                checked: Networking.wifiEnabled
                onToggled: Networking.wifiEnabled = checked
            }
        }

        // Current connection
        StyledText {
            visible: currentNetwork !== null && selectedNetwork === null
            text: currentNetwork ? "Connected: " + currentNetwork.name : ""
            font.family: Theme.fontFamilyUi
            color: Theme.green
        }

        // Password dialog
        ColumnLayout {
            Layout.fillWidth: true
            visible: selectedNetwork !== null
            spacing: 8

            StyledText {
                text: selectedNetwork ? selectedNetwork.name : ""
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.mdOnSurface
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 16
                color: Theme.mdSurfaceContainer
                border.color: Theme.mdOutlineVariant
                border.width: 1

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 8
                    color: Theme.mdOnSurface
                    font.family: Theme.fontFamilyUi
                    font.pixelSize: Theme.fontSize
                    echoMode: TextInput.Password
                    clip: true
                    text: passwordText
                    onTextChanged: passwordText = text
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 16
                    color: connectArea.pressed ? Theme.mdPrimary : Theme.mdPrimaryContainer

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.mdMotionShort
                            easing.type: Easing.OutCubic
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: "Connect"
                        font.family: Theme.fontFamilyUi
                        color: Theme.mdOnPrimaryContainer
                    }

                    MouseArea {
                        id: connectArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (selectedNetwork) {
                                selectedNetwork.connectWithPsk(passwordText);
                                selectedNetwork = null;
                                passwordText = "";
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 16
                    color: cancelArea.pressed
                        ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdPressedState)
                        : (cancelArea.containsMouse
                            ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdHoverState)
                            : Theme.mdSurfaceContainer)

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.mdMotionShort
                            easing.type: Easing.OutCubic
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: Theme.fontFamilyUi
                        color: Theme.mdOnSurface
                    }

                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            selectedNetwork = null;
                            passwordText = "";
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.mdOutlineVariant
            opacity: 0.55
            visible: wifiDevice && wifiDevice.networks.values.length > 0 && selectedNetwork === null
        }

        // Network list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            visible: selectedNetwork === null
            model: wifiDevice ? wifiDevice.networks.values : []

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
                        text: modelData.name
                        font.family: Theme.fontFamilyUi
                        color: modelData.connected ? Theme.mdOnPrimaryContainer : Theme.mdOnSurface
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: modelData.connected
                        text: "connected"
                        font.family: Theme.fontFamilyUi
                        color: Theme.mdOnPrimaryContainer
                        font.pixelSize: 11
                    }

                    StyledText {
                        visible: !modelData.connected && modelData.security !== WifiSecurityType.Open
                        text: "\uE10B"
                        font.family: Theme.iconFontFamily
                        color: Theme.mdOnSurfaceVariant
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.connected)
                            return;
                        if (modelData.security === WifiSecurityType.Open || modelData.known) {
                            modelData.requestConnect();
                        } else {
                            selectedNetwork = modelData;
                            passwordText = "";
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: selectedNetwork === null && (!wifiDevice || wifiDevice.networks.values.length === 0)
        }

        StyledText {
            visible: selectedNetwork === null && (!wifiDevice || wifiDevice.networks.values.length === 0)
            text: "No networks"
            font.family: Theme.fontFamilyUi
            color: Theme.mdOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }

        // Scan button
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 16
            visible: selectedNetwork === null
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
                text: wifiDevice && wifiDevice.scannerEnabled ? "Scanning..." : "Scan Networks"
                font.family: Theme.fontFamilyUi
                color: Theme.mdOnSurfaceVariant
            }

            MouseArea {
                id: mouseAreaScan
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (wifiDevice)
                        wifiDevice.scannerEnabled = true;
                }
            }
        }
    }
}
