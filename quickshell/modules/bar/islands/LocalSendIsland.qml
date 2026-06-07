import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    spacing: Math.round(Theme.islandGap / 2)

    function label() {
        switch (LocalSendService.mode) {
        case "scanning":
            return "Scanning";
        case "devices":
            return LocalSendService.devices.length + " devices";
        case "incoming":
            return LocalSendService.incomingRequest ? LocalSendService.incomingRequest.sender : "Incoming";
        case "sending":
            return "Sending";
        case "receiving":
            return "Receiving";
        case "complete":
            return "Complete";
        case "error":
            return "LocalSend";
        case "drop":
            return LocalSendService.hasFiles ? LocalSendService.selectedFiles.length + " files" : "Drop files";
        default:
            return "LocalSend";
        }
    }

    Icon {
        text: "\uE152"
        font.pixelSize: Theme.fontSize
        color: LocalSendService.mode === "error" ? Theme.yellow : Theme.fg
    }

    StyledText {
        text: label()
        role: LocalSendService.mode === "error" ? "yellow" : "fg"
        font.family: Theme.fontFamilyUi
        elide: Text.ElideRight
        Layout.maximumWidth: Theme.islandCompactModuleMinWidth + Theme.islandButtonSize
    }
}
