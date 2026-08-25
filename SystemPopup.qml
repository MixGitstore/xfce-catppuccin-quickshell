import QtQuick

Item {
    id: root

    required property var host
    required property var themeData
    required property var barItem
    MouseArea {
        id: systemDismissArea

        x: 0
        y: 0
        width: host.width
        height: Math.max(0, barItem.y)
        visible: host.systemOpen
        z: 18
        onClicked: host.closeSystem()
    }

    Rectangle {
        id: systemPopup

        x: barItem.x + barItem.width - width - 8
        y: barItem.y - 8 - height
        width: 300
        height: host.systemPopupHeight
        radius: themeData.radius
        color: Qt.rgba(themeData.base.r, themeData.base.g, themeData.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(themeData.surface2.r, themeData.surface2.g, themeData.surface2.b, 0.82)
        property bool entered: false
        opacity: entered && host.systemOpen ? 1 : 0
        scale: entered && host.systemOpen ? 1 : 0.96
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

Row {
    width: parent.width
    height: 42
    spacing: 10

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40
        radius: 12
        color: themeData.surface0
        border.width: 1
        border.color: themeData.surface1

        Image {
            anchors.centerIn: parent
            width: 34
            height: 34
            source: host.configuration.profileImage
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 50
        spacing: -1

        Text {
            text: host.configuration.profileName
            color: themeData.text
            font.family: themeData.fontFamily
            font.pixelSize: 14
            font.weight: Font.Normal
        }

        Text {
            width: parent.width
            text: host.systemHostName + "  •  System resources"
            color: themeData.overlay
            elide: Text.ElideRight
            font.family: themeData.fontFamily
            font.pixelSize: 9
        }
    }
}

Grid {
    id: resourceGrid

    width: parent.width
    height: 154
    columns: 2
    columnSpacing: 8
    rowSpacing: 8

    Repeater {
        model: host.systemResourceItems

        Rectangle {
            id: resourceCard

            required property var modelData
            width: (resourceGrid.width - resourceGrid.columnSpacing) / 2
            height: 73
            radius: 11
            color: themeData.surface0

            Text {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 10
                    topMargin: 8
                }
                text: resourceCard.modelData.label
                color: resourceCard.modelData.accent
                font.family: themeData.fontFamily
                font.pixelSize: 10
                font.weight: Font.Normal
            }

            Text {
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 10
                    topMargin: 7
                }
                text: resourceCard.modelData.value
                color: themeData.text
                font.family: themeData.monoFamily
                font.pixelSize: 12
                font.weight: Font.Normal
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 34
                }
                height: 5
                radius: 3
                color: themeData.surface1

                Rectangle {
                    width: parent.width * Math.max(0,
                        Math.min(1, Number(resourceCard.modelData.level)))
                    height: parent.height
                    radius: parent.radius
                    color: resourceCard.modelData.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 10
                    rightMargin: 10
                    bottomMargin: 8
                }
                text: resourceCard.modelData.detail
                color: themeData.overlay
                elide: Text.ElideRight
                font.family: themeData.fontFamily
                font.pixelSize: 8
            }
        }
    }
}

Rectangle {
    width: parent.width
    height: 1
    color: themeData.surface0
}

Row {
    width: parent.width
    height: 42
    spacing: 7

    Repeater {
        model: [
            { action: "switch-user", icon: "⇄", label: "Switch user" },
            { action: "restart", icon: "↻", label: "Restart" },
            { action: "shutdown", icon: "⏻", label: "Shut down" }
        ]

        Rectangle {
            id: systemActionButton

            required property var modelData
            width: (parent.width - 2 * parent.spacing) / 3
            height: parent.height
            radius: 10
            color: systemActionPointer.containsMouse
                ? (modelData.action === "shutdown"
                    ? Qt.rgba(themeData.red.r, themeData.red.g, themeData.red.b, 0.20)
                    : themeData.surface1)
                : themeData.surface0

            Behavior on color { ColorAnimation { duration: 100 } }

            Row {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: systemActionButton.modelData.icon
                    color: systemActionButton.modelData.action === "shutdown"
                        ? themeData.red : themeData.mauve
                    font.family: themeData.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Normal
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: systemActionButton.modelData.label
                    color: themeData.subtext
                    font.family: themeData.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Normal
                }
            }

            MouseArea {
                id: systemActionPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: host.requestSystemAction(
                    systemActionButton.modelData.action)
            }
        }
    }
}
        }

        Rectangle {
anchors.fill: parent
radius: parent.radius
color: Qt.rgba(themeData.base.r, themeData.base.g, themeData.base.b, 0.995)
visible: host.systemConfirmAction.length > 0
z: 30

Column {
    anchors.centerIn: parent
    width: parent.width - 40
    spacing: 14

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: host.systemConfirmAction === "restart" ? "↻" : "⏻"
        color: host.systemConfirmAction === "restart"
            ? themeData.mauve : themeData.red
        font.family: themeData.fontFamily
        font.pixelSize: 32
    }

    Text {
        width: parent.width
        text: host.systemConfirmAction === "restart"
            ? "Restart the computer?"
            : "Shut down the computer?"
        color: themeData.text
        horizontalAlignment: Text.AlignHCenter
        font.family: themeData.fontFamily
        font.pixelSize: 14
        font.weight: Font.Normal
    }

    Text {
        width: parent.width
        text: "Save your open work before continuing."
        color: themeData.overlay
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.family: themeData.fontFamily
        font.pixelSize: 10
    }

    Row {
        width: parent.width
        height: 38
        spacing: 8

        Rectangle {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            radius: 10
            color: cancelSystemPointer.containsMouse
                ? themeData.surface1 : themeData.surface0

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: themeData.subtext
                font.family: themeData.fontFamily
                font.pixelSize: 11
                font.weight: Font.Normal
            }

            MouseArea {
                id: cancelSystemPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: host.systemConfirmAction = ""
            }
        }

        Rectangle {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            radius: 10
            color: confirmSystemPointer.containsMouse
                ? Qt.rgba(themeData.red.r, themeData.red.g, themeData.red.b, 0.34)
                : Qt.rgba(themeData.red.r, themeData.red.g, themeData.red.b, 0.20)
            border.width: 1
            border.color: themeData.red

            Text {
                anchors.centerIn: parent
                text: "Confirm"
                color: themeData.red
                font.family: themeData.fontFamily
                font.pixelSize: 11
                font.weight: Font.Normal
            }

            MouseArea {
                id: confirmSystemPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: host.confirmSystemAction()
            }
        }
    }
}
        }
    }
}
