import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../services"
import "../../components"

Rectangle {
    id: root
    height: expanded ? expandedHeight : 28
    width: {
        var mainType = displayedIslandType();
        if (expanded && mainType === "notification") {
            if (NotificationService.unreadCount > 0) {
                return 380;
            }
        }
        return mainLoader.implicitWidth + compactPaddingLeft + compactPaddingRight;
    }
    radius: 14
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth
    clip: true
    visible: displayedIslandType() !== ""

    property bool expanded: false
    property bool forceNotificationIsland: false
    property int expandedHeight: {
        if (displayedIslandType() === "notification") {
            return 300;
        }
        return 156;
    }
    property int compactPaddingLeft: 12
    property int compactPaddingRight: 8

    function displayedIslandType() {
        var island = IslandManager.activeIsland;
        if (forceNotificationIsland && NotificationService.unreadCount > 0)
            return "notification";
        if (NotificationService.presentationMode === "transient" && island && island.type !== "notification")
            return "notification";
        if (island)
            return island.type;
        if (NotificationService.unreadCount > 0)
            return "notification";
        return "";
    }

    function showNotificationBadge() {
        var island = IslandManager.activeIsland;
        if (!island || NotificationService.unreadCount === 0)
            return false;
        return displayedIslandType() !== "notification";
    }

    Behavior on height {
        NumberAnimation {
            duration: 120
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.23, 1.0, 0.32, 1.0]
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: 120
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.23, 1.0, 0.32, 1.0]
        }
    }

    onVisibleChanged: if (!visible)
        expanded = false

    onExpandedChanged: {
        if (!expanded)
            forceNotificationIsland = false;
    }

    Connections {
        target: IslandManager
        function onActiveIslandChanged() {
            root.expanded = false;
            if (NotificationService.unreadCount === 0)
                root.forceNotificationIsland = false;
        }
    }

    Connections {
        target: NotificationService.trackedNotifications
        function onValuesChanged() {
            if (NotificationService.unreadCount === 0) {
                root.forceNotificationIsland = false;
                root.expanded = false;
            }
        }
    }

    // ========== CONTROLLERS ==========
    Item {
        id: mediaController
        property var player: findBestPlayer()

        function findBestPlayer() {
            var players = Mpris.players.values;
            for (var i = 0; i < players.length; i++) {
                if (players[i] && players[i].metadata && players[i].metadata["xesam:title"]) {
                    return players[i];
                }
            }
            return null;
        }

        onPlayerChanged: checkMedia()

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                var best = mediaController.findBestPlayer();
                if (best !== mediaController.player) {
                    mediaController.player = best;
                }
            }
        }

        function checkMedia() {
            if (player && player.metadata && player.metadata["xesam:title"]) {
                IslandManager.addIsland("media", 1, {
                    player: player
                });
            } else {
                IslandManager.removeIsland("media");
            }
        }

        Connections {
            target: mediaController.player || null
            function onMetadataChanged() {
                mediaController.checkMedia();
            }
            function onPlaybackStateChanged() {
                mediaController.checkMedia();
            }
        }

        Connections {
            target: Mpris.players
            function onValuesChanged() {
                mediaController.player = mediaController.findBestPlayer();
                mediaController.checkMedia();
            }
        }

        Component.onCompleted: checkMedia()
    }

    // Notification controller
    Item {
        id: notificationController
        Component.onCompleted: {
            // Force instantiation of the notification service on startup
            var _ = NotificationService;
        }
    }
    // Message controller (stub)
    Item {
        id: messageController
    }
    // LocalSend controller (stub)
    Item {
        id: localsendController
    }

    // ========== COMPACT CONTENT ==========
    Item {
        id: compactArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 28

        Item {
            id: mainArea
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: mainLoader.implicitWidth
            height: parent.height

            Loader {
                id: mainLoader
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: root.compactPaddingLeft
                source: {
                    var type = root.displayedIslandType();
                    if (!type)
                        return "";
                    type = type.charAt(0).toUpperCase() + type.slice(1);
                    return "islands/" + type + "Island.qml";
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }
    }

    // ========== EXPANDED CONTENT ==========
    Loader {
        id: expandedLoader
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height - 28
        opacity: root.expanded ? 1 : 0
        enabled: root.expanded
        visible: root.expanded || opacity > 0
        source: {
            var type = root.displayedIslandType();
            if (!type)
                return "";
            type = type.charAt(0).toUpperCase() + type.slice(1);
            return "islands/" + type + "IslandExpanded.qml";
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 80
                easing.type: Easing.Bezier
                easing.bezierCurve: [0.23, 1.0, 0.32, 1.0]
            }
        }
    }
}
