import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var app
    // Avoid Qt's built-in palette name, which is a QPalette rather than Theme.qml.
    required property var themeData
    property bool accent: false
    property bool launchOnClick: true
    property bool running: false
    property bool active: false

    signal hovered(string label, bool active)
    signal activated()
    signal contextRequested()

    implicitWidth: themeData.buttonSize
    implicitHeight: themeData.buttonSize

    IconImage {
        id: appIcon

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        implicitSize: root.app.iconSize || themeData.iconSize
        source: root.app.iconSource
            ? (String(root.app.iconSource).indexOf("assets/") === 0
                ? "file://" + Quickshell.shellDir + "/" + root.app.iconSource
                : root.app.iconSource)
            : Quickshell.iconPath(root.app.icon, "application-x-executable")
        mipmap: true
        scale: pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1.0)

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 1
        }
        width: root.active ? 13 : 5
        height: 3
        radius: 2
        color: root.active ? themeData.mauve : themeData.lavender
        visible: root.running

        Behavior on width {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color { ColorAnimation { duration: 110 } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onContainsMouseChanged: root.hovered(root.app.name, containsMouse)
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.contextRequested()
            } else {
                root.activated()
                if (root.launchOnClick) {
                    Quickshell.execDetached(root.app.command)
                }
            }
        }
    }
}
