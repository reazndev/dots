import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    id: root
    spacing: 8

    property int count: NotificationService.unreadCount
    property var notification: NotificationService.latestNotification

    Item {
        id: iconOrFallback
        width: 22
        height: 22
        Layout.alignment: Qt.AlignVCenter

        Image {
            id: appIconImage
            anchors.fill: parent
            source: NotificationService.appIconSource(notification)
            fillMode: Image.PreserveAspectFit
            cache: false
            visible: status === Image.Ready
        }

        StyledText {
            anchors.centerIn: parent
            text: NotificationService.appLabel(notification)
            role: "accent"
            font.pixelSize: 9
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: appIconImage.status !== Image.Ready
        }
    }

    StyledText {
        text: {
            if (!notification)
                return "Notifications";
            var text = notification.summary || notification.body || NotificationService.appLabel(notification);
            if (text.length > 42)
                return text.substring(0, 42) + "…";
            return text;
        }
        role: "fg"
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
    }

    // Number badge on the right when there are multiple notifications
    Rectangle {
        visible: count > 1
        height: 16
        width: Math.max(16, countText.implicitWidth + 8)
        radius: 8
        color: Theme.accent
        Layout.alignment: Qt.AlignVCenter

        StyledText {
            id: countText
            anchors.centerIn: parent
            text: count.toString()
            color: Theme.bg
            font.bold: true
            font.pixelSize: 10
            font.family: Theme.fontFamilyUi
        }
    }
}
