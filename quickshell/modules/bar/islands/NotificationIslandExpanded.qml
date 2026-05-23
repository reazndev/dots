import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

ColumnLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        StyledText {
            text: "Notifications"
            font.pixelSize: Theme.fontSizeLarge
            font.bold: true
        }
        
        Item {
            Layout.fillWidth: true
        }
        
        // Clear All action
        StyledText {
            text: "Clear All"
            role: "fgDim"
            font.pixelSize: 11
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var list = NotificationService.trackedNotifications.values.slice();
                    for (var i = list.length - 1; i >= 0; i--) {
                        var notif = list[i];
                        if (notif) {
                            notif.tracked = false;
                            try {
                                if (typeof notif.dismiss === "function") {
                                    notif.dismiss();
                                }
                            } catch (e) {
                                // Ignore already closed/destroyed errors
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.border
    }

    // Scrollable Notifications List
    ListView {
        id: notificationList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 6
        model: NotificationService.trackedNotifications.values
        
        delegate: Rectangle {
            id: delegateRoot
            width: notificationList.width
            height: contentLayout.implicitHeight + 12
            color: "transparent"
            radius: Theme.radius - 2
            border.width: 1
            border.color: Theme.border
            
            required property var modelData

            // Smooth fade-out and slide-up transition when dismissed
            ListView.onRemove: {
                removeAnimation.start();
            }

            SequentialAnimation {
                id: removeAnimation
                PropertyAction { target: delegateRoot; property: "ListView.delayRemove"; value: true }
                ParallelAnimation {
                    NumberAnimation { target: delegateRoot; property: "opacity"; to: 0; duration: 150 }
                    NumberAnimation { target: delegateRoot; property: "height"; to: 0; duration: 150 }
                }
                PropertyAction { target: delegateRoot; property: "ListView.delayRemove"; value: false }
            }

            RowLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                // Notification Icon / Fallback
                Item {
                    id: notificationIconBox
                    width: 32
                    height: 32
                    Layout.alignment: Qt.AlignTop
                    
                    Image {
                        id: notificationAppIcon
                        anchors.fill: parent
                        source: NotificationService.appIconSource(modelData)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        cache: false
                        visible: status === Image.Ready
                    }
                    
                    StyledText {
                        anchors.centerIn: parent
                        text: NotificationService.appLabel(modelData)
                        role: "accent"
                        font.pixelSize: 10
                        font.bold: true
                        visible: notificationAppIcon.status !== Image.Ready
                    }
                }

                // Text Content
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1



                    StyledText {
                        text: modelData.summary || ""
                        font.bold: true
                        role: "fg"
                        font.pixelSize: Theme.fontSize
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: modelData.body || ""
                        role: "fgDim"
                        font.pixelSize: Theme.fontSize - 1
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }
                }

                // Interactive Dismiss Button
                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: "transparent"
                    Layout.alignment: Qt.AlignTop
                    
                    StyledText {
                        anchors.centerIn: parent
                        text: "✕"
                        role: "fgDim"
                        font.pixelSize: 9
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: parent.color = Theme.border
                        onExited: parent.color = "transparent"
                        onClicked: {
                            if (modelData) {
                                modelData.tracked = false;
                                try {
                                    if (typeof modelData.dismiss === "function") {
                                        modelData.dismiss();
                                    }
                                } catch (e) {
                                    // Ignore already closed/destroyed errors
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty State Placeholder
        StyledText {
            anchors.centerIn: parent
            text: "No notifications"
            role: "fgDim"
            visible: notificationList.count === 0
        }
    }
}
