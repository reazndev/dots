pragma Singleton
import QtQuick
import Quickshell.Bluetooth

Item {
    id: root

    signal newConnection(var device)

    property var adapter: Bluetooth.defaultAdapter
    property var devices: Bluetooth.devices.values
    property string connectedSignature: ""
    property bool baselineReady: false
    property var latestConnectedDevice: null

    function deviceText(value) {
        return String(value === undefined || value === null ? "" : value).trim();
    }

    function deviceName(device) {
        if (!device)
            return "Bluetooth device";

        var preferred = deviceText(device.deviceName);
        if (preferred.length > 0)
            return preferred;

        var alias = deviceText(device.name);
        if (alias.length > 0)
            return alias;

        var address = deviceText(device.address);
        return address.length > 0 ? address : "Bluetooth device";
    }

    function deviceKey(device) {
        if (!device)
            return "";

        var path = deviceText(device.dbusPath);
        if (path.length > 0)
            return path;

        var address = deviceText(device.address);
        if (address.length > 0)
            return address;

        return deviceName(device);
    }

    function connectedDevices() {
        var connected = [];
        var source = devices || [];
        for (var i = 0; i < source.length; i++) {
            if (source[i] && source[i].connected)
                connected.push(source[i]);
        }
        return connected;
    }

    function connectedDevicesSignature(sourceDevices) {
        var keys = [];
        for (var i = 0; i < sourceDevices.length; i++) {
            var key = deviceKey(sourceDevices[i]);
            if (key.length > 0)
                keys.push(key);
        }
        keys.sort();
        return keys.join("\u001f");
    }

    function previousKeyMap() {
        var previousKeys = {};
        if (connectedSignature.length === 0)
            return previousKeys;

        var keys = connectedSignature.split("\u001f");
        for (var i = 0; i < keys.length; i++) {
            if (keys[i].length > 0)
                previousKeys[keys[i]] = true;
        }
        return previousKeys;
    }

    function findNewDevice(sourceDevices) {
        var previousKeys = previousKeyMap();
        for (var i = 0; i < sourceDevices.length; i++) {
            var key = deviceKey(sourceDevices[i]);
            if (key.length > 0 && !previousKeys[key])
                return sourceDevices[i];
        }
        return sourceDevices.length > 0 ? sourceDevices[0] : null;
    }

    function sync(showNewConnection) {
        devices = Bluetooth.devices.values;
        var connected = connectedDevices();
        var nextSignature = connectedDevicesSignature(connected);
        latestConnectedDevice = connected.length > 0 ? connected[0] : null;

        if (!baselineReady || baselineTimer.running) {
            connectedSignature = nextSignature;
            return;
        }

        if (nextSignature === connectedSignature)
            return;

        var newDevice = findNewDevice(connected);
        connectedSignature = nextSignature;

        if (showNewConnection && newDevice && nextSignature.length > 0)
            root.newConnection(newDevice);
    }

    onAdapterChanged: {
        connectedSignature = "";
        baselineReady = false;
        baselineTimer.restart();
        sync(false);
    }

    Timer {
        id: baselineTimer
        interval: 1000
        repeat: false
        running: true
        onTriggered: {
            root.baselineReady = true;
            root.sync(false);
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sync(true)
    }

    Connections {
        target: Bluetooth.devices
        ignoreUnknownSignals: true
        function onValuesChanged() {
            root.sync(true);
        }
    }
}
