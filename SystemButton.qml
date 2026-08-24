import QtQuick

Item {
    id: root

    required property var themeData
    required property string profileImage
    property bool open: false

    signal activated()

    implicitWidth: themeData.buttonSize
    implicitHeight: themeData.buttonSize

    Rectangle {
        anchors.centerIn: parent
        width: 31
        height: 31
        radius: 10
        color: pointer.containsMouse || root.open
            ? root.themeData.surface1
            : root.themeData.surface0
        border.width: root.open ? 1 : 0
        border.color: root.themeData.mauve

        Behavior on color { ColorAnimation { duration: 100 } }

        Image {
            anchors.centerIn: parent
            width: 27
            height: 27
            source: root.profileImage
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            scale: pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.06 : 1)

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
