import QtQuick

Item {
    id: root
    width: 200
    height: 200

    property var now: new Date()

    Column {
        anchors.centerIn: parent
        spacing: -8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 56; font.weight: Font.ExtraBold; color: "#333333"
            text: {
                var h = root.now.getHours() % 12;
                if (h === 0) h = 12;
                return h < 10 ? "0" + h : h;
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 56; font.weight: Font.Light; color: "#666666"
            text: Qt.formatTime(root.now, "mm")
        }
    }

    Repeater {
        model: 60
        delegate: Rectangle {
            required property int index
            width: index % 5 == 0 ? 6 : 4; height: width; radius: width / 2
            color: index <= root.now.getSeconds() ? "#333333" : "#DDDDDD"
            x: (root.width / 2) + Math.cos((index / 60) * 2 * Math.PI - Math.PI/2) * 95 - radius
            y: (root.height / 2) + Math.sin((index / 60) * 2 * Math.PI - Math.PI/2) * 95 - radius
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}
