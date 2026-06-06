import QtQuick
import "../services"

Item {
    id: root
    property alias source: img.source
    property alias fillMode: img.fillMode
    property alias cache: img.cache
    property alias status: img.status
    property url maskSource

    implicitWidth: 22
    implicitHeight: 22

    Image {
        id: img
        anchors.fill: parent
        cache: false
        fillMode: Image.PreserveAspectCrop
    }

    Image {
        anchors.fill: parent
        source: root.maskSource
        cache: false
    }
}
