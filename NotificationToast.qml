import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var themeData
    required property var notification
    required property real barX
    required property real barY
    required property real barWidth

    signal finished()

    function iconSource() {
        const value = String(notification && notification.appIcon
            ? notification.appIcon : "")
        if (value.indexOf("file:") === 0 || value.indexOf("data:") === 0) {
            return value
        }
        if (value.indexOf("/") === 0) {
            return "file://" + value
        }
        return Quickshell.iconPath(value, "dialog-information")
    }

    function restartTimeout() {
        const requested = notification ? Number(notification.expireTimeout) : 0
        toastTimer.interval = notification && notification.urgency === 2
            ? 10000 : (requested > 0 ? Math.max(2500, requested * 1000) : 5200)
        toastTimer.restart()
    }

    onNotificationChanged: restartTimeout()
    Component.onCompleted: restartTimeout()

    Rectangle {
        id: toast
        x: root.barX + root.barWidth - width - 8
        y: root.barY - 8 - height
        width: 360
        height: notification.actions.length > 0 ? 126 : 98
        radius: root.themeData.radius
        color: Qt.rgba(root.themeData.base.r, root.themeData.base.g,
            root.themeData.base.b, 0.99)
        border.width: 1
        border.color: notification.urgency === 2
            ? root.themeData.red
            : Qt.rgba(root.themeData.surface2.r, root.themeData.surface2.g,
                root.themeData.surface2.b, 0.86)

        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 160
            easing.type: Easing.OutCubic
        }

        IconImage {
            id: toastIcon
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 13
                topMargin: 13
            }
            implicitSize: 30
            source: root.iconSource()
            mipmap: true
        }

        Text {
            id: toastApp
            anchors {
                left: toastIcon.right
                right: toastClose.left
                top: parent.top
                leftMargin: 10
                rightMargin: 8
                topMargin: 11
            }
            text: notification.appName || "Application"
            color: root.themeData.overlay
            elide: Text.ElideRight
            font.family: root.themeData.fontFamily
            font.pixelSize: 8
        }

        Text {
            anchors {
                left: toastApp.left
                right: toastClose.left
                top: toastApp.bottom
                rightMargin: 8
                topMargin: 3
            }
            text: notification.summary || "Notification"
            color: root.themeData.text
            elide: Text.ElideRight
            font.family: root.themeData.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        Rectangle {
            id: toastClose
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 9
                topMargin: 9
            }
            width: 25
            height: 25
            radius: 8
            color: toastClosePointer.containsMouse
                ? Qt.rgba(root.themeData.red.r, root.themeData.red.g,
                    root.themeData.red.b, 0.22)
                : "transparent"

            Text {
                anchors.centerIn: parent
                text: "×"
                color: root.themeData.red
                font.family: root.themeData.fontFamily
                font.pixelSize: 16
            }

            MouseArea {
                id: toastClosePointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    notification.dismiss()
                    root.finished()
                }
            }
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                top: toastIcon.bottom
                leftMargin: 13
                rightMargin: 13
                topMargin: 8
            }
            text: notification.body || ""
            textFormat: Text.PlainText
            color: root.themeData.subtext
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
            font.family: root.themeData.fontFamily
            font.pixelSize: 9
        }

        Row {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 12
                rightMargin: 12
                bottomMargin: 9
            }
            height: 26
            spacing: 6
            visible: notification.actions.length > 0

            Repeater {
                model: notification.actions.slice(0, 2)

                Rectangle {
                    required property var modelData
                    width: Math.min(150, Math.max(76, actionLabel.implicitWidth + 20))
                    height: 26
                    radius: 8
                    color: toastActionPointer.containsMouse
                        ? root.themeData.mauve : root.themeData.surface0

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: parent.modelData.text || "Open"
                        color: toastActionPointer.containsMouse
                            ? root.themeData.crust : root.themeData.subtext
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 8
                    }

                    MouseArea {
                        id: toastActionPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            parent.modelData.invoke()
                            root.finished()
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: toastTimer
        onTriggered: {
            if (root.notification && root.notification.transient) {
                root.notification.expire()
            }
            root.finished()
        }
    }

    Connections {
        target: root.notification
        ignoreUnknownSignals: true
        function onClosed() { root.finished() }
    }
}
