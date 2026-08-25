
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Scope {
    id: launcherScope

    property bool isOpen: false
    property var allApps: []
    property string pendingName: ""

    function parseApps(line) {
        if (line.startsWith("Name=")) {
            pendingName = line.replace("Name=", "").trim();
        } else if (line.startsWith("Exec=") && pendingName !== "") {
            let exec = line.replace("Exec=", "").replace(/%[fFuU]/g, "").trim();
            allApps.push({ name: pendingName, exec: exec });
            pendingName = "";
        }
    }

    function filterModel() {
        filteredApps.clear();
        let query = searchInput.text.toLowerCase();
        let count = 0;
        for (let app of allApps) {
            if (app.name.toLowerCase().includes(query)) {
                filteredApps.append(app);
                count++;
                if (count >= 15) break;
            }
        }
        if (filteredApps.count > 0) {
            appList.currentIndex = 0;
        }
    }

    function launchApp(execCmd) {
        if (!execCmd) return;
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + execCmd.replace(/"/g, '\\"') + ' &"]; running: true }', launcherScope);
        launcherScope.isOpen = false;
    }

    IpcHandler {
        target: "launcher"
        function toggle() { launcherScope.isOpen = !launcherScope.isOpen; }
        function open() { launcherScope.isOpen = true; }
        function close() { launcherScope.isOpen = false; }
    }

    FloatingWindow {
        id: win
        title: "App Launcher"
        visible: launcherScope.isOpen

        implicitWidth: 500
        implicitHeight: 380
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                searchInput.text = "";
                filterModel();
                searchInput.forceActiveFocus();
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

                Rectangle {
                    width: parent.width
                    height: 36
                    color: theme.surface
                    radius: 8

                    TextField {
                        id: searchInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        color: theme.text
                        font.pixelSize: 14
                        focus: true
                        placeholderText: "Search applications..."
                        placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.4)
                        background: Item {}

                        onTextChanged: launcherScope.filterModel()

                        Keys.onDownPressed: {
                            if (filteredApps.count > 0) {
                                appList.currentIndex = Math.min(appList.currentIndex + 1, filteredApps.count - 1);
                            }
                        }

                        Keys.onUpPressed: {
                            if (filteredApps.count > 0) {
                                appList.currentIndex = Math.max(appList.currentIndex - 1, 0);
                            }
                        }

                        Keys.onReturnPressed: {
                            if (filteredApps.count > 0 && appList.currentIndex >= 0) {
                                let item = filteredApps.get(appList.currentIndex);
                                if (item) launcherScope.launchApp(item.exec);
                            }
                        }

                        Keys.onEscapePressed: launcherScope.isOpen = false
                    }
                }

                ListView {
                    id: appList
                    width: parent.width
                    height: parent.height - 48
                    clip: true
                    spacing: 4

                    model: ListModel { id: filteredApps }

                    delegate: Rectangle {
                        width: appList.width
                        height: 36
                        color: index === appList.currentIndex ? theme.accent : "transparent"
                        radius: 6

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            spacing: 10

                            Text {
                                text: "󰵆"
                                anchors.verticalCenter: parent.verticalCenter
                                color: index === appList.currentIndex ? theme.bg : theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            Text {
                                text: model.name
                                anchors.verticalCenter: parent.verticalCenter
                                color: index === appList.currentIndex ? theme.bg : theme.text
                                font.bold: true
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: launcherScope.launchApp(model.exec)
                        }
                    }
                }
            }
        }

        Process {
            id: appFetchProc
            command: ["sh", "-c", "for f in /run/current-system/sw/share/applications/*.desktop ~/.local/share/applications/*.desktop; do [ -f \"$f\" ] || continue; grep -Eq \"^(NoDisplay|Hidden)=true\" \"$f\" && continue; n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); e=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2-); [ -n \"$n\" ] && [ -n \"$e\" ] && echo \"Name=$n\" && echo \"Exec=$e\"; done 2>/dev/null"]
            running: true 
            
            stdout: SplitParser {
                splitMarker: "\n"
                onRead: data => launcherScope.parseApps(data)
            }
        }
    }
}
