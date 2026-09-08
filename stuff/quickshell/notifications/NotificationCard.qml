import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Rectangle {
    id: card

    required property var notification
    property int lowTimeout: 4000
    property int normalTimeout: 7000
    property bool closing: false
    property string closeOperation: ""
    property var pendingAction: null
    property string pendingReply: ""

    signal keyboardFocusRequested(var item)
    signal keyboardFocusReleased(var item)

    readonly property bool valid: notification !== null && notification !== undefined
    readonly property bool critical: valid && notification.urgency === NotificationUrgency.Critical
    readonly property int requestedTimeout: valid ? notification.expireTimeout : 0
    readonly property bool shouldExpire: valid && !critical && requestedTimeout !== 0
    readonly property int timeout: requestedTimeout > 0
                                   ? requestedTimeout
                                   : (valid && notification.urgency === NotificationUrgency.Low ? lowTimeout : normalTimeout)
    readonly property real progress: {
        if (!valid) return -1
        var value = Number(notification.hints["value"])
        return isNaN(value) ? -1 : Math.max(0, Math.min(100, value))
    }
    readonly property var buttonActions: {
        if (!notification) return []
        var actions = []
        for (var i = 0; i < notification.actions.length; i++) {
            if (notification.actions[i].identifier !== "default") actions.push(notification.actions[i])
        }
        return actions
    }

    function iconSource(icon) {
        if (!icon) return ""
        return icon.indexOf("/") !== -1 || icon.indexOf(":") !== -1
                ? icon
                : Quickshell.iconPath(icon, true)
    }

    function defaultAction() {
        if (!valid) return null
        for (var i = 0; i < notification.actions.length; i++) {
            if (notification.actions[i].identifier === "default") return notification.actions[i]
        }
        return null
    }

    function activate() {
        var action = defaultAction()
        beginClose(action ? "defaultAction" : "dismiss", action, "")
    }

    function invokeAction(action) {
        if (!notification || closing) return
        if (notification.resident) action.invoke()
        else beginClose("action", action, "")
    }

    function sendReply(reply) {
        if (!notification || closing || reply === "") return
        if (notification.resident) notification.sendInlineReply(reply)
        else beginClose("reply", null, reply)
    }

    function beginClose(operation, action, reply) {
        if (!notification || closing) return
        closeOperation = operation
        pendingAction = action
        pendingReply = reply
        closing = true
        expiry.stop()
        dismissAnimation.restart()
    }

    function finishClose() {
        var current = notification
        if (!current) return

        if (closeOperation === "expire") current.expire()
        else if (closeOperation === "dismiss") current.dismiss()
        else if (closeOperation === "reply") current.sendInlineReply(pendingReply)
        else if (pendingAction) {
            var wasResident = current.resident
            pendingAction.invoke()
            if (closeOperation === "defaultAction" && wasResident && current.tracked) current.dismiss()
        }
    }

    function restartExpiry() {
        if (shouldExpire) expiry.restart()
        else expiry.stop()
    }

    implicitHeight: content.implicitHeight + 28
    radius: 14
    color: critical ? "#3A2025" : "#252525"
    border.width: 1
    border.color: critical ? "#D96778" : "#3D3D3D"

    Component.onCompleted: restartExpiry()
    Component.onDestruction: keyboardFocusReleased(replyInput)

    // Keep the notification contents alive until ListView's remove transition ends.
    RetainableLock {
        object: card.notification
        locked: true
    }

    MouseArea {
        anchors.fill: parent
        enabled: !card.closing
        cursorShape: Qt.PointingHandCursor
        onClicked: function() { card.activate() }
    }

    ParallelAnimation {
        id: dismissAnimation

        NumberAnimation {
            target: card
            property: "x"
            from: 0
            to: card.width + 24
            duration: 240
            easing.type: Easing.InCubic
        }
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 200 }
        onFinished: function() { card.finishClose() }
    }

    Timer {
        id: expiry
        interval: Math.max(1, card.timeout)
        repeat: false
        onTriggered: function() { card.beginClose("expire", null, "") }
    }

    Connections {
        target: card.notification
        function onExpireTimeoutChanged() { card.restartExpiry() }
        function onUrgencyChanged() { card.restartExpiry() }
        function onAppNameChanged() { card.restartExpiry() }
        function onAppIconChanged() { card.restartExpiry() }
        function onSummaryChanged() { card.restartExpiry() }
        function onBodyChanged() { card.restartExpiry() }
        function onActionsChanged() { card.restartExpiry() }
        function onImageChanged() { card.restartExpiry() }
        function onHintsChanged() { card.restartExpiry() }
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        spacing: 10

        Item {
            width: parent.width
            height: Math.max(42, headerText.implicitHeight)

            IconImage {
                id: appIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 40
                source: card.valid ? card.iconSource(card.notification.appIcon) : ""
                visible: source !== ""
            }

            Rectangle {
                anchors.fill: appIcon
                radius: 9
                color: card.critical ? "#D96778" : "#555555"
                visible: !appIcon.visible

                Text {
                    anchors.centerIn: parent
                    text: card.valid ? (card.notification.appName || card.notification.summary || "?").charAt(0).toUpperCase() : "?"
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                }
            }

            Column {
                id: headerText
                anchors.left: appIcon.right
                anchors.leftMargin: 11
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: card.valid ? (card.notification.appName || card.notification.desktopEntry || "Notification") : ""
                    color: "#AFAFAF"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: card.valid ? card.notification.summary : ""
                    color: "#FFFFFF"
                    font.pixelSize: 15
                    font.bold: true
                    wrapMode: Text.Wrap
                }
            }
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: card.valid ? card.notification.body : ""
            textFormat: Text.RichText
            wrapMode: Text.Wrap
            color: "#E2E2E2"
            linkColor: "#8AB4F8"
            font.pixelSize: 13
            onLinkActivated: function(link) { Qt.openUrlExternally(link) }
        }

        Image {
            width: parent.width
            height: status === Image.Ready && sourceSize.width > 0
                    ? Math.min(180, sourceSize.height * width / sourceSize.width)
                    : 0
            visible: height > 0
            source: card.valid ? card.notification.image : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }

        Rectangle {
            width: parent.width
            height: 5
            radius: 3
            color: "#44FFFFFF"
            visible: card.progress >= 0

            Rectangle {
                width: parent.width * card.progress / 100
                height: parent.height
                radius: parent.radius
                color: card.critical ? "#D96778" : "#8AB4F8"
                Behavior on width { NumberAnimation { duration: 150 } }
            }
        }

        Flow {
            width: parent.width
            height: childrenRect.height
            spacing: 7
            visible: card.buttonActions.length > 0

            Repeater {
                model: card.buttonActions

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: Math.min(content.width, actionContent.implicitWidth + 22)
                    height: 32
                    radius: 8
                    color: actionMouse.containsMouse ? "#33FFFFFF" : "#1FFFFFFF"
                    border.width: 1
                    border.color: "#44FFFFFF"

                    Row {
                        id: actionContent
                        anchors.centerIn: parent
                        spacing: 6

                        IconImage {
                            implicitSize: 16
                            source: card.valid && card.notification.hasActionIcons
                                    ? card.iconSource(actionButton.modelData.identifier)
                                    : ""
                            visible: source !== ""
                        }

                        Text {
                            text: actionButton.modelData.text || actionButton.modelData.identifier
                            color: "white"
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !card.closing
                        onClicked: function() { card.invokeAction(actionButton.modelData) }
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 36
            spacing: 8
            visible: card.valid && card.notification.hasInlineReply

            Rectangle {
                width: parent.width - sendButton.width - parent.spacing
                height: parent.height
                radius: 8
                color: "#18FFFFFF"
                border.width: replyInput.activeFocus ? 1 : 0
                border.color: "#8AB4F8"

                TextInput {
                    id: replyInput
                    anchors.fill: parent
                    anchors.margins: 9
                    color: "white"
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true

                    Text {
                        anchors.fill: parent
                        text: card.valid ? (card.notification.inlineReplyPlaceholder || "Reply…") : "Reply…"
                        color: "#888888"
                        font.pixelSize: 12
                        visible: replyInput.text === "" && !replyInput.activeFocus
                    }

                    onActiveFocusChanged: function() {
                        if (!activeFocus) card.keyboardFocusReleased(replyInput)
                    }
                    Keys.onReturnPressed: function() { sendButton.send() }
                    Keys.onEnterPressed: function() { sendButton.send() }

                    TapHandler {
                        onTapped: function() { card.keyboardFocusRequested(replyInput) }
                    }
                }
            }

            Rectangle {
                id: sendButton
                width: 58
                height: parent.height
                radius: 8
                color: sendMouse.containsMouse ? "#A8C7FA" : "#8AB4F8"

                function send() {
                    var reply = replyInput.text
                    if (reply === "") return
                    replyInput.text = ""
                    card.keyboardFocusReleased(replyInput)
                    card.sendReply(reply)
                }

                Text {
                    anchors.centerIn: parent
                    text: "Send"
                    color: "#172238"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: sendMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function() { sendButton.send() }
                }
            }
        }
    }
}
