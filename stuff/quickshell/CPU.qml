import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    
    Layout.fillWidth: false
    Layout.preferredWidth: 20 // Fixed width for the whole component column
    Layout.fillHeight: true

    property real cpuUsage: 0

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["sh", "-c", "top -bn1 | grep Cpu | awk '{print 100 - $8}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cpuUsage = parseFloat(this.text)
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
                width: 4 // Explicit bar thickness
                height: parent.height
                color: "#E0E0E0"
                radius: 2
            }

            Rectangle {
                id: bar
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: 4 // Explicit bar thickness
                height: Math.max(parent.height * root.cpuUsage / 100, 4)
                color: "#4A90E2"
                radius: 2
                
                Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "C"
            font.bold: true
            font.pixelSize: 10
            color: "#666666"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(root.cpuUsage) + "%"
            font.pixelSize: 8
            color: "#888888"
        }
    }
}
