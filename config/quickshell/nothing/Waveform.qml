import QtQuick

// Nothing-style progress bar: a row of rounded bars, played part white. Heights are pseudo-random
// but seeded by the track, so each song keeps its shape. (A real waveform would mean decoding audio.)
Item {
    id: root

    property string seed
    property real progress: 0 // 0..1

    signal seek(real fraction)

    readonly property int barWidth: 2
    readonly property int gap: 2
    readonly property int count: Math.max(0, Math.floor((width + gap) / (barWidth + gap)))

    readonly property var heights: {
        // FNV-1a hash of the seed feeds a small LCG
        let h = 2166136261;
        for (let i = 0; i < seed.length; i++)
            h = Math.imul(h ^ seed.charCodeAt(i), 16777619) >>> 0;
        const out = [];
        for (let i = 0; i < count; i++) {
            h = (Math.imul(h, 1664525) + 1013904223) >>> 0;
            const envelope = 0.55 + 0.45 * Math.sin(i / count * Math.PI); // taller in the middle
            out.push(0.2 + 0.8 * envelope * (h / 4294967296));
        }
        return out;
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Repeater {
            model: root.count

            Rectangle {
                required property int index

                anchors.verticalCenter: parent.verticalCenter
                width: root.barWidth
                height: Math.max(2, root.height * (root.heights[index] ?? 0.2))
                radius: 1
                color: index / root.count < root.progress ? Theme.text : Theme.track
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.seek(Math.max(0, Math.min(1, mouse.x / width)))
    }
}
