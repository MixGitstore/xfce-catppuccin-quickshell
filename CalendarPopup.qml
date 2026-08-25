import QtQuick

Item {
    id: root

    required property var host
    required property var themeData
    required property var barItem
    MouseArea {
        id: calendarDismissArea

        x: 0
        y: 0
        width: host.width
        height: Math.max(0, barItem.y)
        visible: host.calendarOpen
        z: 18
        onClicked: host.closeCalendar()
    }

    Rectangle {
        id: calendarPopup

        x: barItem.x + barItem.width - width - 52
        y: barItem.y - 8 - height
        width: 348
        height: host.calendarPopupHeight
        radius: themeData.radius
        color: Qt.rgba(themeData.base.r, themeData.base.g, themeData.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(themeData.surface2.r, themeData.surface2.g, themeData.surface2.b, 0.82)
        property bool entered: false
        opacity: entered && host.calendarOpen ? 1 : 0
        scale: entered && host.calendarOpen ? 1 : 0.96
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
    margins: 16
}
spacing: 8

Row {
    width: parent.width
    height: 68
    spacing: 8

    Column {
        width: 126
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            text: Qt.formatDateTime(host.clockSource.date, "HH:mm")
            color: themeData.text
            font.family: themeData.monoFamily
            font.pixelSize: 28
            font.weight: Font.Normal
        }

        Text {
            width: parent.width
            text: host.longDateLabel(host.clockSource.date)
            color: themeData.overlay
            font.family: themeData.fontFamily
            font.pixelSize: 9
            font.weight: Font.Normal
            elide: Text.ElideRight
        }
    }

    Rectangle {
        width: parent.width - 134
        height: 68
        radius: 11
        color: themeData.surface0
        border.width: 1
        border.color: Qt.rgba(
            themeData.surface2.r, themeData.surface2.g, themeData.surface2.b, 0.65)

        Row {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 9

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: host.weatherGlyph
                color: host.weatherFailed ? themeData.overlay : themeData.yellow
                font.family: themeData.monoFamily
                font.pixelSize: 28
                font.weight: Font.Normal
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Row {
                    spacing: 6

                    Text {
                        text: host.weatherReady
                            ? Math.round(host.weatherTemperature) + "°C" : "—°C"
                        color: themeData.text
                        font.family: themeData.monoFamily
                        font.pixelSize: 15
                        font.weight: Font.Normal
                    }

                    Text {
                        anchors.baseline: parent.children[0].baseline
                        text: host.weatherLocation
                        color: themeData.mauve
                        font.family: themeData.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Normal
                    }
                }

                Text {
                    text: host.weatherDescription
                    color: themeData.subtext
                    font.family: themeData.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Normal
                }

                Text {
                    text: host.weatherReady
                        ? "Feels like " + Math.round(host.weatherFeelsLike)
                            + "° · Wind " + Math.round(host.weatherWindSpeed) + " km/h"
                        : "Updates every 15 minutes"
                    color: themeData.overlay
                    font.family: themeData.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.Normal
                }
            }
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
    height: 36

    Rectangle {
        id: previousMonthButton
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: 32
        height: 30
        radius: 8
        color: previousMonthPointer.containsMouse
            ? themeData.surface1 : themeData.surface0

        Text {
            anchors.centerIn: parent
            text: "‹"
            color: themeData.text
            font.family: themeData.fontFamily
            font.pixelSize: 20
            font.weight: Font.Normal
        }

        MouseArea {
            id: previousMonthPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: host.shiftCalendarMonth(-1)
        }
    }

    Text {
        anchors.centerIn: parent
        text: host.calendarMonthNames[host.calendarMonth]
            + " " + host.calendarYear
        color: themeData.text
        font.family: themeData.fontFamily
        font.pixelSize: 13
        font.weight: Font.Normal
    }

    Rectangle {
        id: todayMonthButton
        anchors {
            right: nextMonthButton.left
            rightMargin: 6
            verticalCenter: parent.verticalCenter
        }
        width: 52
        height: 26
        radius: 8
        color: todayMonthPointer.containsMouse
            ? themeData.surface1 : "transparent"

        Text {
            anchors.centerIn: parent
            text: "Today"
            color: themeData.mauve
            font.family: themeData.fontFamily
            font.pixelSize: 9
            font.weight: Font.Normal
        }

        MouseArea {
            id: todayMonthPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: host.resetCalendarMonth()
        }
    }

    Rectangle {
        id: nextMonthButton
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: 32
        height: 30
        radius: 8
        color: nextMonthPointer.containsMouse
            ? themeData.surface1 : themeData.surface0

        Text {
            anchors.centerIn: parent
            text: "›"
            color: themeData.text
            font.family: themeData.fontFamily
            font.pixelSize: 20
            font.weight: Font.Normal
        }

        MouseArea {
            id: nextMonthPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: host.shiftCalendarMonth(1)
        }
    }
}

Row {
    width: parent.width
    height: 20
    spacing: 4

    Repeater {
        model: host.calendarWeekdayNames

        Text {
            required property var modelData
            width: (316 - 24) / 7
            height: 20
            text: String(modelData)
            color: modelData === "Sa" || modelData === "Su"
                ? themeData.mauve : themeData.overlay
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: themeData.fontFamily
            font.pixelSize: 9
            font.weight: Font.Normal
        }
    }
}

Grid {
    id: calendarGrid
    width: parent.width
    height: 212
    columns: 7
    columnSpacing: 4
    rowSpacing: 4

    Repeater {
        model: host.calendarDays

        Rectangle {
            required property var modelData
            width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
            height: 32
            radius: 9
            color: modelData.today
                ? themeData.mauve
                : (calendarDayPointer.containsMouse
                    ? themeData.surface1 : "transparent")
            border.width: modelData.current || modelData.today ? 0 : 1
            border.color: themeData.surface0

            Behavior on color { ColorAnimation { duration: 90 } }

            Text {
                anchors.centerIn: parent
                text: String(parent.modelData.day)
                color: parent.modelData.today
                    ? themeData.crust
                    : (parent.modelData.current ? themeData.text : themeData.overlay)
                opacity: parent.modelData.current || parent.modelData.today ? 1 : 0.52
                font.family: themeData.monoFamily
                font.pixelSize: 11
                font.weight: Font.Normal
            }

            MouseArea {
                id: calendarDayPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!parent.modelData.current) {
                        host.calendarYear = parent.modelData.year
                        host.calendarMonth = parent.modelData.month
                    }
                }
            }
        }
    }
}
        }
    }
}
