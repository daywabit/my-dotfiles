import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.SystemTray

Scope {
    id: mainScope

    // Top Bar Panel (Hides automatically when lock screen is open)
    PanelWindow {
        id: root
        visible: !lockComp.isOpen

        Colors { id: theme }

        anchors {
            top: true
            left: true
            right: true
        }
        
        implicitHeight: 30
        color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.5)

        property int currentWs: 1
        property string batIcon: "󰁹"
        property string batPercent: "50%"
        property bool keepAwake: false

        function toggleKeepAwake() {
            root.keepAwake = !root.keepAwake;
            var cmd = root.keepAwake 
                ? "xset s off -dpms"
                : "xset s on +dpms";
            
            Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd + '"]; running: true }', root);
        }

        Process {
            id: wsProc
            command: ["sh", "-c", "xprop -root _NET_CURRENT_DESKTOP | awk '{print $3 + 1}'"]
            running: true
            stdout: SplitParser {
                onRead: data => {
                    let parsed = parseInt(data.trim());
                    if (!isNaN(parsed)) root.currentWs = parsed;
                }
            }
        }

        Timer {
            interval: 200
            running: true
            repeat: true
            onTriggered: wsProc.running = true
        }

        Process {
            id: batProc
            command: ["sh", "-c", "echo $(cat /sys/class/power_supply/BAT0/capacity):$(cat /sys/class/power_supply/BAT0/status)"]
            running: true
            stdout: SplitParser {
                onRead: data => {
                    let raw = data.trim();
                    if (raw.indexOf(":") !== -1) {
                        let parts = raw.split(":");
                        let cap = parseInt(parts[0]);
                        let status = parts[1].trim();

                        if (!isNaN(cap)) {
                            root.batPercent = cap + "%";
                            if (status === "Charging") root.batIcon = "󰂄";
                            else if (status === "Full") root.batIcon = "󰁹";
                            else {
                                if (cap >= 90) root.batIcon = "󰁹";
                                else if (cap >= 70) root.batIcon = "󰂀";
                                else if (cap >= 50) root.batIcon = "󰁾";
                                else if (cap >= 30) root.batIcon = "󰁼";
                                else if (cap >= 10) root.batIcon = "󰁺";
                                else root.batIcon = "󰂎";
                            }
                        }
                    }
                }
            }
        }

        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: batProc.running = true
        }

        // --- LEFT SECTION ---
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 28
                height: 22
                color: theme.surface
                radius: 6

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: theme.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                }
            }

            Row {
                spacing: 4

                Repeater {
                    model: [1, 2, 3, 4, 5]

                    Rectangle {
                        required property int modelData
                        
                        width: root.currentWs === modelData ? 28 : 22
                        height: 22
                        radius: 6
                        color: root.currentWs === modelData ? theme.accent : theme.surface

                        Behavior on width { NumberAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.toString()
                            color: root.currentWs === parent.modelData ? theme.bg : theme.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var wsIndex = parent.modelData - 1;
                                var cmd = "xdotool set_desktop " + wsIndex;
                                Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd + '"]; running: true }', parent);
                            }
                        }
                    }
                }
            }
        }

        // --- CENTER SECTION ---
        Rectangle {
            anchors.centerIn: parent
            width: 90
            height: 22
            color: theme.surface
            radius: 6

            Text {
                id: clockText
                anchors.centerIn: parent
                text: Qt.formatDateTime(new Date(), "hh:mm AP")
                color: theme.text
                font.bold: true
                font.pixelSize: 11
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "hh:mm AP")
            }
        }

        // --- RIGHT SECTION ---
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // System Tray
            Row {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: SystemTray.items

                    Rectangle {
                        width: 22
                        height: 22
                        color: theme.surface
                        radius: 6

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: modelData.icon
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) modelData.openMenu();
                                else modelData.activate();
                            }
                        }
                    }
                }
            }

            // Keep Awake Toggle Button
            Rectangle {
                width: 28
                height: 22
                color: root.keepAwake ? theme.accent : theme.surface
                radius: 6

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: root.keepAwake ? "󰅶" : "󰾪"
                    color: root.keepAwake ? theme.bg : theme.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggleKeepAwake()
                }
            }

            // Battery Widget
            Rectangle {
                width: 75
                height: 22
                color: theme.surface
                radius: 6

                Text {
                    anchors.centerIn: parent
                    text: root.batIcon + " " + root.batPercent
                    color: theme.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 11
                }
            }

            // Power Menu Toggle Button
            Rectangle {
                width: 28
                height: 22
                color: theme.surface
                radius: 6

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    color: theme.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "quickshell ipc call power toggle"]; running: true }', root);
                    }
                }
            }
        }
    }

    // App Launcher Overlay Component
    Launcher {}

    // Wallpaper Picker Component
    WallpaperPicker {}

    // Power Menu Component
    PowerMenu {}

    // Lock Screen Component
    LockScreen { id: lockComp }
}
