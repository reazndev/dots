pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    // ─── Exported properties ───
    property var usageData: ({})
    property var providerNames: []
    property string mostCriticalProvider: ""
    property real mostCriticalPercent: 0
    property string mostCriticalDisplayName: ""
    property string mostCriticalResetDesc: ""
    property bool hasErrors: false
    property string lastError: ""
    property bool isLoading: true

    // Internal
    property string _scriptPath: "/home/reazn/.config/quickshell/scripts/usage_tracker.py"

    function _computeMostCritical() {
        var maxPct = 0;
        var criticalName = "";
        var criticalDisplay = "";
        var criticalReset = "";
        var anyError = false;
        var errorText = "";

        for (var i = 0; i < root.providerNames.length; i++) {
            var name = root.providerNames[i];
            var d = root.usageData[name];
            if (!d)
                continue;
            if (d.error) {
                anyError = true;
                errorText = d.error;
                continue;
            }
            // Check primary, secondary, tertiary for highest usedPercent
            var windows = [d.primary, d.secondary, d.tertiary];
            for (var j = 0; j < windows.length; j++) {
                var w = windows[j];
                if (w && w.usedPercent > maxPct) {
                    maxPct = w.usedPercent;
                    criticalName = name;
                    criticalDisplay = d.displayName || name;
                    criticalReset = w.resetDescription || "";
                }
            }
            // Also check extraRateWindows (Antigravity model quotas)
            if (d.extraRateWindows) {
                for (var k = 0; k < d.extraRateWindows.length; k++) {
                    var ew = d.extraRateWindows[k];
                    if (ew && ew.usedPercent > maxPct) {
                        maxPct = ew.usedPercent;
                        criticalName = name;
                        criticalDisplay = d.displayName || name;
                        criticalReset = ew.name + ": " + (ew.resetDescription || "");
                    }
                }
            }
            // Also check credits as a fallback (low balance = critical)
            if (d.credits && d.credits.remaining !== undefined && d.credits.remaining < 5) {
                if (maxPct === 0) {
                    criticalName = name;
                    criticalDisplay = d.displayName || name;
                    criticalReset = "$" + d.credits.remaining.toFixed(2) + " left";
                }
            }
        }

        root.mostCriticalProvider = criticalName;
        root.mostCriticalPercent = maxPct;
        root.mostCriticalDisplayName = criticalDisplay;
        root.mostCriticalResetDesc = criticalReset;
        root.hasErrors = anyError;
        root.lastError = errorText;
    }

    function usageFor(provider) {
        return root.usageData[provider] || null;
    }

    function usageColor(usedPercent) {
        if (usedPercent >= 90)
            return Theme.red;
        if (usedPercent >= 70)
            return Theme.yellow;
        return Theme.green;
    }

    function formatPercent(pct) {
        return Math.round(pct) + "%";
    }

    // ─── Process: runs the Python tracker ───
    Process {
        id: trackerProc
        running: true
        command: ["python3", root._scriptPath]

        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data.trim());
                    var names = [];
                    for (var key in parsed) {
                        if (parsed.hasOwnProperty(key)) {
                            names.push(key);
                        }
                    }
                    root.usageData = parsed;
                    root.providerNames = names;
                    root.isLoading = false;
                    root._computeMostCritical();
                } catch (e) {
                    console.log("UsageTrackingService: JSON parse error:", e, "data:", data.substring(0, 200));
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.log("UsageTracker stderr:", data.trim());
            }
        }

        onRunningChanged: {
            if (!running) {
                console.log("UsageTracker process exited, restarting in 5s...");
                restartTimer.start();
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 5000
        repeat: false
        onTriggered: {
            trackerProc.running = true;
        }
    }
}
