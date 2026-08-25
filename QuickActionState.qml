import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property var defaults: [
        "audio", "screenshot", "clipboard", "desktop", "status"
    ]
    property alias order: adapter.order

    function normalizedOrder() {
        const result = []
        const seen = ({})
        const stored = order || []

        for (let index = 0; index < stored.length; ++index) {
            const key = String(stored[index])
            if (defaults.indexOf(key) !== -1 && !seen[key]) {
                seen[key] = true
                result.push(key)
            }
        }
        for (let index = 0; index < defaults.length; ++index) {
            const key = defaults[index]
            if (!seen[key]) {
                seen[key] = true
                result.push(key)
            }
        }
        return result
    }

    function place(key, targetIndex) {
        const wanted = String(key || "")
        if (defaults.indexOf(wanted) === -1) {
            return
        }

        const nextOrder = normalizedOrder().filter(function(candidate) {
            return candidate !== wanted
        })
        let destination = Math.round(Number(targetIndex))
        if (isNaN(destination)) {
            destination = nextOrder.length
        }
        destination = Math.max(0, Math.min(destination, nextOrder.length))
        nextOrder.splice(destination, 0, wanted)
        adapter.order = nextOrder
    }

    property FileView storage: FileView {
        path: Quickshell.shellDir + "/quick-actions.json"
        preload: true
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        printErrors: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property var order: root.defaults.slice()
        }
    }
}
