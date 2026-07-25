import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import "../../components"
import "../../services"

Rectangle {
    anchors.fill: parent
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth
    radius: Theme.radius

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Wi-Fi"
                font.pixelSize: Theme.fontSizeLarge
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
            role: "green"
        }

        // Password dialog
        ColumnLayout {
            Layout.fillWidth: true
            visible: selectedNetwork !== null
            spacing: 8

            StyledText {
                text: selectedNetwork ? selectedNetwork.name : ""
                font.pixelSize: Theme.fontSizeLarge
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 6
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
                border.color: Theme.border
                border.width: 1

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 8
                    color: Theme.fg
                    font.family: Theme.fontFamily
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
                    radius: 6
                    color: Theme.accent

                    StyledText {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: Theme.bg
                    }

                    MouseArea {
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
                    radius: 6
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)

                    StyledText {
                        anchors.centerIn: parent
                        text: "Cancel"
                    }

                    MouseArea {
                        anchors.fill: parent
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
            color: Theme.border
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
                height: 36
                radius: 6
                color: mouseArea.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    StyledText {
                        text: modelData.name
                        role: modelData.connected ? "accent" : "fg"
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: modelData.connected
                        text: "connected"
                        role: "green"
                        font.pixelSize: 11
                    }

                    StyledText {
                        visible: !modelData.connected && modelData.security !== WifiSecurityType.Open
                        text: "\uE10B"
                        font.family: Theme.iconFontFamily
                        role: "fgDim"
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
            role: "fgDim"
            Layout.alignment: Qt.AlignHCenter
        }

        // Scan button
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 6
            visible: selectedNetwork === null
            color: mouseAreaScan.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)

            StyledText {
                anchors.centerIn: parent
                text: wifiDevice && wifiDevice.scannerEnabled ? "Scanning..." : "Scan Networks"
                role: "fgDim"
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
