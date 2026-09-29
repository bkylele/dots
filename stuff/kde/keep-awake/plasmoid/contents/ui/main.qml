import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property bool awake: false
    readonly property string command: "/home/brian/.local/bin/keep-awake"
    readonly property string statusCommand: command + " status"

    Plasmoid.icon: awake ? "preferences-system-power-management" : "system-suspend"
    Plasmoid.toolTipMainText: awake ? "Keep Awake is on" : "Keep Awake is off"
    Plasmoid.toolTipSubText: awake
        ? "Idle-triggered suspend is blocked"
        : "Click to keep this computer awake"

    function run(command) {
        executable.connectSource(command)
    }

    function refresh() {
        executable.disconnectSource(statusCommand)
        executable.connectSource(statusCommand)
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"

        onNewData: function(sourceName, data) {
            const result = String(data["stdout"]).trim()
            if (result === "active" || result === "inactive") {
                root.awake = result === "active"
            }
            disconnectSource(sourceName)
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    compactRepresentation: MouseArea {
        id: compactMouse
        implicitWidth: PlasmaCore.Units.iconSizes.smallMedium
        implicitHeight: implicitWidth
        hoverEnabled: true
        onClicked: root.run(root.command + " toggle")

        PlasmaCore.IconItem {
            anchors.fill: parent
            active: compactMouse.containsMouse
            source: root.Plasmoid.icon
        }
    }

    fullRepresentation: PlasmaComponents.Button {
        text: root.awake ? "Keep Awake: On" : "Keep Awake: Off"
        icon.name: root.Plasmoid.icon
        onClicked: root.run(root.command + " toggle")
    }
}
