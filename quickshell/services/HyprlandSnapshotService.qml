pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property var clients: []
    property var workspaces: []
    property var monitors: []
    property var activeWorkspace: null
    property var windowByAddress: ({})
    property var specialWorkspaceNames: []
    property var configuredSpecialWorkspaceNames: ["special:messenger", "special:music", "special:dev"]
    property int activeWorkspaceId: activeWorkspace && activeWorkspace.id ? activeWorkspace.id : 1
    property string activeSpecialWorkspaceName: activeSpecialWorkspace()
    property bool ready: false

    function parsePayload(data) {
        try {
            var parsed = JSON.parse(String(data).trim());
            clients = parsed.clients || [];
            workspaces = parsed.workspaces || [];
            monitors = parsed.monitors || [];
            activeWorkspace = parsed.activeWorkspace || null;
            activeWorkspaceId = activeWorkspace && activeWorkspace.id ? activeWorkspace.id : activeWorkspaceId;
            activeSpecialWorkspaceName = activeSpecialWorkspace();
            rebuildWindowIndex();
            rebuildSpecialWorkspaces();
            ready = true;
        } catch (e) {
            ready = false;
        }
    }

    function rebuildWindowIndex() {
        var next = {};
        for (var i = 0; i < clients.length; i++) {
            var address = String(clients[i].address || "").toLowerCase();
            if (address.length > 0)
                next[address] = clients[i];
        }
        windowByAddress = next;
    }

    function workspaceById(id) {
        for (var i = 0; i < workspaces.length; i++) {
            if (workspaces[i].id === id)
                return workspaces[i];
        }
        return null;
    }

    function windowsForWorkspace(id) {
        var result = [];
        for (var i = 0; i < clients.length; i++) {
            var client = clients[i];
            if (client && client.workspace && client.workspace.id === id)
                result.push(client);
        }
        return result;
    }

    function windowsForWorkspaceName(name) {
        var result = [];
        for (var i = 0; i < clients.length; i++) {
            var client = clients[i];
            if (client && client.workspace && client.workspace.name === name)
                result.push(client);
        }
        return result;
    }

    function rebuildSpecialWorkspaces() {
        var seen = {};
        var result = configuredSpecialWorkspaceNames.slice();
        for (var configuredIndex = 0; configuredIndex < result.length; configuredIndex++)
            seen[result[configuredIndex]] = true;

        for (var i = 0; i < clients.length; i++) {
            var workspace = clients[i] && clients[i].workspace ? clients[i].workspace : null;
            var name = workspace && workspace.name ? workspace.name : "";
            if (name.indexOf("special:") === 0 && !seen[name]) {
                seen[name] = true;
                result.push(name);
            }
        }
        if (activeSpecialWorkspaceName !== "" && !seen[activeSpecialWorkspaceName])
            result.push(activeSpecialWorkspaceName);
        specialWorkspaceNames = result;
    }

    function activeSpecialWorkspace() {
        for (var i = 0; i < monitors.length; i++) {
            var special = monitors[i].specialWorkspace;
            if (special && special.name && special.name.indexOf("special:") === 0)
                return special.name;
        }
        return "";
    }

    function specialWorkspaceShortName(name) {
        var value = String(name || "");
        return value.indexOf("special:") === 0 ? value.slice(8) : value;
    }

    function specialWorkspaceDisplayName(name) {
        var shortName = specialWorkspaceShortName(name);
        switch (shortName) {
        case "messenger":
            return "msg";
        default:
            return shortName;
        }
    }

    function specialWorkspaceIcon(name) {
        var shortName = specialWorkspaceShortName(name);
        switch (shortName) {
        case "messenger":
            return "\uE565";
        case "music":
            return "\uE122";
        case "dev":
            return "\uE093";
        default:
            return "\uE470";
        }
    }

    Process {
        running: true
        command: ["python3", "-c", "import json, subprocess, time\n\ndef snap(subject):\n    try:\n        return json.loads(subprocess.check_output(['hyprctl', subject, '-j'], stderr=subprocess.DEVNULL))\n    except Exception:\n        return [] if subject != 'activeworkspace' else None\n\nwhile True:\n    print(json.dumps({\n        'clients': snap('clients'),\n        'workspaces': snap('workspaces'),\n        'monitors': snap('monitors'),\n        'activeWorkspace': snap('activeworkspace')\n    }), flush=True)\n    time.sleep(0.45)"]
        stdout: SplitParser {
            onRead: data => root.parsePayload(data)
        }
    }
}
