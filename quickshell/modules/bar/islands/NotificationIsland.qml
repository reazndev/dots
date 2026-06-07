import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    id: root
    spacing: Theme.islandGap
    height: Theme.islandNotificationCompactHeight - 12
    clip: true

    property int count: NotificationService.unreadCount
    property var notification: NotificationService.latestNotification

    function compactText(value) {
        return String(value || "")
            .replace(/<[^>]*>/g, " ")
            .replace(/\s+/g, " ")
            .trim();
    }

    function summaryText() {
        if (!notification)
            return "Notifications";

        var summary = compactText(notification.summary);
        var appLabel = compactText(NotificationService.appLabel(notification));
        var appName = compactText(notification.appName);
        var body = compactText(notification.body);

        if (!summary)
            return body || "Notification";

        var sLower = summary.toLowerCase();
        if (sLower === appLabel.toLowerCase() || sLower === appName.toLowerCase())
            return body || "Notification";

        return summary;
    }

    function bodyText() {
        if (!notification)
            return "";

        var summary = compactText(notification.summary);
        var body = compactText(notification.body);
        var appLabel = compactText(NotificationService.appLabel(notification));
        var appName = compactText(notification.appName);

        if (!body)
            return "";

        var sLower = summary.toLowerCase();
        if (!summary || sLower === appLabel.toLowerCase() || sLower === appName.toLowerCase())
            return "";

        return body;
    }

    Item {
        id: iconOrFallback
        width: 30
        height: 30
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: width
        Layout.preferredHeight: height

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

    ColumnLayout {
        Layout.preferredWidth: count > 1 ? Theme.islandNotificationCompactTextWidth : Theme.islandNotificationCompactTextWidth + 38
        Layout.maximumWidth: Layout.preferredWidth
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: Theme.fontSize * 2 + 6
        spacing: 1

        StyledText {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.fontSize + 1
            text: root.summaryText()
            role: "fg"
            font.bold: true
            font.family: Theme.fontFamilyUi
            font.pixelSize: Theme.fontSize
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        StyledText {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.fontSize + 1
            text: root.bodyText()
            role: "fgDim"
            font.family: Theme.fontFamilyUi
            font.pixelSize: Theme.fontSize - 1
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            visible: text !== ""
        }
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
