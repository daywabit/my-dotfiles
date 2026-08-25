import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Scope {
    id: powerScope

    property bool isOpen: false

    function execute(cmd) {
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd + '"]; running: true }', powerScope);
        powerScope.isOpen = false;
    }

    IpcHandler {
        target: "power"
        function toggle() { powerScope.isOpen = !powerScope.isOpen; }
        function open() { powerScope.isOpen = true; }
        function close() { powerScope.isOpen = false; }
    }

    FloatingWindow {
        id: win
        title: "Power Menu"
        visible: powerScope.isOpen

        implicitWidth: 540
        implicitHeight: 130
        color: "transparent"

        Colors { id: theme }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.90)
            radius: 12
            border.color: theme.accent
            border.width: 1

            FocusScope {
                anchors.fill: parent
                focus: powerScope.isOpen

                Keys.onEscapePressed: powerScope.isOpen = false

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Repeater {
                        model: [
                            { name: "Lock",     icon: "󰌾", cmd: "quickshell ipc call lock open" },
                            { name: "Shutdown", icon: "󰐥", cmd: "systemctl poweroff" },
                            { name: "Reboot",   icon: "󰜉", cmd: "systemctl reboot" },
                            { name: "Suspend",  icon: "󰤄", cmd: "systemctl suspend" },
                            { name: "Log Out",  icon: "󰍃", cmd: "pkill -KILL -u $USER" }
                        ]

                        Rectangle {
                            width: 90
                            height: 85
                            radius: 10
                            color: btnArea.containsMouse ? theme.accent : theme.surface
                            border.color: btnArea.containsMouse ? theme.accent : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    color: btnArea.containsMouse ? theme.bg : theme.accent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 24
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.name
                                    color: btnArea.containsMouse ? theme.bg : theme.text
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                id: btnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: powerScope.execute(modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }
}
