import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var themeData
    required property var displayState
    required property real barX
    required property real barY
    required property real barWidth

    property real brightnessDraft: Number(displayState.brightness)
    property real temperatureDraft: Number(displayState.temperature)
    property string outputName: ""
    property string currentMode: ""
    property string currentRate: ""
    property string selectedMode: ""
    property string selectedRate: ""
    property var modes: []
    property string statusMessage: "Reading display modes…"

    signal closeRequested()
    signal tabRequested(string tab)

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, Number(value)))
    }

    function formatRate(value) {
        const number = Number(value)
        if (!isFinite(number)) {
            return "—"
        }
        return Math.abs(number - Math.round(number)) < 0.03
            ? Math.round(number) + " Hz" : number.toFixed(2) + " Hz"
    }

    function ratesForMode(modeName) {
        for (let index = 0; index < modes.length; ++index) {
            if (modes[index].name === modeName) {
                return modes[index].rates
            }
        }
        return []
    }

    function selectMode(modeName) {
        selectedMode = String(modeName || "")
        const rates = ratesForMode(selectedMode)
        if (selectedMode === currentMode && rates.indexOf(currentRate) !== -1) {
            selectedRate = currentRate
        } else {
            selectedRate = rates.length > 0 ? rates[0] : ""
        }
    }

    function cycleMode(direction) {
        if (modes.length < 1) {
            return
        }
        let index = 0
        for (let candidate = 0; candidate < modes.length; ++candidate) {
            if (modes[candidate].name === selectedMode) {
                index = candidate
                break
            }
        }
        index = (index + direction + modes.length) % modes.length
        selectMode(modes[index].name)
    }

    function cycleRate(direction) {
        const rates = ratesForMode(selectedMode)
        if (rates.length < 1) {
            return
        }
        let index = rates.indexOf(selectedRate)
        if (index < 0) {
            index = 0
        }
        index = (index + direction + rates.length) % rates.length
        selectedRate = rates[index]
    }

    function parseXrandr(output) {
        const lines = String(output || "").split("\n")
        let collecting = false
        let foundOutput = ""
        let foundCurrentMode = ""
        let foundCurrentRate = ""
        const foundModes = []

        for (let index = 0; index < lines.length; ++index) {
            const line = lines[index]
            const connected = line.match(
                /^(\S+)\s+connected(?:\s+primary)?(?:\s+(\d+x\d+)\+\d+\+\d+)?/)
            if (connected) {
                collecting = foundOutput.length === 0 && Boolean(connected[2])
                if (collecting) {
                    foundOutput = connected[1]
                    foundCurrentMode = connected[2]
                }
                continue
            }
            if (!collecting) {
                continue
            }
            if (/^\S/.test(line)) {
                collecting = false
                continue
            }
            const modeLine = line.match(/^\s+(\d+x\d+)\s+(.+)$/)
            if (!modeLine) {
                continue
            }
            const rates = []
            const tokens = modeLine[2].trim().split(/\s+/)
            for (let tokenIndex = 0; tokenIndex < tokens.length; ++tokenIndex) {
                const token = tokens[tokenIndex]
                const numeric = token.replace(/[^0-9.]/g, "")
                const rate = Number(numeric)
                if (!isFinite(rate) || rate <= 0) {
                    continue
                }
                const normalized = rate.toFixed(2)
                if (rates.indexOf(normalized) === -1) {
                    rates.push(normalized)
                }
                if (token.indexOf("*") !== -1) {
                    foundCurrentMode = modeLine[1]
                    foundCurrentRate = normalized
                }
            }
            rates.sort(function(first, second) {
                return Number(second) - Number(first)
            })
            if (rates.length > 0) {
                foundModes.push({ name: modeLine[1], rates: rates })
            }
        }

        outputName = foundOutput
        currentMode = foundCurrentMode
        currentRate = foundCurrentRate
        modes = foundModes
        selectedMode = currentMode
        selectedRate = currentRate
        statusMessage = foundOutput
            ? foundOutput : "No active display detected"
    }

    function refreshModes() {
        if (!displayQuery.running) {
            displayQuery.exec(["xrandr", "--query"])
        }
    }

    function applySelectedMode() {
        if (!outputName || !selectedMode || !selectedRate) {
            return
        }
        if (selectedMode === currentMode && selectedRate === currentRate) {
            statusMessage = "The selected setting is already active"
            return
        }
        displayState.requestMode(
            outputName, selectedMode, selectedRate, currentMode, currentRate)
    }

    Component.onCompleted: refreshModes()

    Process {
        id: displayQuery

        stdout: StdioCollector {
            onStreamFinished: root.parseXrandr(text)
        }
    }

    Timer {
        id: refreshDelay
        interval: 650
        onTriggered: root.refreshModes()
    }

    Connections {
        target: root.displayState

        function onBrightnessChanged() {
            if (!brightnessPointer.pressed) {
                root.brightnessDraft = Number(root.displayState.brightness)
            }
        }

        function onTemperatureChanged() {
            if (!temperaturePointer.pressed) {
                root.temperatureDraft = Number(root.displayState.temperature)
            }
        }

        function onDisplayModeChanged(reverted) {
            root.statusMessage = reverted
                ? "The previous setting was restored" : "The setting was confirmed"
            refreshDelay.restart()
        }
    }

    MouseArea {
        x: 0
        y: 0
        width: root.width
        height: Math.max(0, root.barY)
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: popup
        x: root.barX + root.barWidth - width - 8
        y: root.barY - 8 - height
        width: 370
        height: 410
        radius: root.themeData.radius
        color: Qt.rgba(root.themeData.base.r, root.themeData.base.g,
            root.themeData.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(root.themeData.surface2.r,
            root.themeData.surface2.g, root.themeData.surface2.b, 0.82)
        clip: true

        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }

        Item {
            id: header
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            height: 36

            Row {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                spacing: 4

                Rectangle {
                    width: 76
                    height: 28
                    radius: 9
                    color: networkTabPointer.containsMouse
                        ? root.themeData.surface0 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Network"
                        color: root.themeData.subtext
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: networkTabPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabRequested("network")
                    }
                }

                Rectangle {
                    width: 82
                    height: 28
                    radius: 9
                    color: notificationTabPointer.containsMouse
                        ? root.themeData.surface0 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Notifications"
                        color: root.themeData.subtext
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: notificationTabPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabRequested("notifications")
                    }
                }

                Rectangle {
                    width: 70
                    height: 28
                    radius: 9
                    color: root.themeData.surface1
                    border.width: 1
                    border.color: root.themeData.mauve

                    Text {
                        anchors.centerIn: parent
                        text: "Display"
                        color: root.themeData.mauve
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Rectangle {
            id: brightnessCard
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                leftMargin: 14
                rightMargin: 14
                topMargin: 6
            }
            height: 64
            radius: 11
            color: root.themeData.mantle
            border.width: 1
            border.color: root.themeData.surface0

            Text {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 12
                    topMargin: 9
                }
                text: "Brightness"
                color: root.themeData.text
                font.family: root.themeData.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Text {
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 12
                    topMargin: 9
                }
                text: Math.round(root.brightnessDraft * 100) + "%"
                color: root.themeData.lavender
                font.family: root.themeData.monoFamily
                font.pixelSize: 9
            }

            Rectangle {
                id: brightnessTrack
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 12
                    rightMargin: 12
                    bottomMargin: 12
                }
                height: 6
                radius: 3
                color: root.themeData.surface1

                Rectangle {
                    width: parent.width * ((root.brightnessDraft - 0.1) / 0.9)
                    height: parent.height
                    radius: parent.radius
                    color: root.themeData.lavender
                }

                Rectangle {
                    x: parent.width * ((root.brightnessDraft - 0.1) / 0.9) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: root.themeData.text
                    border.width: 2
                    border.color: root.themeData.lavender
                }

                MouseArea {
                    id: brightnessPointer
                    anchors {
                        fill: parent
                        topMargin: -10
                        bottomMargin: -10
                    }
                    cursorShape: Qt.PointingHandCursor

                    function updateValue(mouseX) {
                        root.brightnessDraft = 0.1
                            + root.clamp(mouseX / width, 0, 1) * 0.9
                    }

                    onPressed: function(mouse) { updateValue(mouse.x) }
                    onPositionChanged: function(mouse) {
                        if (pressed) updateValue(mouse.x)
                    }
                    onReleased: root.displayState.setBrightness(root.brightnessDraft)
                }
            }
        }

        Rectangle {
            id: nightCard
            anchors {
                left: parent.left
                right: parent.right
                top: brightnessCard.bottom
                leftMargin: 14
                rightMargin: 14
                topMargin: 7
            }
            height: 129
            radius: 11
            color: root.themeData.mantle
            border.width: 1
            border.color: root.displayState.nightLightEnabled
                ? Qt.rgba(root.themeData.peach.r, root.themeData.peach.g,
                    root.themeData.peach.b, 0.72)
                : root.themeData.surface0

            Text {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 12
                    topMargin: 10
                }
                text: "Night Light"
                color: root.displayState.nightLightEnabled
                    ? root.themeData.peach : root.themeData.text
                font.family: root.themeData.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 12
                    topMargin: 7
                }
                width: 40
                height: 22
                radius: 11
                color: root.displayState.nightLightEnabled
                    ? root.themeData.peach : root.themeData.surface1

                Rectangle {
                    x: root.displayState.nightLightEnabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    radius: 8
                    color: root.displayState.nightLightEnabled
                        ? root.themeData.crust : root.themeData.overlay

                    Behavior on x {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.displayState.setNightLight(
                        !root.displayState.nightLightEnabled)
                }
            }

            Text {
                x: 12
                y: 43
                text: "Automatic"
                color: root.themeData.subtext
                font.family: root.themeData.fontFamily
                font.pixelSize: 9
            }

            Rectangle {
                x: 66
                y: 38
                width: 34
                height: 18
                radius: 9
                color: root.displayState.automaticEnabled
                    ? root.themeData.mauve : root.themeData.surface1

                Rectangle {
                    x: root.displayState.automaticEnabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: root.displayState.automaticEnabled
                        ? root.themeData.crust : root.themeData.overlay
                    Behavior on x { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.displayState.setAutomatic(
                        !root.displayState.automaticEnabled)
                }
            }

            Rectangle {
                x: 124
                y: 35
                width: 58
                height: 24
                radius: 7
                color: root.themeData.surface0
                border.width: startInput.activeFocus ? 1 : 0
                border.color: root.themeData.mauve

                TextInput {
                    id: startInput
                    anchors.centerIn: parent
                    width: 46
                    text: root.displayState.startTime
                    color: root.themeData.text
                    horizontalAlignment: TextInput.AlignHCenter
                    selectByMouse: true
                    inputMask: "99:99"
                    inputMethodHints: Qt.ImhDigitsOnly
                    font.family: root.themeData.monoFamily
                    font.pixelSize: 9
                    onEditingFinished: {
                        root.displayState.setStartTime(text)
                        text = root.displayState.startTime
                    }
                }
            }

            Text {
                x: 190
                y: 41
                text: "→"
                color: root.themeData.overlay
                font.family: root.themeData.monoFamily
                font.pixelSize: 10
            }

            Rectangle {
                x: 210
                y: 35
                width: 58
                height: 24
                radius: 7
                color: root.themeData.surface0
                border.width: endInput.activeFocus ? 1 : 0
                border.color: root.themeData.mauve

                TextInput {
                    id: endInput
                    anchors.centerIn: parent
                    width: 46
                    text: root.displayState.endTime
                    color: root.themeData.text
                    horizontalAlignment: TextInput.AlignHCenter
                    selectByMouse: true
                    inputMask: "99:99"
                    inputMethodHints: Qt.ImhDigitsOnly
                    font.family: root.themeData.monoFamily
                    font.pixelSize: 9
                    onEditingFinished: {
                        root.displayState.setEndTime(text)
                        text = root.displayState.endTime
                    }
                }
            }

            Text {
                x: 278
                y: 42
                text: root.displayState.automaticEnabled ? "active" : "manual"
                color: root.displayState.automaticEnabled
                    ? root.themeData.green : root.themeData.overlay
                font.family: root.themeData.fontFamily
                font.pixelSize: 8
            }

            Text {
                x: 12
                y: 74
                text: "Temperature"
                color: root.themeData.subtext
                font.family: root.themeData.fontFamily
                font.pixelSize: 9
            }

            Text {
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 12
                    topMargin: 73
                }
                text: Math.round(root.temperatureDraft) + " K"
                color: root.themeData.peach
                font.family: root.themeData.monoFamily
                font.pixelSize: 9
            }

            Rectangle {
                id: temperatureTrack
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 12
                    rightMargin: 12
                    bottomMargin: 13
                }
                height: 5
                radius: 3
                color: root.themeData.surface1

                Rectangle {
                    width: parent.width * ((root.temperatureDraft - 3000) / 3000)
                    height: parent.height
                    radius: parent.radius
                    color: root.themeData.peach
                }

                Rectangle {
                    x: parent.width * ((root.temperatureDraft - 3000) / 3000) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 13
                    height: 13
                    radius: 7
                    color: root.themeData.text
                    border.width: 2
                    border.color: root.themeData.peach
                }

                MouseArea {
                    id: temperaturePointer
                    anchors {
                        fill: parent
                        topMargin: -9
                        bottomMargin: -9
                    }
                    cursorShape: Qt.PointingHandCursor

                    function updateValue(mouseX) {
                        root.temperatureDraft = 3000
                            + root.clamp(mouseX / width, 0, 1) * 3000
                    }

                    onPressed: function(mouse) { updateValue(mouse.x) }
                    onPositionChanged: function(mouse) {
                        if (pressed) updateValue(mouse.x)
                    }
                    onReleased: root.displayState.setTemperature(root.temperatureDraft)
                }
            }
        }

        Rectangle {
            id: modeCard
            anchors {
                left: parent.left
                right: parent.right
                top: nightCard.bottom
                leftMargin: 14
                rightMargin: 14
                topMargin: 7
            }
            height: 133
            radius: 11
            color: root.themeData.mantle
            border.width: 1
            border.color: root.themeData.surface0

            Text {
                x: 12
                y: 9
                text: root.outputName ? "Display · " + root.outputName : "Display"
                color: root.themeData.text
                font.family: root.themeData.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Text {
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 12
                    topMargin: 10
                }
                text: root.statusMessage
                width: 185
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                color: root.themeData.overlay
                font.family: root.themeData.fontFamily
                font.pixelSize: 8
            }

            Text {
                x: 12
                y: 43
                text: "Resolution"
                color: root.themeData.subtext
                font.family: root.themeData.fontFamily
                font.pixelSize: 9
            }

            Rectangle {
                x: 132
                y: 34
                width: 24
                height: 25
                radius: 7
                color: modePreviousPointer.containsMouse
                    ? root.themeData.surface1 : root.themeData.surface0
                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.themeData.mauve
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 16
                }
                MouseArea {
                    id: modePreviousPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleMode(-1)
                }
            }

            Text {
                x: 162
                y: 41
                width: 126
                text: root.selectedMode || "—"
                horizontalAlignment: Text.AlignHCenter
                color: root.themeData.text
                font.family: root.themeData.monoFamily
                font.pixelSize: 9
            }

            Rectangle {
                x: 294
                y: 34
                width: 24
                height: 25
                radius: 7
                color: modeNextPointer.containsMouse
                    ? root.themeData.surface1 : root.themeData.surface0
                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: root.themeData.mauve
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 16
                }
                MouseArea {
                    id: modeNextPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleMode(1)
                }
            }

            Text {
                x: 12
                y: 73
                text: "Refresh rate"
                color: root.themeData.subtext
                font.family: root.themeData.fontFamily
                font.pixelSize: 9
            }

            Rectangle {
                x: 132
                y: 64
                width: 24
                height: 25
                radius: 7
                color: ratePreviousPointer.containsMouse
                    ? root.themeData.surface1 : root.themeData.surface0
                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.themeData.lavender
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 16
                }
                MouseArea {
                    id: ratePreviousPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleRate(-1)
                }
            }

            Text {
                x: 162
                y: 71
                width: 126
                text: root.formatRate(root.selectedRate)
                horizontalAlignment: Text.AlignHCenter
                color: root.themeData.text
                font.family: root.themeData.monoFamily
                font.pixelSize: 9
            }

            Rectangle {
                x: 294
                y: 64
                width: 24
                height: 25
                radius: 7
                color: rateNextPointer.containsMouse
                    ? root.themeData.surface1 : root.themeData.surface0
                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: root.themeData.lavender
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 16
                }
                MouseArea {
                    id: rateNextPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleRate(1)
                }
            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 9
                }
                width: 112
                height: 27
                radius: 9
                color: applyPointer.containsMouse
                    ? root.themeData.mauve : root.themeData.surface1
                border.width: 1
                border.color: root.themeData.mauve
                opacity: root.outputName ? 1 : 0.45

                Text {
                    anchors.centerIn: parent
                    text: "Apply setting"
                    color: applyPointer.containsMouse
                        ? root.themeData.crust : root.themeData.mauve
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: applyPointer
                    anchors.fill: parent
                    enabled: Boolean(root.outputName)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applySelectedMode()
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            z: 20
            visible: root.displayState.confirmationPending
            color: Qt.rgba(root.themeData.base.r, root.themeData.base.g,
                root.themeData.base.b, 0.985)

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 92
                }
                text: "Keep this setting?"
                color: root.themeData.text
                font.family: root.themeData.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 132
                }
                width: 300
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "The previous resolution will be restored automatically in "
                    + root.displayState.confirmationSeconds + " seconds."
                color: root.themeData.subtext
                font.family: root.themeData.fontFamily
                font.pixelSize: 10
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    width: 126
                    height: 34
                    radius: 10
                    color: revertPointer.containsMouse
                        ? root.themeData.surface1 : root.themeData.surface0
                    border.width: 1
                    border.color: root.themeData.surface2
                    Text {
                        anchors.centerIn: parent
                        text: "Restore"
                        color: root.themeData.subtext
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: revertPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.displayState.revertMode()
                    }
                }

                Rectangle {
                    width: 126
                    height: 34
                    radius: 10
                    color: keepPointer.containsMouse
                        ? root.themeData.lavender : root.themeData.mauve
                    Text {
                        anchors.centerIn: parent
                        text: "Keep"
                        color: root.themeData.crust
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: keepPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.displayState.confirmMode()
                    }
                }
            }
        }
    }
}
