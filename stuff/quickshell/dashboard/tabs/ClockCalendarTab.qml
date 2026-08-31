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
        spacing: 6

        // --- Weather (top center) ---
        WeatherWidget {
            Layout.preferredWidth: 240
            Layout.preferredHeight: 80
            Layout.alignment: Qt.AlignHCenter
        }

        // --- Middle row: Clock (left) + Quick Actions (right) ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            DotClock {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 160
                now: root.now
            }

            QuickActions {
                Layout.preferredWidth: 170
                Layout.preferredHeight: 110
                Layout.alignment: Qt.AlignRight
                actions: [
                    // Nerd Font Material Design Icons (surrogate pairs for codepoints > U+FFFF)
                    { icon: "\uDB81\uDDA9", label: "WiFi", active: false },       // nf-md-wifi
                    { icon: "\uDB80\uDCAF", label: "Bluetooth", active: false },   // nf-md-bluetooth
                    { icon: "\uDB80\uDC1D", label: "Airplane Mode", active: false }, // nf-md-airplane
                    { icon: "\uDB81\uDD82", label: "VPN", active: false },         // nf-md-vpn
                    { icon: "",              label: "Empty", active: false },
                    { icon: "",              label: "Empty", active: false }
                ]
            }
        }

        // --- Calendar (bottom, wider and shorter) ---
        Calendar {
            id: calendar
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: false
        }
    }
}
