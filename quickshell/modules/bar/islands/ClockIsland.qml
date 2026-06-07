import QtQuick
import "../../../services"
import "../../../components"

StyledText {
    text: TimeService.text
    role: "fg"
    font.family: Theme.fontFamilyUi
    font.pixelSize: Theme.fontSizeLarge
    font.bold: true
}
