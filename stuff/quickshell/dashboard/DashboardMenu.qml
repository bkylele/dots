import QtQuick
import qs.dashboard.tabs

Item {
    id: root
    anchors.fill: parent

    // --- Tab Registry ---
    // To add a new tab, append a Component here AND a corresponding icon to tabIcons.
    property list<Component> tabs: [
        Component { ClockCalendarTab {} },
        Component { SystemStatusTab {} }
    ]
    property var tabIcons: ["\u23F0", "\uD83D\uDCBB"]
    property int tabCount: tabs.length
    property int currentTabIndex: 0

    // Icons representing the tab you'd navigate TO
    property string prevTabIcon: tabIcons[(currentTabIndex - 1 + tabCount) % tabCount]
    property string nextTabIcon: tabIcons[(currentTabIndex + 1) % tabCount]

    property var now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    function reset() {
        tabContainer.opacity = 1;
        currentTabIndex = 0;
        // Reset the active tab if it supports it
        if (tabLoader.item && typeof tabLoader.item.reset === "function") {
            tabLoader.item.reset();
        }
    }

    // Quick Fade Out -> Fade In logic
    function nextTab() {
        tabSwitcher.newIndex = (currentTabIndex + 1) % tabCount;
        tabSwitcher.start();
    }

    function prevTab() {
        tabSwitcher.newIndex = (currentTabIndex - 1 + tabCount) % tabCount;
        tabSwitcher.start();
    }

    SequentialAnimation {
        id: tabSwitcher
        property int newIndex: 0
        
        NumberAnimation { target: tabContainer; property: "opacity"; to: 0; duration: 100; easing.type: Easing.OutCubic }
        PropertyAction { target: root; property: "currentTabIndex"; value: tabSwitcher.newIndex }
        NumberAnimation { target: tabContainer; property: "opacity"; to: 1; duration: 100; easing.type: Easing.InCubic }
    }

    // Tab Content Container
    Item {
        id: tabContainer
        anchors.fill: parent
        anchors.margins: 60

        Loader {
            id: tabLoader
            anchors.fill: parent
            sourceComponent: tabs[currentTabIndex]
            onLoaded: {
                // Pass the shared clock to tabs that need it
                if (item && item.hasOwnProperty("now")) {
                    item.now = Qt.binding(function() { return root.now; });
                }
            }
        }
    }
}
