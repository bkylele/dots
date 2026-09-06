pragma Singleton

import Quickshell
import Quickshell.Io

// Shared, cross-screen state for the app runner.
//
// One AppRunner window exists per screen, but only the instance whose screen
// name matches `activeScreen` shows itself. That keeps the runner on a single
// monitor and makes dismissing it a global action.
Singleton {
    id: root

    // Name of the screen the runner is currently shown on ("" = hidden)
    property string activeScreen: ""

    readonly property bool shown: activeScreen !== "" && screenExists(activeScreen)

    function screenExists(name) {
        var screens = Quickshell.screens
        for (var i = 0; i < screens.length; i++) {
            if (screens[i].name === name) {
                return true
            }
        }
        return false
    }

    function toggle() {
        if (shown) {
            hide()
        } else {
            // Resolve the target screen first — showOn() is called once the
            // compositor answers.
            focusedOutputProc.running = true
        }
    }

    function showOn(name) {
        activeScreen = name
    }

    function hide() {
        activeScreen = ""
    }

    function fallbackScreen() {
        var screens = Quickshell.screens
        return screens.length > 0 ? screens[0].name : ""
    }

    // --- Which monitor should the runner appear on? ---
    // niri's focused output is the monitor being interacted with. Enable
    // `focus-follows-mouse` in the niri input config to make it track the
    // pointer without clicking.
    Process {
        id: focusedOutputProc
        command: ["niri", "msg", "-j", "focused-output"]
        stdout: StdioCollector {
            onStreamFinished: {
                var name = ""
                try {
                    name = JSON.parse(this.text).name || ""
                } catch (e) {
                    name = ""
                }
                if (name === "" || !root.screenExists(name)) {
                    name = root.fallbackScreen()
                }
                root.showOn(name)
            }
        }
    }
}
