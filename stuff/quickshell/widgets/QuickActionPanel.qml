import QtQuick
import Quickshell.Widgets

// The expanded quick-action panel: a card that the parent animates from the
// QuickActions button's rect out to full size. This component owns the chrome
// (header, separator, body loader) but not the geometry animation — the parent
// drives x/y/width/height and contentOpacity, because the same sequence also
// fades the rest of the dashboard.
//
// ClippingRectangle (not Rectangle + clip) so body rows are clipped to the
// rounded corners instead of the bounding box.
ClippingRectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool showRefresh: false

    // Driven by the parent's expand/collapse animation.
    property real contentOpacity: 0

    property Component bodyComponent: null

    signal backClicked()
    signal refreshClicked()

    readonly property int headerHeight: 56

    color: "#F0F0F0"
    radius: 18

    // Swallow clicks anywhere in the panel, including padding — otherwise they
    // fall through to the dismiss area behind and collapse the panel.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) { mouse.accepted = true }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: root.contentOpacity
        visible: opacity > 0

        // --- Header ---
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.headerHeight

            Rectangle {
                id: backButton
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                color: backMouse.containsMouse ? "#20000000" : "transparent"
                scale: backMouse.containsMouse ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: "←"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#666666"
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) { root.backClicked() }
                }
            }

            Column {
                anchors.left: backButton.right
                anchors.leftMargin: 8
                anchors.right: refreshButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: root.title
                    font.pixelSize: 18
                    font.bold: true
                    color: "#333333"
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.subtitle
                    font.pixelSize: 12
                    color: "#888888"
                    elide: Text.ElideRight
                    visible: root.subtitle !== ""
                }
            }

            Rectangle {
                id: refreshButton
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                visible: root.showRefresh
                color: refreshMouse.containsMouse ? "#20000000" : "transparent"
                scale: refreshMouse.containsMouse ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: "↻"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#666666"
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) { root.refreshClicked() }
                }
            }
        }

        // --- Separator ---
        Rectangle {
            id: separator
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 1
            color: "#E8E8E8"
        }

        // --- Body ---
        Loader {
            anchors.top: separator.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            sourceComponent: root.bodyComponent
        }
    }
}
