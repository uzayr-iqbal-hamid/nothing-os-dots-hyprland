import QtQuick
import QtQuick.Effects
import Quickshell

// An app's icon, made monochrome to fit the palette. Takes an app key as DockState uses them
// (desktop entry id, else window class).
// A plain Image with a fixed decode size, not IconImage: IconImage decodes at the item's current
// size, which is 0 before layout (SVGs then decode at full size, and the first frame came out wrong).
Item {
    id: root

    required property string appKey
    property int decodeSize: 80
    readonly property var entry: DesktopEntries.heuristicLookup(appKey)

    Image {
        id: image
        anchors.fill: parent
        visible: false // drawn through the effect below
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(root.decodeSize, root.decodeSize)
        mipmap: true
        source: {
            const name = root.entry?.icon ?? "";
            if (name.startsWith("/"))
                return "file://" + name;
            return Quickshell.iconPath(name || root.appKey, "application-x-executable");
        }
    }

    MultiEffect {
        anchors.fill: image
        source: image
        saturation: -1
        brightness: 0.1
        contrast: 0.25
    }
}
