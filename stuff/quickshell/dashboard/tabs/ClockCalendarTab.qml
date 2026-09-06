import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.services
import qs.widgets

Item {
    id: root
    anchors.fill: parent

    property var now: new Date()

    // --- Quick action panel state ---
    readonly property int expandedIndex: QuickActionsState.expandedIndex
    // Read by DashboardMenu to block tab switching while a panel is open —
    // switching destroys this tab via its Loader and the panel would vanish.
    readonly property bool modal: expandedIndex >= 0

    readonly property int panelSize: 440   // fits inside the 650 circle, corners included

    function reset() {
        calendar.currentMonth = new Date();
        // Collapse without animating; the dashboard is already fading out.
        // collapse() first — it fires onExpandedIndexChanged, which would start
        // the collapse animation back up if we stopped the animations first.
        QuickActionsState.collapse();
        expandAnim.stop();
        collapseAnim.stop();
        panel.contentOpacity = 0;
        mainContent.opacity = 1;
    }

    onExpandedIndexChanged: {
        if (expandedIndex >= 0) {
            // Already open (body swap only) — don't replay the animation.
            if (mainContent.opacity === 0) return;
            collapseAnim.stop();
            var r = cardRect();
            panel.x = r.x; panel.y = r.y;
            panel.width = r.width; panel.height = r.height;
            panel.contentOpacity = 0;
            expandAnim.start();
        } else {
            expandAnim.stop();
            collapseAnim.start();
        }
    }

    // The card's rect in tab coordinates. mapToItem registers no binding
    // dependencies, so this must be called imperatively, at the moment it's needed.
    function cardRect() {
        var r = quickActions.mapToItem(root, 0, 0, quickActions.width, quickActions.height);
        if (!r || r.width === 0) {
            // The layout may not have polished (e.g. a screen whose dashboard has
            // never been shown). Fall back to the panel's own center.
            return Qt.rect((root.width - 170) / 2, (root.height - 62) / 2, 170, 62);
        }
        return r;
    }

    SequentialAnimation {
        id: expandAnim
        // 1. Everything except the card fades out. The panel is sitting exactly
        //    on the card, opaque and the same colour, so the swap is invisible.
        NumberAnimation { target: mainContent; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
        // 2. The card blows up. OutCubic, never OutBack: overshoot would throw the
        //    corners outside the dashboard circle.
        ParallelAnimation {
            NumberAnimation { target: panel; property: "x"; to: (root.width - root.panelSize) / 2; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "y"; to: (root.height - root.panelSize) / 2; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "width"; to: root.panelSize; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "height"; to: root.panelSize; duration: 300; easing.type: Easing.OutCubic }
        }
        // 3. The list fades in.
        NumberAnimation { target: panel; property: "contentOpacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: collapseAnim
        NumberAnimation { target: panel; property: "contentOpacity"; to: 0; duration: 120; easing.type: Easing.OutCubic }
        ScriptAction { script: collapseAnim.dest = root.cardRect() }
        ParallelAnimation {
            NumberAnimation { target: panel; property: "x"; to: collapseAnim.dest.x; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "y"; to: collapseAnim.dest.y; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "width"; to: collapseAnim.dest.width; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "height"; to: collapseAnim.dest.height; duration: 260; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: mainContent; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }

        property rect dest: Qt.rect(0, 0, 170, 62)
    }

    ColumnLayout {
        id: mainContent
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
            spacing: 36

            DotClock {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 160
                now: root.now
            }

            QuickActions {
                id: quickActions

                // Static \u2014 must not be rebuilt, it backs the Repeater.
                // Nerd Font Material Design Icons (surrogate pairs for codepoints > U+FFFF)
                actions: [
                    { icon: "\uDB81\uDDA9", label: "Wi-Fi" },      // nf-md-wifi
                    { icon: "\uDB80\uDCAF", label: "Bluetooth" },  // nf-md-bluetooth
                    { icon: "\uDB81\uDD82", label: "VPN" }         // nf-md-vpn
                ]

                activeStates: [
                    Networking.wifiEnabled,
                    Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false,
                    Tailscale.running
                ]
                enabledStates: [
                    Networking.wifiHardwareEnabled,
                    Bluetooth.defaultAdapter !== null,
                    true
                ]
                busyStates: [false, false, Tailscale.busy]

                onActionToggled: function(index) {
                    if (index === 0) QuickActionsState.toggleWifi()
                    else if (index === 1) QuickActionsState.toggleBluetooth()
                    else if (index === 2) QuickActionsState.toggleVpn()
                }

                onActionExpanded: function(index) {
                    QuickActionsState.expand(index)
                }
            }
        }

        // --- Calendar (bottom, wider and shorter) ---
        Calendar {
            id: calendar
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: false
        }
    }

    // --- Click outside the panel to dismiss ---
    // Negative margins reach past the 530x530 tab box to cover the whole 650
    // circle, since dash's own MouseArea (declared before DashboardMenu) would
    // otherwise swallow clicks in the outer ring.
    MouseArea {
        anchors.fill: parent
        anchors.margins: -60
        enabled: root.modal
        acceptedButtons: Qt.LeftButton
        onClicked: function(mouse) { QuickActionsState.collapse() }
    }

    // --- The expanding panel ---
    QuickActionPanel {
        id: panel
        z: 2
        visible: root.modal || collapseAnim.running

        title: root.expandedIndex === 0 ? "Wi-Fi"
             : root.expandedIndex === 1 ? "Bluetooth"
             : root.expandedIndex === 2 ? "Tailscale" : ""

        subtitle: root.expandedIndex === 2
                  ? (Tailscale.selfName + (Tailscale.running ? "" : " · " + Tailscale.backendState))
                  : ""

        showRefresh: root.expandedIndex === 0 || root.expandedIndex === 2

        bodyComponent: root.expandedIndex === 0 ? wifiBody
                     : root.expandedIndex === 1 ? bluetoothBody
                     : root.expandedIndex === 2 ? tailscaleBody : null

        onBackClicked: QuickActionsState.collapse()
        onRefreshClicked: {
            if (root.expandedIndex === 0) QuickActionsState.recomputeNetworks()
            else if (root.expandedIndex === 2) Tailscale.refresh()
        }
    }

    Component { id: wifiBody; WifiList {} }
    Component { id: bluetoothBody; BluetoothList {} }
    Component { id: tailscaleBody; TailscaleList {} }
}
