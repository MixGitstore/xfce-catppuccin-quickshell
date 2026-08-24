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
    NotificationState { id: notifications }
    UserConfig { id: userConfig }

    SystemClock {
        id: clock
        // A minute tick is enough for the bar and avoids needless wakeups.
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData

            screen: modelData
            clockSource: clock
            windowTracker: windowState
            pinnedState: pinnedApps
            notificationState: notifications
            configuration: userConfig
            // Desktop and restored windows keep the bar pinned. Snapped,
            // maximized or fullscreen windows switch it to autohide.
            pinnedOpen: !windowState.autoHideActive
        }
    }
}
