pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int percent: 0
    property bool available: false
    property bool initialized: false
    readonly property string displayText: percent + "%"

    signal brightnessAdjusted()

    function parseBrightnessOutput(output) {
        var text = String(output || "").trim();
        if (!text)
            return;

        // brightnessctl -m output format:
        // device,class,current,percent,max
        var parts = text.split(",");
        if (parts.length < 4)
            return;

        var percentMatch = String(parts[3]).match(/([0-9]*\.?[0-9]+)/);
        if (!percentMatch)
            return;

        var nextPercent = Math.max(0, Math.min(100, Math.round(parseFloat(percentMatch[1]))));
        var changed = available && initialized && nextPercent !== percent;

        percent = nextPercent;
        available = true;

        if (!initialized) {
            initialized = true;
            return;
        }

        if (changed)
            brightnessAdjusted();
    }

    Process {
        running: true
        command: ["bash", "-c", "brightnessctl -m 2>/dev/null; while true; do sleep 0.2; brightnessctl -m 2>/dev/null; done"]
        stdout: SplitParser {
            onRead: data => root.parseBrightnessOutput(data)
        }
    }
}
