import QtQuick
import "../../services"
import "../../components"

Rectangle {
    id: popupRoot
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width
    height: 0
    opacity: 0
    clip: true

    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth
    radius: Theme.radius

    states: State {
        name: "visible"
        when: parent.visible
        PropertyChanges {
            target: popupRoot
            height: parent.height
            opacity: 1
        }
    }

    transitions: Transition {
        to: "visible"
        NumberAnimation {
            property: "height"
            duration: 200
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.23, 1.0, 0.32, 1.0]
        }
        NumberAnimation {
            property: "opacity"
            duration: 150
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.23, 1.0, 0.32, 1.0]
        }
    }

    Loader {
        anchors.top: parent.top
        width: parent.width
        height: popupRoot.parent.height
        source: {
            var island = IslandManager.activeIsland;
            if (!island)
                return "";
            var type = island.type;
            type = type.charAt(0).toUpperCase() + type.slice(1);
            return "islands/" + type + "IslandExpanded.qml";
        }
    }
}
