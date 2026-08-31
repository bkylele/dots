import QtQuick

Item {
    id: root
    width: 170
    height: 110

    // --- Action Model ---
    // Each action: { icon: "string", label: "string", active: bool }
    // The icon string is rendered using the Nerd Font specified by iconFont.
    // To add a new quick action, append an object to this list.
    property var actions: []

    // Nerd Font family for rendering icons
    property string iconFont: "JetBrainsMono Nerd Font"

    // Emitted when an action button is clicked, with the index of the action.
    // The parent component is responsible for toggling state / executing logic.
    signal actionToggled(int index)

    Rectangle {
        anchors.fill: parent
        color: "#F0F0F0"
        radius: 18

        Grid {
            anchors.centerIn: parent
            columns: 3
            spacing: 10

            Repeater {
                model: root.actions

                Rectangle {
                    width: 42; height: 42; radius: 21
                    color: modelData.active ? "#444444" : "#BBBBBB"
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.pixelSize: 18
                        font.family: root.iconFont
                        font.bold: true
                        color: modelData.active ? "#FFFFFF" : "#777777"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: function(mouse) {
                            root.actionToggled(index)
                        }
                    }
                }
            }
        }
    }
}
