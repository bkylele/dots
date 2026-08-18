import QtQuick
import Quickshell
import Quickshell.Wayland

// Stub: Right edge panel
// TODO: Implement right panel content and hover trigger
PanelWindow {
    required property var modelData
    screen: modelData

    id: root
    color: "transparent"
    exclusiveZone: 0
    visible: false

    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    implicitWidth: 10
    implicitHeight: screen.height
}
