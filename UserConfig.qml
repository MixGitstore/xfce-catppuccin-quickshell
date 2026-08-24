import QtQuick
import Quickshell

QtObject {
    // Change these three values to your location. Coordinates can be found at
    // https://www.openstreetmap.org or https://www.latlong.net.
    readonly property string weatherCity: "Iași"
    readonly property real weatherLatitude: 47.1585
    readonly property real weatherLongitude: 27.6014

    // "auto" lets Open-Meteo select the correct timezone from the coordinates.
    readonly property string weatherTimezone: "auto"

    // The standard ~/.face image is optional. The system icon is used if the
    // file is not available or cannot be decoded.
    readonly property string profileName:
        Quickshell.env("USER") || Quickshell.env("LOGNAME") || "user"
    readonly property string profileImage:
        "file://" + (Quickshell.env("HOME") || "") + "/.face"
}
