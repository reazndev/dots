import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

Rectangle {
    id: root
    height: 28
    width: Math.max(28, countText.implicitWidth + 16)
    radius: height / 2
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth

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
        color: Theme.accent
        font.bold: true
        font.pixelSize: 11
        font.family: Theme.fontFamilyUi
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
