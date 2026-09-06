pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

// Shared quick-actions state.
//
// TopPanel is instantiated per screen (Variants in shell.qml), so every monitor has
// its own dashboard. Panel state lives here so all of them agree, and so the
// side-effecting bits — the wifi scanner, the tailscale poll rate, an in-flight
// connect — have exactly one writer.
Singleton {
    id: root

    // --- Which panel is expanded: -1 none, 0 wifi, 1 bluetooth, 2 vpn ---
    property int expandedIndex: -1

    readonly property bool wifiPanelOpen: expandedIndex === 0

    function expand(index) { expandedIndex = index }
    function collapse() { expandedIndex = -1 }

    onExpandedIndexChanged: {
        // Leaving the wifi panel abandons any half-finished connect attempt,
        // including the typed password.
        if (expandedIndex !== 0) resetWifi()
        Tailscale.detailOpen = (expandedIndex === 2)
        if (expandedIndex === 2) Tailscale.refresh()
    }

    // --- Toggles ---
    function toggleWifi() {
        if (!Networking.wifiHardwareEnabled) return
        Networking.wifiEnabled = !Networking.wifiEnabled
    }

    function toggleBluetooth() {
        var adapter = Bluetooth.defaultAdapter
        if (!adapter) return
        adapter.enabled = !adapter.enabled
    }

    function toggleVpn() { Tailscale.toggle() }

    // --- Wifi device ---
    // Networking.devices.values is the reactive dependency; NetworkDevice.type is
    // constant, so this only re-evaluates when devices come or go.
    readonly property var wifiDevice: {
        var ds = Networking.devices.values
        for (var i = 0; i < ds.length; i++) {
            if (ds[i].type === DeviceType.Wifi) return ds[i]
        }
        return null
    }

    // Scanning only while the wifi panel is open. Binding (not an imperative
    // write) so a device that appears later still gets it, and it unwinds cleanly.
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: true
        when: root.wifiDevice !== null && root.wifiPanelOpen
    }

    // --- Network list ---
    // Computed imperatively, never in a binding: a comparator that reads
    // signalStrength would capture every network as a dependency, and NetworkManager
    // emits strength updates constantly while scanning, so the rows would reorder
    // and jitter every few seconds.
    property var orderedNetworks: []

    function signalBucket(strength) {
        return Math.max(1, Math.min(4, Math.ceil(strength * 4)))
    }

    function isSecured(security) {
        return security !== WifiSecurityType.Open && security !== WifiSecurityType.Owe
    }

    // Only these can take a plain passphrase.
    function canUsePsk(security) {
        return security === WifiSecurityType.WpaPsk
            || security === WifiSecurityType.Wpa2Psk
            || security === WifiSecurityType.Sae
    }

    function recomputeNetworks() {
        // Freeze the list while a connect is in flight, so the row holding the
        // password field can't move or be replaced under the cursor.
        if (wifiPhase !== "idle") return
        if (!wifiDevice) {
            orderedNetworks = []
            return
        }

        var nets = wifiDevice.networks.values
        var seen = {}
        var list = []
        for (var i = 0; i < nets.length; i++) {
            var n = nets[i]
            // Hidden SSIDs can't be joined through this API.
            if (!n.name || n.name === "") continue
            if (seen[n.name]) continue
            seen[n.name] = true
            list.push(n)
        }

        list.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.known !== b.known) return a.known ? -1 : 1
            var ba = root.signalBucket(a.signalStrength)
            var bb = root.signalBucket(b.signalStrength)
            if (ba !== bb) return bb - ba
            return a.name.localeCompare(b.name)
        })

        orderedNetworks = list
    }

    Connections {
        target: root.wifiDevice ? root.wifiDevice.networks : null
        function onValuesChanged() { root.recomputeNetworks() }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.wifiPanelOpen
        onTriggered: root.recomputeNetworks()
    }

    onWifiPanelOpenChanged: if (wifiPanelOpen) recomputeNetworks()

    // --- Wifi connect state machine ---
    // "idle" | "connecting" | "needsPsk" | "error"
    property string wifiPhase: "idle"
    property var activeNetwork: null
    property string pskText: ""
    property bool pskAttempted: false
    property string wifiError: ""

    function resetWifi() {
        watchdog.stop()
        errorClear.stop()
        activeNetwork = null
        wifiPhase = "idle"
        pskText = ""
        pskAttempted = false
        wifiError = ""
    }

    function activateNetwork(net) {
        if (!net) return
        if (net.connected) {
            net.disconnect()
            return
        }
        activeNetwork = net
        pskText = ""
        pskAttempted = false
        wifiError = ""
        wifiPhase = "connecting"
        watchdog.restart()
        // Always try connect() first: the backend may already hold the PSK, and
        // the docs recommend this to avoid prompting when it isn't needed.
        net.connect()
    }

    function pskIsPlausible(psk) {
        if (psk.length === 64) return /^[0-9a-fA-F]{64}$/.test(psk)
        return psk.length >= 8 && psk.length <= 63
    }

    function submitPsk() {
        if (!activeNetwork) return
        if (!pskIsPlausible(pskText)) {
            wifiError = "Password must be 8-63 characters"
            return
        }
        pskAttempted = true
        wifiError = ""
        wifiPhase = "connecting"
        watchdog.restart()
        activeNetwork.connectWithPsk(pskText)
    }

    function describeFailure(reason) {
        switch (reason) {
        case ConnectionFailReason.NoSecrets: return "Password required"
        case ConnectionFailReason.WifiAuthTimeout: return "Authentication timed out"
        case ConnectionFailReason.WifiNetworkLost: return "Network disappeared"
        case ConnectionFailReason.WifiClientFailed: return "Connection failed"
        case ConnectionFailReason.WifiClientDisconnected: return "Disconnected"
        default: return "Couldn't connect"
        }
    }

    Connections {
        target: root.activeNetwork

        function onConnectionFailed(reason) {
            watchdog.stop()
            if (reason === ConnectionFailReason.NoSecrets) {
                if (root.canUsePsk(root.activeNetwork.security)) {
                    root.wifiPhase = "needsPsk"
                    // The only way to tell a first prompt from a bad password.
                    root.wifiError = root.pskAttempted ? "Wrong password" : ""
                } else {
                    root.wifiPhase = "error"
                    root.wifiError = "Enterprise networks aren't supported here"
                    errorClear.restart()
                }
            } else {
                root.wifiPhase = "error"
                root.wifiError = root.describeFailure(reason)
                errorClear.restart()
            }
        }

        // There is no success signal — watch the network itself.
        function onConnectedChanged() {
            if (root.activeNetwork && root.activeNetwork.connected) {
                root.resetWifi()
                root.recomputeNetworks()
            }
        }
    }

    // An AP can vanish between scans, which nulls the reference.
    onActiveNetworkChanged: if (!activeNetwork && wifiPhase !== "idle") resetWifi()

    Timer {
        // NetworkManager can stall (DHCP) without ever emitting connectionFailed.
        id: watchdog
        interval: 25000
        repeat: false
        onTriggered: {
            root.wifiPhase = "error"
            root.wifiError = "Timed out"
            errorClear.restart()
        }
    }

    Timer {
        id: errorClear
        interval: 4000
        repeat: false
        onTriggered: root.resetWifi()
    }
}
