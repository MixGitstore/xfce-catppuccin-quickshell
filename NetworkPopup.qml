import QtQuick
import Quickshell
import Quickshell.Networking

Item {
    id: root

    required property var themeData
    required property real barX
    required property real barY
    required property real barWidth
    property string statusMessage: ""
    property var selectedNetwork: null

    signal closeRequested()
    signal tabRequested(string tab)

    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: {
        for (let index = 0; index < devices.length; ++index) {
            if (devices[index].type === DeviceType.Wifi) {
                return devices[index]
            }
        }
        return null
    }
    readonly property var connectedNetwork: {
        for (let deviceIndex = 0; deviceIndex < devices.length; ++deviceIndex) {
            const networks = devices[deviceIndex].networks.values
            for (let networkIndex = 0; networkIndex < networks.length; ++networkIndex) {
                if (networks[networkIndex].connected) {
                    return networks[networkIndex]
                }
            }
        }
        return null
    }
    readonly property var wifiNetworks: {
        if (!wifiDevice) {
            return []
        }
        return wifiDevice.networks.values.slice().sort(function(first, second) {
            if (first.connected !== second.connected) {
                return first.connected ? -1 : 1
            }
            if (first.known !== second.known) {
                return first.known ? -1 : 1
            }
            return Number(second.signalStrength || 0)
                - Number(first.signalStrength || 0)
        })
    }

    function needsPsk(network) {
        return network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.Sae
    }

    function activateNetwork(network) {
        statusMessage = ""
        if (network.connected) {
            network.disconnect()
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect()
        } else if (needsPsk(network)) {
            selectedNetwork = network
            passwordInput.text = ""
            Qt.callLater(function() { passwordInput.forceActiveFocus() })
        } else {
            statusMessage = "This network requires advanced configuration"
        }
    }

    function connectSelected() {
        if (!selectedNetwork || passwordInput.text.length < 8) {
            statusMessage = "The password must contain at least 8 characters"
            return
        }
        selectedNetwork.connectWithPsk(passwordInput.text)
        passwordInput.text = ""
        selectedNetwork = null
        statusMessage = "Connecting…"
    }

    function updateScanner() {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true
        }
    }

    Component.onCompleted: updateScanner()
    onWifiDeviceChanged: updateScanner()
    Component.onDestruction: {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = false
        }
    }

    ScriptModel {
        id: wifiModel
        values: root.wifiNetworks
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
        height: 390
        radius: root.themeData.radius
        color: Qt.rgba(root.themeData.base.r, root.themeData.base.g,
            root.themeData.base.b, 0.985)
        border.width: 1
        border.color: Qt.rgba(root.themeData.surface2.r, root.themeData.surface2.g,
            root.themeData.surface2.b, 0.82)
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
                    color: root.themeData.surface1
                    border.width: 1
                    border.color: root.themeData.mauve

                    Text {
                        anchors.centerIn: parent
                        text: "Network"
                        color: root.themeData.mauve
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    width: 82
                    height: 28
                    radius: 9
                    color: notificationsTabPointer.containsMouse
                        ? root.themeData.surface0 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Notifications"
                        color: root.themeData.subtext
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: notificationsTabPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabRequested("notifications")
                    }
                }
            }

            Rectangle {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: 74
                height: 28
                radius: 9
                visible: Boolean(root.wifiDevice)
                color: Networking.wifiEnabled
                    ? Qt.rgba(root.themeData.green.r, root.themeData.green.g,
                        root.themeData.green.b, 0.18)
                    : root.themeData.surface0
                border.width: 1
                border.color: Networking.wifiEnabled
                    ? root.themeData.green : root.themeData.surface2

                Text {
                    anchors.centerIn: parent
                    text: Networking.wifiEnabled ? "Wi-Fi ON" : "Wi-Fi OFF"
                    color: Networking.wifiEnabled
                        ? root.themeData.green : root.themeData.overlay
                    font.family: root.themeData.monoFamily
                    font.pixelSize: 9
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }
        }

        Rectangle {
            id: currentCard
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                leftMargin: 14
                rightMargin: 14
                topMargin: 8
            }
            height: 49
            radius: 11
            color: root.themeData.mantle
            border.width: 1
            border.color: root.connectedNetwork
                ? Qt.rgba(root.themeData.green.r, root.themeData.green.g,
                    root.themeData.green.b, 0.62)
                : root.themeData.surface0

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 12
                    rightMargin: 12
                    topMargin: 8
                }
                text: root.connectedNetwork
                    ? root.connectedNetwork.name : "No active connection"
                color: root.connectedNetwork ? root.themeData.text : root.themeData.overlay
                elide: Text.ElideRight
                font.family: root.themeData.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    leftMargin: 12
                    bottomMargin: 7
                }
                text: root.connectedNetwork
                    ? "Connected · " + root.connectedNetwork.device.name
                    : (Networking.wifiHardwareEnabled ? "Available" : "Wi-Fi hardware blocked")
                color: root.connectedNetwork ? root.themeData.green : root.themeData.overlay
                font.family: root.themeData.fontFamily
                font.pixelSize: 8
            }
        }

        Item {
            id: passwordArea
            anchors {
                left: parent.left
                right: parent.right
                top: currentCard.bottom
                leftMargin: 14
                rightMargin: 14
                topMargin: 8
            }
            height: root.selectedNetwork ? 66 : 0
            visible: height > 0
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: root.themeData.surface0
                border.width: 1
                border.color: root.themeData.mauve

                TextInput {
                    id: passwordInput
                    anchors {
                        left: parent.left
                        right: connectButton.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 11
                        rightMargin: 8
                    }
                    height: 32
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.themeData.text
                    selectionColor: root.themeData.mauve
                    selectedTextColor: root.themeData.crust
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 11
                    Keys.onReturnPressed: root.connectSelected()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: passwordInput.text.length === 0
                        text: "Password for "
                            + (root.selectedNetwork ? root.selectedNetwork.name : "network")
                        color: root.themeData.overlay
                        font: passwordInput.font
                    }
                }

                Rectangle {
                    id: connectButton
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 8
                    }
                    width: 78
                    height: 30
                    radius: 9
                    color: connectPointer.containsMouse
                        ? root.themeData.lavender : root.themeData.mauve

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: root.themeData.crust
                        font.family: root.themeData.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: connectPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.connectSelected()
                    }
                }
            }
        }

        Text {
            id: listTitle
            anchors {
                left: parent.left
                right: parent.right
                top: passwordArea.bottom
                leftMargin: 16
                rightMargin: 16
                topMargin: 9
            }
            height: 22
            text: root.statusMessage.length > 0
                ? root.statusMessage
                : (root.wifiDevice ? "Wi-Fi networks" : "No Wi-Fi adapter")
            color: root.statusMessage.length > 0
                ? root.themeData.yellow : root.themeData.subtext
            elide: Text.ElideRight
            font.family: root.themeData.fontFamily
            font.pixelSize: 9
        }

        ListView {
            id: networkList
            anchors {
                left: parent.left
                right: parent.right
                top: listTitle.bottom
                bottom: advancedButton.top
                leftMargin: 10
                rightMargin: 10
                bottomMargin: 7
            }
            model: wifiModel
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: networkList.width
                height: 43
                radius: 9
                color: networkPointer.containsMouse
                    ? root.themeData.surface1
                    : (modelData.connected ? root.themeData.surface0 : "transparent")

                Text {
                    anchors {
                        left: parent.left
                        right: strengthLabel.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 11
                        rightMargin: 8
                    }
                    text: (modelData.security === WifiSecurityType.Open ? "" : "  ")
                        + modelData.name
                    color: modelData.connected ? root.themeData.green : root.themeData.text
                    elide: Text.ElideRight
                    font.family: root.themeData.fontFamily
                    font.pixelSize: 11
                }

                Text {
                    id: strengthLabel
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 11
                    }
                    text: modelData.stateChanging
                        ? "…" : Math.round(modelData.signalStrength * 100) + "%"
                    color: modelData.connected ? root.themeData.green : root.themeData.overlay
                    font.family: root.themeData.monoFamily
                    font.pixelSize: 9
                }

                MouseArea {
                    id: networkPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activateNetwork(parent.modelData)
                }

                Connections {
                    target: modelData
                    function onConnectionFailed(reason) {
                        root.statusMessage = reason === ConnectionFailReason.NoSecrets
                            ? "The password is missing or incorrect"
                            : "Connection failed"
                    }
                }
            }
        }

        Rectangle {
            id: advancedButton
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 14
                rightMargin: 14
                bottomMargin: 12
            }
            height: 31
            radius: 9
            color: advancedPointer.containsMouse
                ? root.themeData.surface1 : root.themeData.surface0

            Text {
                anchors.centerIn: parent
                text: "Advanced NetworkManager settings"
                color: root.themeData.subtext
                font.family: root.themeData.fontFamily
                font.pixelSize: 9
            }

            MouseArea {
                id: advancedPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }
}
