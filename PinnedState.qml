import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property alias pins: adapter.pins

    function recordKey(record) {
        return typeof record === "string" ? record : (record.key || "")
    }

    function isPinned(pinKey) {
        const wanted = String(pinKey || "").toLowerCase()
        for (let index = 0; index < pins.length; ++index) {
            if (recordKey(pins[index]).toLowerCase() === wanted) {
                return true
            }
        }
        return false
    }

    function pin(record) {
        const key = recordKey(record)
        if (key.length === 0 || isPinned(key)) {
            return
        }

        const nextPins = pins.slice()
        nextPins.push(record)
        adapter.pins = nextPins
    }

    function unpin(pinKey) {
        const wanted = String(pinKey || "").toLowerCase()
        adapter.pins = pins.filter(function(record) {
            return recordKey(record).toLowerCase() !== wanted
        })
    }

    property FileView storage: FileView {
        path: Quickshell.shellDir + "/pinned-apps.json"
        preload: true
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        printErrors: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property var pins: []
        }
    }
}
