import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    required property var clockSource

    property alias brightness: adapter.brightness
    property alias nightLightEnabled: adapter.nightLightEnabled
    property alias automaticEnabled: adapter.automaticEnabled
    property alias temperature: adapter.temperature
    property alias startTime: adapter.startTime
    property alias endTime: adapter.endTime

    property bool ready: false
    property bool confirmationPending: false
    property int confirmationSeconds: 0
    property string previousOutput: ""
    property string previousMode: ""
    property string previousRate: ""
    property int startupReapplyStep: 0

    signal displayModeChanged(bool reverted)

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, Number(value)))
    }

    function timeMinutes(value) {
        const match = String(value || "").match(/^(\d{1,2}):(\d{2})$/)
        if (!match) {
            return -1
        }
        const hour = Number(match[1])
        const minute = Number(match[2])
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            return -1
        }
        return hour * 60 + minute
    }

    function normalizedTime(value) {
        const minutes = timeMinutes(value)
        if (minutes < 0) {
            return ""
        }
        const hour = Math.floor(minutes / 60)
        const minute = minutes % 60
        return String(hour).padStart(2, "0") + ":"
            + String(minute).padStart(2, "0")
    }

    function scheduleIsActive(dateValue) {
        const date = dateValue instanceof Date ? dateValue : new Date()
        const current = date.getHours() * 60 + date.getMinutes()
        const start = timeMinutes(startTime)
        const end = timeMinutes(endTime)
        if (start < 0 || end < 0 || start === end) {
            return false
        }
        return start < end
            ? current >= start && current < end
            : current >= start || current < end
    }

    function notifyNightLight(enabled) {
        const title = enabled ? "Night Light enabled" : "Night Light disabled"
        const message = enabled
            ? "Color temperature was set to " + temperature + " K."
            : "Display colors returned to daytime mode."
        Quickshell.execDetached([
            "notify-send", "-a", "Quickshell", "-i", "weather-clear-night-symbolic",
            title, message
        ])
    }

    function applyVisuals(nightOverride, brightnessOverride, temperatureOverride) {
        // JsonAdapter property notifications are asynchronous. Setters pass the
        // requested values explicitly so Redshift never sees the previous state.
        const requestedNight = nightOverride === undefined
            ? nightLightEnabled : Boolean(nightOverride)
        const requestedBrightness = brightnessOverride === undefined
            ? brightness : Number(brightnessOverride)
        const requestedTemperature = temperatureOverride === undefined
            ? temperature : Number(temperatureOverride)
        const safeBrightness = clamp(requestedBrightness, 0.1, 1.0)
        const safeTemperature = requestedNight
            ? Math.round(clamp(requestedTemperature, 3000, 6000)) : 6500
        const level = safeBrightness.toFixed(2)
        console.info("[display] Night Light:", requestedNight,
            "temperature:", safeTemperature, "brightness:", level)
        // One-shot Redshift updates the X11 gamma ramps and exits immediately.
        // It handles both brightness and colour temperature, so no daemon runs.
        Quickshell.execDetached([
            "redshift", "-P", "-O", String(safeTemperature),
            "-b", level + ":" + level
        ])
    }

    function evaluateAutomatic(notifyChange) {
        if (!automaticEnabled) {
            return
        }
        // Always read the wall clock directly. The minute clock may still hold
        // its pre-suspend value during the first moments after resume.
        const target = scheduleIsActive(new Date())
        if (nightLightEnabled === target) {
            return
        }
        adapter.nightLightEnabled = target
        applyVisuals(target, brightness, temperature)
        if (ready && notifyChange) {
            notifyNightLight(target)
        }
    }

    function reapplyForCurrentTime(notifyChange) {
        const before = Boolean(nightLightEnabled)
        const target = automaticEnabled ? scheduleIsActive(new Date()) : before
        if (automaticEnabled) {
            adapter.nightLightEnabled = target
        }
        applyVisuals(target, brightness, temperature)
        if (ready && notifyChange && before !== target) {
            notifyNightLight(target)
        }
    }

    function beginStartupReapply() {
        // XFCE can restore its display profile shortly after session clients
        // start. Confirm the gamma a few times, then stop completely.
        startupReapplyStep = 0
        startupReapply.restart()
    }

    function handleSleepSignal(line) {
        const message = String(line || "")
        if (message.indexOf("PrepareForSleep") === -1
                || (message.indexOf("(false") === -1
                    && message.indexOf("boolean false") === -1)) {
            return
        }
        reapplyForCurrentTime(true)
        beginStartupReapply()
    }

    function setBrightness(value) {
        const target = clamp(value, 0.1, 1.0)
        adapter.brightness = target
        applyVisuals(nightLightEnabled, target, temperature)
    }

    function setTemperature(value) {
        const target = Math.round(clamp(value, 3000, 6000) / 50) * 50
        adapter.temperature = target
        if (nightLightEnabled) {
            applyVisuals(true, brightness, target)
        }
    }

    function setNightLight(enabled) {
        // A manual change becomes authoritative until automatic mode is enabled again.
        const target = Boolean(enabled)
        adapter.automaticEnabled = false
        adapter.nightLightEnabled = target
        applyVisuals(target, brightness, temperature)
    }

    function setAutomatic(enabled) {
        const targetAutomatic = Boolean(enabled)
        adapter.automaticEnabled = targetAutomatic
        if (targetAutomatic) {
            const before = Boolean(nightLightEnabled)
            const targetNight = scheduleIsActive(new Date())
            adapter.nightLightEnabled = targetNight
            applyVisuals(targetNight, brightness, temperature)
            if (ready && before !== targetNight) {
                notifyNightLight(targetNight)
            }
        }
    }

    function setStartTime(value) {
        const normalized = normalizedTime(value)
        if (normalized.length === 0) {
            return false
        }
        adapter.startTime = normalized
        evaluateAutomatic(false)
        return true
    }

    function setEndTime(value) {
        const normalized = normalizedTime(value)
        if (normalized.length === 0) {
            return false
        }
        adapter.endTime = normalized
        evaluateAutomatic(false)
        return true
    }

    function requestMode(output, mode, rate, oldMode, oldRate) {
        if (!output || !mode || !rate) {
            return
        }
        previousOutput = String(output)
        previousMode = String(oldMode)
        previousRate = String(oldRate)
        confirmationSeconds = 15
        confirmationPending = true
        Quickshell.execDetached([
            "xrandr", "--output", String(output), "--mode", String(mode),
            "--rate", String(rate)
        ])
        gammaReapply.restart()
    }

    function confirmMode() {
        confirmationPending = false
        confirmationSeconds = 0
        displayModeChanged(false)
    }

    function revertMode() {
        if (!confirmationPending) {
            return
        }
        confirmationPending = false
        confirmationSeconds = 0
        if (previousOutput && previousMode && previousRate) {
            Quickshell.execDetached([
                "xrandr", "--output", previousOutput, "--mode", previousMode,
                "--rate", previousRate
            ])
            gammaReapply.restart()
        }
        displayModeChanged(true)
    }

    property Timer confirmationTimer: Timer {
        interval: 1000
        repeat: true
        running: root.confirmationPending
        onTriggered: {
            if (root.confirmationSeconds <= 1) {
                root.revertMode()
            } else {
                root.confirmationSeconds -= 1
            }
        }
    }

    property Timer gammaReapply: Timer {
        interval: 450
        onTriggered: root.applyVisuals()
    }

    property Timer startupReapply: Timer {
        interval: 1500
        repeat: true

        onTriggered: {
            root.reapplyForCurrentTime(false)
            root.startupReapplyStep += 1
            if (root.startupReapplyStep >= 3) {
                stop()
            }
        }
    }

    property Process sleepMonitor: Process {
        running: true
        command: [
            "stdbuf", "-oL", "gdbus", "monitor", "--system",
            "--dest", "org.freedesktop.login1",
            "--object-path", "/org/freedesktop/login1"
        ]

        stdout: SplitParser {
            onRead: function(line) { root.handleSleepSignal(line) }
        }

        onRunningChanged: {
            if (!running) {
                sleepMonitorRestart.restart()
            }
        }
    }

    property Timer sleepMonitorRestart: Timer {
        interval: 3000
        onTriggered: root.sleepMonitor.running = true
    }

    property Connections clockConnection: Connections {
        target: root.clockSource

        function onDateChanged() {
            root.evaluateAutomatic(true)
        }
    }

    property FileView storage: FileView {
        path: Quickshell.shellDir + "/display-state.json"
        preload: true
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        printErrors: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property real brightness: 1.0
            property bool nightLightEnabled: false
            property bool automaticEnabled: true
            property int temperature: 4200
            property string startTime: "20:00"
            property string endTime: "07:00"
        }
    }

    Component.onCompleted: Qt.callLater(function() {
        root.reapplyForCurrentTime(false)
        root.ready = true
        root.beginStartupReapply()
    })
}
