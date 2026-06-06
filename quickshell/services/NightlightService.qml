pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool enabled: false
    property int temperature: 6000
    property bool identity: false

    // Poll hyprsunset status every 3 seconds
    Process {
        running: true
        command: ["bash", "-c", "while true; do pidof hyprsunset > /dev/null && echo 'on' || echo 'off'; sleep 3; done"]
        stdout: SplitParser {
            onRead: data => {
                var wasEnabled = root.enabled;
                root.enabled = (data.trim() === "on");
            }
        }
    }

    function toggle() {
        if (root.enabled) {
            stopCmd.running = true;
        } else {
            startCmd.running = true;
        }
    }

    function increaseTemperature() {
        adjustCmd.command = ["hyprctl", "hyprsunset", "temperature", "+500"];
        adjustCmd.running = true;
        root.temperature = Math.min(root.temperature + 500, 10000);
    }

    function decreaseTemperature() {
        adjustCmd.command = ["hyprctl", "hyprsunset", "temperature", "-500"];
        adjustCmd.running = true;
        root.temperature = Math.max(root.temperature - 500, 1000);
    }

    Process {
        id: startCmd
        command: ["hyprsunset"]
        onExited: {
            if (code !== 0) {
                console.log("Failed to start hyprsunset");
            }
        }
    }

    Process {
        id: stopCmd
        command: ["killall", "hyprsunset"]
        onExited: {
            root.temperature = 6000;
        }
    }

    Process {
        id: adjustCmd
        command: []
        onExited: {
            if (code !== 0) {
                console.log("Failed to adjust hyprsunset temperature");
            }
        }
    }
}
