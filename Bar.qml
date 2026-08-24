import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "Apps.js" as Apps

PanelWindow {
    id: window

    required property var clockSource
    required property var windowTracker
    required property var pinnedState
    required property var notificationState
    required property var configuration
    property bool pinnedOpen: false
    property bool searchOpen: false
    property bool audioOpen: false
    property bool systemOpen: false
    property bool calendarOpen: false
    property bool clipboardOpen: false
    property bool networkOpen: false
    property bool notificationsOpen: false
    property var notificationToast: null
    property var clipboardItems: []
    property int calendarYear: (new Date()).getFullYear()
    property int calendarMonth: (new Date()).getMonth()
    property bool weatherReady: false
    property bool weatherFailed: false
    property real weatherTemperature: 0
    property real weatherFeelsLike: 0
    property real weatherWindSpeed: 0
    property int weatherCode: -1
    property bool weatherIsDay: true
    property string weatherUpdatedAt: ""
    property double weatherLastFetchMs: 0
    readonly property string weatherLocation: configuration.weatherCity
    readonly property real weatherLatitude: configuration.weatherLatitude
    readonly property real weatherLongitude: configuration.weatherLongitude
    readonly property string homeDirectory: Quickshell.env("HOME") || ""
    readonly property string configDirectory: Quickshell.shellDir
    readonly property string assetIconDirectory:
        "file://" + Quickshell.shellDir + "/assets/icons/"
    property string systemConfirmAction: ""
    property real systemCpuPercent: -1
    property real systemRamUsed: 0
    property real systemRamTotal: 0
    property real systemGpuPercent: -1
    property real systemGpuMemoryUsed: 0
    property real systemGpuMemoryTotal: 0
    property real systemDiskUsed: 0
    property real systemDiskTotal: 0
    property string systemHostName: "localhost"
    property string audioDeviceChooser: ""
    property string searchQuery: ""
    property var fileResults: []
    property bool contextMenuOpen: false
    property var contextApp: null
    property string contextWindowId: ""
    property bool contextAppActive: false
    property real contextAnchorX: 0
    property bool windowChooserMode: false
    property var contextWindows: []
    readonly property int resultsHeight: 292
    readonly property int audioPopupHeight: 314
    readonly property int systemPopupHeight: 300
    readonly property int calendarPopupHeight: 404
    readonly property int clipboardPopupHeight: 332
    readonly property int networkPopupHeight: 390
    readonly property int notificationsPopupHeight: 390
    readonly property bool fullscreenLocked: windowTracker.fullscreenActive
    readonly property bool expanded: !fullscreenLocked
        && (pinnedOpen || searchOpen || contextMenuOpen
            || audioOpen || systemOpen || calendarOpen || clipboardOpen
            || networkOpen || notificationsOpen
            || barHover.hovered || hideDelay.running)
    readonly property var calendarMonthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var calendarMonthNamesShort: [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
    readonly property var calendarWeekdayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    readonly property var calendarWeekdayNamesLong: [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]
    readonly property var calendarDays: buildCalendarDays(calendarYear, calendarMonth)
    readonly property string weatherDescription: weatherDescriptionForCode(weatherCode)
    readonly property string weatherGlyph: weatherGlyphForCode(weatherCode, weatherIsDay)
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audioControl: audioSink ? audioSink.audio : null
    readonly property bool audioAvailable: audioControl !== null
    readonly property real audioVolume: audioAvailable ? audioControl.volume : 0
    readonly property bool audioMuted: audioAvailable ? audioControl.muted : true
    readonly property int audioPercent: Math.round(audioVolume * 100)
    readonly property string audioDescription: audioSink
        ? (audioSink.description || audioSink.nickname || audioSink.name || "Audio output")
        : "No audio device"
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
            : "Nothing is playing")
    readonly property string mediaSubtitle: mediaPlayer
        ? (mediaPlayer.trackArtist || mediaPlayer.identity || "Media player")
        : (audioStreams.length > 0 ? "Active audio stream" : "")
    readonly property var systemResourceItems: [
        {
            label: "CPU",
            value: systemCpuPercent >= 0
                ? Math.round(systemCpuPercent) + "%" : "—",
            detail: "Processor",
            level: systemCpuPercent >= 0 ? systemCpuPercent / 100 : 0,
            accent: theme.mauve
        },
        {
            label: "RAM",
            value: systemRamTotal > 0
                ? Math.round(systemRamUsed * 100 / systemRamTotal) + "%" : "—",
            detail: systemRamTotal > 0
                ? formatBytes(systemRamUsed) + " / " + formatBytes(systemRamTotal)
                : "Loading…",
            level: systemRamTotal > 0 ? systemRamUsed / systemRamTotal : 0,
            accent: theme.blue
        },
        {
            label: "GPU",
            value: systemGpuPercent >= 0
                ? Math.round(systemGpuPercent) + "%" : "N/A",
            detail: systemGpuMemoryTotal > 0
                ? formatBytes(systemGpuMemoryUsed) + " / "
                    + formatBytes(systemGpuMemoryTotal)
                : (systemGpuPercent >= 0 ? "Graphics" : "Data unavailable"),
            level: systemGpuPercent >= 0 ? systemGpuPercent / 100 : 0,
            accent: theme.green
        },
        {
            label: "Storage",
            value: systemDiskTotal > 0
                ? Math.round(systemDiskUsed * 100 / systemDiskTotal) + "%" : "—",
            detail: systemDiskTotal > 0
                ? formatBytes(systemDiskUsed) + " / " + formatBytes(systemDiskTotal)
                : "Loading…",
            level: systemDiskTotal > 0 ? systemDiskUsed / systemDiskTotal : 0,
            accent: theme.peach
        }
    ]

    readonly property var installedApps: {
        return DesktopEntries.applications.values
            .filter(function(entry) {
                return entry && entry.name && !entry.noDisplay
            })
            .sort(function(first, second) {
                return first.name.toLowerCase().localeCompare(second.name.toLowerCase())
            })
    }
    readonly property var filteredApps: {
        const needle = searchQuery.trim().toLowerCase()
        if (needle.length === 0) {
            return installedApps
        }

        return installedApps
            .filter(function(entry) {
                const name = entry.name.toLowerCase()
                const genericName = (entry.genericName || "").toLowerCase()
                return name.indexOf(needle) !== -1
                    || genericName.indexOf(needle) !== -1
            })
            .sort(function(first, second) {
                const firstName = first.name.toLowerCase()
                const secondName = second.name.toLowerCase()
                const firstRank = firstName.indexOf(needle) === 0 ? 0 : 1
                const secondRank = secondName.indexOf(needle) === 0 ? 0 : 1

                if (firstRank !== secondRank) {
                    return firstRank - secondRank
                }
                return firstName.localeCompare(secondName)
            })
            .slice(0, 10)
    }
    readonly property var searchItems: {
        if (searchQuery.trim().length === 0) {
            return filteredApps
        }
        return filteredApps.concat(fileResults)
    }
    readonly property var appFinder: ({
        name: "Search applications",
        icon: "catppuccin-search",
        iconSource: assetIconDirectory + "catppuccin-search.svg",
        command: []
    })
    readonly property var screenshotAction: ({
        name: "Screenshot",
        icon: "catppuccin-screenshot",
        iconSource: assetIconDirectory + "catppuccin-screenshot.svg",
        iconSize: theme.quickActionIconSize,
        command: ["xfce4-screenshooter", "--region"]
    })
    readonly property var clipboardAction: ({
        name: "Clipboard history",
        icon: "catppuccin-clipboard",
        iconSource: assetIconDirectory + "catppuccin-clipboard.svg",
        iconSize: theme.quickActionIconSize,
        command: []
    })
    readonly property var showDesktopAction: ({
        name: "Show desktop",
        icon: "catppuccin-showdesktop",
        iconSource: assetIconDirectory + "catppuccin-showdesktop.svg",
        iconSize: theme.quickActionIconSize,
        command: [
            "bash",
            Quickshell.shellDir + "/toggle-desktop.sh"
        ]
    })
    readonly property var resolvedPinnedApps: {
        const records = window.pinnedState.pins
        const result = []
        for (let index = 0; index < records.length; ++index) {
            const app = window.appFromPinRecord(records[index])
            if (app) {
                result.push(app)
            }
        }
        return result
    }
    readonly property var runningUnpinnedApps: {
        // Touch the installed application model so this binding is refreshed
        // when Quickshell finishes indexing desktop entries.
        const availableApplications = installedApps
        const windows = window.windowTracker.clientWindows
        const result = []
        const seen = ({})

        for (let index = 0; index < windows.length; ++index) {
            const client = windows[index]
            if (client.skipTaskbar) {
                continue
            }

            const app = window.appFromClientWindow(client)
            if (!app || seen[app.pinKey] || window.pinnedState.isPinned(app.pinKey)) {
                continue
            }
            seen[app.pinKey] = true
            result.push(app)
        }
        return result
    }
    readonly property var taskbarApps: resolvedPinnedApps.concat(runningUnpinnedApps)
    readonly property var networkDevices: Networking.devices.values
    readonly property var connectedNetwork: {
        for (let deviceIndex = 0; deviceIndex < networkDevices.length; ++deviceIndex) {
            const networks = networkDevices[deviceIndex].networks.values
            for (let networkIndex = 0; networkIndex < networks.length; ++networkIndex) {
                if (networks[networkIndex].connected) {
                    return networks[networkIndex]
                }
            }
        }
        return null
    }
    readonly property string networkIconName: {
        if (!connectedNetwork) {
            return Networking.wifiEnabled
                ? "network-wireless-offline-symbolic" : "network-offline-symbolic"
        }
        if (connectedNetwork.device.type === DeviceType.Wired) {
            return "network-wired-symbolic"
        }
        const strength = Number(connectedNetwork.signalStrength || 0)
        if (strength >= 0.75) return "network-wireless-signal-excellent-symbolic"
        if (strength >= 0.50) return "network-wireless-signal-good-symbolic"
        if (strength >= 0.25) return "network-wireless-signal-ok-symbolic"
        return "network-wireless-signal-weak-symbolic"
    }

    IpcHandler {
        target: "bar"
        enabled: Quickshell.screens.length > 0
            && window.screen === Quickshell.screens[0]

        function openSearch(): void {
            window.openSearch()
        }

        function searchIsOpen(): bool {
            return window.searchOpen
        }

        function openNetwork(): void {
            window.openNetwork()
        }

        function openNotifications(): void {
            window.openNotifications()
        }

        function clearNotifications(): void {
            window.notificationToast = null
            window.notificationState.clearAll()
        }

        function openClipboard(): void {
            window.openClipboard()
        }

        function openCalendar(): void {
            window.openCalendar()
        }

        function openAudio(): void {
            window.openAudio()
        }

        function openSystem(): void {
            window.openSystem()
        }

        function closePopups(): void {
            window.closeNetwork()
            window.closeNotifications()
            window.closeClipboard()
            window.closeCalendar()
            window.closeAudio()
            window.closeSystem()
            window.closeSearch()
            window.closeContextMenu()
            window.notificationToast = null
        }
    }
    readonly property var contextMenuItems: {
        if (!contextApp) {
            return []
        }

        const items = []
        if (windowChooserMode) {
            const effectiveActive = windowTracker.activeClientWindow()
            for (let index = contextWindows.length - 1; index >= 0; --index) {
                const client = contextWindows[index]
                items.push({
                    kind: "window",
                    label: client.title && client.title.length > 0
                        ? client.title
                        : contextApp.name + " — window " + (index + 1),
                    windowId: client.id,
                    active: client.id === effectiveActive
                })
            }
            return items
        }

        if (contextWindowId.length > 0) {
            items.push({
                kind: "toggle",
                label: contextAppActive ? "Minimize" : "Show window"
            })
            items.push({
                kind: "maximize",
                label: "Maximize / restore"
            })
            items.push({
                kind: "close",
                label: "Close window",
                danger: true
            })
        }

        items.push({
            kind: "launch",
            label: contextWindowId.length > 0
                ? "Launch again"
                : "Open application",
            command: contextApp.command,
            sectionBreak: contextWindowId.length > 0
        })

        const appActions = contextApp.contextActions || []
        for (let index = 0; index < appActions.length; ++index) {
            items.push({
                kind: "command",
                label: appActions[index].label,
                command: appActions[index].command
            })
        }
        items.push({
            kind: "pin",
            label: pinnedState.isPinned(contextApp.pinKey)
                ? "Remove from bar"
                : "Pin to bar",
            sectionBreak: true
        })
        return items
    }

    function canonicalDesktopKey(entryId) {
        const id = String(entryId || "")
        return id.length === 0 || id.toLowerCase().endsWith(".desktop")
            ? id
            : id + ".desktop"
    }

    function normalizedDesktopKey(entryId) {
        const id = String(entryId || "").toLowerCase()
        return id.endsWith(".desktop") ? id.substring(0, id.length - 8) : id
    }

    function desktopEntryByKey(pinKey) {
        const wanted = normalizedDesktopKey(pinKey)
        const entries = installedApps
        for (let index = 0; index < entries.length; ++index) {
            if (normalizedDesktopKey(entries[index].id) === wanted) {
                return entries[index]
            }
        }

        let entry = DesktopEntries.byId(pinKey)
        if (!entry && String(pinKey).toLowerCase().endsWith(".desktop")) {
            entry = DesktopEntries.byId(String(pinKey).slice(0, -8))
        }
        return entry
    }

    function desktopEntryForClasses(classes) {
        const normalizedClasses = (classes || []).map(function(value) {
            return String(value).toLowerCase()
        })
        const entries = installedApps

        for (let index = 0; index < entries.length; ++index) {
            const entry = entries[index]
            const startupClass = String(entry.startupClass || "").toLowerCase()
            const entryId = normalizedDesktopKey(entry.id)
            if ((startupClass.length > 0 && normalizedClasses.indexOf(startupClass) !== -1)
                    || normalizedClasses.indexOf(entryId) !== -1) {
                return entry
            }
        }

        for (let index = normalizedClasses.length - 1; index >= 0; --index) {
            const entry = DesktopEntries.heuristicLookup(normalizedClasses[index])
            if (entry) {
                return entry
            }
        }
        return null
    }

    function desktopContextActions(entry) {
        const result = []
        if (!entry || !entry.actions) {
            return result
        }

        for (let index = 0; index < entry.actions.length && index < 3; ++index) {
            result.push({
                label: entry.actions[index].name,
                command: entry.actions[index].command
            })
        }
        return result
    }

    function appFromDesktopEntry(entry, pinKey, classes) {
        if (!entry) {
            return null
        }

        const appClasses = (classes || []).slice()
        if (entry.startupClass && appClasses.indexOf(entry.startupClass) === -1) {
            appClasses.push(entry.startupClass)
        }
        return {
            pinKey: pinKey || canonicalDesktopKey(entry.id),
            name: entry.name,
            icon: entry.icon,
            command: entry.command,
            desktopEntry: entry,
            wmClasses: appClasses,
            contextActions: desktopContextActions(entry)
        }
    }

    function appFromPinRecord(record) {
        const pinKey = window.pinnedState.recordKey(record)
        const predefined = Apps.byPinKey(pinKey)
        if (predefined) {
            return predefined
        }

        const entry = desktopEntryByKey(pinKey)
        if (entry) {
            const runningClasses = window.classesForPinKey(pinKey)
            return appFromDesktopEntry(entry, pinKey, runningClasses)
        }

        if (typeof record !== "string" && record.name) {
            return {
                pinKey: pinKey,
                name: record.name,
                icon: record.icon || "application-x-executable",
                iconSource: record.iconSource || "",
                command: record.command || [],
                wmClasses: record.wmClasses || [],
                contextActions: []
            }
        }
        return null
    }

    function pinKeyForClient(client) {
        const predefined = Apps.byClasses(client.classes)
        if (predefined) {
            return predefined.pinKey
        }

        const entry = desktopEntryForClasses(client.classes)
        if (entry) {
            return canonicalDesktopKey(entry.id)
        }
        const fallbackClass = client.classes.length > 0
            ? client.classes[client.classes.length - 1]
            : client.id
        return "wmclass:" + fallbackClass.toLowerCase()
    }

    function classesForPinKey(pinKey) {
        const clients = window.windowTracker.clientWindows
        for (let index = clients.length - 1; index >= 0; --index) {
            if (!clients[index].skipTaskbar
                    && pinKeyForClient(clients[index]) === pinKey) {
                return clients[index].classes
            }
        }
        return []
    }

    function appFromClientWindow(client) {
        const predefined = Apps.byClasses(client.classes)
        if (predefined) {
            return predefined
        }

        const entry = desktopEntryForClasses(client.classes)
        if (entry) {
            return appFromDesktopEntry(
                entry, canonicalDesktopKey(entry.id), client.classes)
        }

        const fallbackClass = client.classes.length > 0
            ? client.classes[client.classes.length - 1]
            : "Application"
        return {
            pinKey: "wmclass:" + fallbackClass.toLowerCase(),
            name: fallbackClass,
            icon: "application-x-executable",
            command: [],
            wmClasses: client.classes,
            contextActions: []
        }
    }

    function pinRecordForApp(app) {
        const command = []
        const classes = []
        for (let index = 0; app.command && index < app.command.length; ++index) {
            command.push(String(app.command[index]))
        }
        for (let index = 0; app.wmClasses && index < app.wmClasses.length; ++index) {
            classes.push(String(app.wmClasses[index]))
        }
        return {
            key: app.pinKey,
            name: app.name,
            icon: app.icon || "application-x-executable",
            iconSource: app.iconSource || "",
            command: command,
            wmClasses: classes
        }
    }

    function weatherDescriptionForCode(code) {
        const value = Number(code)
        if (value === 0) return "Clear sky"
        if (value === 1) return "Mostly clear"
        if (value === 2) return "Partly cloudy"
        if (value === 3) return "Overcast"
        if (value === 45 || value === 48) return "Fog"
        if (value === 51 || value === 53 || value === 55) return "Drizzle"
        if (value === 56 || value === 57) return "Freezing drizzle"
        if (value === 61 || value === 63 || value === 65) return "Rain"
        if (value === 66 || value === 67) return "Freezing rain"
        if (value === 71 || value === 73 || value === 75 || value === 77) return "Snow"
        if (value === 80 || value === 81 || value === 82) return "Rain showers"
        if (value === 85 || value === 86) return "Snow showers"
        if (value === 95 || value === 96 || value === 99) return "Thunderstorm"
        return weatherFailed ? "Weather unavailable" : "Updating…"
    }

    function weatherGlyphForCode(code, isDay) {
        const value = Number(code)
        if (value === 0) return isDay ? "󰖙" : "󰖔"
        if (value === 1 || value === 2) return isDay ? "󰖕" : "󰼱"
        if (value === 3) return "󰖐"
        if (value === 45 || value === 48) return "󰖑"
        if (value >= 51 && value <= 57) return "󰖗"
        if ((value >= 61 && value <= 67) || (value >= 80 && value <= 82)) return "󰖖"
        if ((value >= 71 && value <= 77) || value === 85 || value === 86) return "󰖘"
        if (value >= 95) return "󰖓"
        return "󰖐"
    }

    function buildCalendarDays(year, month) {
        const today = new Date()
        const firstWeekday = (new Date(year, month, 1).getDay() + 6) % 7
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const daysInPreviousMonth = new Date(year, month, 0).getDate()
        const result = []

        for (let index = 0; index < 42; ++index) {
            let itemYear = year
            let itemMonth = month
            let itemDay = index - firstWeekday + 1
            let inCurrentMonth = true

            if (itemDay < 1) {
                itemMonth -= 1
                if (itemMonth < 0) {
                    itemMonth = 11
                    itemYear -= 1
                }
                itemDay = daysInPreviousMonth + itemDay
                inCurrentMonth = false
            } else if (itemDay > daysInMonth) {
                itemDay -= daysInMonth
                itemMonth += 1
                if (itemMonth > 11) {
                    itemMonth = 0
                    itemYear += 1
                }
                inCurrentMonth = false
            }

            result.push({
                day: itemDay,
                month: itemMonth,
                year: itemYear,
                current: inCurrentMonth,
                today: itemDay === today.getDate()
                    && itemMonth === today.getMonth()
                    && itemYear === today.getFullYear()
            })
        }
        return result
    }

    function compactDateLabel(date) {
        return calendarWeekdayNamesLong[date.getDay()].substring(0, 3)
            + ", " + calendarMonthNamesShort[date.getMonth()] + " " + date.getDate()
    }

    function longDateLabel(date) {
        return calendarWeekdayNamesLong[date.getDay()] + ", "
            + calendarMonthNames[date.getMonth()] + " " + date.getDate()
            + ", " + date.getFullYear()
    }

    function shiftCalendarMonth(offset) {
        let nextMonth = calendarMonth + Number(offset)
        let nextYear = calendarYear
        while (nextMonth < 0) {
            nextMonth += 12
            nextYear -= 1
        }
        while (nextMonth > 11) {
            nextMonth -= 12
            nextYear += 1
        }
        calendarMonth = nextMonth
        calendarYear = nextYear
    }

    function resetCalendarMonth() {
        const today = new Date()
        calendarYear = today.getFullYear()
        calendarMonth = today.getMonth()
    }

    function parseWeather(payload) {
        try {
            const response = JSON.parse(String(payload))
            const current = response.current
            if (!current || current.temperature_2m === undefined) {
                throw new Error("missing current weather")
            }
            weatherTemperature = Number(current.temperature_2m)
            weatherFeelsLike = Number(current.apparent_temperature)
            weatherWindSpeed = Number(current.wind_speed_10m)
            weatherCode = Number(current.weather_code)
            weatherIsDay = Number(current.is_day) === 1
            weatherUpdatedAt = String(current.time || "")
            weatherReady = true
            weatherFailed = false
        } catch (error) {
            weatherFailed = true
        }
    }

    function refreshWeather() {
        const now = Date.now()
        if (weatherProcess.running
                || (weatherLastFetchMs > 0 && now - weatherLastFetchMs < 15 * 60 * 1000)) {
            return
        }
        weatherLastFetchMs = now
        const endpoint = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + weatherLatitude
            + "&longitude=" + weatherLongitude
            + "&current=temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m"
            + "&timezone=" + encodeURIComponent(configuration.weatherTimezone)
            + "&forecast_days=1"
        weatherProcess.exec(["curl", "-fsS", "--max-time", "8", endpoint])
    }

    function clipboardPreview(text) {
        const compact = String(text || "")
            .replace(/[\r\n\t]+/g, " ")
            .replace(/\s+/g, " ")
            .trim()
        return compact.length > 0 ? compact : "No text content"
    }

    function captureClipboard(text) {
        const value = String(text || "")
        if (value.length === 0) {
            return
        }

        const nextItems = []
        nextItems.push({ text: value })
        for (let index = 0; index < clipboardItems.length && nextItems.length < 10; ++index) {
            if (String(clipboardItems[index].text) !== value) {
                nextItems.push({ text: String(clipboardItems[index].text) })
            }
        }
        clipboardItems = nextItems
    }

    function selectClipboardItem(item) {
        if (!item || item.text === undefined) {
            return
        }
        Quickshell.clipboardText = String(item.text)
        closeClipboard()
    }

    function removeClipboardItem(index) {
        if (index < 0 || index >= clipboardItems.length) {
            return
        }
        const nextItems = clipboardItems.slice()
        nextItems.splice(index, 1)
        clipboardItems = nextItems
    }

    function clearClipboardHistory() {
        clipboardItems = []
    }

    function openClipboard() {
        closeNetwork()
        closeNotifications()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeSearch()
        closeContextMenu()
        clipboardOpen = true
    }

    function closeClipboard() {
        clipboardOpen = false
    }

    function toggleClipboard() {
        if (clipboardOpen) {
            closeClipboard()
        } else {
            openClipboard()
        }
    }

    function openCalendar() {
        closeNetwork()
        closeNotifications()
        closeClipboard()
        closeAudio()
        closeSystem()
        closeSearch()
        closeContextMenu()
        resetCalendarMonth()
        calendarOpen = true
        refreshWeather()
    }

    function closeCalendar() {
        calendarOpen = false
    }

    function toggleCalendar() {
        if (calendarOpen) {
            closeCalendar()
        } else {
            openCalendar()
        }
    }

    function openSearch() {
        closeNetwork()
        closeNotifications()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeContextMenu()
        searchOpen = true
        searchQuery = ""
        Qt.callLater(function() {
            searchInput.forceActiveFocus()
            resultsList.currentIndex = resultsList.count > 0 ? 0 : -1
        })
    }

    function closeSearch() {
        searchOpen = false
        searchQuery = ""
        searchInput.text = ""
        resultsList.currentIndex = -1
        searchInput.focus = false
    }

    function toggleSearch() {
        if (searchOpen) {
            closeSearch()
        } else {
            openSearch()
        }
    }

    function openAudio() {
        closeNetwork()
        closeNotifications()
        closeClipboard()
        closeCalendar()
        closeSearch()
        closeSystem()
        closeContextMenu()
        audioOpen = true
    }

    function closeAudio() {
        audioOpen = false
        audioDeviceChooser = ""
    }

    function toggleAudio() {
        if (audioOpen) {
            closeAudio()
        } else {
            openAudio()
        }
    }

    function openNetwork() {
        closeNotifications()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeSearch()
        closeContextMenu()
        networkOpen = true
    }

    function closeNetwork() {
        networkOpen = false
    }

    function toggleNetwork() {
        if (networkOpen) closeNetwork()
        else openNetwork()
    }

    function openNotifications() {
        closeNetwork()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeSearch()
        closeContextMenu()
        notificationToast = null
        notificationsOpen = true
    }

    function closeNotifications() {
        notificationsOpen = false
    }

    function toggleNotifications() {
        if (notificationsOpen) closeNotifications()
        else openNotifications()
    }

    function formatBytes(bytes) {
        const value = Number(bytes)
        if (!isFinite(value) || value <= 0) {
            return "0 B"
        }
        const units = ["B", "KiB", "MiB", "GiB", "TiB"]
        const unitIndex = Math.min(
            units.length - 1,
            Math.floor(Math.log(value) / Math.log(1024)))
        const scaled = value / Math.pow(1024, unitIndex)
        return (scaled >= 10 || unitIndex === 0
            ? scaled.toFixed(0) : scaled.toFixed(1)) + " " + units[unitIndex]
    }

    function refreshSystemStats() {
        if (!systemStatsProcess.running) {
            systemStatsProcess.exec([
                "bash",
                configDirectory + "/system-stats.sh"
            ])
        }
    }

    function parseSystemStats(line) {
        const fields = String(line).split("|")
        if (fields[0] === "CPU") {
            systemCpuPercent = Number(fields[1])
        } else if (fields[0] === "RAM") {
            systemRamUsed = Number(fields[1])
            systemRamTotal = Number(fields[2])
        } else if (fields[0] === "GPU") {
            systemGpuPercent = Number(fields[1])
            systemGpuMemoryUsed = Number(fields[2])
            systemGpuMemoryTotal = Number(fields[3])
        } else if (fields[0] === "DISK") {
            systemDiskUsed = Number(fields[1])
            systemDiskTotal = Number(fields[2])
        } else if (fields[0] === "HOST") {
            systemHostName = fields.slice(1).join("|") || "localhost"
        }
    }

    function openSystem() {
        closeNetwork()
        closeNotifications()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSearch()
        closeContextMenu()
        systemConfirmAction = ""
        systemOpen = true
        refreshSystemStats()
    }

    function closeSystem() {
        systemOpen = false
        systemConfirmAction = ""
    }

    function toggleSystem() {
        if (systemOpen) {
            closeSystem()
        } else {
            openSystem()
        }
    }

    function requestSystemAction(action) {
        if (action === "switch-user") {
            closeSystem()
            Quickshell.execDetached(["xfce4-session-logout", "--switch-user"])
            return
        }
        systemConfirmAction = action
    }

    function confirmSystemAction() {
        const action = systemConfirmAction
        if (action !== "restart" && action !== "shutdown") {
            return
        }
        closeSystem()
        Quickshell.execDetached([
            "xfce4-session-logout",
            action === "restart" ? "--reboot" : "--halt"
        ])
    }

    function setAudioVolume(value) {
        if (!audioAvailable) {
            return
        }

        audioControl.volume = Math.max(0, Math.min(1, Number(value)))
    }

    function adjustAudioVolume(step) {
        setAudioVolume(audioVolume + Number(step))
    }

    function toggleAudioMute() {
        if (audioAvailable) {
            audioControl.muted = !audioControl.muted
        }
    }

    function setMicrophoneVolume(value) {
        if (!microphoneAvailable) {
            return
        }

        microphoneControl.volume = Math.max(0, Math.min(1, Number(value)))
    }

    function toggleMicrophoneMute() {
        if (microphoneAvailable) {
            microphoneControl.muted = !microphoneControl.muted
        }
    }

    function openAudioDeviceChooser(kind) {
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

    function launchResult(index) {
        if (index < 0 || index >= searchItems.length) {
            return
        }

        launchEntry(searchItems[index])
    }

    function launchEntry(entry) {
        if (!entry) {
            return
        }

        closeSearch()
        if (entry.kind === "file" || entry.kind === "folder") {
            Quickshell.execDetached(["xdg-open", entry.path])
        } else {
            entry.execute()
        }
    }

    function activatePinnedApp(app, windowId, appIsActive) {
        closeNetwork()
        closeNotifications()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeSearch()
        closeContextMenu()
        if (windowId.length === 0 && app.desktopEntry) {
            app.desktopEntry.execute()
            return
        }
        if (appIsActive && windowId.length > 0) {
            windowTracker.markWindowMinimized(windowId)
        }
        const command = [
            "bash",
            configDirectory + "/focus-or-launch.sh",
            windowId || "",
            appIsActive ? "1" : "0"
        ].concat(app.command)
        Quickshell.execDetached(command)
    }

    function handleTaskbarClick(app, appWindows, windowId, appIsActive, anchorX) {
        if (appWindows.length > 1) {
            openWindowChooser(app, appWindows, anchorX)
        } else {
            activatePinnedApp(app, windowId, appIsActive)
        }
    }

    function openWindowChooser(app, appWindows, anchorX) {
        closeNetwork()
        closeNotifications()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeSearch()
        contextApp = app
        contextWindows = appWindows.slice()
        contextWindowId = ""
        contextAppActive = false
        contextAnchorX = anchorX
        windowChooserMode = true
        contextMenuOpen = true
    }

    function openContextMenu(app, windowId, appIsActive, anchorX) {
        closeNetwork()
        closeNotifications()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeSearch()
        contextApp = app
        contextWindowId = windowId || ""
        contextAppActive = appIsActive
        contextAnchorX = anchorX
        contextWindows = []
        windowChooserMode = false
        contextMenuOpen = true
    }

    function closeContextMenu() {
        contextMenuOpen = false
        contextApp = null
        contextWindowId = ""
        contextAppActive = false
        contextWindows = []
        windowChooserMode = false
        contextCloseDelay.stop()
    }

    function closeChooserWindow(windowId) {
        const targetId = String(windowId || "")
        if (targetId.length === 0) {
            return
        }

        // Update the selector immediately; XFWM will remove the real client a
        // moment later and the X11 tracker will confirm the new list.
        contextWindows = contextWindows.filter(function(client) {
            return client.id !== targetId
        })
        Quickshell.execDetached(["wmctrl", "-i", "-c", targetId])

        if (contextWindows.length === 0) {
            closeContextMenu()
        }
    }

    function runContextAction(entry) {
        if (!entry || !contextApp) {
            return
        }

        // Delegates are destroyed as soon as the menu closes. Copy every value
        // needed by the action first instead of retaining modelData references.
        const actionKind = String(entry.kind || "")
        const actionWindowId = String(entry.windowId || "")
        const actionCommand = []
        for (let index = 0; entry.command && index < entry.command.length; ++index) {
            actionCommand.push(String(entry.command[index]))
        }
        const appRecord = pinRecordForApp(contextApp)
        const app = {
            pinKey: appRecord.key,
            name: appRecord.name,
            icon: appRecord.icon,
            iconSource: appRecord.iconSource,
            command: appRecord.command,
            wmClasses: appRecord.wmClasses,
            desktopEntry: contextApp.desktopEntry || null
        }
        const appWasPinned = pinnedState.isPinned(appRecord.key)
        const windowId = contextWindowId
        const wasActive = contextAppActive
        closeContextMenu()

        if (actionKind === "toggle") {
            activatePinnedApp(app, windowId, wasActive)
        } else if (actionKind === "window") {
            Quickshell.execDetached(["wmctrl", "-i", "-a", actionWindowId])
        } else if (actionKind === "maximize" || actionKind === "close") {
            Quickshell.execDetached([
                "bash",
                configDirectory + "/window-action.sh",
                actionKind,
                windowId
            ])
        } else if (actionKind === "pin") {
            if (appWasPinned) {
                pinnedState.unpin(appRecord.key)
            } else {
                pinnedState.pin(appRecord)
            }
        } else if (actionCommand.length > 0) {
            Quickshell.execDetached(actionCommand)
        }
    }

    function addPathResult(line) {
        const separator = line.indexOf("\t")
        if (separator < 1 || searchQuery.trim().length < 2) {
            return
        }

        const kind = line.substring(0, separator)
        const path = line.substring(separator + 1)
        const slash = path.lastIndexOf("/")
        const name = slash >= 0 ? path.substring(slash + 1) : path
        const needle = searchQuery.trim().toLowerCase()

        // Ignore any late output left over from the previous query.
        if (name.toLowerCase().indexOf(needle) === -1) {
            return
        }

        for (let index = 0; index < fileResults.length; ++index) {
            if (fileResults[index].path === path) {
                return
            }
        }

        const parentPath = slash > 0 ? path.substring(0, slash) : path
        const nextResults = fileResults.slice()
        nextResults.push({
            kind: kind,
            path: path,
            name: name,
            directory: homeDirectory.length > 0
                    && parentPath.indexOf(homeDirectory) === 0
                ? "~" + parentPath.substring(homeDirectory.length)
                : parentPath,
            icon: kind === "folder" ? "folder" : "text-x-generic"
        })
        fileResults = nextResults

        if (searchOpen && resultsList.currentIndex < 0) {
            resultsList.currentIndex = 0
        }
    }

    Theme { id: theme }

    // PipeWire objects expose live properties only while explicitly tracked.
    PwObjectTracker {
        objects: window.pipewireNodes
    }

    ScriptModel {
        id: searchModel
        values: window.searchItems
    }

    Timer {
        id: fileSearchDelay
        interval: 220
        onTriggered: {
            const query = window.searchQuery.trim()
            if (query.length >= 2) {
                fileSearchProcess.exec([
                    "bash",
                    configDirectory + "/search-paths.sh",
                    query
                ])
            }
        }
    }

    Process {
        id: fileSearchProcess

        stdout: SplitParser {
            onRead: function(line) {
                window.addPathResult(line)
            }
        }
    }

    Process {
        id: systemStatsProcess

        stdout: SplitParser {
            onRead: function(line) {
                window.parseSystemStats(line)
            }
        }
    }

    Process {
        id: weatherProcess

        stdout: StdioCollector {
            onStreamFinished: window.parseWeather(text)
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        onTriggered: window.refreshWeather()
    }

    Connections {
        target: Quickshell

        function onClipboardTextChanged() {
            window.captureClipboard(Quickshell.clipboardText)
        }
    }

    Connections {
        target: window.notificationState

        function onNotificationArrived(notification) {
            if (!window.notificationsOpen) {
                window.notificationToast = notification
            }
        }
    }

    Component.onCompleted: {
        window.refreshWeather()
        window.captureClipboard(Quickshell.clipboardText)
    }

    Timer {
        interval: 2000
        repeat: true
        running: window.systemOpen
        onTriggered: window.refreshSystemStats()
    }

    anchors {
        bottom: true
        left: true
        right: true
    }

    // Keep the native X11 window at a constant size. Resizing it every frame is
    // noticeably choppy; only the bar content moves now.
    // Keep the native X11 surface at one constant size. X11 keeps the input
    // shape from the initial surface when a panel is resized dynamically.
    implicitHeight: theme.barHeight + theme.topMargin + 8
        + Math.max(resultsHeight, audioPopupHeight, systemPopupHeight,
            calendarPopupHeight, clipboardPopupHeight, networkPopupHeight,
            notificationsPopupHeight)
    color: "transparent"
    surfaceFormat.opaque: false
    // Fullscreen video and games must not retain even a one-pixel X11 surface
    // edge. The tracker lives outside this window, so it can safely show the
    // panel again as soon as fullscreen ends.
    visible: !fullscreenLocked
    aboveWindows: true
    // The window must already be focusable when the opening click arrives;
    // changing this only afterwards is too late for reliable keyboard focus on X11.
    focusable: true
    // On X11 an item-backed mask does not reliably grow with the search window.
    // Use the full native input surface while results are open, then restore the
    // narrow autohide mask when search closes.
    mask: fullscreenLocked
        ? compactInputMask
        : (searchOpen || contextMenuOpen || audioOpen || systemOpen || calendarOpen
            || clipboardOpen || networkOpen || notificationsOpen || notificationToast
            ? expandedInputMask
            : compactInputMask)

    Region {
        id: compactInputMask
        item: inputRegion
    }

    Region {
        id: expandedInputMask
        x: 0
        y: 0
        width: window.width
        height: window.height
    }

    // The bar floats above windows; maximized, snapped and fullscreen windows
    // trigger its existing autohide behavior without reserving desktop space.
    exclusionMode: ExclusionMode.Ignore

    HoverHandler {
        id: barHover
        enabled: !window.fullscreenLocked

        onHoveredChanged: {
            if (hovered) {
                hideDelay.stop()
            } else if (!window.pinnedOpen) {
                hideDelay.restart()
            }
        }
    }

    Timer {
        id: hideDelay
        interval: 650
    }

    onPinnedOpenChanged: {
        if (pinnedOpen) {
            hideDelay.stop()
        } else {
            // A popup must not keep the bar expanded when the active window
            // becomes maximized, snapped or fullscreen.
            closeNetwork()
            closeNotifications()
            closeClipboard()
            closeCalendar()
            closeAudio()
            closeSystem()
            closeSearch()
            closeContextMenu()
            notificationToast = null

            if (!barHover.hovered) {
                hideDelay.restart()
            }
        }
    }

    onSearchQueryChanged: {
        fileResults = []
        fileSearchDelay.stop()

        if (fileSearchProcess.running) {
            fileSearchProcess.running = false
        }

        if (searchQuery.trim().length >= 2) {
            fileSearchDelay.restart()
        }
    }

    // When hidden, only the 3 px bottom reveal edge receives input. When open,
    // the region also covers the bottom gap so hover survives the animation.
    Item {
        id: inputRegion
        x: theme.sideMargin
        width: Math.max(0, window.width - theme.sideMargin * 2)
        height: window.fullscreenLocked
            ? 0
            : (window.searchOpen || window.contextMenuOpen
                || window.audioOpen || window.systemOpen || window.calendarOpen
                || window.clipboardOpen || window.networkOpen
                || window.notificationsOpen || window.notificationToast
                ? window.implicitHeight
                : (window.expanded
                    ? theme.barHeight + theme.topMargin
                    : theme.hiddenHeight))
        y: window.height - height
    }

    Rectangle {
        id: bar
        x: theme.sideMargin
        y: window.expanded
            ? window.height - theme.topMargin - height
            : (window.fullscreenLocked
                ? window.height
                : window.height - theme.hiddenHeight)
        visible: !window.fullscreenLocked
        width: Math.max(0, window.width - theme.sideMargin * 2)
        height: theme.barHeight
        radius: theme.radius
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.96)
        border.width: 1
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.72)
        clip: true

        Behavior on y {
            SmoothedAnimation {
                velocity: 320
                maximumEasingTime: 75
                reversingMode: SmoothedAnimation.Eased
            }
        }

        Item {
            id: barContent

            anchors {
                fill: parent
                leftMargin: 7
                rightMargin: 7
                topMargin: 6
                bottomMargin: 6
            }
            Rectangle {
                id: searchBox

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                readonly property real availableWidth: Math.max(
                    theme.buttonSize + 8,
                    pinnedBox.x - 12)
                width: implicitWidth
                height: theme.buttonSize
                implicitWidth: window.searchOpen
                    ? Math.min(390, availableWidth)
                    : theme.buttonSize + 8
                radius: 11
                color: window.searchOpen ? theme.mantle : "transparent"
                border.width: window.searchOpen ? 1 : 0
                border.color: window.searchOpen ? theme.mauve : theme.surface0
                clip: true

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 210
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color { ColorAnimation { duration: 130 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                AppButton {
                    id: searchButton

                    anchors {
                        left: parent.left
                        leftMargin: 4
                        verticalCenter: parent.verticalCenter
                    }
                    app: window.appFinder
                    themeData: theme
                    accent: true
                    launchOnClick: false
                    onActivated: window.toggleSearch()
                }

                Item {
                    id: searchTextArea

                    x: searchButton.x + searchButton.width + 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, parent.width - x - 10)
                    height: theme.buttonSize
                    visible: window.searchOpen

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        text: "Search applications, files, or folders…"
                        color: theme.overlay
                        opacity: searchInput.text.length === 0 ? 1 : 0
                        font.family: theme.fontFamily
                        font.pixelSize: 13
                        visible: opacity > 0

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    TextInput {
                        id: searchInput

                        anchors {
                            fill: parent
                            topMargin: 7
                            bottomMargin: 7
                        }
                        enabled: window.searchOpen
                        opacity: window.searchOpen ? 1 : 0
                        color: theme.text
                        selectionColor: theme.mauve
                        selectedTextColor: theme.crust
                        cursorVisible: activeFocus
                        clip: true
                        font.family: theme.fontFamily
                        font.pixelSize: 13
                        verticalAlignment: TextInput.AlignVCenter

                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        onTextChanged: {
                            window.searchQuery = text
                            Qt.callLater(function() {
                                resultsList.currentIndex = resultsList.count > 0 ? 0 : -1
                            })
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                window.closeSearch()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                if (resultsList.count > 0) {
                                    resultsList.currentIndex = Math.min(
                                        resultsList.currentIndex + 1,
                                        resultsList.count - 1)
                                    resultsList.positionViewAtIndex(
                                        resultsList.currentIndex,
                                        ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                if (resultsList.count > 0) {
                                    resultsList.currentIndex = Math.max(
                                        resultsList.currentIndex - 1,
                                        0)
                                    resultsList.positionViewAtIndex(
                                        resultsList.currentIndex,
                                        ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return
                                    || event.key === Qt.Key_Enter) {
                                window.launchResult(resultsList.currentIndex)
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: pinnedBox

                anchors.centerIn: parent
                width: pinnedRow.implicitWidth + 12
                height: theme.buttonSize
                radius: 12
                color: theme.mantle
                border.width: 1
                border.color: theme.surface0
                clip: true

                Row {
                    id: pinnedRow
                    anchors.centerIn: parent
                    spacing: theme.itemSpacing

                    Repeater {
                        model: window.taskbarApps

                        AppButton {
                            required property var modelData
                            readonly property var trackedWindows:
                                window.windowTracker.windowsForClasses(modelData.wmClasses)
                            readonly property string trackedWindowId:
                                window.windowTracker.windowForClasses(modelData.wmClasses)

                            app: modelData
                            themeData: theme
                            running: trackedWindowId.length > 0
                            active: window.windowTracker.classesAreActive(modelData.wmClasses)
                            launchOnClick: false
                            onActivated: {
                                const point = mapToItem(bar, width / 2, height)
                                window.handleTaskbarClick(
                                    modelData, trackedWindows, trackedWindowId,
                                    active, point.x)
                            }
                            onContextRequested: {
                                const point = mapToItem(bar, width / 2, height)
                                window.openContextMenu(
                                    modelData, trackedWindowId, active, point.x)
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: rightBox

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: rightContent.implicitWidth + 18
                height: theme.buttonSize
                radius: 11
                color: theme.mantle
                border.width: 1
                border.color: theme.surface0

                Row {
                    id: rightContent
                    anchors.centerIn: parent
                    spacing: 10

                    Row {
                        id: systemTrayRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Repeater {
                            model: SystemTray.items

                            TrayButton {
                                required property var modelData

                                trayItem: modelData
                                parentWindow: window
                                themeData: theme
                                onInteracted: {
                                    window.closeNetwork()
                                    window.closeNotifications()
                                    window.closeClipboard()
                                    window.closeCalendar()
                                    window.closeAudio()
                                    window.closeSystem()
                                    window.closeSearch()
                                    window.closeContextMenu()
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 22
                        color: theme.surface1
                        visible: SystemTray.items.values.length > 0
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        AudioButton {
                            id: audioButton

                            themeData: theme
                            volume: window.audioVolume
                            muted: window.audioMuted
                            available: window.audioAvailable
                            open: window.audioOpen

                            onActivated: window.toggleAudio()
                            onMuteRequested: window.toggleAudioMute()
                            onMixerRequested: {
                                window.closeAudio()
                                Quickshell.execDetached(["pavucontrol"])
                            }
                            onVolumeStepRequested: function(step) {
                                window.adjustAudioVolume(step)
                            }
                        }

                        AppButton {
                            app: window.screenshotAction
                            themeData: theme
                        }

                        AppButton {
                            id: clipboardButton
                            app: window.clipboardAction
                            themeData: theme
                            launchOnClick: false
                            onActivated: window.toggleClipboard()
                        }

                        AppButton {
                            app: window.showDesktopAction
                            themeData: theme
                        }

                        StatusIconButton {
                            id: statusCenterButton
                            themeData: theme
                            glyph: window.networkOpen || window.notificationsOpen
                                ? "" : ""
                            glyphColor: theme.lavender
                            open: window.networkOpen || window.notificationsOpen
                            count: window.notificationState.count
                            onActivated: {
                                if (window.networkOpen || window.notificationsOpen) {
                                    window.closeNetwork()
                                    window.closeNotifications()
                                } else {
                                    window.openNetwork()
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 22
                        color: theme.surface1
                    }

                    Rectangle {
                        id: weatherClockButton

                        anchors.verticalCenter: parent.verticalCenter
                        width: weatherClockContent.implicitWidth + 12
                        height: theme.buttonSize - 4
                        radius: 9
                        color: window.calendarOpen || weatherClockPointer.containsMouse
                            ? theme.surface1 : "transparent"

                        Behavior on color { ColorAnimation { duration: 110 } }

                        Row {
                            id: weatherClockContent
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: window.weatherGlyph
                                color: window.weatherFailed ? theme.overlay : theme.yellow
                                font.family: theme.monoFamily
                                font.pixelSize: 18
                                font.weight: Font.Normal
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: window.weatherReady
                                    ? Math.round(window.weatherTemperature) + "°"
                                    : "—°"
                                color: theme.subtext
                                font.family: theme.monoFamily
                                font.pixelSize: 11
                                font.weight: Font.Normal
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: -2

                                Text {
                                    anchors.right: parent.right
                                    text: Qt.formatDateTime(window.clockSource.date, "HH:mm")
                                    color: theme.text
                                    font.family: theme.monoFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Normal
                                }

                                Text {
                                    anchors.right: parent.right
                                    text: window.compactDateLabel(window.clockSource.date)
                                    color: theme.overlay
                                    font.family: theme.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Normal
                                }
                            }
                        }

                        MouseArea {
                            id: weatherClockPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.toggleCalendar()
                        }
                    }

                    SystemButton {
                        themeData: theme
                        profileImage: window.configuration.profileImage
                        open: window.systemOpen
                        onActivated: window.toggleSystem()
                    }
                }
            }
        }
    }

    Loader {
        id: clipboardPopupLoader
        anchors.fill: parent
        active: window.clipboardOpen
        z: 18

        sourceComponent: Component {
            Item {
                MouseArea {
                    id: clipboardDismissArea

        x: 0
        y: 0
        width: window.width
        height: Math.max(0, bar.y)
        visible: window.clipboardOpen
        z: 18
        onClicked: window.closeClipboard()
    }

                Rectangle {
                    id: clipboardPopup

        x: bar.x + bar.width - width - 84
        y: bar.y - 8 - height
        width: 360
        height: window.clipboardPopupHeight
        radius: theme.radius
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.82)
        opacity: window.clipboardOpen ? 1 : 0
        scale: window.clipboardOpen ? 1 : 0.96
        transformOrigin: Item.BottomRight
        visible: opacity > 0
        clip: true
        z: 20

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
            spacing: 9

            Item {
                width: parent.width
                height: 38

                Row {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 9

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 22
                        source: window.clipboardAction.iconSource
                        mipmap: true
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: -1

                        Text {
                            text: "Clipboard"
                            color: theme.text
                            font.family: theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Normal
                        }

                        Text {
                            text: window.clipboardItems.length === 1
                                ? "1 item in the current session"
                                : window.clipboardItems.length + " items in the current session"
                            color: theme.overlay
                            font.family: theme.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Normal
                        }
                    }
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    width: 66
                    height: 28
                    radius: 8
                    visible: window.clipboardItems.length > 0
                    color: clearClipboardPointer.containsMouse
                        ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.18)
                        : theme.surface0

                    Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        color: clearClipboardPointer.containsMouse ? theme.red : theme.subtext
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Normal
                    }

                    MouseArea {
                        id: clearClipboardPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.clearClipboardHistory()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: theme.surface0
            }

            Item {
                width: parent.width
                height: 236

                ListView {
                    id: clipboardList

                    anchors.fill: parent
                    clip: true
                    spacing: 5
                    model: window.clipboardItems
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: clipboardList.width
                        height: 42
                        radius: 10
                        color: clipboardItemPointer.containsMouse
                            ? theme.surface1 : theme.surface0
                        border.width: 1
                        border.color: index === 0
                            ? Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.75)
                            : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.45)

                        Behavior on color { ColorAnimation { duration: 90 } }

                        Rectangle {
                            anchors {
                                left: parent.left
                                leftMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            width: 24
                            height: 24
                            radius: 7
                            color: parent.index === 0
                                ? Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.22)
                                : theme.surface1

                            Text {
                                anchors.centerIn: parent
                                text: String(parent.parent.index + 1)
                                color: parent.parent.index === 0 ? theme.mauve : theme.overlay
                                font.family: theme.monoFamily
                                font.pixelSize: 9
                                font.weight: Font.Normal
                            }
                        }

                        Column {
                            anchors {
                                left: parent.left
                                leftMargin: 40
                                right: deleteClipboardButton.left
                                rightMargin: 7
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: -1

                            Text {
                                width: parent.width
                                text: window.clipboardPreview(parent.parent.modelData.text)
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Normal
                            }

                            Text {
                                text: parent.parent.index === 0
                                    ? "Current clipboard" : "Click to select"
                                color: parent.parent.index === 0 ? theme.mauve : theme.overlay
                                font.family: theme.fontFamily
                                font.pixelSize: 8
                                font.weight: Font.Normal
                            }
                        }

                        Rectangle {
                            id: deleteClipboardButton
                            anchors {
                                right: parent.right
                                rightMargin: 7
                                verticalCenter: parent.verticalCenter
                            }
                            width: 26
                            height: 26
                            radius: 8
                            color: deleteClipboardPointer.containsMouse
                                ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.18)
                                : "transparent"
                            z: 3

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: deleteClipboardPointer.containsMouse
                                    ? theme.red : theme.overlay
                                font.family: theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Normal
                            }

                            MouseArea {
                                id: deleteClipboardPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.removeClipboardItem(
                                    deleteClipboardButton.parent.index)
                            }
                        }

                        MouseArea {
                            id: clipboardItemPointer
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                                right: deleteClipboardButton.left
                            }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.selectClipboardItem(parent.modelData)
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: window.clipboardItems.length === 0

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitSize: 34
                        source: window.clipboardAction.iconSource
                        mipmap: true
                        opacity: 0.55
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "History is empty"
                        color: theme.subtext
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Normal
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Copy some text and it will appear here"
                        color: theme.overlay
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Normal
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Last 10 text entries · stored in memory only"
                color: theme.overlay
                font.family: theme.fontFamily
                font.pixelSize: 8
                font.weight: Font.Normal
            }
        }
                }
            }
        }
    }

    Loader {
        id: calendarPopupLoader
        anchors.fill: parent
        active: window.calendarOpen
        z: 18

        sourceComponent: Component {
            Item {
                MouseArea {
                    id: calendarDismissArea

        x: 0
        y: 0
        width: window.width
        height: Math.max(0, bar.y)
        visible: window.calendarOpen
        z: 18
        onClicked: window.closeCalendar()
    }

                Rectangle {
                    id: calendarPopup

        x: bar.x + bar.width - width - 52
        y: bar.y - 8 - height
        width: 348
        height: window.calendarPopupHeight
        radius: theme.radius
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.82)
        opacity: window.calendarOpen ? 1 : 0
        scale: window.calendarOpen ? 1 : 0.96
        transformOrigin: Item.BottomRight
        visible: opacity > 0
        clip: true
        z: 20

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
                        text: Qt.formatDateTime(window.clockSource.date, "HH:mm")
                        color: theme.text
                        font.family: theme.monoFamily
                        font.pixelSize: 28
                        font.weight: Font.Normal
                    }

                    Text {
                        width: parent.width
                        text: window.longDateLabel(window.clockSource.date)
                        color: theme.overlay
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Normal
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    width: parent.width - 134
                    height: 68
                    radius: 11
                    color: theme.surface0
                    border.width: 1
                    border.color: Qt.rgba(
                        theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.65)

                    Row {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 9

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: window.weatherGlyph
                            color: window.weatherFailed ? theme.overlay : theme.yellow
                            font.family: theme.monoFamily
                            font.pixelSize: 28
                            font.weight: Font.Normal
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Row {
                                spacing: 6

                                Text {
                                    text: window.weatherReady
                                        ? Math.round(window.weatherTemperature) + "°C" : "—°C"
                                    color: theme.text
                                    font.family: theme.monoFamily
                                    font.pixelSize: 15
                                    font.weight: Font.Normal
                                }

                                Text {
                                    anchors.baseline: parent.children[0].baseline
                                    text: window.weatherLocation
                                    color: theme.mauve
                                    font.family: theme.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Normal
                                }
                            }

                            Text {
                                text: window.weatherDescription
                                color: theme.subtext
                                font.family: theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Normal
                            }

                            Text {
                                text: window.weatherReady
                                    ? "Feels like " + Math.round(window.weatherFeelsLike)
                                        + "° · Wind " + Math.round(window.weatherWindSpeed) + " km/h"
                                    : "Updates every 15 minutes"
                                color: theme.overlay
                                font.family: theme.fontFamily
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
                color: theme.surface0
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
                        ? theme.surface1 : theme.surface0

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Normal
                    }

                    MouseArea {
                        id: previousMonthPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.shiftCalendarMonth(-1)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: window.calendarMonthNames[window.calendarMonth]
                        + " " + window.calendarYear
                    color: theme.text
                    font.family: theme.fontFamily
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
                        ? theme.surface1 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Today"
                        color: theme.mauve
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Normal
                    }

                    MouseArea {
                        id: todayMonthPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.resetCalendarMonth()
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
                        ? theme.surface1 : theme.surface0

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Normal
                    }

                    MouseArea {
                        id: nextMonthPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.shiftCalendarMonth(1)
                    }
                }
            }

            Row {
                width: parent.width
                height: 20
                spacing: 4

                Repeater {
                    model: window.calendarWeekdayNames

                    Text {
                        required property var modelData
                        width: (316 - 24) / 7
                        height: 20
                        text: String(modelData)
                        color: modelData === "Sa" || modelData === "Su"
                            ? theme.mauve : theme.overlay
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: theme.fontFamily
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
                    model: window.calendarDays

                    Rectangle {
                        required property var modelData
                        width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                        height: 32
                        radius: 9
                        color: modelData.today
                            ? theme.mauve
                            : (calendarDayPointer.containsMouse
                                ? theme.surface1 : "transparent")
                        border.width: modelData.current || modelData.today ? 0 : 1
                        border.color: theme.surface0

                        Behavior on color { ColorAnimation { duration: 90 } }

                        Text {
                            anchors.centerIn: parent
                            text: String(parent.modelData.day)
                            color: parent.modelData.today
                                ? theme.crust
                                : (parent.modelData.current ? theme.text : theme.overlay)
                            opacity: parent.modelData.current || parent.modelData.today ? 1 : 0.52
                            font.family: theme.monoFamily
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
                                    window.calendarYear = parent.modelData.year
                                    window.calendarMonth = parent.modelData.month
                                }
                            }
                        }
                    }
                }
            }
        }
                }
            }
        }
    }

    Loader {
        id: systemPopupLoader
        anchors.fill: parent
        active: window.systemOpen
        z: 18

        sourceComponent: Component {
            Item {
                MouseArea {
                    id: systemDismissArea

        x: 0
        y: 0
        width: window.width
        height: Math.max(0, bar.y)
        visible: window.systemOpen
        z: 18
        onClicked: window.closeSystem()
    }

                Rectangle {
                    id: systemPopup

        x: bar.x + bar.width - width - 8
        y: bar.y - 8 - height
        width: 300
        height: window.systemPopupHeight
        radius: theme.radius
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.82)
        opacity: window.systemOpen ? 1 : 0
        scale: window.systemOpen ? 1 : 0.96
        transformOrigin: Item.BottomRight
        visible: opacity > 0
        clip: true
        z: 20

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
            spacing: 9

            Row {
                width: parent.width
                height: 42
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 12
                    color: theme.surface0
                    border.width: 1
                    border.color: theme.surface1

                    Image {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        source: window.configuration.profileImage
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 50
                    spacing: -1

                    Text {
                        text: window.configuration.profileName
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Normal
                    }

                    Text {
                        width: parent.width
                        text: window.systemHostName + "  •  System resources"
                        color: theme.overlay
                        elide: Text.ElideRight
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                    }
                }
            }

            Grid {
                id: resourceGrid

                width: parent.width
                height: 154
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: window.systemResourceItems

                    Rectangle {
                        id: resourceCard

                        required property var modelData
                        width: (resourceGrid.width - resourceGrid.columnSpacing) / 2
                        height: 73
                        radius: 11
                        color: theme.surface0

                        Text {
                            anchors {
                                left: parent.left
                                top: parent.top
                                leftMargin: 10
                                topMargin: 8
                            }
                            text: resourceCard.modelData.label
                            color: resourceCard.modelData.accent
                            font.family: theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Normal
                        }

                        Text {
                            anchors {
                                right: parent.right
                                top: parent.top
                                rightMargin: 10
                                topMargin: 7
                            }
                            text: resourceCard.modelData.value
                            color: theme.text
                            font.family: theme.monoFamily
                            font.pixelSize: 12
                            font.weight: Font.Normal
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                leftMargin: 10
                                rightMargin: 10
                                topMargin: 34
                            }
                            height: 5
                            radius: 3
                            color: theme.surface1

                            Rectangle {
                                width: parent.width * Math.max(0,
                                    Math.min(1, Number(resourceCard.modelData.level)))
                                height: parent.height
                                radius: parent.radius
                                color: resourceCard.modelData.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 280
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: 10
                                rightMargin: 10
                                bottomMargin: 8
                            }
                            text: resourceCard.modelData.detail
                            color: theme.overlay
                            elide: Text.ElideRight
                            font.family: theme.fontFamily
                            font.pixelSize: 8
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: theme.surface0
            }

            Row {
                width: parent.width
                height: 42
                spacing: 7

                Repeater {
                    model: [
                        { action: "switch-user", icon: "⇄", label: "Switch user" },
                        { action: "restart", icon: "↻", label: "Restart" },
                        { action: "shutdown", icon: "⏻", label: "Shut down" }
                    ]

                    Rectangle {
                        id: systemActionButton

                        required property var modelData
                        width: (parent.width - 2 * parent.spacing) / 3
                        height: parent.height
                        radius: 10
                        color: systemActionPointer.containsMouse
                            ? (modelData.action === "shutdown"
                                ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.20)
                                : theme.surface1)
                            : theme.surface0

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: systemActionButton.modelData.icon
                                color: systemActionButton.modelData.action === "shutdown"
                                    ? theme.red : theme.mauve
                                font.family: theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Normal
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: systemActionButton.modelData.label
                                color: theme.subtext
                                font.family: theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Normal
                            }
                        }

                        MouseArea {
                            id: systemActionPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.requestSystemAction(
                                systemActionButton.modelData.action)
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.995)
            visible: window.systemConfirmAction.length > 0
            z: 30

            Column {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 14

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: window.systemConfirmAction === "restart" ? "↻" : "⏻"
                    color: window.systemConfirmAction === "restart"
                        ? theme.mauve : theme.red
                    font.family: theme.fontFamily
                    font.pixelSize: 32
                }

                Text {
                    width: parent.width
                    text: window.systemConfirmAction === "restart"
                        ? "Restart the computer?"
                        : "Shut down the computer?"
                    color: theme.text
                    horizontalAlignment: Text.AlignHCenter
                    font.family: theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Normal
                }

                Text {
                    width: parent.width
                    text: "Save your open work before continuing."
                    color: theme.overlay
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.family: theme.fontFamily
                    font.pixelSize: 10
                }

                Row {
                    width: parent.width
                    height: 38
                    spacing: 8

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: 10
                        color: cancelSystemPointer.containsMouse
                            ? theme.surface1 : theme.surface0

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: theme.subtext
                            font.family: theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Normal
                        }

                        MouseArea {
                            id: cancelSystemPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.systemConfirmAction = ""
                        }
                    }

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: 10
                        color: confirmSystemPointer.containsMouse
                            ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.34)
                            : Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.20)
                        border.width: 1
                        border.color: theme.red

                        Text {
                            anchors.centerIn: parent
                            text: "Confirm"
                            color: theme.red
                            font.family: theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Normal
                        }

                        MouseArea {
                            id: confirmSystemPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.confirmSystemAction()
                        }
                    }
                }
            }
        }
                }
            }
        }
    }

    Loader {
        id: audioPopupLoader
        anchors.fill: parent
        active: window.audioOpen
        z: 18

        sourceComponent: Component {
            Item {
                MouseArea {
                    id: audioDismissArea

        x: 0
        y: 0
        width: window.width
        height: Math.max(0, bar.y)
        visible: window.audioOpen
        z: 18
        onClicked: window.closeAudio()
    }

                Rectangle {
                    id: audioPopup

        x: bar.x + bar.width - width - 8
        y: bar.y - 8 - height
        width: 286
        height: window.audioPopupHeight
        radius: theme.radius
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.82)
        opacity: window.audioOpen ? 1 : 0
        scale: window.audioOpen ? 1 : 0.96
        transformOrigin: Item.BottomRight
        visible: opacity > 0
        clip: true
        z: 20

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
                    source: audioButton.iconSource
                    mipmap: true
                }

                Column {
                    y: Math.round((parent.height - height) / 2)
                    width: parent.width - 79
                    spacing: -1

                    Text {
                        text: "Audio output  ▾"
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Normal
                    }

                    Text {
                        width: parent.width
                        text: window.audioDescription
                        color: theme.overlay
                        elide: Text.ElideRight
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                    }

                    TapHandler {
                        cursorShape: Qt.PointingHandCursor
                        onTapped: window.openAudioDeviceChooser("sink")
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    text: window.audioAvailable ? window.audioPercent + "%" : "—"
                    color: window.audioMuted ? theme.red : theme.mauve
                    horizontalAlignment: Text.AlignRight
                    font.family: theme.monoFamily
                    font.pixelSize: 12
                    font.weight: Font.Normal

                    Behavior on color { ColorAnimation { duration: 100 } }
                }
            }

            Item {
                id: volumeSlider

                width: parent.width
                height: 34
                enabled: window.audioAvailable
                readonly property real level: Math.max(0, Math.min(1, window.audioVolume))

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
                    color: theme.surface1

                    Rectangle {
                        width: parent.width * volumeSlider.level
                        height: parent.height
                        radius: parent.radius
                        color: window.audioMuted ? theme.red : theme.mauve

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
                        color: theme.rosewater
                        border.width: 2
                        border.color: theme.mauve

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
                        window.setAudioVolume(ratio)
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
                        window.adjustAudioVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
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
                        ? Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.72)
                        : (window.audioMuted
                            ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.18)
                            : theme.surface0)

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: window.audioMuted ? "Unmute" : "Mute"
                        color: window.audioMuted ? theme.red : theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Normal
                    }

                    MouseArea {
                        id: mutePointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.toggleAudioMute()
                    }
                }

                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    radius: 9
                    color: mixerPointer.containsMouse ? theme.surface1 : theme.surface0

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Audio mixer"
                        color: theme.subtext
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Normal
                    }

                    MouseArea {
                        id: mixerPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            window.closeAudio()
                            Quickshell.execDetached(["pavucontrol"])
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: theme.surface0
            }

            Row {
                width: parent.width
                height: 30
                spacing: 9

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 22
                    source: window.microphoneMuted
                        ? window.assetIconDirectory + "catppuccin-microphone-muted.svg"
                        : window.assetIconDirectory + "catppuccin-microphone.svg"
                    mipmap: true
                    opacity: window.microphoneAvailable ? 1 : 0.45

                    MouseArea {
                        anchors.fill: parent
                        enabled: window.microphoneAvailable
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.toggleMicrophoneMute()
                    }
                }

                Column {
                    y: Math.round((parent.height - height) / 2)
                    width: parent.width - 79
                    spacing: -1

                    Text {
                        text: "Microphone  ▾"
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Normal
                    }

                    Text {
                        width: parent.width
                        text: window.microphoneDescription
                        color: theme.overlay
                        elide: Text.ElideRight
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                    }

                    TapHandler {
                        cursorShape: Qt.PointingHandCursor
                        onTapped: window.openAudioDeviceChooser("source")
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    text: window.microphoneAvailable
                        ? window.microphonePercent + "%"
                        : "—"
                    color: window.microphoneMuted ? theme.red : theme.blue
                    horizontalAlignment: Text.AlignRight
                    font.family: theme.monoFamily
                    font.pixelSize: 11
                    font.weight: Font.Normal

                    Behavior on color { ColorAnimation { duration: 100 } }
                }
            }

            Item {
                id: microphoneSlider

                width: parent.width
                height: 28
                enabled: window.microphoneAvailable
                readonly property real level:
                    Math.max(0, Math.min(1, window.microphoneVolume))

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
                    color: theme.surface1

                    Rectangle {
                        width: parent.width * microphoneSlider.level
                        height: parent.height
                        radius: parent.radius
                        color: window.microphoneMuted ? theme.red : theme.blue

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
                        color: theme.rosewater
                        border.width: 2
                        border.color: theme.blue

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
                        window.setMicrophoneVolume(ratio)
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
                        window.setMicrophoneVolume(window.microphoneVolume
                            + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
                        wheel.accepted = true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: theme.surface0
            }

            Rectangle {
                width: parent.width
                height: 68
                radius: 10
                color: theme.surface0

                Row {
                    anchors {
                        fill: parent
                        margins: 9
                    }
                    spacing: 8

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 23
                        source: window.assetIconDirectory + "catppuccin-media.svg"
                        mipmap: true
                        opacity: window.mediaAvailable ? 1 : 0.42
                    }

                    Column {
                        y: Math.round((parent.height - height) / 2)
                        width: parent.width - 104
                        spacing: 0

                        Text {
                            text: "Now playing"
                            color: theme.overlay
                            font.family: theme.fontFamily
                            font.pixelSize: 9
                        }

                        Text {
                            width: parent.width
                            text: window.mediaTitle
                            color: theme.text
                            elide: Text.ElideRight
                            font.family: theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Normal
                        }

                        Text {
                            width: parent.width
                            text: window.mediaSubtitle
                            color: theme.subtext
                            elide: Text.ElideRight
                            font.family: theme.fontFamily
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
                                    ? theme.surface2
                                    : "transparent"
                                opacity: {
                                    if (!window.mediaPlayer) {
                                        return 0.35
                                    }
                                    if (modelData === "previous") {
                                        return window.mediaPlayer.canGoPrevious ? 1 : 0.35
                                    }
                                    if (modelData === "next") {
                                        return window.mediaPlayer.canGoNext ? 1 : 0.35
                                    }
                                    return window.mediaPlayer.canTogglePlaying ? 1 : 0.35
                                }

                                Behavior on color { ColorAnimation { duration: 90 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData === "previous"
                                        ? "‹"
                                        : (parent.modelData === "next"
                                            ? "›"
                                            : (window.mediaPlayer
                                                && window.mediaPlayer.isPlaying ? "Ⅱ" : "▶"))
                                    color: parent.modelData === "toggle"
                                        ? theme.mauve
                                        : theme.subtext
                                    font.family: theme.fontFamily
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
                                            window.previousMediaTrack()
                                        } else if (parent.modelData === "next") {
                                            window.nextMediaTrack()
                                        } else {
                                            window.toggleMediaPlayback()
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
            color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.995)
            visible: window.audioDeviceChooser.length > 0
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
                            ? theme.surface1
                            : theme.surface0

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: theme.text
                            font.family: theme.fontFamily
                            font.pixelSize: 22
                        }

                        MouseArea {
                            id: chooserBackPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.audioDeviceChooser = ""
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: window.audioDeviceChooser === "source"
                            ? "Choose a microphone"
                            : "Choose an audio output"
                        color: theme.text
                        font.family: theme.fontFamily
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
                    model: window.audioDeviceChooser === "source"
                        ? window.audioSources
                        : window.audioSinks

                    delegate: Rectangle {
                        id: deviceChoice

                        required property var modelData
                        required property int index
                        readonly property bool selected:
                            window.audioDeviceChooser === "source"
                                ? modelData === window.microphoneSource
                                : modelData === window.audioSink

                        width: audioDeviceList.width
                        height: 48
                        radius: 10
                        color: deviceChoicePointer.containsMouse
                            ? theme.surface1
                            : (selected
                                ? Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.14)
                                : theme.surface0)
                        border.width: selected ? 1 : 0
                        border.color: theme.mauve

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
                            color: parent.selected ? theme.mauve : theme.overlay
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
                            color: selected ? theme.text : theme.subtext
                            elide: Text.ElideRight
                            font.family: theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Normal
                        }

                        MouseArea {
                            id: deviceChoicePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.selectAudioDevice(deviceChoice.modelData)
                        }
                    }
                }
            }
        }
                }
            }
        }
    }

    Loader {
        id: networkPopupLoader
        anchors.fill: parent
        active: window.networkOpen
        z: 22

        sourceComponent: Component {
            NetworkPopup {
                themeData: theme
                barX: bar.x
                barY: bar.y
                barWidth: bar.width
                onCloseRequested: window.closeNetwork()
                onTabRequested: function(tab) {
                    if (tab === "notifications") window.openNotifications()
                }
            }
        }
    }

    Loader {
        id: notificationsPopupLoader
        anchors.fill: parent
        active: window.notificationsOpen
        z: 22

        sourceComponent: Component {
            NotificationPopup {
                themeData: theme
                notificationState: window.notificationState
                barX: bar.x
                barY: bar.y
                barWidth: bar.width
                onCloseRequested: window.closeNotifications()
                onTabRequested: function(tab) {
                    if (tab === "network") window.openNetwork()
                }
            }
        }
    }

    Loader {
        id: notificationToastLoader
        anchors.fill: parent
        active: window.notificationToast !== null
        z: 40

        sourceComponent: Component {
            NotificationToast {
                notification: window.notificationToast
                themeData: theme
                barX: bar.x
                barY: bar.y
                barWidth: bar.width
                onFinished: window.notificationToast = null
            }
        }
    }

    Rectangle {
        id: searchResults

        x: bar.x + 7
        y: bar.y - 8 - height
        width: searchBox.width
        height: window.resultsHeight
        radius: theme.radius
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.98)
        border.width: 1
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.78)
        opacity: window.searchOpen ? 1 : 0
        scale: window.searchOpen ? 1 : 0.97
        transformOrigin: Item.Bottom
        visible: opacity > 0
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            visible: resultsList.count === 0
            text: window.searchQuery.trim().length < 2
                ? "Type at least 2 characters to search files"
                : "No results found"
            color: theme.overlay
            font.family: theme.fontFamily
            font.pixelSize: 12
        }

        ListView {
            id: resultsList

            anchors {
                fill: parent
                margins: 7
            }
            visible: count > 0
            model: searchModel
            clip: true
            spacing: 1
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds

            delegate: SearchResult {
                required property var modelData
                required property int index

                width: resultsList.width
                entry: modelData
                themeData: theme
                selected: ListView.isCurrentItem

                onHovered: resultsList.currentIndex = index
                onActivated: function(entry) {
                    window.launchEntry(entry)
                }
            }
        }
    }

    Item {
        id: contextInteractionArea

        readonly property real menuWidth: 252
        readonly property real desiredX:
            bar.x + window.contextAnchorX - menuWidth / 2
        x: Math.max(theme.sideMargin,
            Math.min(desiredX, window.width - theme.sideMargin - menuWidth))
        y: bar.y - 8 - contextMenu.height
        width: menuWidth
        height: contextMenu.height + 8 + bar.height
        visible: window.contextMenuOpen
        z: 30

        onVisibleChanged: {
            if (visible && !contextMenuHover.hovered) {
                contextCloseDelay.restart()
            }
        }

        HoverHandler {
            id: contextMenuHover

            onHoveredChanged: {
                if (hovered) {
                    contextCloseDelay.stop()
                } else if (window.contextMenuOpen) {
                    contextCloseDelay.restart()
                }
            }
        }

        Rectangle {
            id: contextMenu

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: Math.min(
                window.resultsHeight,
                55 + window.contextMenuItems.length * 33)
            radius: theme.radius
            color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.99)
            border.width: 1
            border.color: Qt.rgba(
                theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.82)
            clip: true

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 13
                    rightMargin: 13
                    topMargin: 10
                }
                height: 29
                text: window.contextApp
                    ? (window.windowChooserMode
                        ? window.contextApp.name + " — "
                            + window.contextWindows.length + " windows"
                        : window.contextApp.name)
                    : ""
                color: theme.text
                font.family: theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Normal
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 9
                    rightMargin: 9
                    topMargin: 43
                }
                height: 1
                color: theme.surface0
            }

            ListView {
                id: contextActionList
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 6
                    rightMargin: 6
                    topMargin: 48
                    bottomMargin: 7
                }
                model: window.contextMenuItems
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: contextAction
                    required property var modelData

                    width: contextActionList.width
                    height: 33
                    radius: 8
                    color: contextPointer.containsMouse
                        ? Qt.rgba(
                            theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.88)
                        : "transparent"

                    Behavior on color { ColorAnimation { duration: 90 } }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 6
                            rightMargin: 6
                        }
                        height: modelData.sectionBreak ? 1 : 0
                        color: theme.surface0
                        visible: height > 0
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            leftMargin: 9
                            verticalCenter: parent.verticalCenter
                        }
                        width: 5
                        height: 5
                        radius: 3
                        color: theme.mauve
                        visible: modelData.active === true
                    }

                    Text {
                        anchors {
                            fill: parent
                            leftMargin: modelData.active === true ? 21 : 10
                            rightMargin: modelData.kind === "window" ? 42 : 10
                            topMargin: modelData.sectionBreak ? 2 : 0
                        }
                        text: modelData.label
                        color: modelData.danger ? theme.red : theme.subtext
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Normal
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: contextPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.runContextAction(contextAction.modelData)
                    }

                    Rectangle {
                        id: closeWindowButton

                        anchors {
                            right: parent.right
                            rightMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        width: 24
                        height: 24
                        radius: 7
                        color: closeWindowPointer.containsMouse
                            ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.22)
                            : "transparent"
                        visible: modelData.kind === "window"
                        z: 2

                        Behavior on color { ColorAnimation { duration: 90 } }

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: closeWindowPointer.containsMouse
                                ? theme.red
                                : theme.overlay
                            font.family: theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Normal

                            Behavior on color { ColorAnimation { duration: 90 } }
                        }

                        MouseArea {
                            id: closeWindowPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.closeChooserWindow(
                                String(contextAction.modelData.windowId))
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: contextCloseDelay
        interval: 650
        onTriggered: window.closeContextMenu()
    }
}
