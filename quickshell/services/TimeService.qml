pragma Singleton
import QtQuick

Item {
    id: root
    property string text: Qt.formatDateTime(new Date(), "hh:mm:ss")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
    }
}
