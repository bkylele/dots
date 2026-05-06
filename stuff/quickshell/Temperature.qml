import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    
    Layout.fillWidth: false
    Layout.preferredWidth: 20
    Layout.fillHeight: true

    property real temperature: 0

    Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["cat", "/sys/class/thermal/thermal_zone0/temp"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseFloat(this.text);
                if (!isNaN(val)) {
                    root.temperature = val / 1000;
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 4
                height: parent.height
                color: "#E0E0E0"
                radius: 2
            }

            Rectangle {
                id: bar
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: 4
                height: Math.max(Math.min((root.temperature - 30) * (parent.height / 70), parent.height), 4)
                color: {
                    if (root.temperature >= 80) return "#FF4B4B"
                    if (root.temperature >= 60) return "#F5A623"
                    return "#4A90E2"
                }
                radius: 2
                
                Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 500 } }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "T"
            font.bold: true
            font.pixelSize: 10
            color: "#666666"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(root.temperature) + "°"
            font.pixelSize: 8
            color: "#888888"
        }
    }
}
