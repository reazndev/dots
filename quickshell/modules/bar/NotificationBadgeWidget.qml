import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

Rectangle {
    id: root
    height: 16
    width: Math.max(16, countText.implicitWidth + 8)
    radius: height / 2
    color: Theme.accent
    border.color: Theme.border
    border.width: 0

    property int count: NotificationService.unreadCount
    property bool visibleBadge: count > 0
                           && IslandManager.activeIsland
                           && IslandManager.activeIsland.type !== "notification"
                           && NotificationService.presentationMode !== "transient"
    signal activated()

    visible: visibleBadge

    StyledText {
        id: countText
        anchors.centerIn: parent
        text: root.count > 9 ? "9+" : root.count.toString()
        color: Theme.bg
        font.bold: true
        font.pixelSize: 10
        font.family: Theme.fontFamilyUi
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
