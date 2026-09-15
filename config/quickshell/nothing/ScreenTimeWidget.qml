import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Screen time tile: today's active time, a bar split by the top apps, and those apps with their times.
// Models are lists of app keys (strings), so delegates stay put as the numbers tick up.
Rectangle {
    id: root

    readonly property real total: ScreenTimeService.todayTotal
    readonly property var leaders: ScreenTimeService.todayRanking.slice(0, 3)
    // most used app in the accent, then white, then grey
    readonly property var shades: [Theme.accent, Theme.text, Theme.textDim]

    function duration(seconds) {
        if (seconds > 0 && seconds < 60)
            return "<1m";
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        return hours > 0 ? `${hours}h ${minutes % 60}m` : `${minutes}m`;
    }

    implicitWidth: 400
    implicitHeight: 200
    radius: Theme.radiusWidget
    color: Theme.widget

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 0

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "SCREEN TIME"
                color: Theme.textDim
                font.family: Theme.fontLabel
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }
            Text {
                text: "TODAY"
                color: Theme.textFaint
                font.family: Theme.fontLabel
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }
        }

        Text {
            Layout.topMargin: 2
            text: root.duration(root.total)
            color: Theme.text
            font.family: Theme.fontSans
            font.pixelSize: 34
            font.variableAxes: ({ "wght": 700, "opsz": 32 })
        }

        ClippingRectangle {
            id: bar
            Layout.fillWidth: true
            Layout.topMargin: 6
            implicitHeight: 6
            radius: 3
            color: Theme.track

            Row {
                height: bar.height
                spacing: 2

                Repeater {
                    model: ScriptModel {
                        values: root.leaders
                    }

                    Rectangle {
                        required property string modelData
                        required property int index

                        height: bar.height
                        width: bar.width * ScreenTimeService.todaySeconds(modelData) / Math.max(root.total, 1)
                        color: root.shades[index]
                    }
                }
            }
        }

        Text {
            visible: root.leaders.length === 0
            Layout.topMargin: 14
            text: "NOTHING COUNTED YET"
            color: Theme.textFaint
            font.family: Theme.fontLabel
            font.pixelSize: 9
            font.letterSpacing: Theme.labelSpacing
        }

        Repeater {
            model: ScriptModel {
                values: root.leaders
            }

            RowLayout {
                id: appRow

                required property string modelData
                required property int index

                Layout.fillWidth: true
                Layout.topMargin: index === 0 ? 12 : 6
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: root.shades[appRow.index]
                }
                AppIcon {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    appKey: appRow.modelData
                    decodeSize: 36
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: DesktopEntries.heuristicLookup(appRow.modelData)?.name ?? appRow.modelData
                    color: Theme.text
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    font.variableAxes: ({ "wght": 500 })
                }
                Text {
                    text: root.duration(ScreenTimeService.todaySeconds(appRow.modelData))
                    color: Theme.textDim
                    font.family: Theme.fontLabel
                    font.pixelSize: 11
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
