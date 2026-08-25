import QtQuick
import Quickshell

Item {
    id: root

    required property var host
    required property var themeData
    required property var barItem
    required property var searchBoxItem

    function resetSelection() {
        resultsList.currentIndex = resultsList.count > 0 ? 0 : -1
        if (resultsList.currentIndex >= 0) {
            resultsList.positionViewAtIndex(
                resultsList.currentIndex, ListView.Contain)
        }
    }

    function moveSelection(step) {
        if (resultsList.count === 0) {
            resultsList.currentIndex = -1
            return
        }
        resultsList.currentIndex = Math.max(0, Math.min(
            resultsList.currentIndex + Number(step),
            resultsList.count - 1))
        resultsList.positionViewAtIndex(
            resultsList.currentIndex, ListView.Contain)
    }

    function activateSelected() {
        host.launchResult(resultsList.currentIndex)
    }

    ScriptModel {
        id: searchModel
        values: host.searchItems
    }

    Connections {
        target: host
        function onSearchQueryChanged() { Qt.callLater(root.resetSelection) }
        function onFileResultsChanged() {
            if (resultsList.currentIndex < 0 && resultsList.count > 0) {
                resultsList.currentIndex = 0
            }
        }
    }

    Rectangle {
        id: searchResults
    
        x: barItem.x + 7
        y: barItem.y - 8 - height
        width: searchBoxItem.width
        height: host.resultsHeight
        radius: themeData.radius
        color: Qt.rgba(themeData.base.r, themeData.base.g, themeData.base.b, 0.98)
        border.width: 1
        border.color: Qt.rgba(themeData.surface2.r, themeData.surface2.g, themeData.surface2.b, 0.78)
        property bool entered: false
        opacity: entered && host.searchOpen ? 1 : 0
        scale: entered && host.searchOpen ? 1 : 0.97
        transformOrigin: Item.Bottom
        visible: opacity > 0
        clip: true

        Component.onCompleted: Qt.callLater(function() { entered = true })
    
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    
        Text {
            anchors.centerIn: parent
            visible: resultsList.count === 0
            text: host.searchQuery.trim().length < 2
                ? "Type at least 2 characters to search files"
                : "No results found"
            color: themeData.overlay
            font.family: themeData.fontFamily
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
                    host.launchEntry(entry)
                }
            }
        }
    }
}
