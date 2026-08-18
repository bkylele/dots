import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.widgets

Item {
    id: root
    anchors.fill: parent

    ColumnLayout {
        anchors.centerIn: parent
        width: 300
        spacing: 40

        Text {
            text: "SYSTEM RESOURCES"
            font.bold: true; font.pixelSize: 18; color: "#444444"
            Layout.alignment: Qt.AlignHCenter; font.letterSpacing: 2
        }

        Rectangle {
            Layout.preferredWidth: 250; Layout.preferredHeight: 250
            Layout.alignment: Qt.AlignHCenter
            color: "#F0F0F0"; radius: 25
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 30; spacing: 40
                CpuMonitor { Layout.fillHeight: true; Layout.preferredWidth: 30 }
                MemoryMonitor { Layout.fillHeight: true; Layout.preferredWidth: 30 }
                TemperatureMonitor { Layout.fillHeight: true; Layout.preferredWidth: 30 }
            }
        }

        Text {
            text: "Uptime: " + uptimeProc.uptimeText
            font.pixelSize: 14; color: "#666666"
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -24
        }

        Item {
            Process {
                id: uptimeProc
                property string uptimeText: "..."
                command: ["sh", "-c", "cat /proc/uptime | awk '{print $1}'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const seconds = parseInt(this.text);
                        if (!isNaN(seconds)) {
                            const hours = Math.floor(seconds / 3600);
                            const minutes = Math.floor((seconds % 3600) / 60);
                            uptimeProc.uptimeText = hours + "h " + minutes + "m";
                        }
                    }
                }
            }
            Timer {
                interval: 60000; repeat: true; running: true
                onTriggered: uptimeProc.running = true
            }
        }
    }
}
