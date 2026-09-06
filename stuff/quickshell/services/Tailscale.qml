pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Tailscale state, shared across every screen's dashboard.
//
// There is no native Quickshell module and tailscaled exposes no well-known DBus
// name, so this polls the CLI. Reads work unprivileged because the tailscaled
// socket is world-accessible; `up`/`down` additionally require the operator to be
// set (services.tailscale.extraSetFlags = [ "--operator=brian" ]).
Singleton {
    id: root

    // Absolute path: Process does not run in a shell, so PATH is whatever the
    // session inherited.
    readonly property string bin: "/run/current-system/sw/bin/tailscale"

    // --- State ---
    property string backendState: ""        // "Running" | "Stopped" | "NeedsLogin" | ...
    property var peers: []                  // sorted, display-ready peer objects
    property string selfName: ""            // this machine's DNS name, no trailing dot
    property string exitNodeId: ""          // ID of the exit node in use, "" if none
    property bool busy: false               // an up/down is in flight
    property string lastError: ""

    readonly property bool running: backendState === "Running"
    readonly property bool needsLogin: backendState === "NeedsLogin"

    // Set by QuickActionsState while the VPN panel is open, to poll faster.
    property bool detailOpen: false

    function refresh() {
        // Guard re-entrancy: a slow status must not stack up behind a fast timer.
        if (!statusProc.running) {
            statusProc.running = true
        }
    }

    function toggle() {
        if (busy) return
        runAction(running ? "down" : "up")
    }

    function runAction(verb) {
        root.lastError = ""
        root.busy = true
        actionProc.command = [root.bin, verb]
        actionProc.running = true
    }

    // "2026-09-05T19:26:36Z" -> "3h ago". Returns "" for the zero value, which is
    // what LastSeen holds while a peer is online.
    function relativeTime(iso) {
        if (!iso || iso.indexOf("0001-01-01") === 0) return ""
        var then = new Date(iso).getTime()
        if (isNaN(then)) return ""
        var mins = Math.floor((Date.now() - then) / 60000)
        if (mins < 1) return "just now"
        if (mins < 60) return mins + "m ago"
        var hours = Math.floor(mins / 60)
        if (hours < 24) return hours + "h ago"
        return Math.floor(hours / 24) + "d ago"
    }

    // --- Status polling ---
    Process {
        id: statusProc
        command: [root.bin, "status", "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var json
                try {
                    json = JSON.parse(this.text)
                } catch (e) {
                    root.backendState = ""
                    root.peers = []
                    return
                }
                root.applyStatus(json)
            }
        }
    }

    function applyStatus(json) {
        backendState = json.BackendState || ""
        exitNodeId = (json.ExitNodeStatus && json.ExitNodeStatus.ID) ? json.ExitNodeStatus.ID : ""

        var suffix = json.MagicDNSSuffix || ""
        var self = json.Self || {}
        selfName = stripSuffix(self.DNSName || "", suffix)

        // Peer is a MAP keyed by "nodekey:<hex>", not an array.
        var list = []
        var raw = json.Peer || {}
        var keys = Object.keys(raw)
        for (var i = 0; i < keys.length; i++) {
            var p = raw[keys[i]]
            list.push({
                id: p.ID || "",
                host: p.HostName || stripSuffix(p.DNSName || "", suffix),
                os: p.OS || "",
                online: p.Online === true,
                lastSeen: p.Online === true ? "" : relativeTime(p.LastSeen),
                route: (p.CurAddr && p.CurAddr !== "") ? "direct" : (p.Relay ? "relay " + p.Relay : ""),
                isExitNode: root.exitNodeId !== "" && p.ID === root.exitNodeId,
                offersExit: p.ExitNodeOption === true
            })
        }

        // Online first, then by hostname.
        list.sort(function(a, b) {
            if (a.online !== b.online) return a.online ? -1 : 1
            return a.host.localeCompare(b.host)
        })

        // Only publish when something actually changed, so the list view isn't
        // rebuilt (and scroll position lost) on every poll.
        var encoded = JSON.stringify(list)
        if (encoded !== lastPeersJson) {
            lastPeersJson = encoded
            peers = list
        }
    }

    property string lastPeersJson: ""

    function stripSuffix(dnsName, suffix) {
        var name = dnsName.replace(/\.$/, "")
        if (suffix !== "" && name.indexOf("." + suffix) > 0) {
            name = name.substring(0, name.length - suffix.length - 1)
        }
        return name
    }

    Timer {
        // Fast while the panel is open; slow otherwise, so the collapsed button
        // still reflects reality without the panel ever being opened.
        interval: root.detailOpen ? 3000 : 30000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    // --- up / down ---
    Process {
        id: actionProc
        stderr: StdioCollector {
            onStreamFinished: {
                var msg = this.text.trim()
                if (msg.length > 0) root.lastError = msg
            }
        }
        onExited: function(exitCode, exitStatus) {
            root.busy = false
            root.refresh()
        }
    }
}
