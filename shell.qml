//@ pragma UseQApplication
//@ pragma IconTheme Papirus
//@ pragma DropExpensiveFonts

import QtQuick
import Quickshell

ShellRoot {
    id: root

    // The installed Catppuccin action icons use SVG features unsupported by QtSvg.
    // Keep hot reload silent; errors remain available through `qs log`.
    Connections {
        target: Quickshell

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup()
        }

        function onReloadFailed(errorString) {
            Quickshell.inhibitReloadPopup()
        }
    }

    X11FullscreenTracker { id: windowState }
    PinnedState { id: pinnedApps }
    QuickActionState { id: quickActions }
    NotificationState { id: notifications }
    AudioRouteState { id: audioRoutes }
    UserConfig { id: userConfig }

    SystemClock {
        id: clock
        // A minute tick is enough for the bar and avoids needless wakeups.
        precision: SystemClock.Minutes
    }

    // Uses the minute tick above for the Night Light schedule. Redshift and
    // xrandr are only launched as short one-shot commands when a value changes.
    DisplayState {
        id: displaySettings
        clockSource: clock
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData

            screen: modelData
            clockSource: clock
            windowTracker: windowState
            pinnedState: pinnedApps
            quickActionState: quickActions
            notificationState: notifications
            configuration: userConfig
            displayState: displaySettings
            audioRouteState: audioRoutes
            // Desktop and restored windows keep the bar pinned. Snapped,
            // maximized or fullscreen windows switch it to autohide.
            pinnedOpen: !windowState.autoHideActive
        }
    }
}
