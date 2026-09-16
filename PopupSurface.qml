import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var host
    required property var themeData

    implicitWidth: host.width
    implicitHeight: host.popupSurfaceHeight
    color: "transparent"
    visible: host.popupSurfaceActive && !host.fullscreenLocked
    grabFocus: false
    readonly property bool interactivePopupOpen:
        host.searchOpen || host.contextMenuOpen || host.audioOpen
        || host.systemOpen || host.calendarOpen || host.clipboardOpen
        || host.networkOpen || host.notificationsOpen || host.displayOpen
    readonly property int toastHeight: host.notificationToast
            && host.notificationToast.actions
            && host.notificationToast.actions.length > 0
        ? 126 : 98

    anchor {
        window: host
        rect.x: 0
        rect.y: -1
        rect.width: 1
        rect.height: 1
        edges: Edges.Top | Edges.Left
        gravity: Edges.Top | Edges.Right
        adjustment: PopupAdjustment.None
    }

    // A notification must intercept input only on the visible toast. Keeping
    // the full 410 px surface clickable would temporarily block applications
    // behind it. Interactive popups retain the full mask for click-outside.
    mask: root.interactivePopupOpen
        ? popupInputMask
        : (host.notificationToast !== null ? toastInputMask : emptyInputMask)

    Region {
        id: popupInputMask
        x: 0
        y: 0
        width: root.width
        height: root.height
    }

    Region {
        id: emptyInputMask
        x: 0
        y: 0
        width: 0
        height: 0
    }

    Region {
        id: toastInputMask
        x: root.host.width - root.themeData.sideMargin - width - 8
        y: root.height - height
        width: 360
        height: root.toastHeight
    }

    // These lightweight proxies preserve the exact coordinates the popup
    // components used when they lived inside the large panel surface.
    Item {
        id: barProxy
        x: root.themeData.sideMargin
        y: root.height + 8
        width: Math.max(0, root.host.width - root.themeData.sideMargin * 2)
        height: root.themeData.barHeight
    }

    Item {
        id: searchBoxProxy
        width: root.host.popupSearchBoxWidth
        height: root.themeData.buttonSize
    }

    Item {
        id: audioAnchorProxy
        x: root.host.popupAudioAnchorCenterX
        width: 0
        height: 0
    }

    function resetSearchSelection() {
        if (searchPopupLoader.item) {
            searchPopupLoader.item.resetSelection()
        }
    }

    function moveSearchSelection(step) {
        if (searchPopupLoader.item) {
            searchPopupLoader.item.moveSelection(step)
        }
    }

    function activateSearchSelection() {
        if (searchPopupLoader.item) {
            searchPopupLoader.item.activateSelected()
        }
    }

    function stopContextCloseTimer() {
        if (contextPopupLoader.item) {
            contextPopupLoader.item.stopCloseTimer()
        }
    }

    Loader {
        id: clipboardPopupLoader
        anchors.fill: parent
        z: 18

        function syncSource() {
            if (root.host.clipboardOpen) {
                clipboardUnloadTimer.stop()
                if (source.toString().length === 0) {
                    setSource(Qt.resolvedUrl("ClipboardPopup.qml"), {
                        "host": root.host,
                        "themeData": root.themeData,
                        "barItem": barProxy
                    })
                }
            } else if (source.toString().length > 0) {
                clipboardUnloadTimer.restart()
            }
        }

        Component.onCompleted: syncSource()

        Connections {
            target: root.host
            function onClipboardOpenChanged() {
                clipboardPopupLoader.syncSource()
            }
        }

        Timer {
            id: clipboardUnloadTimer
            interval: 190
            onTriggered: clipboardPopupLoader.source = ""
        }
    }

    Loader {
        id: calendarPopupLoader
        anchors.fill: parent
        z: 19

        function syncSource() {
            if (root.host.calendarOpen) {
                calendarUnloadTimer.stop()
                if (source.toString().length === 0) {
                    setSource(Qt.resolvedUrl("CalendarPopup.qml"), {
                        "host": root.host,
                        "themeData": root.themeData,
                        "barItem": barProxy
                    })
                }
            } else if (source.toString().length > 0) {
                calendarUnloadTimer.restart()
            }
        }

        Component.onCompleted: syncSource()

        Connections {
            target: root.host
            function onCalendarOpenChanged() {
                calendarPopupLoader.syncSource()
            }
        }

        Timer {
            id: calendarUnloadTimer
            interval: 190
            onTriggered: calendarPopupLoader.source = ""
        }
    }

    Loader {
        id: systemPopupLoader
        anchors.fill: parent
        z: 20

        function syncSource() {
            if (root.host.systemOpen) {
                systemUnloadTimer.stop()
                if (source.toString().length === 0) {
                    setSource(Qt.resolvedUrl("SystemPopup.qml"), {
                        "host": root.host,
                        "themeData": root.themeData,
                        "barItem": barProxy
                    })
                }
            } else if (source.toString().length > 0) {
                systemUnloadTimer.restart()
            }
        }

        Component.onCompleted: syncSource()

        Connections {
            target: root.host
            function onSystemOpenChanged() {
                systemPopupLoader.syncSource()
            }
        }

        Timer {
            id: systemUnloadTimer
            interval: 190
            onTriggered: systemPopupLoader.source = ""
        }
    }

    Loader {
        id: audioPopupLoader
        anchors.fill: parent
        z: 21

        function syncSource() {
            if (root.host.audioOpen) {
                audioUnloadTimer.stop()
                if (source.toString().length === 0) {
                    setSource(Qt.resolvedUrl("AudioPopup.qml"), {
                        "host": root.host,
                        "themeData": root.themeData,
                        "barItem": barProxy,
                        "anchorItem": audioAnchorProxy
                    })
                }
            } else if (source.toString().length > 0) {
                audioUnloadTimer.restart()
            }
        }

        Component.onCompleted: syncSource()

        Connections {
            target: root.host
            function onAudioOpenChanged() {
                audioPopupLoader.syncSource()
            }
        }

        Timer {
            id: audioUnloadTimer
            interval: 190
            onTriggered: audioPopupLoader.source = ""
        }
    }

    Loader {
        anchors.fill: parent
        active: root.host.networkOpen
        z: 22

        sourceComponent: Component {
            NetworkPopup {
                themeData: root.themeData
                barX: barProxy.x
                barY: barProxy.y
                barWidth: barProxy.width
                onCloseRequested: root.host.closeNetwork()
                onTabRequested: function(tab) {
                    if (tab === "notifications") root.host.openNotifications()
                    else if (tab === "display") root.host.openDisplay()
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.host.notificationsOpen
        z: 22

        sourceComponent: Component {
            NotificationPopup {
                themeData: root.themeData
                notificationState: root.host.notificationState
                barX: barProxy.x
                barY: barProxy.y
                barWidth: barProxy.width
                onCloseRequested: root.host.closeNotifications()
                onTabRequested: function(tab) {
                    if (tab === "network") root.host.openNetwork()
                    else if (tab === "display") root.host.openDisplay()
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.host.displayOpen
        z: 22

        sourceComponent: Component {
            DisplayPopup {
                themeData: root.themeData
                displayState: root.host.displayState
                barX: barProxy.x
                barY: barProxy.y
                barWidth: barProxy.width
                onCloseRequested: root.host.closeDisplay()
                onTabRequested: function(tab) {
                    if (tab === "network") root.host.openNetwork()
                    else if (tab === "notifications") root.host.openNotifications()
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.host.notificationToast !== null
        z: 40

        sourceComponent: Component {
            NotificationToast {
                notification: root.host.notificationToast
                themeData: root.themeData
                barX: barProxy.x
                barY: barProxy.y
                barWidth: barProxy.width
                onFinished: root.host.notificationToast = null
            }
        }
    }

    Loader {
        id: searchPopupLoader
        anchors.fill: parent
        z: 17

        function syncSource() {
            if (root.host.searchOpen) {
                searchUnloadTimer.stop()
                if (source.toString().length === 0) {
                    setSource(Qt.resolvedUrl("SearchPopup.qml"), {
                        "host": root.host,
                        "themeData": root.themeData,
                        "barItem": barProxy,
                        "searchBoxItem": searchBoxProxy
                    })
                    if (item) {
                        Qt.callLater(item.resetSelection)
                    }
                }
            } else if (source.toString().length > 0) {
                searchUnloadTimer.restart()
            }
        }

        Component.onCompleted: syncSource()

        Connections {
            target: root.host
            function onSearchOpenChanged() {
                searchPopupLoader.syncSource()
            }
        }

        Timer {
            id: searchUnloadTimer
            interval: 190
            onTriggered: searchPopupLoader.source = ""
        }
    }

    Loader {
        id: contextPopupLoader
        anchors.fill: parent
        z: 30

        function syncSource() {
            if (root.host.contextMenuOpen) {
                contextUnloadTimer.stop()
                if (source.toString().length === 0) {
                    setSource(Qt.resolvedUrl("AppContextPopup.qml"), {
                        "host": root.host,
                        "themeData": root.themeData,
                        "barItem": barProxy
                    })
                }
            } else if (source.toString().length > 0) {
                contextUnloadTimer.restart()
            }
        }

        Component.onCompleted: syncSource()

        Connections {
            target: root.host
            function onContextMenuOpenChanged() {
                contextPopupLoader.syncSource()
            }
        }

        Timer {
            id: contextUnloadTimer
            interval: 190
            onTriggered: contextPopupLoader.source = ""
        }
    }
}
