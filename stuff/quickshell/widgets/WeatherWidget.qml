import QtQuick
import Quickshell.Io

Item {
    id: root
    width: 240
    height: 80

    property string temperature: "--°F"
    property string condition: "..."
    property string location: "..."
    property string weatherIcon: "\uDB81\uDD99" // nf-md-weather_sunny (default)

    // Nerd Font family for weather icons
    property string iconFont: "JetBrainsMono Nerd Font"

    // Map weather condition strings to Nerd Font Material Design weather icons
    function conditionToIcon(cond) {
        var c = cond.toLowerCase();
        if (c.indexOf("thunder") !== -1 || c.indexOf("storm") !== -1) return "\uDB81\uDD93"; // nf-md-weather_lightning
        if (c.indexOf("snow") !== -1 || c.indexOf("blizzard") !== -1 || c.indexOf("sleet") !== -1 || c.indexOf("ice") !== -1) return "\uDB81\uDD98"; // nf-md-weather_snowy
        if (c.indexOf("rain") !== -1 || c.indexOf("drizzle") !== -1 || c.indexOf("shower") !== -1) return "\uDB81\uDD97"; // nf-md-weather_rainy
        if (c.indexOf("fog") !== -1 || c.indexOf("mist") !== -1 || c.indexOf("haze") !== -1) return "\uDB81\uDD91"; // nf-md-weather_fog
        if (c.indexOf("partly") !== -1) return "\uDB81\uDD95"; // nf-md-weather_partly_cloudy
        if (c.indexOf("cloud") !== -1 || c.indexOf("overcast") !== -1) return "\uDB81\uDD90"; // nf-md-weather_cloudy
        if (c.indexOf("sunny") !== -1 || c.indexOf("clear") !== -1) return "\uDB81\uDD99"; // nf-md-weather_sunny
        return "\uDB81\uDD99";
    }

    Process {
        id: weatherProc
        command: ["curl", "-s", "--max-time", "5", "wttr.in/?u&format=%t|%C|%l"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text.trim();
                var parts = raw.split("|");
                if (parts.length >= 3) {
                    root.temperature = parts[0].replace("+", "").trim();
                    root.condition = parts[1].trim();
                    // Take just the city name (before the first comma)
                    root.location = parts[2].split(",")[0].trim();
                    root.weatherIcon = root.conditionToIcon(parts[1]);
                }
            }
        }
    }

    // Refresh every 10 minutes
    Timer {
        interval: 600000
        repeat: true
        running: true
        onTriggered: weatherProc.running = true
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Text {
            text: root.weatherIcon
            font.pixelSize: 36
            font.family: root.iconFont
            anchors.verticalCenter: parent.verticalCenter
            color: "#333333"
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: root.temperature
                font.pixelSize: 28
                font.bold: true
                color: "#333333"
            }

            Text {
                text: root.condition
                font.pixelSize: 13
                color: "#666666"
            }

            Text {
                text: root.location
                font.pixelSize: 13
                color: "#888888"
            }
        }
    }
}
