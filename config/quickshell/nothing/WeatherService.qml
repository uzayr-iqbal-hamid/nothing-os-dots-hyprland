pragma Singleton
import QtQuick
import Quickshell

// One weather source shared by every bar (and later the desktop widgets).
// Open-Meteo, no API key. Location from Config, or by IP when unset.
Singleton {
    id: root

    property bool ready: false
    property real temp: NaN
    property real tempMax: NaN
    property real tempMin: NaN
    property int code: -1 // WMO weather code
    property bool isDay: true
    property string city: ""

    readonly property string description: {
        if (code < 0)
            return "";
        if (code === 0)
            return isDay ? "Clear" : "Clear night";
        if (code === 1)
            return "Mostly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code === 45 || code === 48)
            return "Fog";
        if (code >= 51 && code <= 57)
            return "Drizzle";
        if (code >= 61 && code <= 67)
            return "Rain";
        if (code >= 71 && code <= 77)
            return "Snow";
        if (code >= 80 && code <= 82)
            return "Showers";
        if (code === 85 || code === 86)
            return "Snow showers";
        if (code >= 95)
            return "Thunderstorm";
        return "";
    }

    property real _lat: Config.weatherLatitude
    property real _lon: Config.weatherLongitude

    function _get(url, onJson) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.warn("weather: request failed", xhr.status, url);
                retry.restart();
                return;
            }
            try {
                onJson(JSON.parse(xhr.responseText));
            } catch (e) {
                console.warn("weather: bad response", e);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function refresh() {
        if (!isNaN(_lat) && !isNaN(_lon)) {
            _fetchForecast();
            return;
        }
        _get("https://ipinfo.io/json", d => {
            const loc = (d.loc || "").split(",").map(Number);
            if (loc.length !== 2 || isNaN(loc[0]) || isNaN(loc[1]))
                return;
            _lat = loc[0];
            _lon = loc[1];
            city = d.city || "";
            _fetchForecast();
        });
    }

    function _fetchForecast() {
        _get(`https://api.open-meteo.com/v1/forecast?latitude=${_lat}&longitude=${_lon}`
             + "&current=temperature_2m,weather_code,is_day"
             + "&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto", d => {
            temp = d.current.temperature_2m;
            code = d.current.weather_code;
            isDay = d.current.is_day === 1;
            tempMax = d.daily.temperature_2m_max[0];
            tempMin = d.daily.temperature_2m_min[0];
            ready = true;
        });
    }

    Timer {
        interval: Config.weatherRefreshMinutes * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // the network often isn't up yet at login
    Timer {
        id: retry
        interval: 60 * 1000
        onTriggered: root.refresh()
    }
}
