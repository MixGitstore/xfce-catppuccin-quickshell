import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    required property var trayItem
    required property var parentWindow
    required property var themeData

    signal interacted()

    readonly property string itemIdentity: trayItem
        ? (String(trayItem.id || "") + " "
            + String(trayItem.title || "")).toLowerCase()
        : ""
    readonly property string displayIconSource:
        itemIdentity.indexOf("steam") !== -1
            ? "file://" + Quickshell.shellDir + "/assets/icons/catppuccin-steam.svg"
            : (trayItem && trayItem.icon
                ? trayItem.icon
                : Quickshell.iconPath("application-x-executable"))
    // StatusNotifier pixmaps do not share the same transparent padding.
    // Compensate their optical bounds while keeping one common center/click box.
    readonly property real opticalIconSize: {
        if (itemIdentity.indexOf("steam") !== -1) {
            return 21
        }
        if (itemIdentity.indexOf("discord") !== -1) {
            return 21
        }
        if (itemIdentity.indexOf("qbittorrent") !== -1) {
            return 16
        }
        return 18
    }

    implicitWidth: 28
    implicitHeight: themeData.buttonSize

    function displayMenu() {
        if (!trayItem || !trayItem.hasMenu) {
            return
        }

        root.interacted()
        const point = root.mapToItem(null, root.width / 2, root.height)
        trayItem.display(
            root.parentWindow,
            Math.round(point.x),
            Math.round(point.y))
    }

    Rectangle {
        anchors.centerIn: parent
        width: 27
        height: 31
        radius: 9
        color: pointer.containsMouse ? root.themeData.surface1 : "transparent"

        Behavior on color { ColorAnimation { duration: 90 } }
    }

    IconImage {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        implicitSize: root.opticalIconSize
        source: root.displayIconSource
        mipmap: true
        opacity: root.trayItem && root.trayItem.status === Status.Passive
            ? 0.72 : 1
        scale: pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1)

        Behavior on opacity { NumberAnimation { duration: 100 } }
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 3
            topMargin: 3
        }
        width: 6
        height: 6
        radius: 3
        color: root.themeData.red
        border.width: 1
        border.color: root.themeData.mantle
        visible: root.trayItem
            && root.trayItem.status === Status.NeedsAttention
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (!root.trayItem) {
                return
            }

            if (mouse.button === Qt.RightButton) {
                root.displayMenu()
            } else if (mouse.button === Qt.MiddleButton) {
                root.interacted()
                root.trayItem.secondaryActivate()
            } else if (root.trayItem.onlyMenu && root.trayItem.hasMenu) {
                root.displayMenu()
            } else {
                root.interacted()
                root.trayItem.activate()
            }
        }

        onWheel: function(wheel) {
            if (!root.trayItem) {
                return
            }

            const horizontal = Math.abs(wheel.angleDelta.x)
                > Math.abs(wheel.angleDelta.y)
            const delta = horizontal ? wheel.angleDelta.x : wheel.angleDelta.y
            root.interacted()
            root.trayItem.scroll(delta, horizontal)
            wheel.accepted = true
        }
    }
}
