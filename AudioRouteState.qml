import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

QtObject {
    id: root

    property alias routes: adapter.routes
    property var sinkIndices: ({})
    property int monitoringClients: 0
    property bool listenerRetryReady: true
    readonly property bool monitoringActive:
        routes.length > 0 || monitoringClients > 0
    readonly property var mediaPlayers:
        monitoringActive ? Mpris.players.values : []

    function acquireMonitoring() {
        monitoringClients += 1
    }

    function releaseMonitoring() {
        monitoringClients = Math.max(0, monitoringClients - 1)
    }

    function normalized(value) {
        return String(value || "").trim().toLowerCase().replace(/\s+/g, " ")
    }

    function streamProperty(stream, key, fallback) {
        const properties = stream && stream.properties ? stream.properties : ({})
        if (properties[key] !== undefined && String(properties[key]).length > 0) {
            return String(properties[key])
        }
        return fallback || ""
    }

    function streamApplication(stream) {
        return streamProperty(stream, "application.name",
            streamProperty(stream, "application.process.binary", "Audio stream"))
    }

    function mediaName(stream) {
        return streamProperty(stream, "media.name", "")
    }

    function mediaNameIsGeneric(value) {
        const name = normalized(value)
        return name.length === 0 || name === "audiostream" || name === "playback"
            || name === "audio" || name === "unknown"
    }

    function matchingPlayer(stream) {
        const app = normalized(streamApplication(stream))
        let fallback = null
        for (let index = 0; index < mediaPlayers.length; ++index) {
            const player = mediaPlayers[index]
            const identity = normalized(player.identity)
            const desktop = normalized(player.desktopEntry)
            const dbus = normalized(player.dbusName)
            const matches = (identity.length > 0
                    && (identity.indexOf(app) !== -1 || app.indexOf(identity) !== -1))
                || (desktop.length > 0
                    && (desktop.indexOf(app) !== -1 || app.indexOf(desktop) !== -1))
                || (dbus.length > 0 && dbus.indexOf(app) !== -1)
            if (!matches) {
                continue
            }
            if (player.isPlaying && player.trackTitle) {
                return player
            }
            if (!fallback && player.trackTitle) {
                fallback = player
            }
        }
        return fallback
    }

    function liveKey(stream) {
        const app = normalized(streamApplication(stream))
        const processId = streamProperty(stream, "application.process.id", "0")
        return "live|" + app + "|" + processId + "|" + String(stream.index)
    }

    function mediaKey(stream) {
        const media = mediaName(stream)
        if (mediaNameIsGeneric(media)) {
            return ""
        }
        return "media|" + normalized(streamApplication(stream))
            + "|" + normalized(media)
    }

    function mprisKey(stream) {
        // A paused generic browser stream cannot be reliably paired with the
        // currently active MPRIS tab. Its live key still keeps it separate.
        if (stream.corked) {
            return ""
        }
        const player = matchingPlayer(stream)
        if (!player || !player.trackTitle) {
            return ""
        }
        return "mpris|" + normalized(streamApplication(stream))
            + "|" + normalized(player.trackTitle)
    }

    function matchKeys(stream) {
        const result = [liveKey(stream)]
        const media = mediaKey(stream)
        const mpris = mprisKey(stream)
        if (media && result.indexOf(media) === -1) {
            result.push(media)
        }
        if (mpris && result.indexOf(mpris) === -1) {
            result.push(mpris)
        }
        return result
    }

    function ruleForStream(stream) {
        if (!stream) {
            return null
        }
        const keys = matchKeys(stream)
        for (let keyIndex = 0; keyIndex < keys.length; ++keyIndex) {
            for (let routeIndex = routes.length - 1; routeIndex >= 0; --routeIndex) {
                if (routes[routeIndex].key === keys[keyIndex]) {
                    return routes[routeIndex]
                }
            }
        }
        return null
    }

    function rememberRoute(stream, sink) {
        if (!stream || !sink || !sink.name) {
            return
        }
        const keys = matchKeys(stream)
        const existing = ruleForStream(stream)
        const groupId = existing && existing.groupId
            ? existing.groupId : liveKey(stream)
        const next = routes.filter(function(route) {
            return route.groupId !== groupId && keys.indexOf(route.key) === -1
        })
        const label = streamApplication(stream)
        const now = Date.now()
        for (let index = 0; index < keys.length; ++index) {
            next.push({
                key: keys[index],
                groupId: groupId,
                sinkName: String(sink.name),
                label: label,
                updatedAt: now
            })
        }
        // Prevent abandoned video-title rules from growing without a bound.
        adapter.routes = next.slice(Math.max(0, next.length - 120))
        scanDelay.restart()
        metadataFollowup.restart()
    }

    function forgetRoute(stream) {
        if (!stream) {
            return
        }
        const keys = matchKeys(stream)
        const existing = ruleForStream(stream)
        const groupId = existing ? existing.groupId : ""
        adapter.routes = routes.filter(function(route) {
            return (!groupId || route.groupId !== groupId)
                && keys.indexOf(route.key) === -1
        })
    }

    function parseSinks(output) {
        try {
            const parsed = JSON.parse(String(output || "[]"))
            const next = ({})
            for (let index = 0; index < parsed.length; ++index) {
                next[String(parsed[index].name)] = Number(parsed[index].index)
            }
            sinkIndices = next
            scanDelay.restart()
        } catch (error) {
            console.warn("[audio-routes] Could not read outputs:", error)
        }
    }

    function applyRoutes(output) {
        let streams = []
        try {
            const parsed = JSON.parse(String(output || "[]"))
            streams = Array.isArray(parsed) ? parsed : []
        } catch (error) {
            console.warn("[audio-routes] Could not read streams:", error)
            return
        }

        for (let index = 0; index < streams.length; ++index) {
            const stream = streams[index]
            const rule = ruleForStream(stream)
            if (!rule || sinkIndices[rule.sinkName] === undefined) {
                continue
            }
            const wantedIndex = Number(sinkIndices[rule.sinkName])
            if (Number(stream.sink) === wantedIndex) {
                continue
            }
            console.info("[audio-routes] Restoring", streamApplication(stream),
                "#" + stream.index, "to", rule.sinkName)
            Quickshell.execDetached([
                "pactl", "move-sink-input", String(stream.index), rule.sinkName
            ])
        }
    }

    function refreshSinks() {
        if (!sinkQuery.running) {
            sinkQuery.exec(["pactl", "-f", "json", "list", "sinks"])
        }
    }

    function scanStreams() {
        if (!streamQuery.running) {
            streamQuery.exec(["pactl", "-f", "json", "list", "sink-inputs"])
        }
    }

    function handleEvent(line) {
        const event = String(line || "")
        if (event.indexOf("sink-input") !== -1) {
            scanDelay.restart()
            metadataFollowup.restart()
        } else if (event.indexOf(" on sink #") !== -1
                || event.indexOf(" on server") !== -1) {
            sinkRefreshDelay.restart()
        }
    }

    property Process eventListener: Process {
        running: root.monitoringActive && root.listenerRetryReady
        command: ["stdbuf", "-oL", "pactl", "subscribe"]

        stdout: SplitParser {
            onRead: function(line) { root.handleEvent(line) }
        }

        onRunningChanged: {
            if (!running && root.monitoringActive
                    && root.listenerRetryReady) {
                root.listenerRetryReady = false
                listenerRestart.restart()
            }
        }
    }

    property Process sinkQuery: Process {
        stdout: StdioCollector {
            onStreamFinished: root.parseSinks(text)
        }
    }

    property Process streamQuery: Process {
        stdout: StdioCollector {
            onStreamFinished: root.applyRoutes(text)
        }
    }

    property Timer scanDelay: Timer {
        interval: 420
        onTriggered: root.scanStreams()
    }

    property Timer metadataFollowup: Timer {
        // Gives browser MPRIS metadata time to follow a resumed audio stream.
        interval: 1400
        onTriggered: root.scanStreams()
    }

    property Timer sinkRefreshDelay: Timer {
        interval: 300
        onTriggered: root.refreshSinks()
    }

    property Timer listenerRestart: Timer {
        interval: 2500
        onTriggered: {
            if (root.monitoringActive) {
                root.listenerRetryReady = true
            }
        }
    }

    property FileView storage: FileView {
        path: Quickshell.shellDir + "/audio-routes.json"
        preload: true
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        printErrors: true

        onFileChanged: {
            reload()
            scanDelay.restart()
        }
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property var routes: []
        }
    }

    onMonitoringActiveChanged: {
        if (monitoringActive) {
            refreshSinks()
            scanDelay.restart()
        } else {
            listenerRetryReady = true
            scanDelay.stop()
            metadataFollowup.stop()
            sinkRefreshDelay.stop()
            listenerRestart.stop()
        }
    }

    Component.onCompleted: {
        if (monitoringActive) {
            refreshSinks()
            scanDelay.restart()
        }
    }
}
