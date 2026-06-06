import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../services"
import "../../components"

Rectangle {
    id: root
    height: 28
    implicitWidth: row.implicitWidth + 16
    radius: height / 2
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth

    property var player: Mpris.players.values[0] || null
    property var popup: null
    property real progressValue: 0

    visible: player && player.metadata && player.metadata["xesam:title"]

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.popup)
                root.popup.visible = !root.popup.visible;
        }
    }

    Timer {
        interval: 500
        running: player && player.playbackStatus === "Playing"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!player || !player.metadata) {
                root.progressValue = 0;
                return;
            }
            var len = player.metadata["mpris:length"] || 0;
            var pos = player.position || 0;
            root.progressValue = len > 0 ? Math.min((pos / len) * 100, 100) : 0;
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // Album art
        Rectangle {
            width: 22
            height: 22
            radius: width / 2
            color: Theme.fgDim
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: root.player && root.player.metadata && root.player.metadata["mpris:artUrl"] ? root.player.metadata["mpris:artUrl"] : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                text: "\uE122"
                font.pixelSize: 12
                color: Theme.bg
                visible: !albumArt.visible
            }
        }

        // Song info
        StyledText {
            text: {
                if (!root.player || !root.player.metadata)
                    return "";
                var title = root.player.metadata["xesam:title"] || "";
                var artist = root.player.metadata["xesam:artist"] || "";
                if (Array.isArray(artist))
                    artist = artist.join(", ");
                if (title.length > 20)
                    title = title.slice(0, 20) + "…";
                if (title && artist)
                    return title + " – " + artist;
                if (title)
                    return title;
                return "";
            }
            role: "fg"
        }

        // Progress donut
        DonutChart {
            width: 18
            height: 18
            value: root.progressValue
            icon: root.player && root.player.playbackStatus === "Playing" ? "\uE13C" : "\uE12E"
            fgColor: Theme.green
            lineWidth: 2
        }
    }
}
