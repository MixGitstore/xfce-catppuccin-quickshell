import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var themeData
    property real volume: 0
    property bool muted: false
    property bool available: false
    property bool open: false

    signal activated()
    signal muteRequested()
    signal mixerRequested()
    signal volumeStepRequested(real step)

    readonly property string iconSource: {
        const base = "file://" + Quickshell.shellDir + "/assets/icons/"
        if (!available || muted || volume <= 0.001) {
            return base + "catppuccin-volume-muted.svg"
        }
        if (volume < 0.34) {
            return base + "catppuccin-volume-low.svg"
        }
        if (volume < 0.67) {
            return base + "catppuccin-volume-medium.svg"
        }
        return base + "catppuccin-volume-high.svg"
    }

    implicitWidth: themeData.buttonSize
    implicitHeight: themeData.buttonSize

    IconImage {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        implicitSize: themeData.quickActionIconSize
        source: root.iconSource
        mipmap: true
        opacity: root.available ? 1 : 0.45
        scale: pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1.0)

        Behavior on opacity { NumberAnimation { duration: 100 } }
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 1
        }
        width: root.open ? 12 : 4
        height: 2
        radius: 1
        color: root.muted ? themeData.red : themeData.mauve
        opacity: root.open || root.muted ? 1 : 0

        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 100 } }
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                root.muteRequested()
            } else if (mouse.button === Qt.RightButton) {
                root.mixerRequested()
            } else {
                root.activated()
            }
        }

        onWheel: function(wheel) {
            const direction = wheel.angleDelta.y > 0 ? 1 : -1
            root.volumeStepRequested(direction * 0.05)
            wheel.accepted = true
        }
    }
}
