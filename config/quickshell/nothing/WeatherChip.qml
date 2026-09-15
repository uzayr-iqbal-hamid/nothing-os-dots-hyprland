import QtQuick

// Weather glyph + current temperature.
Row {
    spacing: 5
    visible: WeatherService.ready

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.weather(WeatherService.code, WeatherService.isDay)
        color: Theme.textDim
        font.family: Theme.fontIcon
        font.pixelSize: 14
    }

    // Lettera Mono gives "°" a full monospace cell; pull it in against the number
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: -3

        Text {
            text: Math.round(WeatherService.temp)
            color: Theme.textDim
            font.family: Theme.fontLabel
            font.pixelSize: 12
        }
        Text {
            text: "°"
            color: Theme.textDim
            font.family: Theme.fontLabel
            font.pixelSize: 12
        }
    }
}
