import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Item {
    id: root

    required property var host
    required property var themeData
    required property var barItem
    required property var anchorItem

    readonly property real anchorCenterX: {
        if (anchorItem) {
            return anchorItem.mapToItem(
                root, anchorItem.width / 2, anchorItem.height / 2).x
        }
        return barItem.x + barItem.width - themeData.sideMargin
    }

    property string audioDeviceChooser: ""
    property bool routeViewOpen: false
    property string routePage: "streams"
    property var routeStreams: []
    property var routeSinks: []
    property var selectedRouteStream: null
    property string routingStatus: ""
    property string routingError: ""
    property var pendingRouteSink: null
    readonly property var defaultRouteChoice: ({
        isDefaultChoice: true,
        index: -1,
        name: host.audioSink ? String(host.audioSink.name || "") : "",
        description: "Default output"
    })
    readonly property var routeOutputChoices:
        [defaultRouteChoice].concat(routeSinks)
    readonly property var pipewireNodes: Pipewire.nodes.values
    readonly property var audioSinks: pipewireNodes.filter(function(node) {
        return node && node.audio && node.isSink && !node.isStream
    }).sort(function(first, second) {
        return String(first.description || first.name).localeCompare(
            String(second.description || second.name))
    })
    readonly property var audioSources: pipewireNodes.filter(function(node) {
        return node && node.audio && !node.isSink && !node.isStream
    }).sort(function(first, second) {
        return String(first.description || first.name).localeCompare(
            String(second.description || second.name))
    })
    readonly property var audioStreams: pipewireNodes.filter(function(node) {
        return node && node.audio && node.isStream && node.isSink
    })
    readonly property var microphoneSource: Pipewire.defaultAudioSource
    readonly property var microphoneControl:
        microphoneSource ? microphoneSource.audio : null
    readonly property bool microphoneAvailable: microphoneControl !== null
    readonly property real microphoneVolume:
        microphoneAvailable ? microphoneControl.volume : 0
    readonly property bool microphoneMuted:
        microphoneAvailable ? microphoneControl.muted : true
    readonly property int microphonePercent: Math.round(microphoneVolume * 100)
    readonly property string microphoneDescription: microphoneSource
        ? (microphoneSource.description || microphoneSource.nickname
            || microphoneSource.name || "Microphone")
        : "No microphone"
    readonly property var mediaPlayers: Mpris.players.values
    readonly property var mediaPlayer: {
        for (let index = 0; index < mediaPlayers.length; ++index) {
            if (mediaPlayers[index].isPlaying) {
                return mediaPlayers[index]
            }
        }
        for (let index = 0; index < mediaPlayers.length; ++index) {
            if (mediaPlayers[index].trackTitle) {
                return mediaPlayers[index]
            }
        }
        return mediaPlayers.length > 0 ? mediaPlayers[0] : null
    }
    readonly property bool mediaAvailable: mediaPlayer !== null
        || audioStreams.length > 0
    readonly property string mediaTitle: mediaPlayer
        ? (mediaPlayer.trackTitle || mediaPlayer.identity || "Media playback")
        : (audioStreams.length > 0
            ? (audioStreams[0].description || audioStreams[0].name || "Audio stream")
            : "Nothing playing")
    readonly property string mediaSubtitle: mediaPlayer
        ? (mediaPlayer.trackArtist || mediaPlayer.identity || "Player media")
        : (audioStreams.length > 0 ? "Active audio stream" : "")

    function setMicrophoneVolume(value) {
        if (microphoneAvailable) {
            microphoneControl.volume = Math.max(0, Math.min(1, Number(value)))
        }
    }

    function toggleMicrophoneMute() {
        if (microphoneAvailable) {
            microphoneControl.muted = !microphoneControl.muted
        }
    }

    function openAudioDeviceChooser(kind) {
        routeViewOpen = false
        audioDeviceChooser = kind === "source" ? "source" : "sink"
    }

    function selectAudioDevice(node) {
        if (!node) {
            return
        }
        if (audioDeviceChooser === "source") {
            Pipewire.preferredDefaultAudioSource = node
        } else {
            Pipewire.preferredDefaultAudioSink = node
        }
        audioDeviceChooser = ""
    }

    function toggleMediaPlayback() {
        if (mediaPlayer && mediaPlayer.canTogglePlaying) {
            mediaPlayer.togglePlaying()
        }
    }

    function previousMediaTrack() {
        if (mediaPlayer && mediaPlayer.canGoPrevious) {
            mediaPlayer.previous()
        }
    }

    function nextMediaTrack() {
        if (mediaPlayer && mediaPlayer.canGoNext) {
            mediaPlayer.next()
        }
    }

    function streamProperty(properties, key, fallback) {
        if (properties && properties[key] !== undefined
                && String(properties[key]).length > 0) {
            return String(properties[key])
        }
        return fallback || ""
    }

    function streamLabel(stream) {
        const properties = stream.properties || ({})
        return streamProperty(properties, "application.name",
            streamProperty(properties, "application.process.binary", "Audio stream"))
    }

    function streamSubtitle(stream) {
        const properties = stream.properties || ({})
        let mediaName = streamProperty(properties, "media.name", "")
        if (mediaName === "AudioStream" || mediaName === "Playback"
                || mediaName === streamLabel(stream)) {
            mediaName = ""
        }
        const output = sinkDescription(stream.sink)
        return (stream.corked ? "Paused · " : "")
            + (mediaName ? mediaName + " · " : "")
            + (output || "Unknown output")
    }

    function sinkDescription(index) {
        for (let sinkIndex = 0; sinkIndex < routeSinks.length; ++sinkIndex) {
            if (Number(routeSinks[sinkIndex].index) === Number(index)) {
                return routeSinks[sinkIndex].description
                    || routeSinks[sinkIndex].name || "Audio output"
            }
        }
        return ""
    }

    function parseRouteSinks(output) {
        try {
            const parsed = JSON.parse(String(output || "[]"))
            routeSinks = Array.isArray(parsed) ? parsed : []
            routingError = ""
        } catch (error) {
            routeSinks = []
            routingError = "Could not read audio outputs"
        }
    }

    function parseRouteStreams(output) {
        try {
            const parsed = JSON.parse(String(output || "[]"))
            routeStreams = Array.isArray(parsed) ? parsed : []
            routingStatus = routeStreams.length > 0
                ? routeStreams.length + (routeStreams.length === 1
                    ? " active audio stream" : " active audio streams")
                : "No active audio streams"
            routingError = ""
        } catch (error) {
            routeStreams = []
            routingError = "Could not read audio streams"
        }
    }

    function refreshRouting() {
        routingError = ""
        routingStatus = "Refreshing…"
        if (!routeSinkQuery.running) {
            routeSinkQuery.exec(["pactl", "-f", "json", "list", "sinks"])
        }
        if (!routeStreamQuery.running) {
            routeStreamQuery.exec([
                "pactl", "-f", "json", "list", "sink-inputs"
            ])
        }
    }

    function openStreamRouter() {
        audioDeviceChooser = ""
        routePage = "streams"
        selectedRouteStream = null
        routeViewOpen = true
        refreshRouting()
    }

    function chooseStream(stream) {
        selectedRouteStream = stream
        routePage = "outputs"
    }

    function routeSelectedStream(sink) {
        if (!selectedRouteStream || !sink || routeMoveProcess.running) {
            return
        }
        let actualSink = sink
        if (sink.isDefaultChoice) {
            actualSink = null
            for (let index = 0; index < routeSinks.length; ++index) {
                if (routeSinks[index].name === sink.name) {
                    actualSink = routeSinks[index]
                    break
                }
            }
        }
        if (!actualSink || !actualSink.name) {
            routingError = "The default output is unavailable"
            return
        }
        pendingRouteSink = sink
        routingError = ""
        routingStatus = "Moving stream…"
        routeMoveProcess.exec([
            "pactl", "move-sink-input", String(selectedRouteStream.index),
            String(actualSink.name)
        ])
    }

    Process {
        id: routeSinkQuery

        stdout: StdioCollector {
            onStreamFinished: root.parseRouteSinks(text)
        }
    }

    Process {
        id: routeStreamQuery

        stdout: StdioCollector {
            onStreamFinished: root.parseRouteStreams(text)
        }
    }

    Process {
        id: routeMoveProcess

        stderr: StdioCollector {
            onStreamFinished: root.routingError = String(text || "").trim()
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                if (root.pendingRouteSink && root.pendingRouteSink.isDefaultChoice) {
                    host.audioRouteState.forgetRoute(root.selectedRouteStream)
                    root.routingStatus = "The stream follows the default output"
                } else if (root.pendingRouteSink) {
                    host.audioRouteState.rememberRoute(
                        root.selectedRouteStream, root.pendingRouteSink)
                    root.routingStatus = "Stream moved and remembered on "
                        + (root.pendingRouteSink.description
                            || root.pendingRouteSink.name)
                }
                root.routePage = "streams"
                root.selectedRouteStream = null
                routeRefreshDelay.restart()
            } else if (!root.routingError) {
                root.routingError = "Failed to move the audio stream"
            }
            root.pendingRouteSink = null
        }
    }

    Timer {
        id: routeRefreshDelay
        interval: 350
        onTriggered: root.refreshRouting()
    }

    // All devices and streams are tracked only while this component exists.
    PwObjectTracker {
        objects: root.pipewireNodes
    }
    MouseArea {
        id: audioDismissArea

        x: 0
        y: 0
        width: host.width
        height: Math.max(0, barItem.y)
        visible: host.audioOpen
        z: 18
        onClicked: host.closeAudio()
    }

    Rectangle {
        id: audioPopup

        x: Math.max(themeData.sideMargin, Math.min(
            root.anchorCenterX - width / 2,
            host.width - themeData.sideMargin - width))
        y: barItem.y - 8 - height
        width: 286
        height: host.audioPopupHeight
        radius: themeData.radius
        color: Qt.rgba(themeData.base.r, themeData.base.g, themeData.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(themeData.surface2.r, themeData.surface2.g, themeData.surface2.b, 0.82)
        property bool entered: false
        opacity: entered && host.audioOpen ? 1 : 0
        scale: entered && host.audioOpen ? 1 : 0.96
        transformOrigin: Item.Bottom
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
spacing: 8

Row {
    width: parent.width
    height: 30
    spacing: 9

    IconImage {
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 23
        source: host.audioIconSource
        mipmap: true
    }

    Column {
        y: Math.round((parent.height - height) / 2)
        width: parent.width - 79
        spacing: -1

        Text {
            text: "Audio output  ▾"
            color: themeData.text
            font.family: themeData.fontFamily
            font.pixelSize: 13
            font.weight: Font.Normal
        }

        Text {
            width: parent.width
            text: host.audioDescription
            color: themeData.overlay
            elide: Text.ElideRight
            font.family: themeData.fontFamily
            font.pixelSize: 9
        }

        TapHandler {
            cursorShape: Qt.PointingHandCursor
            onTapped: root.openAudioDeviceChooser("sink")
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        text: host.audioAvailable ? host.audioPercent + "%" : "—"
        color: host.audioMuted ? themeData.red : themeData.mauve
        horizontalAlignment: Text.AlignRight
        font.family: themeData.monoFamily
        font.pixelSize: 12
        font.weight: Font.Normal

        Behavior on color { ColorAnimation { duration: 100 } }
    }
}

Item {
    id: volumeSlider

    width: parent.width
    height: 34
    enabled: host.audioAvailable
    readonly property real level: Math.max(0, Math.min(1, host.audioVolume))

    Rectangle {
        id: volumeTrack

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 3
            rightMargin: 3
        }
        height: 6
        radius: 3
        color: themeData.surface1

        Rectangle {
            width: parent.width * volumeSlider.level
            height: parent.height
            radius: parent.radius
            color: host.audioMuted ? themeData.red : themeData.mauve

            Behavior on width {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Rectangle {
            x: Math.max(-width / 2,
                Math.min(parent.width - width / 2,
                    parent.width * volumeSlider.level - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: volumePointer.pressed ? 15 : 13
            height: width
            radius: width / 2
            color: themeData.rosewater
            border.width: 2
            border.color: themeData.mauve

            Behavior on x {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }
            Behavior on width { NumberAnimation { duration: 80 } }
        }
    }

    MouseArea {
        id: volumePointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function setFromX(pointerX) {
            const trackX = volumeTrack.x
            const ratio = (pointerX - trackX) / volumeTrack.width
            host.setAudioVolume(ratio)
        }

        onPressed: function(mouse) {
            setFromX(mouse.x)
        }
        onPositionChanged: function(mouse) {
            if (pressed) {
                setFromX(mouse.x)
            }
        }
        onWheel: function(wheel) {
            host.adjustAudioVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
            wheel.accepted = true
        }
    }
}

Row {
    width: parent.width
    height: 34
    spacing: 8

    Rectangle {
        width: (parent.width - parent.spacing) / 2
        height: parent.height
        radius: 9
        color: mutePointer.containsMouse
            ? Qt.rgba(themeData.surface2.r, themeData.surface2.g, themeData.surface2.b, 0.72)
            : (host.audioMuted
                ? Qt.rgba(themeData.red.r, themeData.red.g, themeData.red.b, 0.18)
                : themeData.surface0)

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: host.audioMuted ? "Unmute" : "Mute"
            color: host.audioMuted ? themeData.red : themeData.text
            font.family: themeData.fontFamily
            font.pixelSize: 11
            font.weight: Font.Normal
        }

        MouseArea {
            id: mutePointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: host.toggleAudioMute()
        }
    }

    Rectangle {
        width: (parent.width - parent.spacing) / 2
        height: parent.height
        radius: 9
        color: mixerPointer.containsMouse ? themeData.surface1 : themeData.surface0

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: "Route audio"
            color: themeData.subtext
            font.family: themeData.fontFamily
            font.pixelSize: 11
            font.weight: Font.Normal
        }

        MouseArea {
            id: mixerPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openStreamRouter()
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
    height: 30
    spacing: 9

    IconImage {
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 22
        source: root.microphoneMuted
            ? "file://" + Quickshell.shellDir
                + "/assets/icons/catppuccin-microphone-muted.svg"
            : "file://" + Quickshell.shellDir
                + "/assets/icons/catppuccin-microphone.svg"
        mipmap: true
        opacity: root.microphoneAvailable ? 1 : 0.45

        MouseArea {
            anchors.fill: parent
            enabled: root.microphoneAvailable
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMicrophoneMute()
        }
    }

    Column {
        y: Math.round((parent.height - height) / 2)
        width: parent.width - 79
        spacing: -1

        Text {
            text: "Microphone  ▾"
            color: themeData.text
            font.family: themeData.fontFamily
            font.pixelSize: 12
            font.weight: Font.Normal
        }

        Text {
            width: parent.width
            text: root.microphoneDescription
            color: themeData.overlay
            elide: Text.ElideRight
            font.family: themeData.fontFamily
            font.pixelSize: 9
        }

        TapHandler {
            cursorShape: Qt.PointingHandCursor
            onTapped: root.openAudioDeviceChooser("source")
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        text: root.microphoneAvailable
            ? root.microphonePercent + "%"
            : "—"
        color: root.microphoneMuted ? themeData.red : themeData.blue
        horizontalAlignment: Text.AlignRight
        font.family: themeData.monoFamily
        font.pixelSize: 11
        font.weight: Font.Normal

        Behavior on color { ColorAnimation { duration: 100 } }
    }
}

Item {
    id: microphoneSlider

    width: parent.width
    height: 28
    enabled: root.microphoneAvailable
    readonly property real level:
        Math.max(0, Math.min(1, root.microphoneVolume))

    Rectangle {
        id: microphoneTrack

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 3
            rightMargin: 3
        }
        height: 5
        radius: 3
        color: themeData.surface1

        Rectangle {
            width: parent.width * microphoneSlider.level
            height: parent.height
            radius: parent.radius
            color: root.microphoneMuted ? themeData.red : themeData.blue

            Behavior on width {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Rectangle {
            x: Math.max(-width / 2,
                Math.min(parent.width - width / 2,
                    parent.width * microphoneSlider.level - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: microphonePointer.pressed ? 14 : 12
            height: width
            radius: width / 2
            color: themeData.rosewater
            border.width: 2
            border.color: themeData.blue

            Behavior on x {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }
            Behavior on width { NumberAnimation { duration: 80 } }
        }
    }

    MouseArea {
        id: microphonePointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function setFromX(pointerX) {
            const ratio = (pointerX - microphoneTrack.x)
                / microphoneTrack.width
            root.setMicrophoneVolume(ratio)
        }

        onPressed: function(mouse) {
            setFromX(mouse.x)
        }
        onPositionChanged: function(mouse) {
            if (pressed) {
                setFromX(mouse.x)
            }
        }
        onWheel: function(wheel) {
            root.setMicrophoneVolume(root.microphoneVolume
                + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
            wheel.accepted = true
        }
    }
}

Rectangle {
    width: parent.width
    height: 1
    color: themeData.surface0
}

Rectangle {
    width: parent.width
    height: 68
    radius: 10
    color: themeData.surface0

    Row {
        anchors {
            fill: parent
            margins: 9
        }
        spacing: 8

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 23
            source: "file://" + Quickshell.shellDir
                + "/assets/icons/catppuccin-media.svg"
            mipmap: true
            opacity: root.mediaAvailable ? 1 : 0.42
        }

        Column {
            y: Math.round((parent.height - height) / 2)
            width: parent.width - 104
            spacing: 0

            Text {
                text: "Now playing"
                color: themeData.overlay
                font.family: themeData.fontFamily
                font.pixelSize: 9
            }

            Text {
                width: parent.width
                text: root.mediaTitle
                color: themeData.text
                elide: Text.ElideRight
                font.family: themeData.fontFamily
                font.pixelSize: 11
                font.weight: Font.Normal
            }

            Text {
                width: parent.width
                text: root.mediaSubtitle
                color: themeData.subtext
                elide: Text.ElideRight
                font.family: themeData.fontFamily
                font.pixelSize: 9
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Repeater {
                model: ["previous", "toggle", "next"]

                Rectangle {
                    required property string modelData

                    width: modelData === "toggle" ? 28 : 23
                    height: 28
                    radius: 8
                    color: mediaControlPointer.containsMouse
                        ? themeData.surface2
                        : "transparent"
                    opacity: {
                        if (!root.mediaPlayer) {
                            return 0.35
                        }
                        if (modelData === "previous") {
                            return root.mediaPlayer.canGoPrevious ? 1 : 0.35
                        }
                        if (modelData === "next") {
                            return root.mediaPlayer.canGoNext ? 1 : 0.35
                        }
                        return root.mediaPlayer.canTogglePlaying ? 1 : 0.35
                    }

                    Behavior on color { ColorAnimation { duration: 90 } }

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData === "previous"
                            ? "‹"
                            : (parent.modelData === "next"
                                ? "›"
                                : (root.mediaPlayer
                                    && root.mediaPlayer.isPlaying ? "Ⅱ" : "▶"))
                        color: parent.modelData === "toggle"
                            ? themeData.mauve
                            : themeData.subtext
                        font.family: themeData.fontFamily
                        font.pixelSize: parent.modelData === "toggle" ? 13 : 20
                        font.weight: Font.Normal
                    }

                    MouseArea {
                        id: mediaControlPointer
                        anchors.fill: parent
                        enabled: parent.opacity > 0.5
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (parent.modelData === "previous") {
                                root.previousMediaTrack()
                            } else if (parent.modelData === "next") {
                                root.nextMediaTrack()
                            } else {
                                root.toggleMediaPlayback()
                            }
                        }
                    }
                }
            }
        }
    }
}
        }

        Rectangle {
anchors.fill: parent
radius: parent.radius
color: Qt.rgba(themeData.base.r, themeData.base.g, themeData.base.b, 0.995)
visible: root.audioDeviceChooser.length > 0
z: 30

Column {
    anchors {
        fill: parent
        margins: 12
    }
    spacing: 8

    Row {
        width: parent.width
        height: 34
        spacing: 8

        Rectangle {
            width: 32
            height: 32
            radius: 9
            color: chooserBackPointer.containsMouse
                ? themeData.surface1
                : themeData.surface0

            Text {
                anchors.centerIn: parent
                text: "‹"
                color: themeData.text
                font.family: themeData.fontFamily
                font.pixelSize: 22
            }

            MouseArea {
                id: chooserBackPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.audioDeviceChooser = ""
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.audioDeviceChooser === "source"
                ? "Choose a microphone"
                : "Choose an audio output"
            color: themeData.text
            font.family: themeData.fontFamily
            font.pixelSize: 13
            font.weight: Font.Normal
        }
    }

    ListView {
        id: audioDeviceList

        width: parent.width
        height: parent.height - 42
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        model: root.audioDeviceChooser === "source"
            ? root.audioSources
            : root.audioSinks

        delegate: Rectangle {
            id: deviceChoice

            required property var modelData
            required property int index
            readonly property bool selected:
                root.audioDeviceChooser === "source"
                    ? modelData === root.microphoneSource
                    : modelData === host.audioSink

            width: audioDeviceList.width
            height: 48
            radius: 10
            color: deviceChoicePointer.containsMouse
                ? themeData.surface1
                : (selected
                    ? Qt.rgba(themeData.mauve.r, themeData.mauve.g, themeData.mauve.b, 0.14)
                    : themeData.surface0)
            border.width: selected ? 1 : 0
            border.color: themeData.mauve

            Behavior on color { ColorAnimation { duration: 90 } }

            Rectangle {
                anchors {
                    left: parent.left
                    leftMargin: 11
                    verticalCenter: parent.verticalCenter
                }
                width: 8
                height: 8
                radius: 4
                color: parent.selected ? themeData.mauve : themeData.overlay
            }

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 29
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                text: modelData.description || modelData.nickname
                    || modelData.name || "Audio device"
                color: selected ? themeData.text : themeData.subtext
                elide: Text.ElideRight
                font.family: themeData.fontFamily
                font.pixelSize: 11
                font.weight: Font.Normal
            }

            MouseArea {
                id: deviceChoicePointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectAudioDevice(deviceChoice.modelData)
            }
        }
    }
}
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(themeData.base.r, themeData.base.g,
                themeData.base.b, 0.995)
            visible: root.routeViewOpen
            z: 31

            Column {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 7

                Row {
                    width: parent.width
                    height: 34
                    spacing: 7

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 9
                        color: routeBackPointer.containsMouse
                            ? themeData.surface1 : themeData.surface0

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: themeData.text
                            font.family: themeData.fontFamily
                            font.pixelSize: 22
                        }

                        MouseArea {
                            id: routeBackPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.routePage === "outputs") {
                                    root.routePage = "streams"
                                    root.selectedRouteStream = null
                                } else {
                                    root.routeViewOpen = false
                                }
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 103
                        text: root.routePage === "outputs"
                            ? "Choose output" : "Audio routing"
                        color: themeData.text
                        elide: Text.ElideRight
                        font.family: themeData.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 9
                        visible: root.routePage === "streams"
                        color: routeRefreshPointer.containsMouse
                            ? themeData.surface1 : themeData.surface0
                        opacity: routeSinkQuery.running || routeStreamQuery.running
                            ? 0.5 : 1

                        Text {
                            anchors.centerIn: parent
                            text: "↻"
                            color: themeData.lavender
                            font.family: themeData.fontFamily
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: routeRefreshPointer
                            anchors.fill: parent
                            enabled: !routeSinkQuery.running && !routeStreamQuery.running
                            hoverEnabled: true
                            cursorShape: enabled
                                ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.refreshRouting()
                        }
                    }

                    Item {
                        width: root.routePage === "streams" ? 0 : 32
                        height: 1
                    }

                    Rectangle {
                        width: 55
                        height: 32
                        radius: 9
                        color: fullMixerPointer.containsMouse
                            ? themeData.surface1 : themeData.surface0

                        Text {
                            anchors.centerIn: parent
                            text: "Mixer"
                            color: themeData.subtext
                            font.family: themeData.fontFamily
                            font.pixelSize: 9
                        }

                        MouseArea {
                            id: fullMixerPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                host.closeAudio()
                                Quickshell.execDetached(["pavucontrol"])
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 24
                    text: root.routingError
                        ? root.routingError
                        : (root.routePage === "outputs" && root.selectedRouteStream
                            ? "Move “" + root.streamLabel(root.selectedRouteStream)
                                + "” to:"
                            : root.routingStatus)
                    color: root.routingError ? themeData.red : themeData.overlay
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    font.family: themeData.fontFamily
                    font.pixelSize: 9
                }

                Item {
                    width: parent.width
                    height: parent.height - 72

                    ListView {
                        id: routeList
                        anchors.fill: parent
                        clip: true
                        spacing: 5
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.routePage === "outputs"
                            ? root.routeOutputChoices : root.routeStreams

                        delegate: Rectangle {
                            id: routeChoice

                            required property var modelData
                            required property int index
                            readonly property bool outputChoice:
                                root.routePage === "outputs"
                            readonly property var rememberedRule: outputChoice
                                && root.selectedRouteStream
                                ? host.audioRouteState.ruleForStream(
                                    root.selectedRouteStream) : null
                            readonly property bool selected: outputChoice
                                && (modelData.isDefaultChoice
                                    ? rememberedRule === null
                                    : rememberedRule !== null
                                        && rememberedRule.sinkName === modelData.name)
                            readonly property bool currentOutput: outputChoice
                                && !modelData.isDefaultChoice
                                && root.selectedRouteStream
                                && Number(root.selectedRouteStream.sink)
                                    === Number(modelData.index)

                            width: routeList.width
                            height: 54
                            radius: 10
                            color: routeChoicePointer.containsMouse
                                ? themeData.surface1
                                : (selected
                                    ? Qt.rgba(themeData.mauve.r,
                                        themeData.mauve.g,
                                        themeData.mauve.b, 0.15)
                                    : themeData.surface0)
                            border.width: selected ? 1 : 0
                            border.color: themeData.mauve

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    leftMargin: 9
                                    verticalCenter: parent.verticalCenter
                                }
                                width: 31
                                height: 31
                                radius: 10
                                color: parent.selected
                                    ? Qt.rgba(themeData.mauve.r,
                                        themeData.mauve.g,
                                        themeData.mauve.b, 0.24)
                                    : themeData.mantle

                                Text {
                                    anchors.centerIn: parent
                                    text: routeChoice.outputChoice
                                        ? (routeChoice.modelData.isDefaultChoice
                                            ? "󰋋" : "󰓃")
                                        : root.streamLabel(routeChoice.modelData)
                                            .slice(0, 1).toUpperCase()
                                    color: routeChoice.selected
                                        ? themeData.mauve : themeData.lavender
                                    font.family: themeData.fontFamily
                                    font.pixelSize: routeChoice.outputChoice ? 14 : 11
                                    font.weight: Font.DemiBold
                                }
                            }

                            Column {
                                anchors {
                                    left: parent.left
                                    right: routeArrow.left
                                    leftMargin: 49
                                    rightMargin: 7
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: routeChoice.outputChoice
                                        ? (routeChoice.modelData.description
                                            || routeChoice.modelData.name
                                            || "Audio output")
                                        : root.streamLabel(routeChoice.modelData)
                                            + "  #" + routeChoice.modelData.index
                                    color: routeChoice.selected
                                        ? themeData.text : themeData.subtext
                                    elide: Text.ElideRight
                                    font.family: themeData.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: parent.width
                                    text: routeChoice.outputChoice
                                        ? (routeChoice.modelData.isDefaultChoice
                                            ? (routeChoice.selected
                                                ? "No fixed rule"
                                                : "Remove remembered rule")
                                            : (routeChoice.currentOutput
                                                ? (routeChoice.selected
                                                    ? "Remembered · current output"
                                                    : "Current output")
                                                : (routeChoice.selected
                                                    ? "Remembered for this stream"
                                                    : "Move and remember")))
                                        : root.streamSubtitle(routeChoice.modelData)
                                    color: routeChoice.selected
                                        ? themeData.green : themeData.overlay
                                    elide: Text.ElideRight
                                    font.family: themeData.fontFamily
                                    font.pixelSize: 8
                                }
                            }

                            Text {
                                id: routeArrow
                                anchors {
                                    right: parent.right
                                    rightMargin: 11
                                    verticalCenter: parent.verticalCenter
                                }
                                text: routeChoice.selected ? "✓" : "›"
                                color: routeChoice.selected
                                    ? themeData.green : themeData.mauve
                                font.family: themeData.fontFamily
                                font.pixelSize: routeChoice.selected ? 11 : 17
                            }

                            MouseArea {
                                id: routeChoicePointer
                                anchors.fill: parent
                                enabled: !routeMoveProcess.running
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (routeChoice.outputChoice) {
                                        root.routeSelectedStream(routeChoice.modelData)
                                    } else {
                                        root.chooseStream(routeChoice.modelData)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: routeList.count === 0
                            && !routeSinkQuery.running && !routeStreamQuery.running
                        width: parent.width - 28
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.routePage === "outputs"
                            ? "No audio outputs are available."
                            : "Start an audio source, then press ↻ to refresh."
                        color: themeData.overlay
                        font.family: themeData.fontFamily
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
