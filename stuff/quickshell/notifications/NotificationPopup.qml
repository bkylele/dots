import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.notifications

PanelWindow {
    id: root

    required property var notificationModel

    // --- Configuration ---
    // Any of: "top-right", "top-left", "bottom-right", "bottom-left".
    property string location: "top-right"
    property int edgeMargin: 16
    property int popupWidth: 380
    property int spacing: 10
    property int lowTimeout: 4000
    property int normalTimeout: 7000

    property bool wantsKeyboardFocus: false
    property var focusedReply: null

    readonly property bool atTop: location.indexOf("top-") === 0
    readonly property bool atRight: location.endsWith("-right")

    color: "transparent"
    exclusiveZone: 0
    aboveWindows: true
    focusable: wantsKeyboardFocus
    visible: notificationModel && notificationModel.values.length > 0

    anchors.top: atTop
    anchors.bottom: !atTop
    anchors.left: !atRight
    anchors.right: atRight
    margins.top: edgeMargin
    margins.bottom: edgeMargin
    margins.left: edgeMargin
    margins.right: edgeMargin

    implicitWidth: popupWidth
    implicitHeight: Math.max(1, Math.min(popupList.contentHeight,
                                         screen ? screen.height - edgeMargin * 2 : popupList.contentHeight))

    WlrLayershell.keyboardFocus: wantsKeyboardFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function requestReplyFocus(item) {
        focusedReply = item
        wantsKeyboardFocus = true
        Qt.callLater(function() {
            if (focusedReply === item) item.forceActiveFocus()
        })
    }

    function releaseReplyFocus(item) {
        if (focusedReply !== item) return
        focusedReply = null
        wantsKeyboardFocus = false
    }

    ListView {
        id: popupList
        anchors.fill: parent
        model: root.notificationModel
        spacing: root.spacing
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        verticalLayoutDirection: root.atTop ? ListView.TopToBottom : ListView.BottomToTop

        delegate: NotificationCard {
            required property var modelData

            width: popupList.width
            notification: modelData
            lowTimeout: root.lowTimeout
            normalTimeout: root.normalTimeout
            onKeyboardFocusRequested: function(item) { root.requestReplyFocus(item) }
            onKeyboardFocusReleased: function(item) { root.releaseReplyFocus(item) }
        }
    }
}
