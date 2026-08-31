import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.dashboard

PanelWindow {
    required property var modelData
    screen: modelData

    id: root
    color: "transparent"
    exclusiveZone: 0
    
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    
    implicitWidth: screen.width
    implicitHeight: screen.height

    focusable: sg.state === "expanded"

    Shortcut {
        enabled: sg.state === "expanded"
        sequence: "Escape"
        onActivated: function() { sg.state = "hidden" }
    }

    mask: Region {
        item: sg.state === "expanded" ? backgroundDim : dash
        Region { item: sg.state === "expanded" ? backgroundDim : hoverZone }
    }

    // Track if either the trigger zone or the pill itself is being hovered (only for preview mode)
    property bool isHovered: (hoverZone.containsMouse || (dashPreviewMouseArea.enabled && dashPreviewMouseArea.containsMouse)) && sg.state !== "expanded"

    onIsHoveredChanged: {
        if (!isHovered && sg.state === "preview") {
            sg.state = "hidden"
        }
    }

    StateGroup {
        id: sg
        state: "hidden"
        states: [
            State {
                name: "hidden"
                PropertyChanges { target: dash; y: -100; width: previewText.contentWidth + 32; height: 40; radius: 20; color: "#FFFFFF" }
                PropertyChanges { target: backgroundDim; opacity: 0 }
                PropertyChanges { target: expandedContent; opacity: 0; scale: 0.8 }
                PropertyChanges { target: previewText; opacity: 0 }
                PropertyChanges { target: navNW; opacity: 0 }
                PropertyChanges { target: navNE; opacity: 0 }
            },
            State {
                name: "preview"
                PropertyChanges { target: dash; y: 10; width: previewText.contentWidth + 32; height: 40; radius: 20; color: "#FFFFFF" }
                PropertyChanges { target: backgroundDim; opacity: 0 }
                PropertyChanges { target: expandedContent; opacity: 0; scale: 0.8 }
                PropertyChanges { target: previewText; opacity: 1 }
                PropertyChanges { target: navNW; opacity: 0 }
                PropertyChanges { target: navNE; opacity: 0 }
            },
            State {
                name: "expanded"
                PropertyChanges { target: dash; y: (root.height - 650) / 2; width: 650; height: 650; radius: 325; color: "#F8F8F8" }
                PropertyChanges { target: backgroundDim; opacity: 0.4 }
                PropertyChanges { target: expandedContent; opacity: 1; scale: 1.0 }
                PropertyChanges { target: previewText; opacity: 0 }
                PropertyChanges { target: navNW; opacity: 1 }
                PropertyChanges { target: navNE; opacity: 1 }
            }
        ]

        transitions: [
            // Expand Transition
            Transition {
                from: "*"; to: "expanded"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: dash; properties: "y,width,height,radius"; duration: 400; easing.type: Easing.OutBack }
                        NumberAnimation { target: backgroundDim; property: "opacity"; duration: 400 }
                        ColorAnimation { target: dash; duration: 400 }
                        NumberAnimation { target: previewText; property: "opacity"; to: 0; duration: 40 }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: expandedContent; property: "opacity"; duration: 250 }
                        NumberAnimation { target: navNW; property: "opacity"; duration: 250 }
                        NumberAnimation { target: navNE; property: "opacity"; duration: 250 }
                    }
                }
            },
            // Hide/Collapse from Expanded
            Transition {
                from: "expanded"; to: "*"
                SequentialAnimation {
                    // 1. Hide expanded content and nav icons first
                    ParallelAnimation {
                        NumberAnimation { target: expandedContent; property: "opacity"; to: 0; duration: 150 }
                        NumberAnimation { target: navNW; property: "opacity"; to: 0; duration: 150 }
                        NumberAnimation { target: navNE; property: "opacity"; to: 0; duration: 150 }
                    }
                    // 2. Move and resize panel
                    ParallelAnimation {
                        NumberAnimation { target: dash; properties: "y,width,height,radius"; duration: 300; easing.type: Easing.OutCubic }
                        NumberAnimation { target: backgroundDim; property: "opacity"; to: 0; duration: 300 }
                        ColorAnimation { target: dash; duration: 300 }
                    }
                    // 3. Show preview text if entering preview state
                    NumberAnimation { target: previewText; property: "opacity"; duration: 100 }
                    // 4. Reset tabs AFTER visual transition is complete
                    ScriptAction { 
                        script: if (expandedContent && typeof expandedContent.reset === "function") expandedContent.reset()
                    }
                }
            },
            // Preview Entry
            Transition {
                from: "hidden"; to: "preview"
                SequentialAnimation {
                    NumberAnimation { target: dash; property: "y"; duration: 250; easing.type: Easing.OutCubic }
                    NumberAnimation { target: previewText; property: "opacity"; to: 1; duration: 100 }
                }
            },
            // Preview Exit
            Transition {
                from: "preview"; to: "hidden"
                SequentialAnimation {
                    NumberAnimation { target: previewText; property: "opacity"; to: 0; duration: 40 }
                    NumberAnimation { target: dash; property: "y"; duration: 250; easing.type: Easing.OutCubic }
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

    Rectangle {
        id: dash
        color: "#FFFFFF"
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true // Ensure integrated buttons don't bleed out
        
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Clicks inside the circle (outside interactive content) are swallowed
        MouseArea {
            anchors.fill: parent
            enabled: sg.state === "expanded"
            onClicked: function(mouse) { mouse.accepted = true }
        }

        // Content for expanded mode
        DashboardMenu {
            id: expandedContent
            anchors.fill: parent
            opacity: 0
            scale: 0.8
            visible: opacity > 0
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
        }


        // Content for preview mode
        Text {
            id: previewText
            visible: opacity > 0
            opacity: 0
            anchors.centerIn: parent

            property var now: new Date()
            property string battery: "--%"
            property bool isCharging: false

            state: "clock"
            states: [
                State {
                    name: "clock"
                    PropertyChanges { target: previewText; text: Qt.formatTime(now, "hh:mm ap") }
                },
                State {
                    name: "battery"
                    PropertyChanges { target: previewText; text: (previewText.isCharging ? "\u26a1 " : "") + battery }
                }
            ]

            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: {
                    previewText.now = new Date()
                    if (previewText.state == "battery") {
                        batteryProc.running = true
                        chargingProc.running = true
                    }
                }
            }

            Process {
                id: batteryProc
                command: ["cat", "/sys/class/power_supply/BAT1/capacity"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const val = this.text.trim();
                        if (val.length > 0) previewText.battery = val + "%";
                    }
                }
            }

            Process {
                id: chargingProc
                command: ["cat", "/sys/class/power_supply/BAT1/status"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const status = this.text.trim();
                        previewText.isCharging = (status === "Charging" || status === "Full");
                    }
                }
            }
        }

        // MouseArea for preview mode interactions
        MouseArea {
            id: dashPreviewMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            enabled: sg.state !== "expanded"
            
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    sg.state = "expanded"
                } else {
                    previewText.state = (previewText.state == "clock") ? "battery" : "clock"
                    if (previewText.state == "battery") {
                        batteryProc.running = true
                        chargingProc.running = true
                    }
                }
            }
        }
    }

    // --- External Navigation Icons (NW and NE, outside the circle) ---
    // Geometry: circle center is (dash.x + dash.width/2, dash.y + dash.height/2)
    // Place icons at 45° outside the circle edge with a small gap.
    property real _circCX: dash.x + dash.width / 2
    property real _circCY: dash.y + dash.height / 2
    property real _circR: dash.width / 2
    // cos(45°) = sin(45°) ≈ 0.7071
    property real _navOffset: (_circR + 28) * 0.7071

    // NW icon (previous tab)
    Rectangle {
        id: navNW
        width: 40; height: 40; radius: 20
        x: _circCX - _navOffset - width / 2
        y: _circCY - _navOffset - height / 2
        opacity: 0
        visible: opacity > 0
        color: navNWMouse.containsMouse ? "#20000000" : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: expandedContent.prevTabIcon
            font.pixelSize: 18
            opacity: navNWMouse.containsMouse ? 0.7 : 0.4
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            id: navNWMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: function(mouse) { expandedContent.prevTab() }
        }
    }

    // NE icon (next tab)
    Rectangle {
        id: navNE
        width: 40; height: 40; radius: 20
        x: _circCX + _navOffset - width / 2
        y: _circCY - _navOffset - height / 2
        opacity: 0
        visible: opacity > 0
        color: navNEMouse.containsMouse ? "#20000000" : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: expandedContent.nextTabIcon
            font.pixelSize: 18
            opacity: navNEMouse.containsMouse ? 0.7 : 0.4
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            id: navNEMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: function(mouse) { expandedContent.nextTab() }
        }
    }

    // Top hover trigger
    MouseArea {
        id: hoverZone
        anchors.top: parent.top
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
