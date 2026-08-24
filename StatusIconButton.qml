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

    signal activated()

    implicitWidth: themeData.buttonSize
    implicitHeight: themeData.buttonSize

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
            scale: pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1)

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
            scale: pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1)

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
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.activated()
    }
}
