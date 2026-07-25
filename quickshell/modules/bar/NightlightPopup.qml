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
            text: "Nightlight"
            font.pixelSize: Theme.fontSizeLarge
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // Toggle row
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Enabled"
                role: "fg"
            }
            Item {
                Layout.fillWidth: true
            }
            Toggle {
                checked: NightlightService.enabled
                onToggled: NightlightService.toggle()
            }
        }

        // Temperature display
        RowLayout {
            Layout.fillWidth: true
            visible: NightlightService.enabled
            StyledText {
                text: "  Temperature"
                font.family: Theme.iconFontFamily
                role: "fg"
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: NightlightService.temperature + "K"
                role: "fgDim"
            }
        }

        // Temperature adjustment buttons
        RowLayout {
            Layout.fillWidth: true
            visible: NightlightService.enabled
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: Theme.radius
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
                border.color: Theme.border
                border.width: Theme.borderWidth

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NightlightService.decreaseTemperature()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: "  Warmer"
                    font.family: Theme.iconFontFamily
                    role: "fg"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: Theme.radius
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
                border.color: Theme.border
                border.width: Theme.borderWidth

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NightlightService.increaseTemperature()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: "  Cooler"
                    font.family: Theme.iconFontFamily
                    role: "fg"
                }
            }
        }

        // Status/info text
        StyledText {
            Layout.fillWidth: true
            text: NightlightService.enabled
                ? "Profiles: 6:00 normal · 18:00 warm · 22:00 very warm"
                : "Click toggle or icon to enable nightlight"
            role: "fgDim"
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}
