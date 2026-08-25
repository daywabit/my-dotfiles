import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Scope {
    id: wallpaperScope

    property bool isOpen: false

    IpcHandler {
        target: "wallpaper"
        function toggle() { wallpaperScope.isOpen = !wallpaperScope.isOpen; }
        function open() { wallpaperScope.isOpen = true; }
        function close() { wallpaperScope.isOpen = false; }
    }

    FloatingWindow {
        id: win
        title: "Wallpaper Picker"
        visible: wallpaperScope.isOpen

        implicitWidth: 800
        implicitHeight: 520
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                wallModel.clear();
                wallFetchProc.running = false;
                wallFetchProc.running = true;
            }
        }

        Colors { id: theme }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.95)
            radius: 12
            border.color: theme.accent
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Select Wallpaper"
                    color: theme.text
                    font.pixelSize: 16
                    font.bold: true
                }

                GridView {
                    id: grid
                    width: parent.width
                    height: parent.height - 40
                    cellWidth: 190
                    cellHeight: 125
                    clip: true

                    model: ListModel { id: wallModel }

                    delegate: Rectangle {
                        width: 180
                        height: 115
                        radius: 8
                        color: theme.surface
                        border.color: mouseArea.containsMouse ? theme.accent : "transparent"
                        border.width: 2
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: "file://" + model.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            
                            // Restricts Qt from decoding full 4K images into RAM
                            sourceSize.width: 180
                            sourceSize.height: 115
                            cache: true
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                let imgPath = model.path;
                                let safePath = imgPath.replace(/'/g, "'\\''");
                                let cmd = "~/.config/matugen/run.sh '" + safePath + "'";
                                
                                Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd.replace(/"/g, '\\"') + '"]; running: true }', wallpaperScope);
                                wallpaperScope.isOpen = false;
                            }
                        }
                    }
                }
            }
        }

        Process {
            id: wallFetchProc
            command: ["sh", "-c", "find ~/Downloads ~/Pictures -maxdepth 3 \\( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \\) 2>/dev/null"]
            running: false

            stdout: SplitParser {
                splitMarker: "\n"
                onRead: data => {
                    let path = data.trim();
                    if (path.length > 0) {
                        wallModel.append({ path: path });
                    }
                }
            }
        }
    }
}
