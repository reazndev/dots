pragma Singleton
import QtQuick

QtObject {
    // Backgrounds
    property color bg: "#171919"
    property color bgTransparent: "transparent"

    // Foregrounds
    property color fg: "#FCFAE7"
    property color fgDim: "#A9A895"

    // Accents
    property color accent: "#9BA296"
    property color green: "#5B605A"
    property color yellow: "#A37662"
    property color red: "#462A26"
    property color blue: "#ECA747"

    // Geometry
    property int barHeight: 36
    property int barMargin: 16
    property int radius: 10
    property int borderWidth: 1
    property int islandCompactHeight: 28
    property int islandCompactRadius: 14
    property int islandExpandedRadius: 32
    property int islandNotificationCompactRadius: 22
    property int islandPadding: 14
    property int islandGap: 10
    property int islandButtonSize: 32
    property int islandAlbumSize: 58
    property int islandOverviewCellWidth: 138
    property int islandOverviewCellHeight: 82
    property int islandOverviewCellGap: 6
    property int islandOverviewOuterPadding: 14
    property int islandOverviewLargeRadius: 30
    property int islandOverviewSmallRadius: 16
    property int islandAnimationDuration: 180
    property int islandNotificationWidth: 380
    property int islandNotificationHeight: 300
    property int islandNotificationCompactWidth: 330
    property int islandNotificationCompactHeight: 48
    property int islandNotificationCompactTextWidth: 230
    property int islandNotificationIconSize: 34
    property int islandNotificationRowMinHeight: 58
    property int islandCompactModuleMinWidth: 82
    property int islandMediaWidth: 380
    property int islandMediaHeight: 178
    property int islandBluetoothWidth: 340
    property int islandBluetoothHeight: 156
    property int islandClockWidth: 220
    property int islandClockHeight: 96

    // Opacity
    property real bgOpacity: 0.92

    // Border
    property color border: "#A9A895"

    // Typography
    property int fontSize: 13
    property int fontSizeLarge: 16
    property string fontFamily: "monospace"
    property string fontFamilyUi: "sans-serif"
    property string iconFontFamily: "lucide"

    // Assets
    property string overviewWallpaperPath: "/home/reazn/Pictures/Wallpaper/441980-ultrawide-painting-oil-painting-canvas-artwork-1610770620.jpg"
}
