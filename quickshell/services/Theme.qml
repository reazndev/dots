pragma Singleton
import QtQuick

QtObject {
    // Backgrounds
    property color bg: "#000109"
    property color bgTransparent: "transparent"
    property string overviewWallpaperPath: ""

    // Foregrounds
    property color fg: "#E6D9D9"
    property color fgDim: "#948686"

    // Accents
    property color accent: "#80717D"
    property color green: "#4F4950"
    property color yellow: "#45637F"
    property color red: "#00354D"
    property color blue: "#79899B"

    // Geometry
    property int barHeight: 36
    property int barMargin: 16
    property int radius: 10
    property int borderWidth: 1

    // Dynamic island geometry
    property int islandCompactHeight: 28
    property int islandCompactRadius: 14
    property int islandExpandedRadius: 18
    property int islandPadding: 14
    property int islandGap: 10
    property int islandButtonSize: 28
    property int islandAnimationDuration: 120

    property int islandCompactModuleMinWidth: 58

    property int islandClockWidth: 210
    property int islandClockHeight: 124

    property int islandMediaWidth: 340
    property int islandMediaHeight: 212
    property int islandAlbumSize: 96

    property int islandBluetoothWidth: 300
    property int islandBluetoothHeight: 140

    property int islandNotificationWidth: 380
    property int islandNotificationHeight: 320
    property int islandNotificationCompactWidth: 340
    property int islandNotificationCompactHeight: 52
    property int islandNotificationCompactRadius: 18
    property int islandNotificationCompactTextWidth: 232
    property int islandNotificationIconSize: 34
    property int islandNotificationRowMinHeight: 58

    property int islandLocalSendWidth: 360
    property int islandLocalSendHeight: 186
    property int islandLocalSendMaxHeight: 360
    property int islandLocalSendDropHeight: 76
    property int islandLocalSendDeviceHeight: 42

    property int islandOverviewCellWidth: 160
    property int islandOverviewCellHeight: 72
    property int islandOverviewCellGap: 8
    property int islandOverviewOuterPadding: 12
    property int islandOverviewSmallRadius: 6
    property int islandOverviewLargeRadius: 12

    // Opacity
    property real bgOpacity: 0.92

    // Border
    property color border: "#948686"

    // Typography
    property int fontSize: 13
    property int fontSizeLarge: 16
    property string fontFamily: "monospace"
    property string fontFamilyUi: "sans-serif"
    property string iconFontFamily: "lucide"
}
