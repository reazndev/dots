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

    property var popupWindow: null

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
        spacing: 12

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
                    text: NightlightService.enabled ? "" : ""
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 16
                    color: Theme.mdOnPrimaryContainer
                }
            }

            StyledText {
                text: "Nightlight"
                font.family: Theme.fontFamilyUi
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.mdOnSurface
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.mdOutlineVariant
            opacity: 0.55
        }

        // Toggle row
        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 16
            color: toggleRowArea.pressed
                ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdPressedState)
                : (toggleRowArea.containsMouse
                    ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdHoverState)
                    : Theme.mdSurfaceContainer)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.mdMotionShort
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                StyledText {
                    text: "Enabled"
                    font.family: Theme.fontFamilyUi
                    color: Theme.mdOnSurface
                }
                Item {
                    Layout.fillWidth: true
                }
                Toggle {
                    checked: NightlightService.enabled
                    onToggled: NightlightService.toggle()
                }
            }

            MouseArea {
                id: toggleRowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NightlightService.toggle()
            }
        }

        // Temperature display
        Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: 16
            color: Theme.mdSurfaceContainer
            visible: NightlightService.enabled

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                StyledText {
                    text: ""
                    font.family: Theme.iconFontFamily
                    color: Theme.mdOnSurface
                }
                StyledText {
                    text: "Temperature"
                    font.family: Theme.fontFamilyUi
                    color: Theme.mdOnSurface
                }
                Item {
                    Layout.fillWidth: true
                }
                StyledText {
                    text: NightlightService.temperature + "K"
                    font.family: Theme.fontFamilyUi
                    color: Theme.mdOnSurfaceVariant
                }
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
                radius: 16
                color: warmerArea.pressed
                    ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdPressedState)
                    : (warmerArea.containsMouse
                        ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdHoverState)
                        : Theme.mdSurfaceContainerHigh)

                MouseArea {
                    id: warmerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NightlightService.decreaseTemperature()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: "  Warmer"
                    font.family: Theme.iconFontFamily
                    color: Theme.mdOnSurface
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 16
                color: coolerArea.pressed
                    ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdPressedState)
                    : (coolerArea.containsMouse
                        ? Qt.rgba(Theme.mdPrimary.r, Theme.mdPrimary.g, Theme.mdPrimary.b, Theme.mdHoverState)
                        : Theme.mdSurfaceContainerHigh)

                MouseArea {
                    id: coolerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NightlightService.increaseTemperature()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: "  Cooler"
                    font.family: Theme.iconFontFamily
                    color: Theme.mdOnSurface
                }
            }
        }

        // Status/info text
        StyledText {
            Layout.fillWidth: true
            text: NightlightService.enabled
                ? "Profiles: 6:00 normal · 18:00 warm · 22:00 very warm"
                : "Click toggle or icon to enable nightlight"
            font.family: Theme.fontFamilyUi
            color: Theme.mdOnSurfaceVariant
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}
