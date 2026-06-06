import QtQuick
import "../services"

Text {
    // "fg" | "fgDim" | "accent" | "green" | "yellow" | "red" | "blue"
    property string role: "fg"

    color: {
        switch (role) {
        case "fgDim":
            return Theme.fgDim;
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
            return Theme.fg;
        }
    }

    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    verticalAlignment: Text.AlignVCenter
}
