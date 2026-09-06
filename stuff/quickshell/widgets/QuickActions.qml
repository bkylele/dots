import QtQuick

Item {
    id: root

    // --- Configuration ---
    property int buttonSize: 42            // Diameter of each circular button
    property int buttonSpacing: 10         // Gap between buttons
    property int hPadding: 12              // Card padding, left/right
    property int vPadding: 10              // Card padding, top/bottom

    // Self-sizing: the parent should NOT also set Layout.preferredWidth/Height.
    implicitWidth: hPadding * 2 + actions.length * buttonSize
                   + Math.max(0, actions.length - 1) * buttonSpacing
    implicitHeight: vPadding * 2 + buttonSize

    // --- Action Model (static) ---
    // Each action: { icon: "string", label: "string" }
    // The icon string is rendered using the Nerd Font specified by iconFont.
    // This list must stay CONSTANT: it backs the Repeater, so rebuilding it
    // destroys and recreates every delegate (killing hover state and the color
    // animation). Live state goes in the parallel arrays below instead.
    property var actions: []

    // --- Action State (dynamic, parallel to `actions` by index) ---
    property var activeStates: []          // bool: the thing is on
    property var enabledStates: []         // bool: the button can be used at all
    property var busyStates: []            // bool: a toggle is in flight

    // Nerd Font family for rendering icons
    property string iconFont: "JetBrainsMono Nerd Font"

    // Left-click: toggle the underlying service.
    signal actionToggled(int index)
    // Right-click: expand this action into its detail panel.
    signal actionExpanded(int index)

    function isActive(i) { return activeStates[i] === true }
    function isEnabled(i) { return enabledStates[i] !== false }   // default: enabled
    function isBusy(i) { return busyStates[i] === true }

    Rectangle {
        anchors.fill: parent
        color: "#F0F0F0"
        radius: 18

        Row {
            anchors.centerIn: parent
            spacing: root.buttonSpacing

            Repeater {
                model: root.actions

                Rectangle {
                    id: button
                    required property int index
                    required property var modelData

                    readonly property bool isActive: root.isActive(index)
                    readonly property bool isEnabled: root.isEnabled(index)
                    readonly property bool isBusy: root.isBusy(index)

                    width: root.buttonSize
                    height: root.buttonSize
                    radius: root.buttonSize / 2

                    color: !isEnabled ? "#D8D8D8"
                         : isBusy ? "#888888"
                         : isActive ? "#444444" : "#BBBBBB"
                    Behavior on color { ColorAnimation { duration: 200 } }

                    scale: buttonMouse.containsMouse && isEnabled ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    Text {
                        anchors.centerIn: parent
                        text: button.modelData.icon
                        font.pixelSize: 18
                        font.family: root.iconFont
                        font.bold: true
                        color: button.isEnabled && (button.isActive || button.isBusy) ? "#FFFFFF" : "#777777"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Hover wash — polarity flips with the fill so it reads on both
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: buttonMouse.containsMouse && button.isEnabled
                               ? (button.isActive ? "#20FFFFFF" : "#20000000")
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: buttonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: button.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                root.actionExpanded(button.index)
                            } else if (button.isEnabled) {
                                root.actionToggled(button.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
