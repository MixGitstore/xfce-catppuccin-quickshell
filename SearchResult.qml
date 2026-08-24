import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var entry
    required property var themeData
    property bool selected: false
    readonly property var item: entry || ({
        name: "",
        icon: "application-x-executable",
        genericName: "",
        comment: ""
    })
    readonly property bool isPath: item.kind === "file" || item.kind === "folder"

    signal activated(var entry)
    signal hovered()

    implicitHeight: 52

    Rectangle {
        anchors {
            fill: parent
            leftMargin: 5
            rightMargin: 5
        }
        radius: 10
        color: pointer.containsMouse || root.selected
            ? Qt.rgba(themeData.surface1.r, themeData.surface1.g, themeData.surface1.b, 0.86)
            : "transparent"

        Behavior on color { ColorAnimation { duration: 90 } }
    }

    IconImage {
        anchors {
            left: parent.left
            leftMargin: 15
            verticalCenter: parent.verticalCenter
        }
        implicitSize: 29
        source: Quickshell.iconPath(root.item.icon,
            root.isPath ? "text-x-generic" : "application-x-executable")
        mipmap: true
    }

    Column {
        anchors {
            left: parent.left
            leftMargin: 56
            right: parent.right
            rightMargin: 15
            verticalCenter: parent.verticalCenter
        }
        spacing: 1

        Text {
            width: parent.width
            text: root.item.name
            color: themeData.text
            font.family: themeData.fontFamily
            font.pixelSize: 13
            font.weight: Font.Normal
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text.length > 0
            text: root.isPath
                ? (root.item.kind === "folder" ? "Folder  •  " : "File  •  ")
                    + root.item.directory
                : (root.item.genericName || root.item.comment || "")
            color: themeData.overlay
            font.family: themeData.fontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered()
        onPressed: {
            root.hovered()
            root.activated(root.item)
        }
    }
}
