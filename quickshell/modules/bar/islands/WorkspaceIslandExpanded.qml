import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../../services"
import "../../../components"

Item {
    id: root
    anchors.fill: parent
    anchors.margins: Theme.islandOverviewOuterPadding
    clip: true

    readonly property int normalWorkspaceCount: 7
    readonly property int totalCells: normalWorkspaceCount + HyprlandSnapshotService.specialWorkspaceNames.length
    readonly property int rows: Math.max(1, Math.ceil(totalCells / columns))
    readonly property int columns: 5
    readonly property int activeWorkspaceId: Math.max(1, HyprlandSnapshotService.activeWorkspaceId)
    readonly property real cellWidth: (width - Theme.islandOverviewCellGap * (columns - 1)) / columns
    readonly property real cellHeight: (height - Theme.islandOverviewCellGap * (rows - 1)) / rows
    readonly property var toplevelValues: ToplevelManager.toplevels && ToplevelManager.toplevels.values ? ToplevelManager.toplevels.values : []

    signal closeRequested()

    function workspaceId(row, column) {
        return row * columns + column + 1;
    }

    function specialNameForCell(row, column) {
        var specialIndex = row * columns + column - normalWorkspaceCount;
        return specialIndex >= 0 && specialIndex < HyprlandSnapshotService.specialWorkspaceNames.length
            ? HyprlandSnapshotService.specialWorkspaceNames[specialIndex]
            : "";
    }

    function cellIsSpecial(row, column) {
        return specialNameForCell(row, column) !== "";
    }

    function cellWindows(row, column) {
        var specialName = specialNameForCell(row, column);
        if (row * columns + column >= totalCells)
            return [];
        return specialName !== ""
            ? HyprlandSnapshotService.windowsForWorkspaceName(specialName)
            : HyprlandSnapshotService.windowsForWorkspace(workspaceId(row, column));
    }

    function monitorForClient(client) {
        var target = client && client.monitor !== undefined ? client.monitor : -1;
        var monitors = HyprlandSnapshotService.monitors || [];
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].id === target || monitors[i].name === target)
                return monitors[i];
        }
        return monitors.length > 0 ? monitors[0] : null;
    }

    function normalizeToplevelAddress(toplevel) {
        var rawAddress = toplevel && toplevel.HyprlandToplevel ? String(toplevel.HyprlandToplevel.address || "") : "";
        if (rawAddress === "")
            return "";
        return rawAddress.indexOf("0x") === 0 ? rawAddress.toLowerCase() : ("0x" + rawAddress).toLowerCase();
    }

    function windowDataForToplevel(toplevel) {
        var address = normalizeToplevelAddress(toplevel);
        if (address === "")
            return null;
        return HyprlandSnapshotService.windowByAddress[address] || null;
    }

    function toplevelForClient(client) {
        var address = client && client.address ? String(client.address).toLowerCase() : "";
        if (address === "")
            return null;
        for (var i = 0; i < toplevelValues.length; i++) {
            if (normalizeToplevelAddress(toplevelValues[i]) === address)
                return toplevelValues[i];
        }
        return null;
    }

    function monitorWidth(monitor) {
        var scale = monitor && monitor.scale ? Number(monitor.scale) : 1;
        var reserved = monitor && monitor.reserved ? monitor.reserved : [0, 0, 0, 0];
        var width = monitor && monitor.width ? Number(monitor.width) : 1920;
        return Math.max(1, (width - Number(reserved[0] || 0) - Number(reserved[2] || 0)) / Math.max(0.0001, scale));
    }

    function monitorHeight(monitor) {
        var scale = monitor && monitor.scale ? Number(monitor.scale) : 1;
        var reserved = monitor && monitor.reserved ? monitor.reserved : [0, 0, 0, 0];
        var height = monitor && monitor.height ? Number(monitor.height) : 1080;
        return Math.max(1, (height - Number(reserved[1] || 0) - Number(reserved[3] || 0)) / Math.max(0.0001, scale));
    }

    function monitorX(monitor) {
        return monitor && monitor.x !== undefined ? Number(monitor.x) : 0;
    }

    function monitorY(monitor) {
        return monitor && monitor.y !== undefined ? Number(monitor.y) : 0;
    }

    function tileX(client, monitor) {
        var at = client && client.at ? client.at : [monitorX(monitor), monitorY(monitor)];
        var scale = monitor && monitor.scale ? Number(monitor.scale) : 1;
        var reserved = monitor && monitor.reserved ? monitor.reserved : [0, 0, 0, 0];
        var localX = Number(at[0]) - monitorX(monitor) - Number(reserved[0] || 0) / Math.max(0.0001, scale);
        return Math.max(0, Math.min(cellWidth, localX * cellWidth / monitorWidth(monitor)));
    }

    function tileY(client, monitor) {
        var at = client && client.at ? client.at : [monitorX(monitor), monitorY(monitor)];
        var scale = monitor && monitor.scale ? Number(monitor.scale) : 1;
        var reserved = monitor && monitor.reserved ? monitor.reserved : [0, 0, 0, 0];
        var localY = Number(at[1]) - monitorY(monitor) - Number(reserved[1] || 0) / Math.max(0.0001, scale);
        return Math.max(0, Math.min(cellHeight, localY * cellHeight / monitorHeight(monitor)));
    }

    function tileWidth(client, monitor) {
        var size = client && client.size ? client.size : [360, 220];
        return Math.max(46, Math.min(cellWidth, Number(size[0]) * cellWidth / monitorWidth(monitor)));
    }

    function tileHeight(client, monitor) {
        var size = client && client.size ? client.size : [360, 220];
        return Math.max(30, Math.min(cellHeight, Number(size[1]) * cellHeight / monitorHeight(monitor)));
    }

    function shortTitle(client) {
        var value = client ? (client.title || client.class || client.initialClass || "") : "";
        return value.length > 18 ? value.slice(0, 18) + "..." : value;
    }

    function focusWindow(client) {
        if (!client || !client.address)
            return;
        var address = String(client.address).toLowerCase();
        var selector = address.indexOf("0x") === 0 ? "address:" + address : "address:0x" + address;
        Hyprland.dispatch("hl.dsp.focus({ window = \"" + selector + "\" })");
        closeRequested();
    }

    function activateCell(row, column) {
        var specialName = specialNameForCell(row, column);
        if (specialName !== "") {
            Hyprland.dispatch("togglespecialworkspace", HyprlandSnapshotService.specialWorkspaceShortName(specialName));
            closeRequested();
            return;
        }
        Hyprland.dispatch("workspace", workspaceId(row, column).toString());
        closeRequested();
    }

    Column {
        anchors.fill: parent
        spacing: Theme.islandOverviewCellGap

        Repeater {
            model: root.rows

            delegate: Row {
                id: wsRow
                required property int index
                width: root.width
                height: root.cellHeight
                spacing: Theme.islandOverviewCellGap

                Repeater {
                    model: root.columns

                    delegate: Rectangle {
                        id: cell
                        required property int index
                        readonly property int rowIndex: wsRow.index
                        readonly property int wsId: root.workspaceId(rowIndex, index)
                        readonly property string specialName: root.specialNameForCell(rowIndex, index)
                        readonly property bool isSpecial: specialName !== ""
                        readonly property var windows: root.cellWindows(rowIndex, index)
                        readonly property bool active: isSpecial
                            ? specialName === HyprlandSnapshotService.activeSpecialWorkspaceName
                            : wsId === root.activeWorkspaceId
                        readonly property bool atLeft: index === 0
                        readonly property bool atRight: index === root.columns - 1
                        readonly property bool atTop: rowIndex === 0
                        readonly property bool atBottom: rowIndex === root.rows - 1
                        readonly property bool cellEnabled: rowIndex * root.columns + index < root.totalCells

                        width: root.cellWidth
                        height: root.cellHeight
                        visible: cellEnabled
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, mouseArea.containsMouse ? 0.12 : 0.07)
                        border.width: active ? 2 : Theme.borderWidth
                        border.color: active ? Theme.blue : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.62)
                        topLeftRadius: atLeft && atTop ? Theme.islandOverviewLargeRadius : Theme.islandOverviewSmallRadius
                        topRightRadius: atRight && atTop ? Theme.islandOverviewLargeRadius : Theme.islandOverviewSmallRadius
                        bottomLeftRadius: atLeft && atBottom ? Theme.islandOverviewLargeRadius : Theme.islandOverviewSmallRadius
                        bottomRightRadius: atRight && atBottom ? Theme.islandOverviewLargeRadius : Theme.islandOverviewSmallRadius
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            source: "file://" + Theme.overviewWallpaperPath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            opacity: 0.68
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, cell.active ? 0.30 : 0.44)
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: cell.isSpecial ? HyprlandSnapshotService.specialWorkspaceDisplayName(cell.specialName) : cell.wsId.toString()
                            role: cell.active ? "blue" : "fgDim"
                            font.family: Theme.fontFamilyUi
                            font.pixelSize: Math.max(34, Math.round(cell.height * 0.34))
                            font.bold: true
                            opacity: 0.7
                            z: 3
                        }

                        Item {
                            anchors.fill: parent
                            clip: true
                            z: 2

                            Repeater {
                                model: cell.windows

                                delegate: Item {
                                    id: tile
                                    required property var modelData

                                    readonly property var client: modelData
                                    readonly property var monitor: root.monitorForClient(client)
                                    readonly property var toplevel: root.toplevelForClient(client)
                                    property bool hovered: false
                                    property bool pressed: false

                                    x: Math.min(cell.width - width, root.tileX(client, monitor))
                                    y: Math.min(cell.height - height, root.tileY(client, monitor))
                                    width: root.tileWidth(client, monitor)
                                    height: root.tileHeight(client, monitor)
                                    z: client && client.fullscreen ? 5 : (client && client.floating ? 4 : 3)

                                    ClippingRectangle {
                                        anchors.fill: parent
                                        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.82)
                                        contentUnderBorder: true
                                        antialiasing: true
                                        topLeftRadius: Math.min(8, Math.max(4, tile.height / 6))
                                        topRightRadius: Math.min(8, Math.max(4, tile.height / 6))
                                        bottomLeftRadius: Math.min(8, Math.max(4, tile.height / 6))
                                        bottomRightRadius: Math.min(8, Math.max(4, tile.height / 6))
                                        border.width: Theme.borderWidth
                                        border.color: tile.hovered
                                            ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.46)
                                            : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.70)

                                        ScreencopyView {
                                            anchors.fill: parent
                                            captureSource: tile.toplevel !== null ? tile.toplevel : null
                                            constraintSize: Qt.size(Math.max(1, Math.round(tile.width)), Math.max(1, Math.round(tile.height)))
                                            live: tile.toplevel !== null
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: tile.pressed
                                                ? Qt.rgba(0, 0, 0, 0.25)
                                                : (tile.hovered ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(0, 0, 0, tile.toplevel !== null ? 0.04 : 0.16))
                                        }

                                        StyledText {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            text: root.shortTitle(tile.client)
                                            role: "fg"
                                            font.family: Theme.fontFamilyUi
                                            font.pixelSize: Math.max(9, Theme.fontSize - 3)
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                            visible: tile.toplevel === null
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onContainsMouseChanged: tile.hovered = containsMouse
                                        onPressed: tile.pressed = true
                                        onReleased: tile.pressed = false
                                        onCanceled: tile.pressed = false
                                        onClicked: root.focusWindow(tile.client)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            z: 1
                            onClicked: root.activateCell(cell.rowIndex, cell.index)
                        }
                    }
                }
            }
        }
    }
}
