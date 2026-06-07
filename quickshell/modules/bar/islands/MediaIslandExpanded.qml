import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: Theme.islandPadding
    spacing: Theme.islandGap

    function seekToRatio(ratio) {
        var player = MediaService.activePlayer;
        if (!player)
            return;
        var length = Number(player.length) || 0;
        if (length <= 0 && player.metadata && player.metadata["mpris:length"])
            length = Number(player.metadata["mpris:length"]);
        if (length <= 0)
            return;

        var target = ratio * length;
        var delta = target - (Number(player.position) || 0);
        player.seek(delta);
        MediaService.updateProgress();
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.islandGap

        RoundedImage {
            id: expandedArt
            Layout.preferredWidth: Theme.islandAlbumSize
            Layout.preferredHeight: Theme.islandAlbumSize
            maskSource: "file:///home/reazn/.config/quickshell/assets/mask_expanded.png"
            source: MediaService.artUrl

            Icon {
                anchors.centerIn: parent
                text: "\uE122"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.bg
                visible: expandedArt.status !== Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.max(2, Math.round(Theme.islandGap / 2))

            StyledText {
                Layout.fillWidth: true
                text: MediaService.trackTitle || "No music playing"
                role: "fg"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: MediaService.artist
                role: "fgDim"
                font.family: Theme.fontFamilyUi
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 44
            Layout.preferredHeight: Theme.islandButtonSize
            spacing: 4

            Repeater {
                model: 5
                delegate: Rectangle {
                    required property int index
                    width: 4
                    height: MediaService.isPlaying
                        ? 7 + (parent.height - 7) * (0.22 + 0.66 * Math.abs(Math.sin(root.visualizerPhase + index * 0.78)))
                        : 7 + (parent.height - 7) * ([0.34, 0.58, 0.82, 0.58, 0.34][index])
                    radius: width / 2
                    color: MediaService.isPlaying ? Theme.accent : Theme.fgDim
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on height {
                        NumberAnimation {
                            duration: MediaService.isPlaying ? 120 : 260
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.islandAnimationDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }

    property real visualizerPhase: 0

    Timer {
        interval: 64
        repeat: true
        running: MediaService.isPlaying
        onTriggered: {
            root.visualizerPhase += 0.18;
            if (root.visualizerPhase > Math.PI * 2)
                root.visualizerPhase -= Math.PI * 2;
        }
    }

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            text: MediaService.timePlayed
            role: "fgDim"
            font.pixelSize: Theme.fontSize - 1
        }

        Rectangle {
            id: progressTrack
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(6, Math.round(Theme.islandGap * 0.7))
            radius: height / 2
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * MediaService.progress
                radius: parent.radius
                color: Theme.fg

                Behavior on width {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.seekToRatio(mouse.x / width)
            }
        }

        StyledText {
            text: MediaService.timeTotal
            role: "fgDim"
            font.pixelSize: Theme.fontSize - 1
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.islandButtonSize

        Icon {
            text: "\uE15F"
            font.pixelSize: Theme.fontSizeLarge + 4
            color: prevArea.pressed ? Theme.fgDim : Theme.fg
            scale: prevArea.pressed ? 0.84 : 1

            Behavior on scale { NumberAnimation { duration: 100 } }

            MouseArea {
                id: prevArea
                anchors.fill: parent
                anchors.margins: -Theme.islandGap
                cursorShape: Qt.PointingHandCursor
                onClicked: if (MediaService.activePlayer) MediaService.activePlayer.previous()
            }
        }

        Rectangle {
            Layout.preferredWidth: Theme.islandButtonSize + 8
            Layout.preferredHeight: Theme.islandButtonSize + 8
            radius: width / 2
            color: playArea.pressed ? Theme.fgDim : Theme.accent
            scale: playArea.pressed ? 0.88 : 1

            Behavior on scale { NumberAnimation { duration: 100 } }
            Behavior on color { ColorAnimation { duration: Theme.islandAnimationDuration } }

            Icon {
                anchors.centerIn: parent
                text: MediaService.isPlaying ? "\uE12E" : "\uE13C"
                font.pixelSize: Theme.fontSizeLarge + 2
                color: Theme.bg
            }

            MouseArea {
                id: playArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaService.togglePlayback()
            }
        }

        Icon {
            text: "\uE160"
            font.pixelSize: Theme.fontSizeLarge + 4
            color: nextArea.pressed ? Theme.fgDim : Theme.fg
            scale: nextArea.pressed ? 0.84 : 1

            Behavior on scale { NumberAnimation { duration: 100 } }

            MouseArea {
                id: nextArea
                anchors.fill: parent
                anchors.margins: -Theme.islandGap
                cursorShape: Qt.PointingHandCursor
                onClicked: if (MediaService.activePlayer) MediaService.activePlayer.next()
            }
        }
    }
}
