import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: tracker

    property bool fullscreenActive: false
    property bool maximizedActive: false
    property bool snappedActive: false
    readonly property bool autoHideActive:
        fullscreenActive || maximizedActive || snappedActive
    property string activeWindow: ""
    // The Quickshell panel is focusable so its search field works on X11. A
    // click on the panel temporarily makes its own native window active; keep
    // the last regular client so pinned buttons can still toggle that window.
    property string lastClientActiveWindow: ""
    property bool enabled: true
    property var clientWindows: []
    property var windowScanBuffer: []
    property bool rescanRequested: false
    property bool snapRecheckRequested: false

    function normalizedClasses(classes) {
        if (!classes) {
            return []
        }

        return classes.map(function(className) {
            return String(className).toLowerCase()
        })
    }

    function matchesClasses(windowEntry, classes) {
        const wanted = normalizedClasses(classes)
        if (!windowEntry || wanted.length === 0) {
            return false
        }

        for (let classIndex = 0; classIndex < windowEntry.classes.length; ++classIndex) {
            if (wanted.indexOf(windowEntry.classes[classIndex]) !== -1) {
                return true
            }
        }
        return false
    }

    function windowForClasses(classes) {
        const effectiveActiveWindow = activeClientWindow()

        // Prefer the active window when an application owns more than one.
        for (let index = clientWindows.length - 1; index >= 0; --index) {
            const entry = clientWindows[index]
            if (entry.id === effectiveActiveWindow && matchesClasses(entry, classes)) {
                return entry.id
            }
        }

        // _NET_CLIENT_LIST_STACKING is ordered bottom-to-top, so the last match
        // is the application's topmost window.
        for (let index = clientWindows.length - 1; index >= 0; --index) {
            if (matchesClasses(clientWindows[index], classes)) {
                return clientWindows[index].id
            }
        }
        return ""
    }

    function classesAreActive(classes) {
        const effectiveActiveWindow = activeClientWindow()
        if (effectiveActiveWindow.length === 0) {
            return false
        }

        for (let index = 0; index < clientWindows.length; ++index) {
            const entry = clientWindows[index]
            if (entry.id === effectiveActiveWindow && matchesClasses(entry, classes)) {
                return true
            }
        }
        return false
    }

    function windowsForClasses(classes) {
        const result = []
        for (let index = 0; index < clientWindows.length; ++index) {
            const entry = clientWindows[index]
            if (!entry.skipTaskbar && matchesClasses(entry, classes)) {
                result.push(entry)
            }
        }
        return result
    }

    function isKnownClient(windowId) {
        for (let index = 0; index < clientWindows.length; ++index) {
            if (clientWindows[index].id === windowId) {
                return true
            }
        }
        return false
    }

    function rememberClientWindow(windowId) {
        if (windowId.length > 0 && isKnownClient(windowId)) {
            lastClientActiveWindow = windowId
        }
    }

    function activeClientWindow() {
        return isKnownClient(activeWindow)
            ? activeWindow
            : lastClientActiveWindow
    }

    function markWindowMinimized(windowId) {
        // The panel may remain the actual X11 active window after minimizing.
        // Forget the previous client immediately so the next click restores it.
        if (activeWindow === windowId) {
            activeWindow = ""
        }
        if (lastClientActiveWindow === windowId) {
            lastClientActiveWindow = ""
        }
    }

    function scheduleWindowScan() {
        windowScanDelay.restart()
    }

    function scanWindows() {
        if (windowScan.running) {
            rescanRequested = true
            return
        }

        windowScan.exec([
            "bash",
            Quickshell.shellDir + "/list-x11-windows.sh"
        ])
    }

    function addScannedWindow(line) {
        const firstSeparator = line.indexOf("\t")
        const secondSeparator = line.indexOf("\t", firstSeparator + 1)
        const thirdSeparator = line.indexOf("\t", secondSeparator + 1)
        if (firstSeparator < 1 || secondSeparator < 0 || thirdSeparator < 0) {
            return
        }

        const id = line.substring(0, firstSeparator)
        const skipTaskbar = line.substring(firstSeparator + 1, secondSeparator) === "1"
        const title = line.substring(secondSeparator + 1, thirdSeparator)
        const classData = line.substring(thirdSeparator + 1)
        const quotedClasses = classData.match(/"([^"]*)"/g) || []
        const classes = quotedClasses.map(function(value) {
            return value.substring(1, value.length - 1).toLowerCase()
        })

        if (classes.length > 0) {
            const nextBuffer = windowScanBuffer.slice()
            nextBuffer.push({
                id: id,
                title: title,
                classes: classes,
                skipTaskbar: skipTaskbar
            })
            windowScanBuffer = nextBuffer
        }
    }

    function updateActiveWindow(line) {
        const match = line.match(/0x[0-9a-fA-F]+/)
        const windowId = match ? match[0] : ""

        stateWatcher.running = false
        geometryWatcher.running = false
        snapGeometryCheck.running = false
        snapCheckDelay.stop()
        fullscreenActive = false
        maximizedActive = false
        snappedActive = false
        activeWindow = windowId === "0x0" ? "" : windowId
        rememberClientWindow(activeWindow)
        scheduleWindowScan()

        if (activeWindow.length > 0) {
            stateWatcher.exec([
                "stdbuf", "-oL", "xprop", "-spy", "-id", activeWindow,
                "_NET_WM_STATE", "_NET_FRAME_EXTENTS"
            ])
            geometryWatcher.exec([
                Quickshell.shellDir + "/watch-x11-geometry",
                activeWindow
            ])
        }
    }

    function scheduleSnapCheck() {
        snapCheckDelay.restart()
    }

    function checkActiveSnap() {
        if (activeWindow.length === 0) {
            snappedActive = false
            return
        }
        if (snapGeometryCheck.running) {
            snapRecheckRequested = true
            return
        }
        snapGeometryCheck.exec([
            "bash",
            Quickshell.shellDir + "/detect-x11-snap.sh",
            activeWindow
        ])
    }

    property Process activeWindowWatcher: Process {
        running: tracker.enabled
        command: [
            "stdbuf", "-oL", "xprop", "-spy", "-root",
            "_NET_ACTIVE_WINDOW"
        ]

        stdout: SplitParser {
            onRead: function(line) {
                tracker.updateActiveWindow(line)
            }
        }

        onRunningChanged: {
            if (!running && tracker.enabled) {
                activeWatcherRestart.restart()
            }
        }
    }

    property Process windowListWatcher: Process {
        running: tracker.enabled
        command: [
            "stdbuf", "-oL", "xprop", "-spy", "-root",
            "_NET_CLIENT_LIST_STACKING"
        ]

        stdout: SplitParser {
            onRead: function(line) {
                tracker.scheduleWindowScan()
            }
        }

        onRunningChanged: {
            if (!running && tracker.enabled) {
                windowWatcherRestart.restart()
            }
        }
    }

    property Process windowScan: Process {
        stdout: SplitParser {
            onRead: function(line) {
                tracker.addScannedWindow(line)
            }
        }

        onRunningChanged: {
            if (running) {
                tracker.windowScanBuffer = []
            } else {
                tracker.clientWindows = tracker.windowScanBuffer.slice()
                tracker.rememberClientWindow(tracker.activeWindow)
                if (tracker.rescanRequested) {
                    tracker.rescanRequested = false
                    windowScanDelay.restart()
                }
            }
        }
    }

    property Process stateWatcher: Process {
        stdout: SplitParser {
            onRead: function(line) {
                if (line.indexOf("_NET_WM_STATE") === 0) {
                    tracker.fullscreenActive =
                        line.indexOf("_NET_WM_STATE_FULLSCREEN") !== -1
                    tracker.maximizedActive =
                        line.indexOf("_NET_WM_STATE_MAXIMIZED_HORZ") !== -1
                        && line.indexOf("_NET_WM_STATE_MAXIMIZED_VERT") !== -1
                } else if (line.indexOf("_NET_FRAME_EXTENTS") === 0) {
                    tracker.scheduleSnapCheck()
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                tracker.fullscreenActive = false
                tracker.maximizedActive = false
            }
        }
    }

    property Process geometryWatcher: Process {
        // Tiny Xlib listener: event-driven and idle between geometry changes.
        stdout: SplitParser {
            onRead: function(line) {
                if (String(line).trim() === "geometry") {
                    tracker.scheduleSnapCheck()
                }
            }
        }
    }

    property Process snapGeometryCheck: Process {
        stdout: SplitParser {
            onRead: function(line) {
                tracker.snappedActive = String(line).trim() === "1"
            }
        }

        onRunningChanged: {
            if (!running && tracker.snapRecheckRequested) {
                tracker.snapRecheckRequested = false
                snapCheckDelay.restart()
            }
        }
    }

    property Timer activeWatcherRestart: Timer {
        interval: 2000
        onTriggered: {
            if (tracker.enabled && !activeWindowWatcher.running) {
                activeWindowWatcher.running = true
            }
        }
    }

    property Timer windowScanDelay: Timer {
        interval: 120
        onTriggered: tracker.scanWindows()
    }

    property Timer snapCheckDelay: Timer {
        interval: 90
        onTriggered: tracker.checkActiveSnap()
    }

    property Timer windowWatcherRestart: Timer {
        interval: 2000
        onTriggered: {
            if (tracker.enabled && !windowListWatcher.running) {
                windowListWatcher.running = true
            }
        }
    }

}
