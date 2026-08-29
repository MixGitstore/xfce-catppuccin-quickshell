import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "Apps.js" as Apps

PanelWindow {
    id: window

    required property var clockSource
    required property var windowTracker
    required property var pinnedState
    required property var quickActionState
    required property var notificationState
    required property var configuration
    required property var displayState
    required property var audioRouteState
    property bool pinnedOpen: false
    property bool searchOpen: false
    property bool audioOpen: false
    property bool systemOpen: false
    property bool calendarOpen: false
    property bool clipboardOpen: false
    property bool networkOpen: false
    property bool notificationsOpen: false
    property bool displayOpen: false
    property bool taskbarReordering: false
    property var audioAnchorItem: null
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
    readonly property int displayPopupHeight: 410
    readonly property int popupSurfaceHeight: Math.max(
        resultsHeight, audioPopupHeight, systemPopupHeight,
        calendarPopupHeight, clipboardPopupHeight, networkPopupHeight,
        notificationsPopupHeight, displayPopupHeight)
    readonly property bool fullscreenLocked: windowTracker.fullscreenActive
    readonly property bool popupRequested: !fullscreenLocked
        && (searchOpen || contextMenuOpen || audioOpen || systemOpen
            || calendarOpen || clipboardOpen || networkOpen
            || notificationsOpen || displayOpen || notificationToast !== null)
    property bool popupSurfaceActive: false
    readonly property real popupSearchBoxWidth: searchBox.width
    property real popupAudioAnchorCenterX: width - theme.sideMargin
    readonly property bool expanded: !fullscreenLocked
        && (pinnedOpen || searchOpen || contextMenuOpen
            || audioOpen || systemOpen || calendarOpen || clipboardOpen
            || networkOpen || notificationsOpen || displayOpen
            || taskbarReordering || barHover.hovered || hideDelay.running)
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
    readonly property string audioIconSource: {
        const base = assetIconDirectory
        if (!audioAvailable || audioMuted || audioVolume <= 0.001) {
            return base + "catppuccin-volume-muted.svg"
        }
        if (audioVolume < 0.34) {
            return base + "catppuccin-volume-low.svg"
        }
        if (audioVolume < 0.67) {
            return base + "catppuccin-volume-medium.svg"
        }
        return base + "catppuccin-volume-high.svg"
    }
    readonly property string audioDescription: audioSink
        ? (audioSink.description || audioSink.nickname || audioSink.name || "Audio output")
        : "No audio device"
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
        if (!searchOpen) {
            return []
        }
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
        const availableApplications = DesktopEntries.applications.values
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

        function openDisplay(): void {
            window.openDisplay()
        }

        function nightLightOn(): void {
            window.displayState.setNightLight(true)
        }

        function nightLightOff(): void {
            window.displayState.setNightLight(false)
        }

        function nightLightAuto(): void {
            window.displayState.setAutomatic(true)
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
            window.closeDisplay()
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
                ? "Launch another instance"
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
                ? "Unpin from taskbar"
                : "Pin to taskbar",
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

    function compactDesktopIdentity(value) {
        return normalizedDesktopKey(value).replace(/[^a-z0-9]/g, "")
    }

    function desktopEntryByKey(pinKey) {
        const wanted = normalizedDesktopKey(pinKey)
        const entries = DesktopEntries.applications.values
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
        const compactClasses = normalizedClasses.map(function(value) {
            return compactDesktopIdentity(value)
        })
        const entries = DesktopEntries.applications.values

        for (let index = 0; index < entries.length; ++index) {
            const entry = entries[index]
            const startupClass = String(entry.startupClass || "").toLowerCase()
            const entryId = normalizedDesktopKey(entry.id)
            const startupParts = startupClass.split(".")
            const entryIdParts = entryId.split(".")
            const identities = [
                startupClass,
                entryId,
                startupParts[startupParts.length - 1],
                entryIdParts[entryIdParts.length - 1],
                String(entry.name || "").toLowerCase()
            ]
            if ((startupClass.length > 0 && normalizedClasses.indexOf(startupClass) !== -1)
                    || normalizedClasses.indexOf(entryId) !== -1) {
                return entry
            }

            for (let identityIndex = 0;
                    identityIndex < identities.length; ++identityIndex) {
                const identityKey = compactDesktopIdentity(
                    identities[identityIndex])
                if (identityKey.length >= 4
                        && compactClasses.indexOf(identityKey) !== -1) {
                    return entry
                }
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
            const runningClasses = window.classesForPinKey(pinKey)
            if (runningClasses.length === 0) {
                return predefined
            }

            const mergedClasses = (predefined.wmClasses || []).slice()
            const knownClasses = ({})
            for (let index = 0; index < mergedClasses.length; ++index) {
                knownClasses[String(mergedClasses[index]).toLowerCase()] = true
            }
            for (let index = 0; index < runningClasses.length; ++index) {
                const className = String(runningClasses[index])
                const classKey = className.toLowerCase()
                if (!knownClasses[classKey]) {
                    knownClasses[classKey] = true
                    mergedClasses.push(className)
                }
            }

            const mergedApp = ({})
            for (const propertyName in predefined) {
                mergedApp[propertyName] = predefined[propertyName]
            }
            mergedApp.wmClasses = mergedClasses
            return mergedApp
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
        const result = []
        const seen = ({})
        for (let index = 0; index < clients.length; ++index) {
            if (!clients[index].skipTaskbar
                    && pinKeyForClient(clients[index]) === pinKey) {
                const classes = clients[index].classes || []
                for (let classIndex = 0; classIndex < classes.length; ++classIndex) {
                    const className = String(classes[classIndex])
                    const classKey = className.toLowerCase()
                    if (!seen[classKey]) {
                        seen[classKey] = true
                        result.push(className)
                    }
                }
            }
        }
        return result
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
            + ", " + date.getDate() + " " + calendarMonthNamesShort[date.getMonth()]
    }

    function longDateLabel(date) {
        return calendarWeekdayNamesLong[date.getDay()] + ", " + date.getDate()
            + " " + calendarMonthNames[date.getMonth()] + " " + date.getFullYear()
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
        closeDisplay()
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
        closeDisplay()
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
        closeDisplay()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeContextMenu()
        searchOpen = true
        searchQuery = ""
        Qt.callLater(function() {
            searchInput.forceActiveFocus()
            window.resetSearchPopupSelection()
        })
    }

    function resetSearchPopupSelection() {
        if (popupSurfaceLoader.item) {
            popupSurfaceLoader.item.resetSearchSelection()
        }
    }

    function moveSearchPopupSelection(step) {
        if (popupSurfaceLoader.item) {
            popupSurfaceLoader.item.moveSearchSelection(step)
        }
    }

    function activateSearchPopupSelection() {
        if (popupSurfaceLoader.item) {
            popupSurfaceLoader.item.activateSearchSelection()
        }
    }

    function closeSearch() {
        searchOpen = false
        searchQuery = ""
        searchInput.text = ""
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
        closeDisplay()
        closeClipboard()
        closeCalendar()
        closeSearch()
        closeSystem()
        closeContextMenu()
        updateAudioPopupAnchor()
        audioOpen = true
    }

    function updateAudioPopupAnchor() {
        if (!audioAnchorItem) {
            popupAudioAnchorCenterX = width - theme.sideMargin
            return
        }

        const point = audioAnchorItem.mapToItem(
            window.contentItem,
            audioAnchorItem.width / 2,
            audioAnchorItem.height / 2)
        const centerX = Number(point.x)
        popupAudioAnchorCenterX = isFinite(centerX) && centerX > 0
            ? centerX
            : width - theme.sideMargin
    }

    function closeAudio() {
        audioOpen = false
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
        closeDisplay()
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
        closeDisplay()
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

    function openDisplay() {
        closeNetwork()
        closeNotifications()
        closeClipboard()
        closeCalendar()
        closeAudio()
        closeSystem()
        closeSearch()
        closeContextMenu()
        displayOpen = true
    }

    function closeDisplay() {
        displayOpen = false
    }

    function toggleDisplay() {
        if (displayOpen) closeDisplay()
        else openDisplay()
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
        closeDisplay()
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
        closeDisplay()
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
        closeDisplay()
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
        closeDisplay()
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
        if (popupSurfaceLoader.item) {
            popupSurfaceLoader.item.stopContextCloseTimer()
        }
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

    }

    Theme { id: theme }

    // Keep only the default output live while the popup is closed. The audio
    // popup tracks microphones, devices and streams only while it is loaded.
    PwObjectTracker {
        objects: window.audioSink ? [window.audioSink] : []
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
        if (window.popupRequested) {
            window.popupSurfaceActive = true
        }
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

    // The permanent X11 surface now contains only the bar. Popup content lives
    // in a separate window created on demand, so the large graphics surface is
    // absent while the panel is idle.
    implicitHeight: theme.barHeight + theme.topMargin + 8
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
    mask: compactInputMask

    Region {
        id: compactInputMask
        item: inputRegion
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
            closeDisplay()
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

    onPopupRequestedChanged: {
        if (popupRequested) {
            popupSurfaceUnloadTimer.stop()
            popupSurfaceActive = true
        } else if (popupSurfaceActive) {
            popupSurfaceUnloadTimer.restart()
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
            : (window.expanded
                ? theme.barHeight + theme.topMargin
                : theme.hiddenHeight)
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
                            Qt.callLater(window.resetSearchPopupSelection)
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                window.closeSearch()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                window.moveSearchPopupSelection(1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                window.moveSearchPopupSelection(-1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return
                                    || event.key === Qt.Key_Enter) {
                                window.activateSearchPopupSelection()
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

                // Keep the taskbar centered while its background grows or shrinks.
                // The row follows the animated inner width, so existing icons move
                // by half an item instead of the new item appearing only on the right.
                Behavior on width {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    id: pinnedRow
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - 12)
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
                            draggable: String(modelData.pinKey || "").length > 0
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
                            onReorderStarted: {
                                window.taskbarReordering = true
                                window.closeContextMenu()
                            }
                            onReorderFinished: function(sceneX) {
                                window.taskbarReordering = false
                                const localPoint = pinnedRow.mapFromItem(
                                    null, sceneX, 0)
                                const stride = theme.buttonSize + theme.itemSpacing
                                let targetIndex = Math.round(
                                    (localPoint.x - theme.buttonSize / 2) / stride)
                                const pinnedCount = window.pinnedState.pins.length
                                const alreadyPinned = window.pinnedState.isPinned(
                                    modelData.pinKey)
                                const maximumIndex = alreadyPinned
                                    ? Math.max(0, pinnedCount - 1)
                                    : pinnedCount
                                targetIndex = Math.max(
                                    0, Math.min(targetIndex, maximumIndex))
                                window.pinnedState.place(
                                    window.pinRecordForApp(modelData), targetIndex)
                            }
                            onReorderCanceled: {
                                window.taskbarReordering = false
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
                                    window.closeDisplay()
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

                    Component {
                        id: audioQuickActionComponent

                        AudioButton {
                            id: audioQuickButton

                            draggable: true
                            themeData: theme
                            volume: window.audioVolume
                            muted: window.audioMuted
                            available: window.audioAvailable
                            open: window.audioOpen

                            Component.onCompleted: window.audioAnchorItem = audioQuickButton
                            Component.onDestruction: {
                                if (window.audioAnchorItem === audioQuickButton) {
                                    window.audioAnchorItem = null
                                }
                            }

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
                    }

                    Component {
                        id: screenshotQuickActionComponent

                        AppButton {
                            draggable: true
                            app: window.screenshotAction
                            themeData: theme
                        }
                    }

                    Component {
                        id: clipboardQuickActionComponent

                        AppButton {
                            draggable: true
                            app: window.clipboardAction
                            themeData: theme
                            launchOnClick: false
                            onActivated: window.toggleClipboard()
                        }
                    }

                    Component {
                        id: desktopQuickActionComponent

                        AppButton {
                            draggable: true
                            app: window.showDesktopAction
                            themeData: theme
                        }
                    }

                    Component {
                        id: statusQuickActionComponent

                        StatusIconButton {
                            draggable: true
                            themeData: theme
                            glyph: window.networkOpen || window.notificationsOpen
                                || window.displayOpen
                                ? "" : ""
                            glyphColor: theme.lavender
                            open: window.networkOpen || window.notificationsOpen
                                || window.displayOpen
                            count: window.notificationState.count
                            onActivated: {
                                if (window.networkOpen || window.notificationsOpen
                                        || window.displayOpen) {
                                    window.closeNetwork()
                                    window.closeNotifications()
                                    window.closeDisplay()
                                } else {
                                    window.openNetwork()
                                }
                            }
                        }
                    }

                    Row {
                        id: quickActionsRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Repeater {
                            model: window.quickActionState.normalizedOrder()

                            Loader {
                                id: quickActionLoader

                                required property var modelData
                                readonly property string actionKey: String(modelData)
                                sourceComponent: actionKey === "audio"
                                    ? audioQuickActionComponent
                                    : (actionKey === "screenshot"
                                        ? screenshotQuickActionComponent
                                        : (actionKey === "clipboard"
                                            ? clipboardQuickActionComponent
                                            : (actionKey === "desktop"
                                                ? desktopQuickActionComponent
                                                : statusQuickActionComponent)))

                                Connections {
                                    target: quickActionLoader.item

                                    function onReorderStarted() {
                                        window.taskbarReordering = true
                                        window.closeContextMenu()
                                    }

                                    function onReorderFinished(sceneX) {
                                        window.taskbarReordering = false
                                        const localPoint = quickActionsRow.mapFromItem(
                                            null, sceneX, 0)
                                        const stride = theme.buttonSize + quickActionsRow.spacing
                                        let targetIndex = Math.round(
                                            (localPoint.x - theme.buttonSize / 2) / stride)
                                        targetIndex = Math.max(0, Math.min(
                                            targetIndex,
                                            window.quickActionState.normalizedOrder().length - 1))
                                        window.quickActionState.place(
                                            quickActionLoader.actionKey, targetIndex)
                                    }

                                    function onReorderCanceled() {
                                        window.taskbarReordering = false
                                    }
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

    LazyLoader {
        id: popupSurfaceLoader
        active: window.popupSurfaceActive

        PopupSurface {
            host: window
            themeData: theme
        }
    }

    Timer {
        id: popupSurfaceUnloadTimer
        interval: 190
        onTriggered: window.popupSurfaceActive = false
    }

}
