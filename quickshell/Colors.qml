import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    property color bg: "#1e1e2e"
    property color fg: "#cdd6f4"
    property color surface: "#181825"
    property color accent: "#89b4fa"
    property color text: "#cdd6f4"

    function parseJson(str) {
        let cleaned = str.trim();
        if (cleaned.length === 0) return;
        try {
            let json = JSON.parse(cleaned);
            if (json.bg) theme.bg = Qt.color(json.bg);
            if (json.fg) theme.fg = Qt.color(json.fg);
            if (json.surface) theme.surface = Qt.color(json.surface);
            if (json.accent) theme.accent = Qt.color(json.accent);
            if (json.text) theme.text = Qt.color(json.text);
            console.log("[Quickshell] Updated theme colors!");
        } catch (e) {}
    }

    function reload() {
        colorProc.running = false;
        colorProc.running = true;
    }

    property Timer reloadTimer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: theme.reload()
    }

    property Process colorProc: Process {
        id: colorProc
        command: ["sh", "-c", "cat ~/.cache/colors.json 2>/dev/null && echo ''"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => theme.parseJson(data)
        }
    }

    Component.onCompleted: theme.reload()
}
