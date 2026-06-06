import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    spacing: 6

    // TODO: Connect to LocalSend / file transfer service
    // Replace static text with transfer progress / file name

    Icon {
        text: "\uE152"
        font.pixelSize: 12
        color: Theme.fg
    }

    StyledText {
        text: "LocalSend"
        role: "fg"
    }
}
