import QtQuick

// The left-hand widget stack: calendar and Bluetooth tiles, then media and screen time.
Column {
    spacing: Theme.gapL

    Row {
        id: topRow
        spacing: Theme.gapL

        CalendarTile {}
        BluetoothTile {}
    }

    // both as wide as the row above
    MediaWidget {
        implicitWidth: topRow.implicitWidth
    }

    ScreenTimeWidget {
        implicitWidth: topRow.implicitWidth
    }
}
