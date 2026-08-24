import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var themeData
    required property var notificationState
    required property real barX
    required property real barY
    required property real barWidth

    signal closeRequested()
    signal tabRequested(string tab)

    function iconSource(notification) {
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

    ScriptModel {
        id: notificationModel
        values: root.notificationState.notifications.slice().reverse()
    }

    MouseArea {
        x: 0
        y: 0
        width: root.width
        height: Math.max(0, root.barY)
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: popup
        x: root.barX + root.barWidth - width - 8
        y: root.barY - 8 - height
        width: 370
        height: 390
        radius: root.themeData.radius
        color: Qt.rgba(root.themeData.base.r, root.themeData.base.g,
            root.themeData.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(root.themeData.surface2.r, root.themeData.surface2.g,
            root.themeData.surface2.b, 0.82)
        clip: true

        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }

        Item {
            id: header
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            height: 36

            Row {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                spacing: 4

                Rectangle {
                    width: 76
                    height: 28
                    radius: 9
                    color: networkTabPointer.containsMouse
                        ? root.themeData.surface0 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Network"
                        color: root.themeData.subtext
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: networkTabPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabRequested("network")
                    }
                }

                Rectangle {
                    width: 82
                    height: 28
                    radius: 9
                    color: root.themeData.surface1
                    border.width: 1
                    border.color: root.themeData.mauve

                    Text {
                        anchors.centerIn: parent
                        text: "Notifications"
                        color: root.themeData.mauve
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: 76
                height: 28
                radius: 9
                visible: root.notificationState.count > 0
                color: clearPointer.containsMouse
                    ? root.themeData.surface1 : root.themeData.surface0

                Text {
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: root.themeData.subtext
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 9
                }

                MouseArea {
                    id: clearPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notificationState.clearAll()
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: notificationList.count === 0
            text: "No notifications"
            color: root.themeData.overlay
            font.family: root.themeData.fontFamily
            font.pixelSize: 11
        }

        ListView {
            id: notificationList
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                bottom: parent.bottom
                leftMargin: 9
                rightMargin: 9
                topMargin: 7
                bottomMargin: 10
            }
            model: notificationModel
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: notificationList.width
                height: modelData.actions.length > 0 ? 116 : 88
                radius: 11
                color: notificationPointer.containsMouse
                    ? root.themeData.surface1 : root.themeData.mantle
                border.width: 1
                border.color: modelData.urgency === 2
                    ? root.themeData.red : root.themeData.surface0

                Behavior on color { ColorAnimation { duration: 100 } }

                IconImage {
                    id: notificationIcon
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: 11
                        topMargin: 11
                    }
                    implicitSize: 27
                    source: root.iconSource(parent.modelData)
                    mipmap: true
                }

                Text {
                    id: appNameLabel
                    anchors {
                        left: notificationIcon.right
                        right: closeButton.left
                        top: parent.top
                        leftMargin: 9
                        rightMargin: 7
                        topMargin: 9
                    }
                    text: modelData.appName || "Application"
                    color: root.themeData.overlay
                    elide: Text.ElideRight
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 8
                }

                Text {
                    anchors {
                        left: appNameLabel.left
                        right: closeButton.left
                        top: appNameLabel.bottom
                        rightMargin: 7
                        topMargin: 2
                    }
                    text: modelData.summary || "Notification"
                    color: root.themeData.text
                    elide: Text.ElideRight
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    id: closeButton
                    anchors {
                        right: parent.right
                        top: parent.top
                        rightMargin: 8
                        topMargin: 8
                    }
                    width: 24
                    height: 24
                    radius: 8
                    color: closePointer.containsMouse
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
                        id: closePointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.modelData.dismiss()
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: notificationIcon.bottom
                        leftMargin: 11
                        rightMargin: 11
                        topMargin: 7
                    }
                    text: modelData.body || ""
                    textFormat: Text.PlainText
                    color: root.themeData.subtext
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 9
                }

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 10
                        rightMargin: 10
                        bottomMargin: 8
                    }
                    height: 25
                    spacing: 6
                    visible: modelData.actions.length > 0

                    Repeater {
                        model: modelData.actions.slice(0, 2)

                        Rectangle {
                            required property var modelData
                            width: Math.min(145, Math.max(72, actionText.implicitWidth + 18))
                            height: 25
                            radius: 8
                            color: actionPointer.containsMouse
                                ? root.themeData.mauve : root.themeData.surface0

                            Text {
                                id: actionText
                                anchors.centerIn: parent
                                text: parent.modelData.text || "Open"
                                color: actionPointer.containsMouse
                                    ? root.themeData.crust : root.themeData.subtext
                                font.family: root.themeData.fontFamily
                                font.pixelSize: 8
                            }

                            MouseArea {
                                id: actionPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: parent.modelData.invoke()
                            }
                        }
                    }
                }

                MouseArea {
                    id: notificationPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }
}
