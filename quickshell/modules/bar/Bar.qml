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
    property var usagePopup: null
    property var nightlightPopup: null
    property alias islandExpanded: island.expanded

    function toggleNotifications() {
        if (island.expanded && island.displayedIslandType() === "notification") {
            island.expanded = false;
        } else {
            island.forceNotificationIsland = true;
            island.expanded = true;
        }
    }

    extraHeight: island.visible ? Math.max(0, island.expandedHeight - (Theme.barHeight + 28) / 2) : 0
    islandMaskX: island.x
    islandMaskY: island.y
    islandMaskWidth: island.width
    islandMaskHeight: island.visible ? island.height : 0

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
                if (barPanel.usagePopup) barPanel.usagePopup.visible = false;
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
            anchors.topMargin: (Theme.barHeight - 28) / 2
            anchors.horizontalCenter: parent.horizontalCenter
        }

        NotificationBadgeWidget {
            id: notificationBadge
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 + island.compactWidth / 2 + 6
            visible: notificationBadge.visibleBadge && !(island.expanded && island.displayedIslandType() === "notification")
            onActivated: {
                island.forceNotificationIsland = true;
                island.expanded = true;
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            SystemWidget {
                Layout.alignment: Qt.AlignVCenter
                popup: barPanel.systemPopup
            }

            UsageWidget {
                Layout.alignment: Qt.AlignVCenter
                popup: barPanel.usagePopup
            }

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

            ClockWidget {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Theme.fontSize + 4
            }
        }
    }
}
