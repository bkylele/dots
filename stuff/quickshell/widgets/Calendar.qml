import QtQuick
import QtQuick.Layouts

Item {
    id: root
    width: 360
    height: 230

    property date currentMonth: new Date()
    property date today: new Date()

    // Helper functions for month logic
    function getDaysInMonth(date) { return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate(); }
    function getDaysInPrevMonth(date) { return new Date(date.getFullYear(), date.getMonth(), 0).getDate(); }
    function getFirstDayOfMonth(date) { return new Date(date.getFullYear(), date.getMonth(), 1).getDay(); }
    function getLastDayOfMonth(date) { return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDay(); }

    function msUntilMidnight() {
        var now = new Date()
        var midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0)
        return midnight - now
    }

    Timer {
        id: midnightTimer
        repeat: false
        running: true
        interval: msUntilMidnight()
        onTriggered: {
            today = new Date()
            interval = msUntilMidnight()
            start()
        }
    }

    // Sync currentMonth with ListView
    onCurrentMonthChanged: {
        var targetIndex = (currentMonth.getFullYear() - 2000) * 12 + currentMonth.getMonth();
        if (monthList.currentIndex !== targetIndex) {
            monthList.currentIndex = targetIndex;
        }
    }

    // Header with month name & navigation
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 34

        Rectangle {
            id: prevButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 28; height: 28
            radius: 14
            color: prevMouse.containsMouse ? "#EEEEEE" : "transparent"
            Text { anchors.centerIn: parent; text: "<"; font.pixelSize: 18 }
            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: monthList.decrementCurrentIndex()
            }
        }

        Rectangle {
            id: monthYearButton
            anchors.centerIn: parent
            width: monthYearText.contentWidth + 20
            height: 32
            radius: 16
            color: monthYearMouse.containsMouse ? "#EEEEEE" : "transparent"

            Text {
                id: monthYearText
                anchors.centerIn: parent
                text: Qt.formatDate(currentMonth, "MMMM yyyy")
                font.bold: true
                font.pixelSize: 18
                color: "#333333"
            }

            MouseArea {
                id: monthYearMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: currentMonth = new Date()
            }
        }

        Rectangle {
            id: nextButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 28; height: 28
            radius: 14
            color: nextMouse.containsMouse ? "#EEEEEE" : "transparent"
            Text { anchors.centerIn: parent; text: ">"; font.pixelSize: 18 }
            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: monthList.incrementCurrentIndex()
            }
        }
    }

    // Stationary Day Labels
    Row {
        id: dayLabels
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0
        Repeater {
            model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            delegate: Item {
                width: 46; height: 24
                Text {
                    text: modelData
                    font.bold: true
                    font.pixelSize: 12
                    anchors.centerIn: parent
                    color: "#666666"
                }
            }
        }
    }

    // Sliding Month Grid
    ListView {
        id: monthList
        anchors.top: dayLabels.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        clip: true
        
        // Make the animation snappy
        highlightMoveDuration: 250
        
        model: 1200 // 100 years of months starting from year 2000
        currentIndex: (currentMonth.getFullYear() - 2000) * 12 + currentMonth.getMonth()
        
        onCurrentIndexChanged: {
            var date = new Date(2000, currentIndex, 1);
            if (date.getMonth() !== currentMonth.getMonth() || date.getFullYear() !== currentMonth.getFullYear()) {
                currentMonth = date;
            }
        }

        delegate: Item {
            width: monthList.width
            height: monthList.height
            
            property date monthDate: new Date(2000, index, 1)
            property int daysInMonth: getDaysInMonth(monthDate)
            property int daysInPrevMonth: getDaysInPrevMonth(monthDate)
            property int firstDayOfMonth: getFirstDayOfMonth(monthDate)
            property int lastDayOfMonth: getLastDayOfMonth(monthDate)

            GridLayout {
                columns: 7
                rowSpacing: 2
                columnSpacing: 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 5

                // Prev month padding
                Repeater {
                    model: firstDayOfMonth
                    delegate: Rectangle {
                        width: 46; height: 24
                        radius: 12
                        color: "transparent"
                        Text {
                            color: "#BBBBBB"
                            anchors.centerIn: parent
                            text: index + daysInPrevMonth - firstDayOfMonth + 1
                        }
                    }
                }

                // Current month
                Repeater {
                    model: daysInMonth
                    delegate: Rectangle {
                        width: 46; height: 24
                        radius: 12
                        color: {
                            var isToday = today.getDate() === (index + 1) &&
                                          today.getMonth() === monthDate.getMonth() &&
                                          today.getFullYear() === monthDate.getFullYear()
                            return isToday ? "#ff6666" : "transparent"
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            color: {
                                var isToday = today.getDate() === (index + 1) &&
                                              today.getMonth() === monthDate.getMonth() &&
                                              today.getFullYear() === monthDate.getFullYear()
                                return isToday ? "white" : "#333333"
                            }
                        }
                    }
                }

                // Next month padding
                Repeater {
                    model: 6 - lastDayOfMonth
                    delegate: Rectangle {
                        width: 46; height: 24
                        radius: 12
                        color: "transparent"
                        Text {
                            color: "#BBBBBB"
                            anchors.centerIn: parent
                            text: index + 1
                        }
                    }
                }
            }
        }
    }
}
