import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    anchors.fill: parent

    property int currentTabIndex: 0
    property var now: new Date()
    
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    function reset() {
        tabContainer.opacity = 1;
        currentTabIndex = 0;
        calendar.currentMonth = new Date();
    }

    // Quick Fade Out -> Fade In logic
    function nextTab() {
        tabSwitcher.newIndex = (currentTabIndex + 1) % 2;
        tabSwitcher.start();
    }

    function prevTab() {
        tabSwitcher.newIndex = (currentTabIndex - 1 + 2) % 2;
        tabSwitcher.start();
    }

    SequentialAnimation {
        id: tabSwitcher
        property int newIndex: 0
        
        NumberAnimation { target: tabContainer; property: "opacity"; to: 0; duration: 100; easing.type: Easing.OutCubic }
        PropertyAction { target: root; property: "currentTabIndex"; value: tabSwitcher.newIndex }
        NumberAnimation { target: tabContainer; property: "opacity"; to: 1; duration: 100; easing.type: Easing.InCubic }
    }

    // Tab Content Container
    Item {
        id: tabContainer
        anchors.fill: parent
        anchors.margins: 60

        // Tab 1: Clock & Calendar
        ColumnLayout {
            visible: currentTabIndex === 0
            anchors.fill: parent
            spacing: 20

            Item {
                id: clockContainer
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                Layout.alignment: Qt.AlignHCenter

                Column {
                    anchors.centerIn: parent
                    spacing: -8
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 56; font.weight: Font.ExtraBold; color: "#333333"
                        text: {
                            var h = root.now.getHours() % 12;
                            if (h === 0) h = 12;
                            return h < 10 ? "0" + h : h;
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 56; font.weight: Font.Light; color: "#666666"
                        text: Qt.formatTime(root.now, "mm")
                    }
                }

                Repeater {
                    model: 60
                    delegate: Rectangle {
                        required property int index
                        width: index % 5 == 0 ? 6 : 4; height: width; radius: width / 2
                        color: index <= root.now.getSeconds() ? "#333333" : "#DDDDDD"
                        x: (clockContainer.width / 2) + Math.cos((index / 60) * 2 * Math.PI - Math.PI/2) * 95 - radius
                        y: (clockContainer.height / 2) + Math.sin((index / 60) * 2 * Math.PI - Math.PI/2) * 95 - radius
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            Calendar {
                id: calendar
                Layout.alignment: Qt.AlignHCenter
                scale: 1.1
            }
        }

        // Tab 2: System Resources
        ColumnLayout {
            visible: currentTabIndex === 1
            anchors.centerIn: parent
            width: 300
            spacing: 40

            Text {
                text: "SYSTEM STATUS"
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
                    CPU { Layout.fillHeight: true; Layout.preferredWidth: 30 }
                    Memory { Layout.fillHeight: true; Layout.preferredWidth: 30 }
                    Temperature { Layout.fillHeight: true; Layout.preferredWidth: 30 }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 10
                Text {
                    text: "Uptime: " + uptimeProc.uptimeText
                    font.pixelSize: 14; color: "#666666"; Layout.alignment: Qt.AlignHCenter
                }
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
}
