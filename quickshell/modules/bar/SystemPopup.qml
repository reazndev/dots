import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"

Rectangle {
    id: root

    anchors.fill: parent
    color: Theme.mdSurface
    border.color: Theme.mdOutlineVariant
    border.width: Theme.borderWidth
    radius: 24
    clip: true
    opacity: parent && parent.visible ? 1 : 0
    scale: parent && parent.visible ? 1 : 0.96

    property string selectedMetric: "cpu"
    property var popupWindow: null

    function tempRole(temp) {
        return temp > 80 ? "red" : (temp > 60 ? "yellow" : "green");
    }

    function statusText() {
        switch (selectedMetric) {
        case "cpu":
            return "CPU " + SystemMonitorService.cpuUsage + "% · " + SystemMonitorService.cpuTemp + "°C";
        case "ram":
            return "RAM " + SystemMonitorService.ramUsage + "% in use";
        case "gpu":
            return "GPU " + SystemMonitorService.gpuUsage + "% · " + SystemMonitorService.gpuTemp + "°C";
        default:
            return "";
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.mdMotionMedium
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.mdMotionMedium
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (!root.popupWindow)
                return;
            root.popupWindow.hovered = hovered;
            if (!hovered)
                root.popupWindow.requestClose();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: Theme.mdPrimaryContainer

                StyledText {
                    anchors.centerIn: parent
                    text: "\uE0A9"
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 16
                    color: Theme.mdOnPrimaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    text: "System"
                    font.family: Theme.fontFamilyUi
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.mdOnSurface
                }

                StyledText {
                    text: root.statusText()
                    font.family: Theme.fontFamilyUi
                    font.pixelSize: 11
                    color: Theme.mdOnSurfaceVariant
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.mdOutlineVariant
            opacity: 0.55
        }

        MetricRow {
            Layout.fillWidth: true
            metricId: "cpu"
            iconText: "\uE0A9"
            title: "CPU"
            subtitle: SystemMonitorService.cpuTemp + "°C"
            subtitleRole: root.tempRole(SystemMonitorService.cpuTemp)
            value: SystemMonitorService.cpuUsage
            selected: root.selectedMetric === metricId
            onActivated: root.selectedMetric = metricId
        }

        MetricRow {
            Layout.fillWidth: true
            metricId: "ram"
            iconText: "\uE445"
            title: "Memory"
            subtitle: SystemMonitorService.ramUsage + "%"
            subtitleRole: "fgDim"
            value: SystemMonitorService.ramUsage
            selected: root.selectedMetric === metricId
            onActivated: root.selectedMetric = metricId
        }

        MetricRow {
            Layout.fillWidth: true
            metricId: "gpu"
            iconText: "\uE66A"
            title: "GPU"
            subtitle: SystemMonitorService.gpuTemp + "°C"
            subtitleRole: root.tempRole(SystemMonitorService.gpuTemp)
            value: SystemMonitorService.gpuUsage
            selected: root.selectedMetric === metricId
            onActivated: root.selectedMetric = metricId
        }
    }

    component MetricRow: Rectangle {
        id: rowRoot

        property string metricId: ""
        property string iconText: ""
        property string title: ""
        property string subtitle: ""
        property string subtitleRole: "fgDim"
        property int value: 0
        property bool selected: false
        signal activated()

        function colorForRole(roleName) {
            switch (roleName) {
            case "fgDim":
                return Theme.mdOnSurfaceVariant;
            case "accent":
                return Theme.accent;
            case "green":
                return Theme.green;
            case "yellow":
                return Theme.yellow;
            case "red":
                return Theme.red;
            case "blue":
                return Theme.blue;
            default:
                return Theme.mdOnSurface;
            }
        }

        implicitHeight: 48
        radius: 16
        color: selected
            ? Theme.mdPrimaryContainer
            : (mouseArea.pressed
                ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdPressedState)
                : (mouseArea.containsMouse
                    ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdHoverState)
                    : Theme.mdSurfaceContainer))
        border.width: selected || mouseArea.containsMouse ? 1 : 0
        border.color: selected ? Theme.mdPrimary : Theme.mdOutlineVariant
        scale: mouseArea.pressed ? 0.985 : 1.0

        Behavior on color {
            ColorAnimation {
                duration: Theme.mdMotionShort
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.mdMotionShort
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            StyledText {
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
                text: rowRoot.iconText
                font.family: Theme.iconFontFamily
                font.pixelSize: 15
                color: rowRoot.selected ? Theme.mdOnPrimaryContainer : Theme.mdOnSurface
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        Layout.fillWidth: true
                        text: rowRoot.title
                        font.family: Theme.fontFamilyUi
                        color: rowRoot.selected ? Theme.mdOnPrimaryContainer : Theme.mdOnSurface
                    }

                    StyledText {
                        text: rowRoot.subtitle
                        color: rowRoot.selected ? Theme.mdOnPrimaryContainer : rowRoot.colorForRole(rowRoot.subtitleRole)
                        font.family: Theme.fontFamilyUi
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: rowRoot.selected
                        ? Qt.rgba(Theme.mdOnPrimaryContainer.r, Theme.mdOnPrimaryContainer.g, Theme.mdOnPrimaryContainer.b, 0.22)
                        : Theme.mdOutlineVariant

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.min(rowRoot.value, 100) / 100
                        radius: parent.radius
                        color: rowRoot.selected ? Theme.mdOnPrimaryContainer : Theme.mdPrimary

                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.mdMotionMedium
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rowRoot.activated()
        }
    }
}
