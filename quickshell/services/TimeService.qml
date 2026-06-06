pragma Singleton
import QtQuick

Item {
    id: root
    property string text: Qt.formatDateTime(new Date(), "hh:mm:ss")
    property string shortText: Qt.formatDateTime(new Date(), "hh:mm")
    property string dateText: Qt.formatDateTime(new Date(), "ddd, MMM dd")

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            root.text = Qt.formatDateTime(now, "hh:mm:ss");
            root.shortText = Qt.formatDateTime(now, "hh:mm");
            root.dateText = Qt.formatDateTime(now, "ddd, MMM dd");
        }
    }
}
