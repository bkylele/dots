import QtQuick
import qs.services

// Read-only list of tailnet peers. No click handlers by design.
Item {
    id: root

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Tailscale.peers
        visible: Tailscale.peers.length > 0

        delegate: Item {
            required property var modelData
            width: list.width
            height: 52

            // Online indicator
            Rectangle {
                id: dot
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: modelData.online ? "#4CAF50" : "#CCCCCC"
            }

            Column {
                anchors.left: dot.right
                anchors.leftMargin: 14
                anchors.right: exitBadge.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: modelData.host
                    font.pixelSize: 14
                    color: modelData.online ? "#333333" : "#999999"
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    // Online peers carry a zero-value LastSeen, so the service
                    // leaves lastSeen empty for them.
                    text: modelData.online ? modelData.route : modelData.lastSeen
                    font.pixelSize: 12
                    color: "#888888"
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }

            Rectangle {
                id: exitBadge
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                visible: modelData.isExitNode || modelData.offersExit
                width: badgeText.width + 16
                height: 20
                radius: 10
                color: modelData.isExitNode ? "#4A90E2" : "transparent"
                border.width: modelData.isExitNode ? 0 : 1
                border.color: "#DDDDDD"

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: modelData.isExitNode ? "exit node" : "exit"
                    font.pixelSize: 10
                    font.bold: modelData.isExitNode
                    color: modelData.isExitNode ? "#FFFFFF" : "#999999"
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 48
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: Tailscale.peers.length === 0
        text: Tailscale.needsLogin ? "Not logged in to Tailscale"
            : !Tailscale.running ? "Tailscale is off — left-click the button to connect"
            : "No peers on this tailnet"
        font.pixelSize: 13
        color: "#999999"
    }
}
