import QtQuick
import Quickshell
import Quickshell.Networking
import qs.services

// Nearby networks. Click to connect; a password field opens inline only if
// NetworkManager reports it actually needs one.
Item {
    id: root

    readonly property var state: QuickActionsState

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: Networking.wifiEnabled && QuickActionsState.orderedNetworks.length > 0

        model: ScriptModel { values: QuickActionsState.orderedNetworks }

        delegate: Rectangle {
            id: row
            required property var modelData
            width: list.width

            readonly property bool isActive: QuickActionsState.activeNetwork === modelData
            readonly property bool needsPsk: isActive && QuickActionsState.wifiPhase === "needsPsk"
            readonly property bool connecting: isActive && QuickActionsState.wifiPhase === "connecting"
            readonly property bool hasError: isActive && QuickActionsState.wifiError !== ""

            height: 52 + (needsPsk ? 44 : 0)
            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            color: rowMouse.pressed ? "#12000000" : (rowMouse.containsMouse ? "#08000000" : "transparent")
            Behavior on color { ColorAnimation { duration: 100 } }
            clip: true

            // --- Main row ---
            Item {
                id: mainRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 52

                // Signal strength, drawn as bars so no icon font is involved.
                Row {
                    id: bars
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            width: 3
                            height: 4 + index * 3
                            radius: 1
                            anchors.bottom: parent.bottom
                            color: index < QuickActionsState.signalBucket(row.modelData.signalStrength)
                                   ? "#666666" : "#DDDDDD"
                        }
                    }
                }

                Column {
                    anchors.left: bars.right
                    anchors.leftMargin: 14
                    anchors.right: statusDot.left
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
                        text: row.hasError ? QuickActionsState.wifiError
                            : row.connecting ? "Connecting…"
                            : row.modelData.connected ? "Connected"
                            : row.modelData.known ? "Saved"
                            : QuickActionsState.isSecured(row.modelData.security) ? "Secured" : "Open"
                        font.pixelSize: 12
                        color: row.hasError ? "#FF4B4B" : (row.connecting ? "#4A90E2" : "#888888")
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    id: statusDot
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8; height: 8; radius: 4
                    color: "#4CAF50"
                    visible: row.modelData.connected
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        QuickActionsState.activateNetwork(row.modelData)
                    }
                }
            }

            // --- Inline password field ---
            // Only ever shown after NetworkManager answers NoSecrets, so we never
            // prompt for a network whose passphrase it already has.
            Rectangle {
                anchors.top: mainRow.bottom
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.right: parent.right
                anchors.rightMargin: 20
                height: 34
                radius: 17
                color: "#FFFFFF"
                visible: row.needsPsk

                TextInput {
                    id: pskField
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: submitButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 13
                    color: "#1a1a1a"
                    clip: true
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                    // The singleton owns the text so it survives delegate recycling;
                    // textEdited (not textChanged) keeps this from looping.
                    text: QuickActionsState.pskText
                    onTextEdited: QuickActionsState.pskText = text

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Password"
                        font.pixelSize: 13
                        color: "#BBBBBB"
                        visible: pskField.text === ""
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            QuickActionsState.submitPsk()
                            event.accepted = true
                        }
                    }
                }

                Rectangle {
                    id: submitButton
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26; height: 26; radius: 13
                    color: submitMouse.containsMouse ? "#20000000" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#666666"
                    }

                    MouseArea {
                        id: submitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) { QuickActionsState.submitPsk() }
                    }
                }

                // Focus needs a beat after the row expands, the same trick the app
                // runner needs (AppRunner.qml focusTimer).
                onVisibleChanged: if (visible) focusTimer.restart()

                Timer {
                    id: focusTimer
                    interval: 50
                    repeat: false
                    onTriggered: pskField.forceActiveFocus()
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
        text: !Networking.wifiHardwareEnabled ? "Wi-Fi is blocked by hardware"
            : !Networking.wifiEnabled ? "Wi-Fi is off — left-click the button to turn it on"
            : QuickActionsState.wifiDevice === null ? "No Wi-Fi device"
            : "Scanning…"
        font.pixelSize: 13
        color: "#999999"
    }
}
