import QtQuick
import Quickshell
import Quickshell.Wayland

// Glyph lights for one screen: seven thin strips hugging the edges, lit by GlyphService. The layer
// covers the whole screen but is click-through, and only mapped while something is lit.
PanelWindow {
    id: glyph

    readonly property int thickness: Config.glyphThickness
    readonly property int inset: Config.glyphInset
    readonly property int corner: Config.glyphCornerGap
    readonly property int split: 28 // gap between the two strips on a side
    readonly property real barGap: Config.glyphTopGap / 2

    visible: GlyphService.active
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "nothing-glyph"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    // Clockwise from the top left, matching GlyphService's segment order. The top pair leaves room
    // for the bar; the bottom strip is the progress bar.
    Segment {
        edge: "top"
        index: 0
        from: glyph.corner
        to: glyph.width / 2 - glyph.barGap
    }
    Segment {
        edge: "top"
        index: 1
        from: glyph.width / 2 + glyph.barGap
        to: glyph.width - glyph.corner
    }
    Segment {
        edge: "right"
        index: 2
        from: glyph.corner
        to: glyph.height / 2 - glyph.split / 2
    }
    Segment {
        edge: "right"
        index: 3
        from: glyph.height / 2 + glyph.split / 2
        to: glyph.height - glyph.corner
    }
    Segment {
        edge: "bottom"
        index: 4
        from: glyph.width * 0.22
        to: glyph.width * 0.78
        showsProgress: true
    }
    Segment {
        edge: "left"
        index: 5
        from: glyph.height / 2 + glyph.split / 2
        to: glyph.height - glyph.corner
    }
    Segment {
        edge: "left"
        index: 6
        from: glyph.corner
        to: glyph.height / 2 - glyph.split / 2
    }

    component Segment: Item {
        id: segment

        required property string edge
        required property int index
        required property real from
        required property real to
        property bool showsProgress: false

        readonly property bool horizontal: edge === "top" || edge === "bottom"
        readonly property real length: Math.max(0, to - from)
        readonly property real level: GlyphService.levels[index] ?? 0
        readonly property bool progressing: showsProgress && GlyphService.progress >= 0
        readonly property real filled: progressing ? length * GlyphService.progress : 0
        // Lit brightness; the progress fill counts as fully lit where it reaches.
        readonly property real glow: progressing ? 1 : level
        readonly property color tint: GlyphService.tint
        readonly property int depth: Config.glyphGlow

        x: horizontal ? from : edge === "left" ? glyph.inset : glyph.width - glyph.inset - glyph.thickness
        y: !horizontal ? from : edge === "top" ? glyph.inset : glyph.height - glyph.inset - glyph.thickness
        width: horizontal ? length : glyph.thickness
        height: horizontal ? glyph.thickness : length

        // Soft light spilling onto the screen, fading away from the edge.
        Rectangle {
            x: segment.edge === "left" ? segment.width : segment.edge === "right" ? -segment.depth : 0
            y: segment.edge === "top" ? segment.height : segment.edge === "bottom" ? -segment.depth : 0
            width: segment.horizontal ? (segment.progressing ? segment.filled : segment.length) : segment.depth
            height: segment.horizontal ? segment.depth : segment.length
            opacity: segment.glow
            gradient: Gradient {
                orientation: segment.horizontal ? Gradient.Vertical : Gradient.Horizontal
                // Brightest against the strip: at the start for top/left, at the end for bottom/right.
                GradientStop {
                    position: 0
                    color: Qt.rgba(segment.tint.r, segment.tint.g, segment.tint.b, segment.edge === "top" || segment.edge === "left" ? 0.32 : 0)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(segment.tint.r, segment.tint.g, segment.tint.b, segment.edge === "top" || segment.edge === "left" ? 0 : 0.32)
                }
            }
        }

        // The strip itself. Unlit segments stay faintly visible while the layer is up, so the
        // shape of the whole interface reads even when one part is lit.
        Rectangle {
            anchors.fill: parent
            radius: glyph.thickness / 2
            color: segment.tint
            opacity: segment.progressing ? 0.16 : Math.max(0.07, segment.level)
        }

        Rectangle {
            visible: segment.progressing
            width: segment.filled
            height: parent.height
            radius: glyph.thickness / 2
            color: Theme.text

            Behavior on width {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
