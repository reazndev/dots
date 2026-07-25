import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: Math.round(Theme.islandPadding * 0.78)
    spacing: Math.round(Theme.islandGap * 0.72)

    function subtitle() {
        if (LocalSendService.mode === "incoming" && LocalSendService.incomingRequest)
            return LocalSendService.incomingRequest.kind === "clipboard"
                ? "Clipboard text · " + LocalSendService.formatBytes(LocalSendService.incomingRequest.total_size)
                : LocalSendService.incomingRequest.file_count + " files · " + LocalSendService.formatBytes(LocalSendService.incomingRequest.total_size);
        if (LocalSendService.hasFiles)
            return LocalSendService.selectedFiles.length + " files · " + LocalSendService.formatBytes(LocalSendService.selectedTotalSize);
        if (LocalSendService.mode === "error")
            return LocalSendService.errorText;
        if (LocalSendService.mode === "complete")
            return LocalSendService.completionText;
        return "Drop files here to send";
    }

    function title() {
        switch (LocalSendService.mode) {
        case "incoming":
            return LocalSendService.incomingRequest ? "Incoming from " + LocalSendService.incomingRequest.sender : "Incoming transfer";
        case "scanning":
            return "Finding nearby devices";
        case "devices":
            return "Send with LocalSend";
        case "sending":
            return "Sending";
        case "receiving":
            return "Receiving";
        case "complete":
            return "Transfer complete";
        case "error":
            return "LocalSend needs attention";
        default:
            return "LocalSend";
        }
    }

    function showFileList() {
        return LocalSendService.hasFiles && LocalSendService.mode !== "sending" && LocalSendService.mode !== "receiving" && LocalSendService.mode !== "incoming";
    }

    function showDeviceList() {
        return LocalSendService.mode === "devices";
    }

    function showProgress() {
        return LocalSendService.mode === "sending" || LocalSendService.mode === "receiving";
    }

    function showDropPanel() {
        return LocalSendService.mode === "drop" || LocalSendService.mode === "scanning" || LocalSendService.mode === "incoming" || LocalSendService.mode === "error" || LocalSendService.mode === "complete";
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(Theme.islandGap * 0.8)

        Rectangle {
            Layout.preferredWidth: Theme.islandButtonSize
            Layout.preferredHeight: Theme.islandButtonSize
            radius: width / 2
            color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, Theme.bgOpacity)

            Icon {
                anchors.centerIn: parent
                text: "\uE152"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.bg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.max(1, Math.round(Theme.islandGap / 3))

            StyledText {
                Layout.fillWidth: true
                text: root.title()
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.subtitle()
                role: LocalSendService.mode === "error" ? "yellow" : "fgDim"
                font.family: Theme.fontFamilyUi
                elide: Text.ElideRight
            }
        }

        StyledText {
            text: LocalSendService.available ? LocalSendService.status : "offline"
            role: LocalSendService.available ? "green" : "yellow"
            font.family: Theme.fontFamilyUi
            font.pixelSize: Theme.fontSize - 1
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.showDropPanel() ? Theme.islandLocalSendDropHeight : 0
        radius: Theme.radius
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, LocalSendService.mode === "drop" || LocalSendService.mode === "scanning" ? 0.10 : 0.06)
        border.color: LocalSendService.mode === "incoming" ? Theme.blue : Theme.border
        border.width: root.showDropPanel() ? Theme.borderWidth : 0
        visible: root.showDropPanel()

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Theme.islandPadding * 2
            spacing: Math.round(Theme.islandGap / 3)

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: LocalSendService.mode === "incoming" && LocalSendService.incomingRequest && LocalSendService.incomingRequest.kind === "clipboard" ? "Copy text to clipboard?" :
                      LocalSendService.mode === "incoming" ? root.title() :
                      LocalSendService.mode === "scanning" ? "Scanning your local network" :
                      LocalSendService.mode === "error" ? LocalSendService.errorText :
                      LocalSendService.mode === "complete" ? LocalSendService.completionText :
                      "Drop files onto the island"
                role: LocalSendService.mode === "error" ? "yellow" : "fg"
                font.family: Theme.fontFamilyUi
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: LocalSendService.mode === "scanning" ? "Waiting for LocalSend devices" :
                      LocalSendService.mode === "incoming" && LocalSendService.incomingRequest && LocalSendService.incomingRequest.kind === "clipboard" ? "Accept to place it in your clipboard" :
                      LocalSendService.mode === "incoming" && LocalSendService.incomingRequest ? LocalSendService.incomingRequest.file_count + " files will save to Downloads" :
                      LocalSendService.hasFiles ? root.subtitle() :
                      "Files are sent directly over your LAN"
                role: "fgDim"
                font.family: Theme.fontFamilyUi
                elide: Text.ElideRight
            }
        }
    }

    Flickable {
        id: scrollArea
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: scrollContent.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        visible: root.showFileList() || root.showProgress()

        ColumnLayout {
            id: scrollContent
            width: scrollArea.width
            spacing: Math.round(Theme.islandGap / 3)

            Repeater {
                model: root.showFileList() ? LocalSendService.selectedFiles : []

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.islandButtonSize
                    radius: height / 2
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                    border.color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.55)
                    border.width: Theme.borderWidth

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.islandGap
                        anchors.rightMargin: Math.round(Theme.islandGap / 2)
                        spacing: Math.round(Theme.islandGap / 2)

                        Icon {
                            text: "\uE152"
                            font.pixelSize: Theme.fontSize
                            color: Theme.fgDim
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name
                            role: "fg"
                            font.family: Theme.fontFamilyUi
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: LocalSendService.formatBytes(modelData.size)
                            role: "fgDim"
                            font.family: Theme.fontFamilyUi
                            font.pixelSize: Theme.fontSize - 1
                        }

                        Rectangle {
                            Layout.preferredWidth: Theme.islandButtonSize - 8
                            Layout.preferredHeight: Theme.islandButtonSize - 8
                            radius: width / 2
                            color: removeArea.pressed ? Theme.red : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

                            Icon {
                                anchors.centerIn: parent
                                text: "\uE084"
                                font.pixelSize: Theme.fontSize
                                color: Theme.fg
                            }

                            MouseArea {
                                id: removeArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LocalSendService.removeFile(modelData.path)
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(Theme.islandGap / 2)
                visible: root.showProgress()

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: LocalSendService.activeTransfer ? LocalSendService.activeTransfer.file_name : "Transfer"
                        role: "fg"
                        font.family: Theme.fontFamilyUi
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: Math.round(LocalSendService.progress) + "%"
                        role: "fg"
                        font.family: Theme.fontFamilyUi
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(Theme.borderWidth * 6, Math.round(Theme.islandGap * 0.8))
                    radius: height / 2
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.min(1, LocalSendService.progress / 100)
                        radius: parent.radius
                        color: Theme.blue

                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.islandAnimationDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !(root.showFileList() || root.showProgress())
    }

    Flickable {
        id: fixedDeviceArea
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(0, Math.min(LocalSendService.devices.length, 2) * (Theme.islandLocalSendDeviceHeight + Math.round(Theme.islandGap / 3)) - Math.round(Theme.islandGap / 3))
        clip: true
        contentWidth: width
        contentHeight: fixedDeviceContent.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        visible: root.showDeviceList()

        ColumnLayout {
            id: fixedDeviceContent
            width: fixedDeviceArea.width
            spacing: Math.round(Theme.islandGap / 3)

            Repeater {
                model: LocalSendService.devices

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.islandLocalSendDeviceHeight
                    radius: Theme.radius
                    color: deviceArea.pressed ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.16) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07)
                    border.color: Theme.border
                    border.width: Theme.borderWidth

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.islandGap
                        anchors.rightMargin: Theme.islandGap
                        spacing: Theme.islandGap

                        Icon {
                            text: modelData.deviceType === "mobile" ? "\uE1DB" : "\uE08E"
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.blue
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.alias || modelData.address
                                role: "fg"
                                font.family: Theme.fontFamilyUi
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.protocol + "://" + modelData.address + ":" + modelData.port
                                role: "fgDim"
                                font.family: Theme.fontFamilyUi
                                font.pixelSize: Theme.fontSize - 1
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: Theme.islandButtonSize * 2
                            Layout.preferredHeight: Theme.islandButtonSize - 4
                            radius: height / 2
                            color: sendArea.pressed ? Theme.fgDim : Theme.blue

                            StyledText {
                                anchors.centerIn: parent
                                text: "Send"
                                role: "fg"
                                font.family: Theme.fontFamilyUi
                                font.bold: true
                                color: Theme.bg
                            }
                        }
                    }

                    MouseArea {
                        id: deviceArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: LocalSendService.sendToDevice(modelData.id)
                    }

                    MouseArea {
                        id: sendArea
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: Theme.islandGap
                        width: Theme.islandButtonSize * 2
                        height: Theme.islandButtonSize - 4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: LocalSendService.sendToDevice(modelData.id)
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.islandGap
        visible: (LocalSendService.mode === "drop" || LocalSendService.mode === "devices" || LocalSendService.mode === "scanning") && LocalSendService.hasFiles

        Rectangle {
            Layout.preferredWidth: Theme.islandButtonSize * 3
            Layout.preferredHeight: Theme.islandButtonSize
            radius: height / 2
            color: scanArea.pressed ? Theme.fgDim : Theme.blue
            visible: LocalSendService.mode !== "scanning"

            StyledText {
                anchors.centerIn: parent
                text: "Scan"
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.bold: true
                color: Theme.bg
            }

            MouseArea {
                id: scanArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: LocalSendService.startScan()
            }
        }

        Rectangle {
            Layout.preferredWidth: Theme.islandButtonSize * 3
            Layout.preferredHeight: Theme.islandButtonSize
            radius: height / 2
            color: clearArea.pressed ? Theme.red : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
            border.color: Theme.border
            border.width: Theme.borderWidth

            StyledText {
                anchors.centerIn: parent
                text: "Clear"
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.bold: true
            }

            MouseArea {
                id: clearArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: LocalSendService.clear()
            }
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Theme.islandButtonSize * 3
        Layout.preferredHeight: Theme.islandButtonSize
        radius: height / 2
        color: stopArea.pressed ? Theme.red : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
        border.color: Theme.border
        border.width: Theme.borderWidth
        visible: root.showProgress()

        StyledText {
            anchors.centerIn: parent
            text: "Stop"
            role: "fg"
            font.family: Theme.fontFamilyUi
            font.bold: true
        }

        MouseArea {
            id: stopArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: LocalSendService.cancelTransfer()
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.islandGap
        visible: LocalSendService.mode === "incoming"

        Rectangle {
            Layout.preferredWidth: Theme.islandButtonSize * 3
            Layout.preferredHeight: Theme.islandButtonSize
            radius: height / 2
            color: rejectArea.pressed ? Theme.red : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
            border.color: Theme.border
            border.width: Theme.borderWidth

            StyledText {
                anchors.centerIn: parent
                text: "Reject"
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.bold: true
            }

            MouseArea {
                id: rejectArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (LocalSendService.incomingRequest) LocalSendService.rejectIncoming(LocalSendService.incomingRequest.id)
            }
        }

        Rectangle {
            Layout.preferredWidth: Theme.islandButtonSize * 3
            Layout.preferredHeight: Theme.islandButtonSize
            radius: height / 2
            color: acceptArea.pressed ? Theme.fgDim : Theme.blue

            StyledText {
                anchors.centerIn: parent
                text: "Accept"
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.bold: true
                color: Theme.bg
            }

            MouseArea {
                id: acceptArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (LocalSendService.incomingRequest) LocalSendService.acceptIncoming(LocalSendService.incomingRequest.id)
            }
        }
    }
}
