import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    id: root
    spacing: Theme.islandGap
    height: Theme.islandNotificationCompactHeight - 10

    property int count: NotificationService.unreadCount
    property var notification: NotificationService.latestNotification

    Item {
        id: iconOrFallback
        width: 26
        height: 26
        Layout.alignment: Qt.AlignVCenter

        Image {
            id: appIconImage
            anchors.fill: parent
            source: NotificationService.appIconSource(notification)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
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
        Layout.preferredWidth: Theme.islandNotificationCompactTextWidth
        Layout.maximumWidth: Theme.islandNotificationCompactTextWidth
        text: {
            if (!notification)
                return "Notifications";
            
            var summary = (notification.summary || "").trim();
            var body = (notification.body || "").trim();
            var appLabel = (NotificationService.appLabel(notification) || "").trim();
            var appName = (notification.appName || "").trim();
            
            var text = summary;
            
            var isAppName = false;
            if (summary) {
                var sLower = summary.toLowerCase();
                var labelLower = appLabel.toLowerCase();
                var nameLower = appName.toLowerCase();
                if (sLower === labelLower || sLower === nameLower || sLower === "vesktop" || sLower === "discord" || sLower === "element" || sLower === "spotify" || sLower === "cachyos-hello" || sLower === "cachyos hello") {
                    isAppName = true;
                }
            }
            
            if (body && (!summary || isAppName)) {
                text = body;
            } else if (!text) {
                text = body || appLabel;
            }
            
            return text;
        }
        role: "fg"
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
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
