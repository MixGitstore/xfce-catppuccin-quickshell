import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    signal notificationArrived(var notification)

    readonly property var notifications: server.trackedNotifications.values
    readonly property int count: notifications.length

    function clearAll() {
        const current = notifications.slice()
        for (let index = 0; index < current.length; ++index) {
            current[index].dismiss()
        }
    }

    function trimHistory() {
        const current = notifications.slice()
        while (current.length > 40) {
            current.shift().dismiss()
        }
    }

    property NotificationServer server: NotificationServer {
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: function(notification) {
            notification.tracked = true
            Qt.callLater(root.trimHistory)
            if (!notification.lastGeneration) {
                root.notificationArrived(notification)
            }
        }
    }
}
