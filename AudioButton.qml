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
    property bool draggable: false
    property bool reordering: false
    property bool suppressNextClick: false
    property bool dragArmed: false
    property real pressSceneX: 0
    property real dragOffsetX: 0

    signal activated()
    signal muteRequested()
    signal mixerRequested()
    signal volumeStepRequested(real step)
    signal reorderStarted()
    signal reorderFinished(real sceneX)
    signal reorderCanceled()

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
    z: reordering ? 100 : 0
    opacity: reordering ? 0.88 : 1

    transform: Translate { x: root.dragOffsetX }

    Behavior on dragOffsetX {
        enabled: !root.reordering
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }
    Behavior on opacity { NumberAnimation { duration: 90 } }

    IconImage {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        implicitSize: themeData.quickActionIconSize
        source: root.iconSource
        mipmap: true
        opacity: root.available ? 1 : 0.45
        scale: root.reordering
            ? 1.13
            : (pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1.0))

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
        enabled: root.available
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: root.reordering
            ? Qt.ClosedHandCursor
            : (root.available ? Qt.PointingHandCursor : Qt.ArrowCursor)
        preventStealing: true

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
            if (root.reordering) {
                root.dragOffsetX = distance
            }
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
