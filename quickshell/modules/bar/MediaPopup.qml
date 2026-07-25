import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../components"
import "../../services"

Rectangle {
    anchors.fill: parent
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth
    radius: Theme.radius

    property var player: Mpris.players.values[0] || null
    property real progressValue: 0

    Timer {
        interval: 500
        running: player && player.playbackStatus === "Playing"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!player || !player.metadata) {
                progressValue = 0;
                return;
            }
            var len = player.metadata["mpris:length"] || 0;
            var pos = player.position || 0;
            progressValue = len > 0 ? Math.min((pos / len) * 100, 100) : 0;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Large album art
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 140
            height: 140
            radius: width / 2
            color: Theme.fgDim
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: player && player.metadata && player.metadata["mpris:artUrl"] ? player.metadata["mpris:artUrl"] : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                text: "\uE122"
                font.pixelSize: 56
                color: Theme.bg
                visible: !albumArt.visible
            }
        }

        // Title
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: player && player.metadata ? (player.metadata["xesam:title"] || "") : ""
            font.pixelSize: Theme.fontSizeLarge
            role: "fg"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        // Artist
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: {
                if (!player || !player.metadata)
                    return "";
                var artist = player.metadata["xesam:artist"] || "";
                if (Array.isArray(artist))
                    artist = artist.join(", ");
                return artist;
            }
            role: "fgDim"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: Theme.fgDim

            Rectangle {
                width: parent.width * (progressValue / 100)
                height: parent.height
                radius: parent.radius
                color: Theme.green
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 28

            Icon {
                text: "\uE15F"
                font.pixelSize: 22
                color: Theme.fg
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (player && player.previous)
                            player.previous();
                    }
                }
            }

            Rectangle {
                width: 44
                height: 44
                radius: 22
                color: Theme.accent

                Icon {
                    anchors.centerIn: parent
                    text: player && player.playbackStatus === "Playing" ? "\uE12E" : "\uE13C"
                    font.pixelSize: 22
                    color: Theme.bg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (player && player.playPause)
                            player.playPause();
                    }
                }
            }

            Icon {
                text: "\uE160"
                font.pixelSize: 22
                color: Theme.fg
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (player && player.next)
                            player.next();
                    }
                }
            }
        }
    }
}
