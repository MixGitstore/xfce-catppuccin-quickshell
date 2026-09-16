import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var themeData
    property string iconName: "dialog-information"
    property string fallbackIcon: "dialog-information"
    property string glyph: ""
    property color glyphColor: themeData.lavender
    property bool open: false
    property bool available: true
    property int count: 0
    property bool draggable: false
    property bool reordering: false
    property bool suppressNextClick: false
    property bool dragArmed: false
    property real pressSceneX: 0
    property real dragOffsetX: 0

    signal activated()
    signal reorderStarted()
    signal reorderFinished(real sceneX)
    signal reorderCanceled()

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

    Rectangle {
        anchors.centerIn: parent
        width: 31
        height: 31
        radius: 10
        color: pointer.containsMouse || root.open
            ? root.themeData.surface1 : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }

        IconImage {
            anchors.centerIn: parent
            implicitSize: root.themeData.quickActionIconSize
            source: Quickshell.iconPath(root.iconName, root.fallbackIcon)
            visible: root.glyph.length === 0
            mipmap: true
            opacity: root.available ? 1 : 0.45
            scale: root.reordering
                ? 1.13
                : (pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1))

            Behavior on opacity { NumberAnimation { duration: 100 } }
            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.glyph.length > 0
            text: root.glyph
            color: pointer.containsMouse || root.open
                ? root.themeData.mauve : root.glyphColor
            font.family: root.themeData.monoFamily
            font.pixelSize: 16
            font.weight: Font.DemiBold
            scale: root.reordering
                ? 1.13
                : (pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1))

            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: -2
                topMargin: -3
            }
            width: Math.max(14, countLabel.implicitWidth + 6)
            height: 14
            radius: 7
            color: root.themeData.red
            visible: root.count > 0

            Text {
                id: countLabel
                anchors.centerIn: parent
                text: root.count > 99 ? "99+" : String(root.count)
                color: root.themeData.crust
                font.family: root.themeData.monoFamily
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
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
        color: root.themeData.mauve
        opacity: root.open ? 1 : 0

        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
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
        }
        onPositionChanged: function(mouse) {
            if (!root.draggable || !root.dragArmed || !pointer.pressed) {
                return
            }
            const point = root.mapToItem(null, mouse.x, mouse.y)
            const distance = point.x - root.pressSceneX
            if (!root.reordering && Math.abs(distance) >= 12) {
                root.reordering = true
                root.suppressNextClick = true
                root.reorderStarted()
            }
            if (root.reordering) {
                root.dragOffsetX = distance
            }
        }
        onReleased: function(mouse) {
            root.dragArmed = false
            if (mouse.button !== Qt.LeftButton || !root.reordering) {
                return
            }
            const point = root.mapToItem(null, mouse.x, mouse.y)
            root.reorderFinished(point.x)
            root.reordering = false
            root.dragOffsetX = 0
            Qt.callLater(function() {
                root.suppressNextClick = false
            })
        }
        onCanceled: {
            root.dragArmed = false
            if (root.reordering) {
                root.reordering = false
                root.dragOffsetX = 0
                root.suppressNextClick = false
                root.reorderCanceled()
            }
        }
        onClicked: {
            if (root.suppressNextClick) {
                root.suppressNextClick = false
                return
            }
            root.activated()
        }
    }
}
