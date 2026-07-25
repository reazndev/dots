pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int cpuUsage: 0
    property int ramUsage: 0
    property int gpuUsage: 0
    property int cpuTemp: 0
    property int gpuTemp: 0

    property bool batteryAvailable: false
    property int batteryPercentage: 0
    property bool batteryCharging: false

    property var prevCpu: null

    // CPU stats
    Process {
        running: true
        command: ["bash", "-c", "while true; do cat /proc/stat | head -1; sleep 2; done"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/);
                var user = parseInt(parts[1]);
                var nice = parseInt(parts[2]);
                var system = parseInt(parts[3]);
                var idle = parseInt(parts[4]);
                var iowait = parseInt(parts[5]);
                var irq = parseInt(parts[6]);
                var softirq = parseInt(parts[7]);
                var steal = parseInt(parts[8]);
                var total = user + nice + system + idle + iowait + irq + softirq + steal;
                var used = total - idle - iowait;
                if (root.prevCpu !== null) {
                    var totalDiff = total - root.prevCpu.total;
                    var usedDiff = used - root.prevCpu.used;
                    if (totalDiff > 0)
                        root.cpuUsage = Math.round(usedDiff / totalDiff * 100);
                }
                root.prevCpu = {
                    total: total,
                    used: used
                };
            }
        }
    }

    // RAM stats
    Process {
        running: true
        command: ["bash", "-c", "while true; do free | awk '/Mem:/ {print $2,$7}'; sleep 2; done"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/);
                var total = parseInt(parts[0]);
                var avail = parseInt(parts[1]);
                if (total > 0)
                    root.ramUsage = Math.round((total - avail) / total * 100);
            }
        }
    }

    // GPU stats (NVIDIA)
    Process {
        running: true
        command: ["bash", "-c", "while true; do nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null; sleep 2; done"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/,\s*/);
                if (parts.length >= 2) {
                    root.gpuUsage = parseInt(parts[0]);
                    root.gpuTemp = parseInt(parts[1]);
                }
            }
        }
    }

    // CPU temp
    Process {
        running: true
        command: ["bash", "-c", "while true; do sensors 2>/dev/null | grep 'Package id 0:' | head -1 | sed 's/[^+]*+\\([0-9]*\\).*/\\1/'; sleep 2; done"]
        stdout: SplitParser {
            onRead: data => {
                var t = parseInt(data.trim());
                if (!isNaN(t))
                    root.cpuTemp = t;
            }
        }
    }

    // Battery stats (laptops only)
    Process {
        running: true
        command: ["bash", "-c", "while true; do shopt -s nullglob; for bat in /sys/class/power_supply/BAT*; do [ -f \"$bat/capacity\" ] && echo \"$(cat \"$bat/capacity\") $(cat \"$bat/status\")\" && break; done || echo unavailable; sleep 5; done"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/);
                if (parts.length >= 2 && parts[0] !== "unavailable") {
                    root.batteryAvailable = true;
                    root.batteryPercentage = Math.max(0, Math.min(100, parseInt(parts[0])));
                    root.batteryCharging = parts[1] === "Charging";
                } else {
                    root.batteryAvailable = false;
                }
            }
        }
    }
}
