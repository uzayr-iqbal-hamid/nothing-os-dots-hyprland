pragma Singleton
import QtQuick
import Quickshell

// Nothing OS design tokens: the one source of truth for the Nothing shell.
// Non-QML apps (hyprland, rofi, swaync, kitty...) get the same values through
// the static templates in ~/.config/wallust/templates (wallust no longer derives colors).
Singleton {
    // surfaces
    // Colours are #AARRGGBB where translucent; the blur behind the translucent layers comes from
    // layerrules in ~/.config/hypr/UserConfigs/WindowRules.conf.
    readonly property color bg: "#000000"         // bar
    readonly property color glass: "#99000000"    // dock, control center, dock tooltip/menu
    // white overlays, not greys: over black they're #1A1A1A / #242424, over glass they stay see-through
    readonly property color surface: "#1AFFFFFF"  // cards inside panels
    readonly property color surfaceHi: "#24FFFFFF" // hovered card, icon wells
    readonly property color outline: "#2E2E2E"    // hairline borders
    readonly property color track: "#3A3A3A"      // slider / progress / waveform background
    readonly property color widget: "#591E1E1E"   // desktop widget tiles

    // text
    readonly property color text: "#FFFFFF"
    readonly property color textDim: "#8C8C8C"    // uppercase labels
    readonly property color textFaint: "#5A5A5A"  // disabled, placeholders

    // the single accent + inverted pill toggles
    readonly property color accent: "#D71921"
    readonly property color pill: "#FFFFFF"
    readonly property color pillText: "#000000"  // not "onPill": QML treats on<Upper> as a signal handler

    // type
    readonly property string fontDot: "Ndot 57"                 // clocks, big numerals
    readonly property string fontDotCaps: "Ndot57Caps"          // dot-matrix words
    readonly property string fontHead: "NType 82"               // a SERIF (Nothing's widget numerals); no ° glyph, not for UI text
    readonly property string fontLabel: "Lettera Mono LL"       // small uppercase labels, values
    readonly property string fontSans: "Adwaita Sans"           // bold headlines on desktop widget tiles
    readonly property string fontSerif: "New York Extra Large"
    readonly property string fontIcon: "JetBrainsMono Nerd Font"
    readonly property real labelSpacing: 1.2                    // letterSpacing for uppercase labels

    // shape
    readonly property int radiusPanel: 20
    readonly property int radiusCard: 16
    readonly property int radiusSmall: 10
    readonly property int radiusPill: 999
    readonly property int radiusWidget: 24
    readonly property int hairline: 1

    // spacing, 4px grid
    readonly property int gapXs: 4
    readonly property int gapS: 8
    readonly property int gapM: 12
    readonly property int gapL: 16
    readonly property int gapXl: 24

    // motion
    readonly property int animFast: 120
    readonly property int animMed: 220
    readonly property int easing: Easing.OutCubic
}
