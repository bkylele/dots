import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    
    Layout.fillWidth: false
    Layout.preferredWidth: 20
    Layout.fillHeight: true

    property real memUsage: 0

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["sh", "-c", "free | grep Mem | awk '{print $3/$2 * 100}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.memUsage = parseFloat(this.text)
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
                height: Math.max(parent.height * root.memUsage / 100, 4)
                color: "#50E3C2"
                radius: 2
                
                Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "M"
            font.bold: true
            font.pixelSize: 10
            color: "#666666"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(root.memUsage) + "%"
            font.pixelSize: 8
            color: "#888888"
        }
    }
}
