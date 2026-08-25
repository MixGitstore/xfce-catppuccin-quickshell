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

    function place(record, targetIndex) {
        const key = recordKey(record)
        if (key.length === 0) {
            return
        }

        const wanted = key.toLowerCase()
        const nextPins = []
        let placedRecord = record
        for (let index = 0; index < pins.length; ++index) {
            if (recordKey(pins[index]).toLowerCase() === wanted) {
                placedRecord = pins[index]
            } else {
                nextPins.push(pins[index])
            }
        }

        let destination = Math.round(Number(targetIndex))
        if (isNaN(destination)) {
            destination = nextPins.length
        }
        destination = Math.max(0, Math.min(destination, nextPins.length))
        nextPins.splice(destination, 0, placedRecord)
        adapter.pins = nextPins
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
