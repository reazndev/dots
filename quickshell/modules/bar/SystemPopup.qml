import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"

Rectangle {
    anchors.fill: parent
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth
    radius: Theme.radius

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        StyledText {
            text: "System"
            font.pixelSize: Theme.fontSizeLarge
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // CPU temp
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "\uE0A9  CPU"
                font.family: Theme.iconFontFamily
                role: "fg"
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: SystemMonitorService.cpuTemp + "°C"
                role: SystemMonitorService.cpuTemp > 80 ? "red" : (SystemMonitorService.cpuTemp > 60 ? "yellow" : "green")
            }
        }

        // GPU temp
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "\uE66A  GPU"
                font.family: Theme.iconFontFamily
                role: "fg"
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: SystemMonitorService.gpuTemp + "°C"
                role: SystemMonitorService.gpuTemp > 80 ? "red" : (SystemMonitorService.gpuTemp > 60 ? "yellow" : "green")
            }
        }

        // CPU usage
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "\uE0A9  CPU Usage"
                font.family: Theme.iconFontFamily
                role: "fg"
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: SystemMonitorService.cpuUsage + "%"
                role: "fgDim"
            }
        }

        // RAM usage
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "\uE445  RAM Usage"
                font.family: Theme.iconFontFamily
                role: "fg"
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: SystemMonitorService.ramUsage + "%"
                role: "fgDim"
            }
        }

        // GPU usage
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "\uE66A  GPU Usage"
                font.family: Theme.iconFontFamily
                role: "fg"
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: SystemMonitorService.gpuUsage + "%"
                role: "fgDim"
            }
        }
    }
}
