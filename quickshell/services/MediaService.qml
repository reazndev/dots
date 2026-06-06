pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root

    property string lastActivePlayerDbusName: ""
    property var playersList: Mpris.players.values
    property var activePlayer: resolveActivePlayer()
    property real progress: 0
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"

    readonly property bool hasPlayer: activePlayer !== null && trackTitle !== ""
    readonly property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property string trackTitle: {
        if (!activePlayer)
            return "";
        if (activePlayer.trackTitle)
            return activePlayer.trackTitle;
        if (activePlayer.title)
            return activePlayer.title;
        if (activePlayer.metadata && activePlayer.metadata["xesam:title"])
            return activePlayer.metadata["xesam:title"];
        return "";
    }
    readonly property string artist: {
        if (!activePlayer)
            return "";
        var value = activePlayer.artist || "";
        if (!value && activePlayer.metadata)
            value = activePlayer.metadata["xesam:artist"] || "";
        if (Array.isArray(value))
            return value.join(", ");
        return value ? String(value) : "";
    }
    readonly property string artUrl: {
        if (!activePlayer)
            return "";
        if (activePlayer.trackArtUrl)
            return activePlayer.trackArtUrl;
        if (activePlayer.artUrl)
            return activePlayer.artUrl;
        if (activePlayer.metadata && activePlayer.metadata["mpris:artUrl"])
            return activePlayer.metadata["mpris:artUrl"];
        return "";
    }

    function formatTime(value) {
        var numberValue = Number(value);
        if (isNaN(numberValue) || numberValue <= 0)
            return "0:00";

        var totalSeconds = 0;
        if (numberValue < 10000)
            totalSeconds = Math.floor(numberValue);
        else if (numberValue < 100000000)
            totalSeconds = Math.floor(numberValue / 1000);
        else
            totalSeconds = Math.floor(numberValue / 1000000);

        var minutes = Math.floor(totalSeconds / 60);
        var seconds = Math.floor(totalSeconds % 60);
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    function playerHasTrackInfo(player) {
        if (!player)
            return false;
        if ((player.trackTitle || player.title || "") !== "")
            return true;
        if (!player.metadata)
            return false;
        return Boolean(player.metadata["xesam:title"] || player.metadata["mpris:trackid"] || player.metadata["xesam:url"]);
    }

    function findPlayerByDbusName(dbusName) {
        if (!playersList || !dbusName)
            return null;
        for (var i = 0; i < playersList.length; i++) {
            if (playersList[i].dbusName === dbusName)
                return playersList[i];
        }
        return null;
    }

    function resolveActivePlayer() {
        if (!playersList || playersList.length === 0)
            return null;

        for (var i = 0; i < playersList.length; i++) {
            if (playersList[i].playbackState === MprisPlaybackState.Playing)
                return playersList[i];
        }

        var rememberedPlayer = findPlayerByDbusName(lastActivePlayerDbusName);
        if (rememberedPlayer && (playerHasTrackInfo(rememberedPlayer) || rememberedPlayer.canControl))
            return rememberedPlayer;

        for (var j = 0; j < playersList.length; j++) {
            if (playersList[j].playbackState === MprisPlaybackState.Paused && playerHasTrackInfo(playersList[j]))
                return playersList[j];
        }

        for (var k = 0; k < playersList.length; k++) {
            if (playersList[k].canControl)
                return playersList[k];
        }

        return playersList[0];
    }

    function refreshPlayer() {
        playersList = Mpris.players.values;
        activePlayer = resolveActivePlayer();
        if (activePlayer && activePlayer.dbusName)
            lastActivePlayerDbusName = activePlayer.dbusName;
        updateProgress();
    }

    function updateProgress() {
        var player = activePlayer;
        if (!player) {
            progress = 0;
            timePlayed = "0:00";
            timeTotal = "0:00";
            return;
        }

        var position = Number(player.position) || 0;
        var length = Number(player.length) || 0;
        if (length <= 0 && player.metadata && player.metadata["mpris:length"])
            length = Number(player.metadata["mpris:length"]);

        progress = length > 0 ? Math.max(0, Math.min(1, position / length)) : 0;
        timePlayed = formatTime(position);
        timeTotal = formatTime(length);
    }

    function togglePlayback() {
        var player = activePlayer;
        if (!player || !player.canControl)
            return;
        if (player.canTogglePlaying) {
            player.togglePlaying();
            return;
        }
        if (player.playbackState === MprisPlaybackState.Playing) {
            if (player.canPause)
                player.pause();
        } else if (player.canPlay) {
            player.play();
        }
    }

    Timer {
        interval: 500
        running: root.activePlayer !== null
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateProgress()
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshPlayer()
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.refreshPlayer();
        }
    }

    Connections {
        target: root.activePlayer || null
        ignoreUnknownSignals: true
        function onMetadataChanged() {
            root.refreshPlayer();
        }
        function onPlaybackStateChanged() {
            root.refreshPlayer();
        }
        function onPositionChanged() {
            root.updateProgress();
        }
        function onLengthChanged() {
            root.updateProgress();
        }
    }
}
