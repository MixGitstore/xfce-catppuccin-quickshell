import QtQuick

Item {
    id: root

    required property var host
    required property var themeData
    required property var barItem

    visible: root.host.contextMenuOpen

    function stopCloseTimer() {
        closeDelay.stop()
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.host.contextMenuOpen
        onClicked: root.host.closeContextMenu()
    }

    Item {
        id: contextInteractionArea

        readonly property real menuWidth: 252
        readonly property real desiredX:
            root.barItem.x + root.host.contextAnchorX - menuWidth / 2

        x: Math.max(root.themeData.sideMargin,
            Math.min(desiredX,
                root.host.width - root.themeData.sideMargin - menuWidth))
        y: root.barItem.y - 8 - contextMenu.height
        width: menuWidth
        height: contextMenu.height + 8 + root.barItem.height
        z: 1

        HoverHandler {
            id: contextMenuHover

            onHoveredChanged: {
                if (hovered) {
                    closeDelay.stop()
                } else if (root.host.contextMenuOpen) {
                    closeDelay.restart()
                }
            }
        }

        Rectangle {
            id: contextMenu

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: Math.min(
            root.host.resultsHeight,
            55 + root.host.contextMenuItems.length * 33)
        radius: root.themeData.radius
        color: Qt.rgba(root.themeData.base.r, root.themeData.base.g,
            root.themeData.base.b, 0.99)
        border.width: 1
        border.color: Qt.rgba(root.themeData.surface2.r,
            root.themeData.surface2.g, root.themeData.surface2.b, 0.82)
        clip: true

        Text {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 13
                rightMargin: 13
                topMargin: 10
            }
            height: 29
            text: root.host.contextApp
                ? (root.host.windowChooserMode
                    ? root.host.contextApp.name + " — "
                        + root.host.contextWindows.length + " windows"
                    : root.host.contextApp.name)
                : ""
            color: root.themeData.text
            font.family: root.themeData.fontFamily
            font.pixelSize: 13
            font.weight: Font.Normal
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 9
                rightMargin: 9
                topMargin: 43
            }
            height: 1
            color: root.themeData.surface0
        }

        ListView {
            id: contextActionList

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: 6
                rightMargin: 6
                topMargin: 48
                bottomMargin: 7
            }
            model: root.host.contextMenuItems
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: contextAction
                required property var modelData

                width: contextActionList.width
                height: 33
                radius: 8
                color: contextPointer.containsMouse
                    ? Qt.rgba(root.themeData.surface1.r,
                        root.themeData.surface1.g,
                        root.themeData.surface1.b, 0.88)
                    : "transparent"

                Behavior on color { ColorAnimation { duration: 90 } }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 6
                        rightMargin: 6
                    }
                    height: contextAction.modelData.sectionBreak ? 1 : 0
                    color: root.themeData.surface0
                    visible: height > 0
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        leftMargin: 9
                        verticalCenter: parent.verticalCenter
                    }
                    width: 5
                    height: 5
                    radius: 3
                    color: root.themeData.mauve
                    visible: contextAction.modelData.active === true
                }

                Text {
                    anchors {
                        fill: parent
                        leftMargin: contextAction.modelData.active === true ? 21 : 10
                        rightMargin: contextAction.modelData.kind === "window" ? 42 : 10
                        topMargin: contextAction.modelData.sectionBreak ? 2 : 0
                    }
                    text: contextAction.modelData.label
                    color: contextAction.modelData.danger
                        ? root.themeData.red : root.themeData.subtext
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: contextPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.host.runContextAction(
                        contextAction.modelData)
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        rightMargin: 5
                        verticalCenter: parent.verticalCenter
                    }
                    width: 24
                    height: 24
                    radius: 7
                    color: closeWindowPointer.containsMouse
                        ? Qt.rgba(root.themeData.red.r, root.themeData.red.g,
                            root.themeData.red.b, 0.22)
                        : "transparent"
                    visible: contextAction.modelData.kind === "window"
                    z: 2

                    Behavior on color { ColorAnimation { duration: 90 } }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeWindowPointer.containsMouse
                            ? root.themeData.red : root.themeData.overlay
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.Normal

                        Behavior on color { ColorAnimation { duration: 90 } }
                    }

                    MouseArea {
                        id: closeWindowPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.host.closeChooserWindow(
                            String(contextAction.modelData.windowId))
                    }
                }
            }
        }
        }
    }

    Timer {
        id: closeDelay
        interval: 650
        onTriggered: root.host.closeContextMenu()
    }
}
