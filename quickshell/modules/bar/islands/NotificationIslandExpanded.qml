import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: Theme.islandPadding
    spacing: Theme.islandGap

    function dismissNotification(notification) {
        if (!notification)
            return;

        notification.tracked = false;
        try {
            if (typeof notification.dismiss === "function")
                notification.dismiss();
        } catch (e) {
            // Notification may already be closed by the source app.
        }
    }

    function clearAll() {
        var list = NotificationService.trackedNotifications.values.slice();
        for (var i = list.length - 1; i >= 0; i--)
            dismissNotification(list[i]);
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.islandGap

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            StyledText {
                text: "Notifications"
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            StyledText {
                text: NotificationService.unreadCount + (NotificationService.unreadCount === 1 ? " item" : " items")
                role: "fgDim"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSize - 1
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredWidth: Math.max(74, clearText.implicitWidth + Theme.islandGap * 2)
            Layout.preferredHeight: 26
            radius: height / 2
            color: clearArea.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.13) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07)
            border.width: Theme.borderWidth
            border.color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.72)
            visible: NotificationService.unreadCount > 0

            Behavior on color { ColorAnimation { duration: Theme.islandAnimationDuration } }

            StyledText {
                id: clearText
                anchors.centerIn: parent
                text: "Clear all"
                role: "fgDim"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSize - 1
                font.bold: true
            }

            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearAll()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.55)
    }

    ListView {
        id: notificationList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Math.round(Theme.islandGap * 0.7)
        model: NotificationService.trackedNotifications.values

        delegate: Rectangle {
            id: delegateRoot
            required property var modelData

            width: notificationList.width
            height: Math.max(Theme.islandNotificationRowMinHeight, contentLayout.implicitHeight + Theme.islandGap * 1.4)
            radius: Theme.radius + 4
            color: rowArea.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.055)
            border.width: Theme.borderWidth
            border.color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, rowArea.containsMouse ? 0.95 : 0.55)
            clip: true

            Behavior on color { ColorAnimation { duration: Theme.islandAnimationDuration } }
            Behavior on border.color { ColorAnimation { duration: Theme.islandAnimationDuration } }

            ListView.onRemove: removeAnimation.start()

            SequentialAnimation {
                id: removeAnimation
                PropertyAction {
                    target: delegateRoot
                    property: "ListView.delayRemove"
                    value: true
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: delegateRoot
                        property: "opacity"
                        to: 0
                        duration: 150
                    }
                    NumberAnimation {
                        target: delegateRoot
                        property: "height"
                        to: 0
                        duration: 150
                    }
                }
                PropertyAction {
                    target: delegateRoot
                    property: "ListView.delayRemove"
                    value: false
                }
            }

            RowLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: Math.round(Theme.islandGap * 0.8)
                spacing: Theme.islandGap

                Item {
                    Layout.preferredWidth: Theme.islandNotificationIconSize
                    Layout.preferredHeight: Theme.islandNotificationIconSize
                    Layout.alignment: Qt.AlignTop

                    Image {
                        id: notificationAppIcon
                        anchors.fill: parent
                        anchors.margins: 4
                        source: NotificationService.appIconSource(modelData)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        cache: false
                        visible: status === Image.Ready
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: NotificationService.appLabel(modelData).slice(0, 2).toUpperCase()
                        role: "accent"
                        font.family: Theme.fontFamilyUi
                        font.pixelSize: Theme.fontSize - 2
                        font.bold: true
                        visible: notificationAppIcon.status !== Image.Ready
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.summary || NotificationService.appLabel(modelData)
                        role: "fg"
                        font.family: Theme.fontFamilyUi
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.body || ""
                        role: "fgDim"
                        font.family: Theme.fontFamilyUi
                        font.pixelSize: Theme.fontSize - 1
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignTop
                    radius: width / 2
                    color: dismissArea.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.14) : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.islandAnimationDuration } }

                    StyledText {
                        anchors.centerIn: parent
                        text: "x"
                        role: "fgDim"
                        font.family: Theme.fontFamilyUi
                        font.pixelSize: Theme.fontSize - 1
                        font.bold: true
                    }

                    MouseArea {
                        id: dismissArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissNotification(modelData)
                    }
                }
            }

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: "No notifications"
            role: "fgDim"
            font.family: Theme.fontFamilyUi
            visible: notificationList.count === 0
        }
    }
}
