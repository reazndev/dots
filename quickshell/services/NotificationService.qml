pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

Item {
    id: root

    // Expose the tracked notifications list and server instance
    property alias trackedNotifications: server.trackedNotifications
    property alias server: server
    readonly property int unreadCount: trackedNotifications.values.length
    readonly property var latestNotification: unreadCount > 0 ? trackedNotifications.values[unreadCount - 1] : null
    property string presentationMode: "none" // none, sticky, transient
    property int transientDuration: 10000

    Timer {
        id: transientTimer
        interval: root.transientDuration
        repeat: false
        onTriggered: {
            root.presentationMode = root.unreadCount > 0 ? "sticky" : "none";
        }
    }

    function appIconSource(notification) {
        if (!notification || !notification.appIcon)
            return "";

        var icon = String(notification.appIcon);
        if (icon.indexOf("/") === 0 || icon.indexOf("file://") === 0 || icon.indexOf("qrc:/") === 0)
            return icon;

        return "image://theme/" + icon;
    }

    function appLabel(notification) {
        if (!notification || !notification.appName)
            return "Notification";
        return notification.appName;
    }

    function receiveNotification(notification) {
        if (!notification)
            return;

        notification.tracked = true;

        if (IslandManager.activeIsland && IslandManager.activeIsland.type !== "notification") {
            root.presentationMode = "transient";
            transientTimer.restart();
        } else {
            root.presentationMode = "sticky";
            transientTimer.stop();
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        imageSupported: true
        
        onNotification: (n) => {
            console.log("New notification received: " + n.summary + " | " + n.body);
            root.receiveNotification(n);
        }
    }

    Connections {
        target: server.trackedNotifications
        function onValuesChanged() {
            if (server.trackedNotifications.values.length === 0) {
                root.presentationMode = "none";
                transientTimer.stop();
            }
        }
    }
}
