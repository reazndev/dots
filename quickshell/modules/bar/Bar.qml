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
            anchors.verticalCenter: island.verticalCenter
            anchors.left: island.right
            anchors.leftMargin: 6
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
            ClockWidget {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Theme.fontSize + 4
            }
        }
    }
}
