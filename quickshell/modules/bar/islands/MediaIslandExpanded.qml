import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../../services"
import "../../../components"

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: 12
    spacing: 10

    property var islandData: IslandManager.activeIsland ? IslandManager.activeIsland.data : {}
    property var player: islandData.player || null
    property real progressValue: 0
    property real localPosition: 0

    Timer {
        interval: 500
        running: player !== null
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (player && player.position > 0) {
                root.localPosition = player.position;
            } else if (player) {
                var len = player.length || (player.metadata ? player.metadata["mpris:length"] : 0) || 0;
                if (len <= 0 || root.localPosition < len) {
                    root.localPosition += 500000;
                }
            }
            updateProgress();
        }
    }

    function updateProgress() {
        if (!player) {
            progressValue = 0;
            return;
        }
        var len = player.length || (player.metadata ? player.metadata["mpris:length"] : 0) || 0;
        var pos = (player.position > 0) ? player.position : root.localPosition;
        progressValue = len > 0 ? Math.min((pos / len) * 100, 100) : 0;
    }

    function seekToRatio(ratio) {
        if (!player)
            return;
        var len = player.length || (player.metadata ? player.metadata["mpris:length"] : 0) || 0;
        if (len <= 0)
            return;
        var target = ratio * len;
        var delta = target - root.localPosition;
        player.seek(delta);
        root.localPosition = target;
        updateProgress();
    }

    function formatTime(value) {
        if (!value || value <= 0)
            return "0:00";
        var seconds = value > 100000 ? Math.floor(value / 1000000) : Math.floor(value);
        var minutes = Math.floor(seconds / 60);
        var secs = seconds % 60;
        return minutes + ":" + (secs < 10 ? "0" : "") + secs;
    }

    Connections {
        target: player || null
        function onPositionChanged() {
            updateProgress();
        }
        function onLengthChanged() {
            updateProgress();
        }
        function onMetadataChanged() {
            root.localPosition = 0;
            updateProgress();
        }
    }

    // Time row: current position (left) | total length (right)
    RowLayout {
        Layout.fillWidth: true

        StyledText {
            text: formatTime((player && player.position > 0) ? player.position : root.localPosition)
            role: "fgDim"
            font.pixelSize: 11
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: formatTime(player && player.metadata ? player.metadata["mpris:length"] : 0)
            role: "fgDim"
            font.pixelSize: 11
        }
    }

    WaveProgressBar {
        Layout.fillWidth: true
        height: 8
        value: progressValue
        onSeekRequested: ratio => root.seekToRatio(ratio)
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 28

        Icon {
            text: "\uE15F"
            font.pixelSize: 20
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
            width: 40
            height: 40
            radius: 20
            color: Theme.accent

            Icon {
                anchors.centerIn: parent
                text: player && player.playbackState === MprisPlaybackState.Playing ? "\uE12E" : "\uE13C"
                font.pixelSize: 20
                color: Theme.bg
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (player && player.togglePlaying)
                        player.togglePlaying();
                }
            }
        }

        Icon {
            text: "\uE160"
            font.pixelSize: 20
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
