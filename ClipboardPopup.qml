import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var host
    required property var themeData
    required property var barItem
    MouseArea {
        id: clipboardDismissArea

        x: 0
        y: 0
        width: host.width
        height: Math.max(0, barItem.y)
        visible: host.clipboardOpen
        z: 18
        onClicked: host.closeClipboard()
    }

    Rectangle {
        id: clipboardPopup

        x: barItem.x + barItem.width - width - 84
        y: barItem.y - 8 - height
        width: 360
        height: host.clipboardPopupHeight
        radius: themeData.radius
        color: Qt.rgba(themeData.base.r, themeData.base.g, themeData.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(themeData.surface2.r, themeData.surface2.g, themeData.surface2.b, 0.82)
        property bool entered: false
        opacity: entered && host.clipboardOpen ? 1 : 0
        scale: entered && host.clipboardOpen ? 1 : 0.96
        transformOrigin: Item.BottomRight
        visible: opacity > 0
        clip: true
        z: 20

        Component.onCompleted: Qt.callLater(function() { entered = true })

        Behavior on opacity {
NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
        }

        Column {
anchors {
    fill: parent
    margins: 14
}
spacing: 9

Item {
    width: parent.width
    height: 38

    Row {
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        spacing: 9

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 22
            source: host.clipboardAction.iconSource
            mipmap: true
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -1

            Text {
                text: "Clipboard"
                color: themeData.text
                font.family: themeData.fontFamily
                font.pixelSize: 13
                font.weight: Font.Normal
            }

            Text {
                text: host.clipboardItems.length === 1
                    ? "1 item in the current session"
                    : host.clipboardItems.length + " items in the current session"
                color: themeData.overlay
                font.family: themeData.fontFamily
                font.pixelSize: 8
                font.weight: Font.Normal
            }
        }
    }

    Rectangle {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: 66
        height: 28
        radius: 8
        visible: host.clipboardItems.length > 0
        color: clearClipboardPointer.containsMouse
            ? Qt.rgba(themeData.red.r, themeData.red.g, themeData.red.b, 0.18)
            : themeData.surface0

        Text {
            anchors.centerIn: parent
            text: "Clear"
            color: clearClipboardPointer.containsMouse ? themeData.red : themeData.subtext
            font.family: themeData.fontFamily
            font.pixelSize: 9
            font.weight: Font.Normal
        }

        MouseArea {
            id: clearClipboardPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: host.clearClipboardHistory()
        }
    }
}

Rectangle {
    width: parent.width
    height: 1
    color: themeData.surface0
}

Item {
    width: parent.width
    height: 236

    ListView {
        id: clipboardList

        anchors.fill: parent
        clip: true
        spacing: 5
        model: host.clipboardItems
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property var modelData
            required property int index

            width: clipboardList.width
            height: 42
            radius: 10
            color: clipboardItemPointer.containsMouse
                ? themeData.surface1 : themeData.surface0
            border.width: 1
            border.color: index === 0
                ? Qt.rgba(themeData.mauve.r, themeData.mauve.g, themeData.mauve.b, 0.75)
                : Qt.rgba(themeData.surface2.r, themeData.surface2.g, themeData.surface2.b, 0.45)

            Behavior on color { ColorAnimation { duration: 90 } }

            Rectangle {
                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                width: 24
                height: 24
                radius: 7
                color: parent.index === 0
                    ? Qt.rgba(themeData.mauve.r, themeData.mauve.g, themeData.mauve.b, 0.22)
                    : themeData.surface1

                Text {
                    anchors.centerIn: parent
                    text: String(parent.parent.index + 1)
                    color: parent.parent.index === 0 ? themeData.mauve : themeData.overlay
                    font.family: themeData.monoFamily
                    font.pixelSize: 9
                    font.weight: Font.Normal
                }
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: 40
                    right: deleteClipboardButton.left
                    rightMargin: 7
                    verticalCenter: parent.verticalCenter
                }
                spacing: -1

                Text {
                    width: parent.width
                    text: host.clipboardPreview(parent.parent.modelData.text)
                    color: themeData.text
                    elide: Text.ElideRight
                    font.family: themeData.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Normal
                }

                Text {
                    text: parent.parent.index === 0
                        ? "Current clipboard" : "Click to select"
                    color: parent.parent.index === 0 ? themeData.mauve : themeData.overlay
                    font.family: themeData.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.Normal
                }
            }

            Rectangle {
                id: deleteClipboardButton
                anchors {
                    right: parent.right
                    rightMargin: 7
                    verticalCenter: parent.verticalCenter
                }
                width: 26
                height: 26
                radius: 8
                color: deleteClipboardPointer.containsMouse
                    ? Qt.rgba(themeData.red.r, themeData.red.g, themeData.red.b, 0.18)
                    : "transparent"
                z: 3

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: deleteClipboardPointer.containsMouse
                        ? themeData.red : themeData.overlay
                    font.family: themeData.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Normal
                }

                MouseArea {
                    id: deleteClipboardPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: host.removeClipboardItem(
                        deleteClipboardButton.parent.index)
                }
            }

            MouseArea {
                id: clipboardItemPointer
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    right: deleteClipboardButton.left
                }
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: host.selectClipboardItem(parent.modelData)
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: host.clipboardItems.length === 0

        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitSize: 34
            source: host.clipboardAction.iconSource
            mipmap: true
            opacity: 0.55
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "History is empty"
            color: themeData.subtext
            font.family: themeData.fontFamily
            font.pixelSize: 11
            font.weight: Font.Normal
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Copy some text and it will appear here"
            color: themeData.overlay
            font.family: themeData.fontFamily
            font.pixelSize: 9
            font.weight: Font.Normal
        }
    }
}

Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: "Last 10 text entries · stored in memory only"
    color: themeData.overlay
    font.family: themeData.fontFamily
    font.pixelSize: 8
    font.weight: Font.Normal
}
        }
    }
}
