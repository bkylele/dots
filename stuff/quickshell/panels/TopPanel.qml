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
            },
            State {
                name: "preview"
                PropertyChanges { target: dash; y: 10; width: previewText.contentWidth + 32; height: 40; radius: 20; color: "#FFFFFF" }
                PropertyChanges { target: backgroundDim; opacity: 0 }
                PropertyChanges { target: expandedContent; opacity: 0; scale: 0.8 }
                PropertyChanges { target: previewText; opacity: 1 }
            },
            State {
                name: "expanded"
                PropertyChanges { target: dash; y: (root.height - 650) / 2; width: 650; height: 650; radius: 325; color: "#F8F8F8" }
                PropertyChanges { target: backgroundDim; opacity: 0.4 }
                PropertyChanges { target: expandedContent; opacity: 1; scale: 1.0 }
                PropertyChanges { target: previewText; opacity: 0 }
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
                    NumberAnimation { target: expandedContent; property: "opacity"; duration: 250 }
                }
            },
            // Hide/Collapse from Expanded
            Transition {
                from: "expanded"; to: "*"
                SequentialAnimation {
                    // 1. Hide expanded content first
                    NumberAnimation { target: expandedContent; property: "opacity"; to: 0; duration: 150 }
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

        // Integrated Navigation: Left
        Rectangle {
            id: leftNavInternal
            width: 36; height: 36; radius: 18
            anchors.left: parent.left
            anchors.leftMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            visible: sg.state === "expanded"
            color: leftNavMouse.containsMouse ? "#20000000" : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "\u2039"
                font.pixelSize: 22
                color: leftNavMouse.containsMouse ? "#88000000" : "#44000000"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: leftNavMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: function(mouse) { expandedContent.prevTab() }
            }
        }

        // Integrated Navigation: Right
        Rectangle {
            id: rightNavInternal
            width: 36; height: 36; radius: 18
            anchors.right: parent.right
            anchors.rightMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            visible: sg.state === "expanded"
            color: rightNavMouse.containsMouse ? "#20000000" : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "\u203a"
                font.pixelSize: 22
                color: rightNavMouse.containsMouse ? "#88000000" : "#44000000"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: rightNavMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: function(mouse) { expandedContent.nextTab() }
            }
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
