import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../services"
import "../../components"

Rectangle {
    id: root
    height: expanded ? expandedHeight : compactHeight
    width: {
        var mainType = displayedIslandType();
        if (expanded) {
            if (mainType === "workspace")
                return workspaceExpandedWidth();
            if (mainType === "media")
                return Theme.islandMediaWidth;
            if (mainType === "bluetooth")
                return Theme.islandBluetoothWidth;
            if (mainType === "volume")
                return Theme.islandClockWidth;
            if (mainType === "clock")
                return Theme.islandClockWidth;
        }
        if (mainType === "notification")
            return expanded ? Theme.islandNotificationWidth : Theme.islandNotificationCompactWidth;
        if (expanded && mainType === "notification")
            return Theme.islandNotificationWidth;
        return compactRow.implicitWidth + compactPaddingLeft + compactPaddingRight;
    }
    radius: expanded ? Theme.islandExpandedRadius : (displayedIslandType() === "notification" ? Theme.islandNotificationCompactRadius : Theme.islandCompactRadius)
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth
    clip: true
    visible: displayedIslandType() !== ""

    property bool expanded: false
    property bool forceNotificationIsland: false
    property bool forceWorkspaceIsland: false
    property bool autoExpandedByTrack: false
    property int expandedHeight: {
        var type = displayedIslandType();
        if (type === "notification") {
            return Theme.islandNotificationHeight;
        }
        if (type === "workspace")
            return workspaceExpandedHeight();
        if (type === "media")
            return Theme.islandMediaHeight;
        if (type === "clock")
            return Theme.islandClockHeight;
        if (type === "volume")
            return Theme.islandClockHeight;
        return Theme.islandBluetoothHeight;
    }
    property int compactPaddingLeft: 12
    property int compactPaddingRight: 8
    readonly property int compactHeight: displayedIslandType() === "notification" && !expanded ? Theme.islandNotificationCompactHeight : Theme.islandCompactHeight
    readonly property int compactWidth: compactRow.implicitWidth + compactPaddingLeft + compactPaddingRight

    function workspaceExpandedWidth() {
        var fallback = Theme.islandOverviewCellWidth * 5 + Theme.islandOverviewCellGap * 4 + Theme.islandOverviewOuterPadding * 2;
        return parent ? Math.max(fallback, parent.width - Theme.barMargin * 2) : fallback;
    }

    function workspaceMonitorAspect() {
        var monitor = HyprlandSnapshotService.monitors && HyprlandSnapshotService.monitors.length > 0
            ? HyprlandSnapshotService.monitors[0]
            : null;
        var width = monitor && monitor.width ? Number(monitor.width) : 1920;
        var height = monitor && monitor.height ? Number(monitor.height) : 1080;
        return width > 0 ? Math.max(0.22, Math.min(0.58, height / width)) : 0.5625;
    }

    function workspaceOverviewRows() {
        return Math.max(1, Math.ceil((7 + HyprlandSnapshotService.specialWorkspaceNames.length) / 5));
    }

    function workspaceExpandedHeight() {
        var contentWidth = workspaceExpandedWidth() - Theme.islandOverviewOuterPadding * 2;
        var cellWidth = (contentWidth - Theme.islandOverviewCellGap * 4) / 5;
        var cellHeight = Math.max(Theme.islandOverviewCellHeight, Math.round(cellWidth * workspaceMonitorAspect()));
        var rows = workspaceOverviewRows();
        return cellHeight * rows + Theme.islandOverviewCellGap * (rows - 1) + Theme.islandOverviewOuterPadding * 2;
    }

    function displayedIslandType() {
        var island = IslandManager.activeIsland;
        
        if (NotificationService.presentationMode === "transient" && NotificationService.activeTransientNotification !== null)
            return "notification";
            
        if (forceNotificationIsland && NotificationService.unreadCount > 0)
            return "notification";

        if (forceWorkspaceIsland)
            return "workspace";
            
        if (island)
            return island.type;
            
        return "clock";
    }

    function compactModuleType() {
        var island = IslandManager.activeIsland;
        if (forceWorkspaceIsland || (island && island.type === "workspace"))
            return "workspace";
        if (island && island.type === "bluetooth")
            return "bluetooth";
        return "clock";
    }

    function expandDefaultAction() {
        if (MediaService.isPlaying) {
            IslandManager.addIsland("media", 1, {});
            autoExpandedByTrack = false;
            expanded = true;
            return;
        }
        expanded = !expanded;
    }

    function markManualMediaInteraction() {
        if (displayedIslandType() === "media")
            autoExpandedByTrack = false;
    }

    function toggleWorkspaceOverview() {
        if (expanded && displayedIslandType() === "workspace") {
            closeWorkspaceOverview();
            return;
        }
        forceWorkspaceIsland = true;
        expanded = true;
    }

    function closeWorkspaceOverview() {
        expanded = false;
        forceWorkspaceIsland = false;
        IslandManager.removeIsland("workspace");
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.expanded = false
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
        if (!expanded) {
            forceNotificationIsland = false;
            forceWorkspaceIsland = false;
            autoExpandedByTrack = false;
            if (IslandManager.activeIsland && IslandManager.activeIsland.type === "media" && MediaService.isPlaying)
                IslandManager.addIsland("media", 1, {});
        }
    }

    Connections {
        target: IslandManager
        function onActiveIslandChanged() {
            root.expanded = false;
            if (NotificationService.unreadCount === 0)
                root.forceNotificationIsland = false;
            if (IslandManager.activeIsland && IslandManager.activeIsland.type !== "workspace")
                root.forceWorkspaceIsland = false;
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
        id: clockController
        Component.onCompleted: IslandManager.addIsland("clock", 0, {})
    }

    Item {
        id: mediaController
        property string lastTrackKey: MediaService.trackKey

        Timer {
            id: mediaAutoHideTimer
            interval: 3600
            repeat: false
            onTriggered: {
                if (root.expanded && root.displayedIslandType() === "media" && root.autoExpandedByTrack)
                    root.expanded = false;
            }
        }

        function checkMedia() {
            if (MediaService.isPlaying) {
                IslandManager.addIsland("media", 1, {});
            } else {
                IslandManager.removeIsland("media");
            }
        }

        function showTrackChangePreview() {
            if (!MediaService.isPlaying)
                return;
            if (root.displayedIslandType() === "notification" || root.displayedIslandType() === "bluetooth")
                return;
            if (root.expanded && root.displayedIslandType() === "media" && !root.autoExpandedByTrack)
                return;

            IslandManager.addIsland("media", 6, {});
            root.forceNotificationIsland = false;
            root.forceWorkspaceIsland = false;
            root.autoExpandedByTrack = true;
            root.expanded = true;
            mediaAutoHideTimer.restart();
        }

        Connections {
            target: MediaService
            function onHasPlayerChanged() {
                mediaController.checkMedia();
            }
            function onIsPlayingChanged() {
                mediaController.checkMedia();
            }
            function onActivePlayerChanged() {
                mediaController.checkMedia();
            }
            function onTrackKeyChanged() {
                if (mediaController.lastTrackKey === MediaService.trackKey)
                    return;

                var previousTrackKey = mediaController.lastTrackKey;
                mediaController.lastTrackKey = MediaService.trackKey;
                if (previousTrackKey !== "" && MediaService.trackKey !== "")
                    mediaController.showTrackChangePreview();
            }
        }

        Component.onCompleted: checkMedia()
    }

    Item {
        id: workspaceController

        property int lastWorkspaceId: HyprlandSnapshotService.activeWorkspaceId
        property string lastSpecialWorkspaceName: HyprlandSnapshotService.activeSpecialWorkspaceName

        function normalizeWorkspaceId(rawValue) {
            var parsed = parseInt(String(rawValue === undefined || rawValue === null ? "" : rawValue), 10);
            return isNaN(parsed) ? -1 : parsed;
        }

        function showWorkspaceModule(workspaceId, specialName) {
            var cleanSpecialName = String(specialName || "");
            var cleanWorkspaceId = normalizeWorkspaceId(workspaceId);
            if (cleanWorkspaceId > 0)
                HyprlandSnapshotService.activeWorkspaceId = cleanWorkspaceId;
            HyprlandSnapshotService.activeSpecialWorkspaceName = cleanSpecialName;

            IslandManager.addIsland("workspace", 4, {
                workspaceId: cleanWorkspaceId > 0 ? cleanWorkspaceId : HyprlandSnapshotService.activeWorkspaceId,
                specialName: cleanSpecialName
            });
            workspaceHideTimer.restart();
        }

        function handleWorkspaceEvent(event) {
            if (!event || !event.name)
                return;

            if (event.name === "workspacev2" || event.name === "workspace") {
                var workspaceArgs = event.parse(event.name === "workspacev2" ? 2 : 1);
                var workspaceId = normalizeWorkspaceId(workspaceArgs.length > 0 ? workspaceArgs[0] : "");
                if (workspaceId > 0)
                    showWorkspaceModule(workspaceId, "");
                return;
            }

            if (event.name === "focusedmonv2" || event.name === "focusedmon") {
                var monitorArgs = event.parse(2);
                var focusedWorkspaceId = normalizeWorkspaceId(monitorArgs.length > 1 ? monitorArgs[1] : "");
                if (focusedWorkspaceId > 0)
                    showWorkspaceModule(focusedWorkspaceId, "");
                return;
            }

            if (event.name === "activespecial") {
                var specialArgs = event.parse(2);
                var specialName = specialArgs.length > 0 ? String(specialArgs[0]) : "";
                if (specialName !== "")
                    showWorkspaceModule(HyprlandSnapshotService.activeWorkspaceId, specialName);
            }
        }

        Timer {
            id: workspaceHideTimer
            interval: 650
            repeat: false
            onTriggered: {
                if (!root.expanded)
                    IslandManager.removeIsland("workspace");
            }
        }

        Connections {
            target: HyprlandSnapshotService
            function onActiveWorkspaceIdChanged() {
                if (workspaceController.lastWorkspaceId === HyprlandSnapshotService.activeWorkspaceId)
                    return;
                workspaceController.lastWorkspaceId = HyprlandSnapshotService.activeWorkspaceId;
                workspaceController.showWorkspaceModule(HyprlandSnapshotService.activeWorkspaceId, HyprlandSnapshotService.activeSpecialWorkspaceName);
            }
            function onActiveSpecialWorkspaceNameChanged() {
                if (workspaceController.lastSpecialWorkspaceName === HyprlandSnapshotService.activeSpecialWorkspaceName)
                    return;
                workspaceController.lastSpecialWorkspaceName = HyprlandSnapshotService.activeSpecialWorkspaceName;
                if (HyprlandSnapshotService.activeSpecialWorkspaceName !== "")
                    workspaceController.showWorkspaceModule(HyprlandSnapshotService.activeWorkspaceId, HyprlandSnapshotService.activeSpecialWorkspaceName);
            }
        }

        Connections {
            target: Hyprland
            function onRawEvent(event) {
                workspaceController.handleWorkspaceEvent(event);
            }
        }
    }

    Item {
        id: bluetoothController

        Timer {
            id: bluetoothHideTimer
            interval: 3600
            repeat: false
            onTriggered: {
                if (!root.expanded)
                    IslandManager.removeIsland("bluetooth");
            }
        }

        Connections {
            target: BluetoothConnectionService
            function onNewConnection(device) {
                IslandManager.addIsland("bluetooth", 5, { device: device });
                bluetoothHideTimer.restart();
            }
        }
    }

    Item {
        id: volumeController

        Timer {
            id: volumeHideTimer
            interval: 900
            repeat: false
            onTriggered: {
                if (!root.expanded)
                    IslandManager.removeIsland("volume");
            }
        }

        Connections {
            target: VolumeService
            function onVolumeAdjusted() {
                IslandManager.addIsland("volume", 7, {});
                root.forceNotificationIsland = false;
                root.forceWorkspaceIsland = false;
                root.expanded = false;
                volumeHideTimer.restart();
            }
        }
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
        height: root.compactHeight
        visible: !root.expanded || (root.displayedIslandType() !== "notification" && root.displayedIslandType() !== "media" && root.displayedIslandType() !== "workspace")

        Loader {
            id: compactNotificationLoader
            anchors.left: parent.left
            anchors.leftMargin: root.compactPaddingLeft
            anchors.verticalCenter: parent.verticalCenter
            source: "islands/NotificationIsland.qml"
            visible: root.displayedIslandType() === "notification" && !root.expanded
        }

        RowLayout {
            id: compactRow
            z: 1
            anchors.left: parent.left
            anchors.leftMargin: root.compactPaddingLeft
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.islandGap
            visible: root.displayedIslandType() !== "notification" || root.expanded

            StyledText {
                id: compactVolumeAmount
                Layout.alignment: Qt.AlignVCenter
                text: VolumeService.displayText
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                visible: root.displayedIslandType() === "volume"
            }

            RoundedImage {
                id: compactAlbumArt
                Layout.preferredWidth: Theme.islandCompactHeight - 6
                Layout.preferredHeight: Theme.islandCompactHeight - 6
                maskSource: "file:///home/reazn/.config/quickshell/assets/mask_compact.png"
                source: MediaService.artUrl
                visible: MediaService.isPlaying && root.displayedIslandType() !== "volume"

                Icon {
                    anchors.centerIn: parent
                    text: "\uE122"
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.bg
                    visible: compactAlbumArt.status !== Image.Ready
                }
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Math.max(Theme.islandCompactModuleMinWidth, mainLoader.implicitWidth)
                Layout.preferredHeight: Theme.islandCompactHeight

                Loader {
                    id: mainLoader
                    anchors.centerIn: parent
                    source: {
                        var type = root.compactModuleType();
                        if (!type)
                            return "";
                        type = type.charAt(0).toUpperCase() + type.slice(1);
                        return "islands/" + type + "Island.qml";
                    }
                }
            }

            DonutChart {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                value: root.displayedIslandType() === "volume" ? VolumeService.displayPercent : MediaService.progress * 100
                icon: ""
                fgColor: Theme.blue
                lineWidth: 3
                visible: root.displayedIslandType() === "volume" || MediaService.isPlaying
            }
        }

        MouseArea {
            z: -1
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.toggleWorkspaceOverview();
                    return;
                }
                if (root.displayedIslandType() === "notification") {
                    root.expanded = true;
                    return;
                }
                root.expandDefaultAction();
            }
        }
    }

    // ========== EXPANDED CONTENT ==========
    Loader {
        id: expandedLoader
        anchors.top: parent.top
        anchors.topMargin: (root.expanded && (root.displayedIslandType() === "notification" || root.displayedIslandType() === "media" || root.displayedIslandType() === "workspace")) ? 0 : Theme.islandCompactHeight
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height - anchors.topMargin
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
        onLoaded: {
            if (item && item.closeRequested)
                item.closeRequested.connect(root.closeWorkspaceOverview);
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            propagateComposedEvents: true
            onPressed: mouse => {
                root.markManualMediaInteraction();
                mouse.accepted = false;
            }
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
