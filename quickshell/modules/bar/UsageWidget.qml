import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    property var popup: null

    // Map provider name to a short abbreviation
    function abbrev(name) {
        switch (name) {
        case "claude": return "Cl";
        case "codex": return "Cd";
        case "copilot": return "Cp";
        case "kimi": return "Km";
        case "moonshot": return "Ms";
        case "antigravity": return "Ag";
        default: return name.substring(0, 2).toUpperCase();
        }
    }

    Row {
        id: row
        spacing: 6

        // Loading state
        StyledText {
            text: "..."
            role: "fgDim"
            visible: UsageTrackingService.isLoading
        }

        // Normal state — show most critical provider
        Row {
            spacing: 5
            visible: !UsageTrackingService.isLoading && UsageTrackingService.mostCriticalProvider !== ""

            // Colored status dot
            Rectangle {
                width: 7
                height: 7
                radius: 3.5
                color: UsageTrackingService.usageColor(UsageTrackingService.mostCriticalPercent)
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: {
                    var name = UsageTrackingService.mostCriticalProvider;
                    var pct = UsageTrackingService.mostCriticalPercent;
                    if (!name) return "";
                    return abbrev(name) + " " + Math.round(pct) + "%";
                }
                color: UsageTrackingService.usageColor(UsageTrackingService.mostCriticalPercent)
            }
        }

        // Error state — red dot when providers error but no rate data
        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: Theme.red
            visible: UsageTrackingService.hasErrors && UsageTrackingService.mostCriticalProvider === "" && !UsageTrackingService.isLoading
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            if (root.popup)
                root.popup.visible = !root.popup.visible;
        }
    }
}
