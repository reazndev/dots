import QtQuick
import QtQuick.Layouts
import "./"
import "../../components"
import "../../services"

PanelRoot {
    id: barPanel

    property var networkPopup: null
    property var bluetoothPopup: null
    property var systemPopup: null
    property var nightlightPopup: null
    property alias islandExpanded: island.expanded
    readonly property int reservedIslandHeight: Math.max(
        Theme.islandNotificationHeight,
        Theme.islandMediaHeight,
        Theme.islandBluetoothHeight,
        Theme.islandClockHeight,
        island.workspaceExpandedHeight()
    )

    function toggleNotifications() {
        if (NotificationService.unreadCount === 0 && NotificationService.activeTransientNotification === null) {
            island.expanded = false;
            island.forceNotificationIsland = false;
            return;
        }

        if (island.expanded && island.displayedIslandType() === "notification") {
            island.expanded = false;
        } else {
            island.forceNotificationIsland = true;
            island.expanded = true;
        }
    }

    function toggleWorkspaceOverview() {
        island.toggleWorkspaceOverview();
    }

    extraHeight: Math.max(0, island.y + reservedIslandHeight - Theme.barHeight + 4)
    islandMaskX: island.x
    islandMaskY: island.y
    islandMaskWidth: island.width
    islandMaskHeight: island.visible ? island.height + 4 : 0

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: Theme.barHeight

        MouseArea {
            anchors.fill: parent
            onClicked: {
                island.expanded = false;
                if (barPanel.networkPopup) barPanel.networkPopup.visible = false;
                if (barPanel.bluetoothPopup) barPanel.bluetoothPopup.visible = false;
                if (barPanel.systemPopup) barPanel.systemPopup.visible = false;
                if (barPanel.nightlightPopup) barPanel.nightlightPopup.visible = false;
            }
        }

        WorkspaceWidget {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        DynamicIslandWidget {
            id: island
            anchors.top: parent.top
            anchors.topMargin: (Theme.barHeight - Theme.islandCompactHeight) / 2
            anchors.horizontalCenter: parent.horizontalCenter
        }

        NotificationBadgeWidget {
            id: notificationBadge
            anchors.verticalCenter: parent.verticalCenter
            x: island.x + island.width + 6
            visible: notificationBadge.visibleBadge && !island.expanded && island.displayedIslandType() !== "notification"
            onActivated: {
                island.forceNotificationIsland = true;
                island.expanded = true;
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            NetworkWidget {
                id: networkWidget
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Theme.fontSize + 4
                popup: barPanel.networkPopup
            }
            BluetoothWidget {
                id: bluetoothWidget
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Theme.fontSize + 4
                popup: barPanel.bluetoothPopup
            }
            NightlightWidget {
                id: nightlightWidget
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Theme.fontSize + 4
                popup: barPanel.nightlightPopup
            }

            SystemWidget {
                Layout.alignment: Qt.AlignVCenter
                popup: barPanel.systemPopup
            }

        }
    }
}
