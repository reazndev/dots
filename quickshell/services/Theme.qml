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
}
