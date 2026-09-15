pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The player to show everywhere: the one playing, else the first one around.
Singleton {
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
}
