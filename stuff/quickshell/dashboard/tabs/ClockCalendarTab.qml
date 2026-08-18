import QtQuick
import QtQuick.Layouts
import qs.widgets

Item {
    id: root
    anchors.fill: parent

    property var now: new Date()

    function reset() {
        calendar.currentMonth = new Date();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        DotClock {
            Layout.preferredWidth: 200
            Layout.preferredHeight: 200
            Layout.alignment: Qt.AlignHCenter
            now: root.now
        }

        Calendar {
            id: calendar
            Layout.alignment: Qt.AlignHCenter
            scale: 1.1
        }
    }
}
