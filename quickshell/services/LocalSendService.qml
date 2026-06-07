pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool available: false
    property string status: "starting"
    property string mode: "idle" // idle | drop | scanning | devices | incoming | sending | receiving | complete | error
    property var selectedFiles: []
    property int selectedTotalSize: 0
    property var devices: []
    property var incomingRequest: null
    property var activeTransfer: null
    property string errorText: ""
    property string completionText: ""
    property int scanCount: 0
    property bool suppressTransferEvents: false
    readonly property real progress: activeTransfer ? Math.round((Number(activeTransfer.progress) || 0) * 100) : 0
    readonly property bool hasFiles: selectedFiles.length > 0
    readonly property bool hasDevices: devices.length > 0

    signal incomingRequested()
    signal transferStarted()
    signal transferFinished()
    signal dismissed()
    signal filesSelected()

    function helperPath() {
        return "/home/reazn/.config/quickshell/helpers/localsend-bridge/target/release/localsend-bridge";
    }

    function sendCommand(payload) {
        if (!bridge.running)
            return;
        bridge.write(JSON.stringify(payload) + "\n");
    }

    function normalizeDropUrls(urls) {
        var result = [];
        for (var i = 0; i < urls.length; i++)
            result.push(String(urls[i]));
        return result;
    }

    function addFiles(urls) {
        suppressTransferEvents = false;
        incomingRequest = null;
        activeTransfer = null;
        completionText = "";
        errorText = "";
        mode = "drop";
        sendCommand({ cmd: "add_files", files: normalizeDropUrls(urls) });
        filesSelected();
    }

    function removeFile(path) {
        sendCommand({ cmd: "remove_file", path: path });
    }

    function previewDrop() {
        if (hasFiles || mode === "sending" || mode === "receiving" || mode === "incoming" || mode === "complete")
            return;
        mode = "drop";
        filesSelected();
    }

    function cancelDropPreview() {
        if (!hasFiles && mode === "drop")
            clear();
    }

    function startScan() {
        scanCount = 0;
        devices = [];
        mode = "scanning";
        sendCommand({ cmd: "scan" });
    }

    function sendToDevice(deviceId) {
        suppressTransferEvents = false;
        mode = "sending";
        activeTransfer = {
            id: "",
            direction: "send",
            device: deviceLabel(deviceById(deviceId)),
            file_name: "",
            progress: 0,
            transferred: 0,
            total: selectedTotalSize,
            status: "sending"
        };
        transferStarted();
        sendCommand({ cmd: "send", device_id: deviceId });
    }

    function acceptIncoming(requestId) {
        suppressTransferEvents = false;
        mode = "receiving";
        sendCommand({ cmd: "accept_incoming", request_id: requestId });
    }

    function rejectIncoming(requestId) {
        sendCommand({ cmd: "reject_incoming", request_id: requestId });
        incomingRequest = null;
        mode = "idle";
    }

    function cancelTransfer() {
        suppressTransferEvents = true;
        sendCommand({ cmd: "cancel", transfer_id: activeTransfer ? activeTransfer.id : null });
        mode = "idle";
        activeTransfer = null;
        dismissed();
    }

    function clear() {
        suppressTransferEvents = true;
        selectedFiles = [];
        selectedTotalSize = 0;
        devices = [];
        incomingRequest = null;
        activeTransfer = null;
        errorText = "";
        completionText = "";
        mode = "idle";
        sendCommand({ cmd: "clear" });
        dismissed();
    }

    function deviceById(id) {
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].id === id)
                return devices[i];
        }
        return null;
    }

    function deviceLabel(device) {
        if (!device)
            return "Device";
        return device.alias || device.address || "Device";
    }

    function formatBytes(bytes) {
        var value = Number(bytes) || 0;
        if (value < 1024)
            return value + " B";
        if (value < 1024 * 1024)
            return (value / 1024).toFixed(value < 10 * 1024 ? 1 : 0) + " KB";
        if (value < 1024 * 1024 * 1024)
            return (value / 1024 / 1024).toFixed(value < 10 * 1024 * 1024 ? 1 : 0) + " MB";
        return (value / 1024 / 1024 / 1024).toFixed(1) + " GB";
    }

    function handleLine(line) {
        var event = null;
        try {
            event = JSON.parse(String(line).trim());
        } catch (e) {
            return;
        }

        switch (event.type) {
        case "ready":
            available = true;
            status = event.protocol + " :" + event.port;
            if (mode === "starting")
                mode = "idle";
            break;
        case "scan_started":
            mode = "scanning";
            scanCount = 0;
            break;
        case "device_found":
            upsertDevice(event.device);
            if (mode === "scanning" && hasFiles)
                mode = "devices";
            break;
        case "scan_finished":
            scanCount = event.count || devices.length;
            if (mode === "scanning")
                mode = devices.length > 0 ? "devices" : (selectedFiles.length > 0 ? "drop" : "idle");
            break;
        case "files_set":
            selectedFiles = event.files || [];
            selectedTotalSize = event.total_size || 0;
            if (mode !== "scanning" && mode !== "devices" && mode !== "sending")
                mode = selectedFiles.length > 0 ? "drop" : "idle";
            break;
        case "incoming_request":
            incomingRequest = event.request;
            activeTransfer = null;
            mode = "incoming";
            incomingRequested();
            break;
        case "transfer_progress":
            if (suppressTransferEvents)
                return;
            activeTransfer = event.transfer;
            mode = event.transfer.direction === "receive" ? "receiving" : "sending";
            break;
        case "transfer_complete":
            if (suppressTransferEvents)
                return;
            completionText = event.message || "Transfer complete";
            mode = "complete";
            activeTransfer = activeTransfer || { progress: 1, transferred: 0, total: 0, direction: event.direction };
            activeTransfer.progress = 1;
            transferFinished();
            completeHideTimer.restart();
            break;
        case "transfer_error":
            if (suppressTransferEvents)
                return;
            errorText = event.message || "LocalSend error";
            mode = "error";
            break;
        case "state":
            status = event.status || status;
            break;
        }
    }

    function upsertDevice(device) {
        if (!device || !device.id)
            return;
        var next = devices.slice();
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === device.id) {
                next[i] = device;
                devices = next;
                return;
            }
        }
        next.push(device);
        devices = next;
    }

    Timer {
        id: completeHideTimer
        interval: 4200
        repeat: false
        onTriggered: root.clear()
    }

    Timer {
        id: helperRestartTimer
        interval: 900
        repeat: false
        onTriggered: {
            if (!bridge.running)
                bridge.running = true;
        }
    }

    Process {
        id: bridge
        running: true
        stdinEnabled: true
        command: [root.helperPath()]
        stdout: SplitParser {
            onRead: data => root.handleLine(data)
        }
        stderr: SplitParser {
            onRead: data => {
                root.errorText = String(data).trim();
                if (root.errorText !== "")
                    root.mode = "error";
            }
        }
        onRunningChanged: {
            if (!running && root.available) {
                root.available = false;
                root.mode = "error";
                root.errorText = "LocalSend helper stopped";
                helperRestartTimer.restart();
            }
        }
        onExited: {
            root.available = false;
            if (root.mode !== "idle" && root.mode !== "complete")
                root.errorText = "Restarting LocalSend helper";
            helperRestartTimer.restart();
        }
    }
}
