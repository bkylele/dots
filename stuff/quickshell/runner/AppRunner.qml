import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    required property var modelData
    screen: modelData

    id: root
    color: "transparent"
    exclusiveZone: 0

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    implicitWidth: screen.width
    implicitHeight: screen.height

    // --- Configuration ---
    property int maxVisibleResults: 8       // Max suggestions shown at once
    property int runnerWidth: 500           // Width of the runner panel
    property int inputHeight: 48            // Height of the text input area
    property int resultRowHeight: 40        // Height of each suggestion row
    property int cornerRadius: 16           // Corner radius of the runner panel
    property string historyPath: ""              // Resolved at startup via initPathProc
    property int maxHistoryEntries: 100     // Max history entries to keep
    property bool pathReady: false          // Whether historyPath has been resolved

    // --- Internal State ---
    property var pathCommands: []           // Cached list of $PATH executables
    property var historyList: []            // Command history (most recent last)
    property var filteredResults: []        // Current visible results
    property int selectedIndex: 0          // Currently highlighted suggestion
    property bool pathLoaded: false         // Whether PATH commands have been loaded
    property bool isNavigating: false       // Whether user is arrow-key navigating

    // Keyboard focus: Exclusive when visible, None when hidden
    WlrLayershell.keyboardFocus: sg.state === "visible" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // --- Toggle: called from IPC handler in shell.qml ---
    function toggle() {
        if (sg.state === "hidden") {
            show()
        } else {
            hide()
        }
    }

    function show() {
        // Reset input state before showing
        inputField.text = ""
        root.selectedIndex = 0
        root.isNavigating = false
        // Load history (only if path has been resolved)
        if (pathReady) {
            historyLoadProc.running = true
        }
        // Load PATH commands if not cached
        if (!pathLoaded) {
            pathLoadProc.running = true
        }
        sg.state = "visible"
        // Delay focus grab to after the transition starts and keyboard focus is active
        focusTimer.restart()
    }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: {
            inputField.forceActiveFocus()
        }
    }

    function hide() {
        sg.state = "hidden"
    }

    // --- Masking: capture input over the runner + dismiss area when visible ---
    mask: Region {
        item: sg.state === "visible" ? dismissArea : emptyMask
    }

    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    // --- States & Transitions ---
    StateGroup {
        id: sg
        state: "hidden"
        states: [
            State {
                name: "hidden"
                PropertyChanges { target: runnerRect; y: -(root.inputHeight + root.resultRowHeight * root.maxVisibleResults + root.cornerRadius * 2 + 20) }
                PropertyChanges { target: runnerContent; opacity: 0 }
            },
            State {
                name: "visible"
                PropertyChanges { target: runnerRect; y: 12 }
                PropertyChanges { target: runnerContent; opacity: 1 }
            }
        ]

        transitions: [
            // Show: slide down + fade in
            Transition {
                from: "hidden"; to: "visible"
                ParallelAnimation {
                    NumberAnimation { target: runnerRect; property: "y"; duration: 300; easing.type: Easing.OutCubic }
                    NumberAnimation { target: runnerContent; property: "opacity"; duration: 250; easing.type: Easing.OutCubic }
                }
            },
            // Hide: fade out then slide up
            Transition {
                from: "visible"; to: "hidden"
                SequentialAnimation {
                    NumberAnimation { target: runnerContent; property: "opacity"; to: 0; duration: 100; easing.type: Easing.OutCubic }
                    NumberAnimation { target: runnerRect; property: "y"; duration: 250; easing.type: Easing.InCubic }
                }
            }
        ]
    }

    // --- Escape to dismiss ---
    Shortcut {
        enabled: sg.state === "visible"
        sequence: "Escape"
        onActivated: function() { root.hide() }
    }

    // --- Click outside to dismiss ---
    MouseArea {
        id: dismissArea
        anchors.fill: parent
        visible: sg.state === "visible"
        onClicked: function(mouse) { root.hide() }
    }

    // --- The Runner Panel ---
    Rectangle {
        id: runnerRect
        width: root.runnerWidth
        anchors.horizontalCenter: parent.horizontalCenter
        height: root.inputHeight + (resultsList.count > 0 ? Math.min(resultsList.count, root.maxVisibleResults) * root.resultRowHeight + 1 : 0)
        radius: root.cornerRadius
        color: "#FFFFFF"
        clip: true

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // Swallow clicks inside the runner
        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true }
        }

        Item {
            id: runnerContent
            anchors.fill: parent
            opacity: 0
            visible: opacity > 0

            // --- Input Row ---
            Item {
                id: inputRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.inputHeight

                // Search icon
                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u2315"  // ⌕
                    font.pixelSize: 18
                    color: "#999999"
                }

                TextInput {
                    id: inputField
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 15
                    color: "#1a1a1a"
                    clip: true
                    selectByMouse: true

                    // Placeholder
                    Text {
                        anchors.fill: parent
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Run a command..."
                        font.pixelSize: 15
                        color: "#999999"
                        visible: !inputField.text
                    }

                    onTextChanged: {
                        root.isNavigating = false
                        root.selectedIndex = 0
                        root.updateResults()
                    }

                    // Handle special keys
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down) {
                            root.isNavigating = true
                            if (root.selectedIndex < root.filteredResults.length - 1) {
                                root.selectedIndex++
                            }
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.isNavigating = true
                            if (root.selectedIndex > 0) {
                                root.selectedIndex--
                            }
                            event.accepted = true
                        } else if (event.key === Qt.Key_Tab) {
                            // Tab completion: fill with selected suggestion
                            if (root.filteredResults.length > 0 && root.selectedIndex < root.filteredResults.length) {
                                inputField.text = root.filteredResults[root.selectedIndex]
                                inputField.cursorPosition = inputField.text.length
                            }
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            var cmd = inputField.text.trim()
                            if (cmd.length > 0) {
                                root.executeCommand(cmd)
                            }
                            event.accepted = true
                        }
                    }
                }
            }

            // --- Separator ---
            Rectangle {
                id: separator
                anchors.top: inputRow.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: resultsList.count > 0 ? 1 : 0
                color: "#E8E8E8"
                visible: resultsList.count > 0
            }

            // --- Results List ---
            ListView {
                id: resultsList
                anchors.top: separator.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true
                model: root.filteredResults
                currentIndex: root.selectedIndex
                highlightMoveDuration: 80

                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    width: resultsList.width
                    height: root.resultRowHeight
                    color: index === root.selectedIndex ? "#12000000" : (delegateMouse.containsMouse ? "#08000000" : "transparent")

                    Behavior on color { ColorAnimation { duration: 100 } }

                    // Selection indicator
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: index === root.selectedIndex ? "▸" : " "
                        font.pixelSize: 12
                        color: "#999999"
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 32
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        font.pixelSize: 14
                        color: "#333333"
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: function(mouse) {
                            inputField.text = modelData
                            inputField.cursorPosition = inputField.text.length
                            inputField.forceActiveFocus()
                        }
                        onEntered: {
                            root.selectedIndex = index
                        }
                    }
                }
            }
        }
    }

    // --- Result Filtering Logic ---
    // Priority: history first (matches full command including args), then PATH (first word only)
    function updateResults() {
        var query = inputField.text.trim()
        var results = []

        if (query.length === 0) {
            // Empty input: show recent history (most recent first)
            var reversed = historyList.slice().reverse()
            results = reversed.slice(0, maxVisibleResults)
        } else {
            var queryLower = query.toLowerCase()
            var firstWord = query.split(/\s+/)[0].toLowerCase()

            // 1. History matches first — match against the FULL command string (including args)
            var seen = {}
            for (var h = historyList.length - 1; h >= 0 && results.length < maxVisibleResults; h--) {
                var entry = historyList[h]
                if (entry.toLowerCase().indexOf(queryLower) === 0 && !seen[entry]) {
                    results.push(entry)
                    seen[entry] = true
                }
            }

            // 2. Fill remaining slots with PATH matches (first word only, no args matching)
            if (results.length < maxVisibleResults && query.indexOf(" ") === -1) {
                for (var p = 0; p < pathCommands.length && results.length < maxVisibleResults; p++) {
                    var cmd = pathCommands[p]
                    if (cmd.toLowerCase().indexOf(firstWord) === 0 && !seen[cmd]) {
                        results.push(cmd)
                        seen[cmd] = true
                    }
                }
            }
        }

        filteredResults = results

        // Ensure selectedIndex is within bounds
        if (selectedIndex >= filteredResults.length) {
            selectedIndex = Math.max(0, filteredResults.length - 1)
        }
    }

    // --- Command Execution ---
    function executeCommand(cmd) {
        // Save to history
        saveToHistory(cmd)
        // Execute
        execProc.command = ["setsid", "-f", "sh", "-c", cmd]
        execProc.running = true
        // Hide the runner
        root.hide()
    }

    Process {
        id: execProc
        // command set dynamically
    }

    // --- Resolve history path at startup ---
    Process {
        id: initPathProc
        running: true  // runs immediately on component creation
        command: ["sh", "-c", "dir=\"${XDG_DATA_HOME:-$HOME/.local/share}/quickshell\" && mkdir -p \"$dir\" && echo \"$dir/runner_history\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var resolved = this.text.trim()
                if (resolved.length > 0) {
                    root.historyPath = resolved
                    root.pathReady = true
                }
            }
        }
    }

    // --- PATH Loading ---
    Process {
        id: pathLoadProc
        command: ["bash", "-c", "compgen -c | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                var cmds = []
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.length > 0) {
                        cmds.push(line)
                    }
                }
                root.pathCommands = cmds
                root.pathLoaded = true
                root.updateResults()
            }
        }
    }

    // --- History Loading ---
    Process {
        id: historyLoadProc
        command: ["sh", "-c", "touch '" + root.historyPath + "' && cat '" + root.historyPath + "'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                var history = []
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.length > 0) {
                        history.push(line)
                    }
                }
                root.historyList = history
                root.updateResults()
            }
        }
    }

    // --- History Saving ---
    function saveToHistory(cmd) {
        if (!pathReady) return

        // Remove duplicates of this command from history
        var newHistory = []
        for (var i = 0; i < historyList.length; i++) {
            if (historyList[i] !== cmd) {
                newHistory.push(historyList[i])
            }
        }
        newHistory.push(cmd)

        // Cap at maxHistoryEntries
        if (newHistory.length > maxHistoryEntries) {
            newHistory = newHistory.slice(newHistory.length - maxHistoryEntries)
        }

        historyList = newHistory

        // Write to file
        var escaped = cmd.replace(/'/g, "'\\''")
        historySaveProc.command = [
            "sh", "-c",
            "touch '" + root.historyPath + "' && " +
            "grep -v -x -F '" + escaped + "' '" + root.historyPath + "' 2>/dev/null > '" + root.historyPath + ".tmp' || true && " +
            "echo '" + escaped + "' >> '" + root.historyPath + ".tmp' && " +
            "tail -n " + root.maxHistoryEntries + " '" + root.historyPath + ".tmp' > '" + root.historyPath + "' && " +
            "rm -f '" + root.historyPath + ".tmp'"
        ]
        historySaveProc.running = true
    }

    Process {
        id: historySaveProc
        // command set dynamically
    }
}
