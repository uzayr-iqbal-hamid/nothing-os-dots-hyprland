pragma Singleton
import QtQuick
import Quickshell

// Nerd Font (JetBrainsMono NF) glyphs, kept as numeric codepoints because raw private-use
// characters don't survive editing. Each one was checked by rendering it.
Singleton {
    function glyph(cp) {
        return String.fromCodePoint(cp);
    }

    readonly property string ethernet: glyph(0xF0200)
    readonly property string offline: glyph(0xF05AA) // wifi_off
    readonly property string bluetooth: glyph(0xF00AF)
    readonly property string bluetoothOff: glyph(0xF00B2)
    readonly property string skipPrevious: glyph(0xF04AE)
    readonly property string skipNext: glyph(0xF04AD)
    readonly property string play: glyph(0xF040A)
    readonly property string pause: glyph(0xF03E4)
    readonly property string music: glyph(0xF075A)
    readonly property string lock: glyph(0xF033E)
    readonly property string power: glyph(0xF0425)
    readonly property string bell: glyph(0xF009A)
    readonly property string bellOff: glyph(0xF009B)
    readonly property string coffee: glyph(0xF0176)
    readonly property string phone: glyph(0xF011C) // cellphone
    readonly property string glyphLights: glyph(0xF0335) // lightbulb
    readonly property string nightLight: glyph(0xF0F65) // crescent moon
    readonly property string cpu: glyph(0xF0EE0)
    readonly property string memory: glyph(0xF035B)
    readonly property string gpu: glyph(0xF08AE) // expansion card
    readonly property string brightness: glyph(0xF00DF) // sun in a circle
    readonly property string mic: glyph(0xF036C)
    readonly property string micOff: glyph(0xF036D)
    readonly property string sleep: glyph(0xF0904) // moon (power_sleep)
    readonly property string logout: glyph(0xF0343)
    readonly property string restart: glyph(0xF0709)

    // BlueZ device icon name (audio-headset, input-mouse, ...) -> glyph
    function btDevice(icon) {
        if (icon.startsWith("audio-head"))
            return glyph(0xF184F); // earbuds
        if (icon.startsWith("audio"))
            return glyph(0xF04C3); // speaker
        if (icon === "input-mouse")
            return glyph(0xF037D);
        if (icon === "input-keyboard")
            return glyph(0xF030C);
        if (icon === "input-gaming")
            return glyph(0xF0296);
        if (icon === "phone")
            return glyph(0xF011C);
        if (icon === "computer")
            return glyph(0xF0322);
        return glyph(0xF00AF); // bluetooth
    }

    function wifi(strength) {
        return glyph(strength > 0.75 ? 0xF0928 : strength > 0.5 ? 0xF0925 : strength > 0.25 ? 0xF0922 : 0xF091F);
    }

    function volume(level, muted) {
        if (muted || level <= 0)
            return glyph(0xF075F); // speaker with x
        return glyph(level > 0.66 ? 0xF057E : level > 0.33 ? 0xF0580 : 0xF057F);
    }

    // WMO weather code -> glyph
    function weather(code, isDay) {
        if (code === 0)
            return glyph(isDay ? 0xF0599 : 0xF0594);
        if (code === 1 || code === 2)
            return glyph(isDay ? 0xF0595 : 0xF0F31);
        if (code === 45 || code === 48)
            return glyph(0xF0591);
        if (code >= 95)
            return glyph(0xF0593);
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return glyph(0xF0598);
        if (code === 65 || code === 67 || code === 82)
            return glyph(0xF0596);
        if (code >= 51)
            return glyph(0xF0597);
        return glyph(0xF0590); // 3 overcast, and anything unknown
    }
}
