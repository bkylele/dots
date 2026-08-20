import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    required property var modelData
    screen: modelData

    id: root
    color: "transparent"
    exclusiveZone: 0

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    anchors.top: true

    implicitWidth: screen.width
    implicitHeight: screen.height

    focusable: sg.state === "expanded"

    Shortcut {
        enabled: sg.state === "expanded"
        sequence: "Escape"
        onActivated: function() { sg.state = "hidden" }
    }

    mask: Region {
        item: sg.state === "expanded" ? backgroundDim : powerButton
        Region { item: sg.state === "expanded" ? backgroundDim : hoverZone }
    }

    // Track hover for preview mode
    property bool isHovered: (hoverZone.containsMouse || (previewMouseArea.enabled && previewMouseArea.containsMouse)) && sg.state !== "expanded"

    onIsHoveredChanged: {
        if (!isHovered && sg.state === "preview") {
            sg.state = "hidden"
        }
    }

    // --- Power Menu Dimensions ---
    property int menuWidth: 380
    property int menuHeight: 140

    StateGroup {
        id: sg
        state: "hidden"
        states: [
            State {
                name: "hidden"
                PropertyChanges { target: powerButton; y: root.height + 100; width: 48; height: 48; radius: 24; color: "#FFFFFF" }
                PropertyChanges { target: backgroundDim; opacity: 0 }
                PropertyChanges { target: expandedContent; opacity: 0; scale: 0.85 }
                PropertyChanges { target: previewIcon; opacity: 0 }
            },
            State {
                name: "preview"
                PropertyChanges { target: powerButton; y: root.height - 58; width: 48; height: 48; radius: 24; color: "#FFFFFF" }
                PropertyChanges { target: backgroundDim; opacity: 0 }
                PropertyChanges { target: expandedContent; opacity: 0; scale: 0.85 }
                PropertyChanges { target: previewIcon; opacity: 1 }
            },
            State {
                name: "expanded"
                PropertyChanges { target: powerButton; y: (root.height - root.menuHeight) / 2; width: root.menuWidth; height: root.menuHeight; radius: 24; color: "#F8F8F8" }
                PropertyChanges { target: backgroundDim; opacity: 0.4 }
                PropertyChanges { target: expandedContent; opacity: 1; scale: 1.0 }
                PropertyChanges { target: previewIcon; opacity: 0 }
            }
        ]

        transitions: [
            // Expand Transition
            Transition {
                from: "*"; to: "expanded"
                SequentialAnimation {
                    NumberAnimation { target: previewIcon; property: "opacity"; to: 0; duration: 40 }
                    ParallelAnimation {
                        NumberAnimation { target: powerButton; properties: "y,width,height,radius"; duration: 400; easing.type: Easing.OutBack }
                        NumberAnimation { target: backgroundDim; property: "opacity"; duration: 400 }
                        ColorAnimation { target: powerButton; duration: 400 }
                    }
                    NumberAnimation { target: expandedContent; properties: "opacity"; duration: 250 }
                }
            },
            // Collapse from Expanded
            Transition {
                from: "expanded"; to: "*"
                SequentialAnimation {
                    NumberAnimation { target: expandedContent; property: "opacity"; to: 0; duration: 150 }
                    ParallelAnimation {
                        NumberAnimation { target: powerButton; properties: "y,width,height,radius"; duration: 300; easing.type: Easing.OutCubic }
                        NumberAnimation { target: backgroundDim; property: "opacity"; to: 0; duration: 300 }
                        ColorAnimation { target: powerButton; duration: 300 }
                    }
                    NumberAnimation { target: previewIcon; property: "opacity"; duration: 100 }
                }
            },
            // Preview Entry
            Transition {
                from: "hidden"; to: "preview"
                SequentialAnimation {
                    NumberAnimation { target: powerButton; property: "y"; duration: 250; easing.type: Easing.OutCubic }
                    NumberAnimation { target: previewIcon; property: "opacity"; to: 1; duration: 100 }
                }
            },
            // Preview Exit
            Transition {
                from: "preview"; to: "hidden"
                SequentialAnimation {
                    NumberAnimation { target: previewIcon; property: "opacity"; to: 0; duration: 40 }
                    NumberAnimation { target: powerButton; property: "y"; duration: 250; easing.type: Easing.OutCubic }
                }
            }
        ]
    }

    // Dim the background when expanded
    Rectangle {
        id: backgroundDim
        anchors.fill: parent
        color: "black"
        opacity: 0
        visible: opacity > 0

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { sg.state = "hidden" }
        }
    }

    // The power button / menu container
    Rectangle {
        id: powerButton
        color: "#FFFFFF"
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        // Swallow clicks inside the menu when expanded
        MouseArea {
            anchors.fill: parent
            enabled: sg.state === "expanded"
            onClicked: function(mouse) { mouse.accepted = true }
        }

        // --- Expanded Content: Power Action Buttons ---
        Item {
            id: expandedContent
            anchors.fill: parent
            opacity: 0
            scale: 0.85
            visible: opacity > 0

            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

            Row {
                anchors.centerIn: parent
                spacing: 28

                // Sleep Button
                Rectangle {
                    id: sleepButton
                    width: 90; height: 90
                    radius: 16
                    color: sleepMouse.containsMouse ? "#18000000" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\u{1F319}" // 🌙
                        font.pixelSize: 36
                    }

                    MouseArea {
                        id: sleepMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) { sleepProc.running = true }
                    }

                    Process {
                        id: sleepProc
                        command: ["systemctl", "suspend"]
                    }
                }

                // Shutdown Button
                Rectangle {
                    id: shutdownButton
                    width: 90; height: 90
                    radius: 16
                    color: shutdownMouse.containsMouse ? "#18000000" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\u23FB" // ⏻ Power symbol
                        font.pixelSize: 36
                        color: "#000000"
                    }

                    MouseArea {
                        id: shutdownMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) { shutdownProc.running = true }
                    }

                    Process {
                        id: shutdownProc
                        command: ["systemctl", "poweroff"]
                    }
                }

                // Restart Button
                Rectangle {
                    id: restartButton
                    width: 90; height: 90
                    radius: 16
                    color: restartMouse.containsMouse ? "#18000000" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\u27F3" // ⟳ Restart/reload arrow
                        font.pixelSize: 36
                    }

                    MouseArea {
                        id: restartMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) { restartProc.running = true }
                    }

                    Process {
                        id: restartProc
                        command: ["systemctl", "reboot"]
                    }
                }
            }
        }

        // Preview icon (power symbol shown in pill)
        Text {
            id: previewIcon
            visible: opacity > 0
            opacity: 0
            anchors.centerIn: parent
            text: "\u23FB" // ⏻
            font.pixelSize: 20
            color: "#333333"
        }

        // MouseArea for preview mode — click to expand
        MouseArea {
            id: previewMouseArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: sg.state !== "expanded"

            onClicked: function(mouse) {
                sg.state = "expanded"
            }
        }
    }

    // Bottom hover trigger zone
    MouseArea {
        id: hoverZone
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 300
        height: 10
        enabled: sg.state !== "expanded"

        hoverEnabled: true
        onEntered: {
            if (sg.state === "hidden") {
                sg.state = "preview"
            }
        }
    }
}
