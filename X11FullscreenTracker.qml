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
    property var pendingActiveWindows: []
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

    function sameWindowList(first, second) {
        if (first.length !== second.length) {
            return false
        }
        for (let index = 0; index < first.length; ++index) {
            const left = first[index]
            const right = second[index]
            if (left.id !== right.id || left.title !== right.title
                    || left.skipTaskbar !== right.skipTaskbar
                    || left.classes.length !== right.classes.length) {
                return false
            }
            for (let classIndex = 0;
                    classIndex < left.classes.length; ++classIndex) {
                if (left.classes[classIndex] !== right.classes[classIndex]) {
                    return false
                }
            }
        }
        return true
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
            if (clientWindows[index].id === windowId
                    && !clientWindows[index].skipTaskbar) {
                return true
            }
        }
        return false
    }

    function isListedWindow(windowId) {
        for (let index = 0; index < clientWindows.length; ++index) {
            if (clientWindows[index].id === windowId) {
                return true
            }
        }
        return false
    }

    function queuePendingActiveWindow(windowId) {
        if (windowId.length === 0 || isListedWindow(windowId)
                || pendingActiveWindows.indexOf(windowId) !== -1) {
            return
        }

        const pending = pendingActiveWindows.slice()
        pending.push(windowId)
        pendingActiveWindows = pending.slice(Math.max(0, pending.length - 8))
    }

    function rememberClientWindow(windowId) {
        if (windowId.length > 0 && isKnownClient(windowId)) {
            lastClientActiveWindow = windowId
            pendingActiveWindows = []
        } else {
            queuePendingActiveWindow(windowId)
        }
    }

    function reconcilePendingActiveWindows() {
        for (let index = pendingActiveWindows.length - 1; index >= 0; --index) {
            const candidate = pendingActiveWindows[index]
            if (isKnownClient(candidate)) {
                lastClientActiveWindow = candidate
                pendingActiveWindows = []
                return
            }
        }

        // Drop newly identified desktop/skip-taskbar surfaces, but retain a
        // small bounded set of unknown IDs for the next membership scan.
        pendingActiveWindows = pendingActiveWindows.filter(function(candidate) {
            return !isListedWindow(candidate)
        }).slice(-8)
    }

    function activeClientWindow() {
        if (isKnownClient(activeWindow)) {
            return activeWindow
        }
        // A listed skip-taskbar surface (for example the desktop) must not make
        // the previously focused application look active. Unknown IDs are
        // typically Quickshell's focusable panel, for which the fallback is
        // required so taskbar toggles remain stable.
        return isListedWindow(activeWindow) ? "" : lastClientActiveWindow
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
        pendingActiveWindows = pendingActiveWindows.filter(function(candidate) {
            return candidate !== windowId
        })
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
            windowScanBuffer.push({
                id: id,
                title: title,
                classes: classes,
                skipTaskbar: skipTaskbar
            })
        }
    }

    function updateActiveWindow(windowId) {
        snapGeometryCheck.running = false
        snapCheckDelay.stop()
        fullscreenActive = false
        maximizedActive = false
        snappedActive = false
        activeWindow = windowId === "0x0" ? "" : windowId
        rememberClientWindow(activeWindow)

        if (activeWindow.length > 0) {
            scheduleSnapCheck()
        }
    }

    function handleX11Event(line) {
        const fields = String(line || "").trim().split("\t")
        if (fields[0] === "active" && fields.length >= 2) {
            updateActiveWindow(fields[1])
        } else if (fields[0] === "clients") {
            scheduleWindowScan()
        } else if (fields[0] === "state" && fields.length >= 3) {
            fullscreenActive = fields[1] === "1"
            maximizedActive = fields[2] === "1"
        } else if (fields[0] === "geometry") {
            scheduleSnapCheck()
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

    property Process eventWatcher: Process {
        running: tracker.enabled
        command: [
            Quickshell.shellDir + "/watch-x11-state"
        ]

        stdout: SplitParser {
            onRead: function(line) {
                tracker.handleX11Event(line)
            }
        }

        onRunningChanged: {
            if (!running && tracker.enabled) {
                eventWatcherRestart.restart()
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
                const nextWindows = tracker.windowScanBuffer.slice()
                if (!tracker.sameWindowList(
                        tracker.clientWindows, nextWindows)) {
                    tracker.clientWindows = nextWindows
                }
                tracker.rememberClientWindow(tracker.activeWindow)
                tracker.reconcilePendingActiveWindows()
                if (tracker.rescanRequested) {
                    tracker.rescanRequested = false
                    windowScanDelay.restart()
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

    property Timer eventWatcherRestart: Timer {
        interval: 2000
        onTriggered: {
            if (tracker.enabled && !eventWatcher.running) {
                eventWatcher.running = true
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

}
