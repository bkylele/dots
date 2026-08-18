import QtQuick
import Quickshell
import Quickshell.Wayland

// Stub: Bottom edge panel
// TODO: Implement bottom panel content and hover trigger
PanelWindow {
    required property var modelData
    screen: modelData

    id: root
    color: "transparent"
    exclusiveZone: 0
    visible: false

    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    implicitWidth: screen.width
    implicitHeight: 10
}
