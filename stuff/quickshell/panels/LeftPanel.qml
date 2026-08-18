import QtQuick
import Quickshell
import Quickshell.Wayland

// Stub: Left edge panel
// TODO: Implement left panel content and hover trigger
PanelWindow {
    required property var modelData
    screen: modelData

    id: root
    color: "transparent"
    exclusiveZone: 0
    visible: false

    anchors.left: true
    anchors.top: true
    anchors.bottom: true

    implicitWidth: 10
    implicitHeight: screen.height
}
