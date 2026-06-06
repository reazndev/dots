import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../../services"
import "../../../components"

RowLayout {
    spacing: 8

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
                localPosition = player.position;
            } else if (player) {
                var len = player.length || (player.metadata ? player.metadata["mpris:length"] : 0) || 0;
                if (len <= 0 || localPosition < len) {
                    localPosition += 500000;
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
        var pos = (player.position > 0) ? player.position : localPosition;
        progressValue = len > 0 ? Math.min((pos / len) * 100, 100) : 0;
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
            localPosition = 0;
            updateProgress();
        }
    }

    RoundedImage {
        id: albumArt
        width: 22
        height: 22
        maskSource: "file:///home/reazn/.config/quickshell/assets/mask_compact.png"
        source: player && player.metadata && player.metadata["mpris:artUrl"] ? player.metadata["mpris:artUrl"] : ""

        Icon {
            anchors.centerIn: parent
            text: "\uE122"
            font.pixelSize: 10
            color: Theme.bg
            visible: albumArt.status !== Image.Ready
        }
    }

    StyledText {
        text: {
            if (!player || !player.metadata)
                return "";
            var title = player.metadata["xesam:title"] || "";
            var artist = player.metadata["xesam:artist"] || "";
            if (Array.isArray(artist))
                artist = artist.join(", ");
            if (title.length > 30)
                title = title.slice(0, 30) + "…";
            if (title && artist)
                return title + " – " + artist;
            if (title)
                return title;
            return "";
        }
        role: "fg"
    }

    DonutChart {
        width: 18
        height: 18
        value: progressValue
        icon: ""
        fgColor: Theme.green
        lineWidth: 2
    }
}
