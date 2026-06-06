import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

RowLayout {
    spacing: 6

    // TODO: Connect to messaging service (Discord, Telegram, etc.)
    // Replace static text with unread message count / latest sender

    Icon {
        text: "\uE116"
        font.pixelSize: 12
        color: Theme.fg
    }

    StyledText {
        text: "Messages"
        role: "fg"
    }
}
