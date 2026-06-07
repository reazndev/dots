pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int percent: 0
    property bool muted: false
    property bool available: false
    property bool initialized: false
    readonly property int displayPercent: muted ? 0 : percent
    readonly property string displayText: muted ? "Muted" : percent + "%"

    signal volumeAdjusted()

    function parseVolumeOutput(output) {
        var text = String(output || "").trim();
        var match = text.match(/([0-9]*\.?[0-9]+)/);
        if (!match)
            return;

        var nextPercent = Math.max(0, Math.min(100, Math.round(parseFloat(match[1]) * 100)));
        var nextMuted = text.toLowerCase().indexOf("muted") !== -1;
        var changed = available && initialized && (nextPercent !== percent || nextMuted !== muted);

        percent = nextPercent;
        muted = nextMuted;
        available = true;

        if (!initialized) {
            initialized = true;
            return;
        }

        if (changed)
            volumeAdjusted();
    }

    Process {
        running: true
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null; pactl subscribe 2>/dev/null | while read -r line; do case \"$line\" in *sink*|*card*|*server*) wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null;; esac; done"]
        stdout: SplitParser {
            onRead: data => root.parseVolumeOutput(data)
        }
    }
}
