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
    property bool draggable: false
    property bool reordering: false
    property bool suppressNextClick: false
    property bool dragArmed: false
    property real pressSceneX: 0
    property real dragOffsetX: 0

    signal hovered(string label, bool active)
    signal activated()
    signal contextRequested()
    signal reorderStarted()
    signal reorderFinished(real sceneX)
    signal reorderCanceled()

    implicitWidth: themeData.buttonSize
    implicitHeight: themeData.buttonSize
    z: reordering ? 100 : 0
    opacity: reordering ? 0.88 : 1

    transform: Translate {
        x: root.dragOffsetX
    }

    Behavior on dragOffsetX {
        enabled: !root.reordering
        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity { NumberAnimation { duration: 90 } }

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
        scale: root.reordering
            ? 1.13
            : (pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1.0))

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

    Timer {
        id: reorderHoldTimer

        interval: 230
        repeat: false
        onTriggered: {
            if (!root.draggable || !root.dragArmed || !pointer.pressed) {
                return
            }
            root.reordering = true
            root.suppressNextClick = true
            root.reorderStarted()
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.reordering
            ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        preventStealing: true

        onContainsMouseChanged: root.hovered(root.app.name, containsMouse)
        onPressed: function(mouse) {
            if (mouse.button !== Qt.LeftButton || !root.draggable) {
                return
            }
            const point = root.mapToItem(null, mouse.x, mouse.y)
            root.pressSceneX = point.x
            root.dragOffsetX = 0
            root.suppressNextClick = false
            root.dragArmed = true
            reorderHoldTimer.restart()
        }
        onPositionChanged: function(mouse) {
            if (!root.draggable || !root.dragArmed || !pointer.pressed) {
                return
            }
            const point = root.mapToItem(null, mouse.x, mouse.y)
            const distance = point.x - root.pressSceneX
            if (!root.reordering && Math.abs(distance) >= 6) {
                reorderHoldTimer.stop()
                root.reordering = true
                root.suppressNextClick = true
                root.reorderStarted()
            }
            if (!root.reordering) {
                return
            }
            root.dragOffsetX = distance
        }
        onReleased: function(mouse) {
            reorderHoldTimer.stop()
            root.dragArmed = false
            if (mouse.button !== Qt.LeftButton || !root.reordering) {
                return
            }
            const point = root.mapToItem(null, mouse.x, mouse.y)
            root.reorderFinished(point.x)
            root.reordering = false
            root.dragOffsetX = 0
        }
        onCanceled: {
            reorderHoldTimer.stop()
            root.dragArmed = false
            if (root.reordering) {
                root.reordering = false
                root.dragOffsetX = 0
                root.suppressNextClick = false
                root.reorderCanceled()
            }
        }
        onClicked: function(mouse) {
            if (root.suppressNextClick) {
                root.suppressNextClick = false
                return
            }
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
