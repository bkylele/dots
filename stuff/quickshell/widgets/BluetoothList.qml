import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets

// Paired bluetooth devices. Click a row to connect or disconnect.
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    // Devices are QObjects with stable identity, so ScriptModel can reuse
    // delegates instead of rebuilding the list on every property change.
    readonly property var pairedDevices: {
        var all = Bluetooth.devices.values
        var list = []
        for (var i = 0; i < all.length; i++) {
            if (all[i].paired || all[i].bonded) list.push(all[i])
        }
        return list
    }

    function stateLabel(device) {
        // Verified enum order on this build: Disconnected=0, Connected=1,
        // Disconnecting=2, Connecting=3 — never compare these numerically.
        switch (device.state) {
        case BluetoothDeviceState.Connecting: return "Connecting…"
        case BluetoothDeviceState.Disconnecting: return "Disconnecting…"
        case BluetoothDeviceState.Connected: return "Connected"
        default: return device.address
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: root.pairedDevices.length > 0 && root.adapter !== null && root.adapter.enabled

        model: ScriptModel {
            values: {
                var list = [...root.pairedDevices]
                list.sort(function(a, b) {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1
                    return (a.name || "").localeCompare(b.name || "")
                })
                return list
            }
        }

        delegate: Rectangle {
            id: row
            required property var modelData
            width: list.width
            height: 52
            color: rowMouse.pressed ? "#12000000" : (rowMouse.containsMouse ? "#08000000" : "transparent")
            Behavior on color { ColorAnimation { duration: 100 } }

            readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting
                                      || modelData.state === BluetoothDeviceState.Disconnecting

            IconImage {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 22
                // Not every device reports one (the Surface Pen doesn't).
                source: row.modelData.icon !== "" ? Quickshell.iconPath(row.modelData.icon, true) : ""
                visible: source !== ""
            }

            Rectangle {
                // Fallback marker for devices with no icon
                anchors.centerIn: icon
                width: 8; height: 8; radius: 4
                color: "#BBBBBB"
                visible: !icon.visible
            }

            Column {
                anchors.left: icon.right
                anchors.leftMargin: 14
                anchors.right: rightInfo.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: row.modelData.name
                    font.pixelSize: 14
                    font.bold: row.modelData.connected
                    color: "#333333"
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.stateLabel(row.modelData)
                    font.pixelSize: 12
                    color: row.busy ? "#4A90E2" : "#888888"
                    elide: Text.ElideRight
                }
            }

            Row {
                id: rightInfo
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    // No RSSI exists in this Quickshell version, so battery is the
                    // only per-device signal worth showing.
                    text: row.modelData.batteryAvailable
                          ? Math.round(row.modelData.battery * 100) + "%" : ""
                    font.pixelSize: 12
                    color: "#999999"
                    visible: text !== ""
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8; height: 8; radius: 4
                    color: "#4CAF50"
                    visible: row.modelData.connected
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    if (row.busy) return
                    if (row.modelData.connected) row.modelData.disconnect()
                    else row.modelData.connect()
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 48
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: !list.visible
        text: root.adapter === null ? "No Bluetooth adapter"
            : !root.adapter.enabled ? "Bluetooth is off — left-click the button to turn it on"
            : "No paired devices"
        font.pixelSize: 13
        color: "#999999"
    }
}
