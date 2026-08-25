import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Scope {
    id: lockScope

    property bool isOpen: false
    property bool isError: false

    IpcHandler {
        target: "lock"
        function toggle() { lockScope.isOpen = !lockScope.isOpen; }
        function open() { lockScope.isOpen = true; }
        function close() { lockScope.isOpen = false; }
    }

    FloatingWindow {
        id: win
        title: "Lock Screen"
        visible: lockScope.isOpen

        implicitWidth: Screen.width
        implicitHeight: Screen.height
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                passInput.text = "";
                lockScope.isError = false;
                passInput.forceActiveFocus();
            }
        }

        Colors { id: theme }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.96)

            FocusScope {
                anchors.fill: parent
                focus: lockScope.isOpen

                Column {
                    anchors.centerIn: parent
                    spacing: 16

                    // Clock Display
                    Text {
                        id: clockDisplay
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(new Date(), "hh:mm")
                        color: theme.accent
                        font.pixelSize: 88
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    // Date Display
                    Text {
                        id: dateDisplay
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Timer {
                        interval: 1000
                        running: lockScope.isOpen
                        repeat: true
                        onTriggered: {
                            clockDisplay.text = Qt.formatDateTime(new Date(), "hh:mm");
                            dateDisplay.text = Qt.formatDateTime(new Date(), "dddd, MMMM d");
                        }
                    }

                    Item { width: 1; height: 35 }

                    // User Profile Badge
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 150
                        height: 38
                        color: theme.surface
                        radius: 19
                        border.color: theme.accent
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: ""
                                color: theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "daywa"
                                color: theme.text
                                font.pixelSize: 13
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Password Field
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 270
                        height: 42
                        color: theme.surface
                        radius: 10
                        border.color: lockScope.isError ? "#ffb4ab" : (passInput.activeFocus ? theme.accent : "transparent")
                        border.width: 2

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextField {
                            id: passInput
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: Text.AlignVCenter
                            echoMode: TextInput.Password
                            color: theme.text
                            font.pixelSize: 15
                            placeholderText: "Enter password..."
                            placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.4)
                            background: Item {}

                            onAccepted: {
                                if (text.length > 0) {
                                    authProc.verify(text);
                                }
                            }
                        }
                    }

                    // Error Indicator
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: lockScope.isError ? "Incorrect password" : ""
                        color: "#ffb4ab"
                        font.pixelSize: 12
                        visible: lockScope.isError
                    }
                }
            }

            // Authentication Backend
            Process {
                id: authProc

                function verify(password) {
                    let b64Pass = Qt.btoa(password);
                    let pyScript = "import ctypes, ctypes.util, os, sys; "
                        + "PAM_SUCCESS = 0; "
                        + "class PamMessage(ctypes.Structure): _fields_ = [('msg_style', ctypes.c_int), ('msg', ctypes.c_char_p)]; "
                        + "class PamResponse(ctypes.Structure): _fields_ = [('resp', ctypes.c_char_p), ('resp_retcode', ctypes.c_int)]; "
                        + "CONV_FUNC = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.POINTER(PamMessage)), ctypes.POINTER(ctypes.POINTER(PamResponse)), ctypes.c_void_p); "
                        + "class PamConv(ctypes.Structure): _fields_ = [('conv', CONV_FUNC), ('appdata_ptr', ctypes.c_void_p)]; "
                        + "def auth(user, pwd): "
                        + "    try: libpam = ctypes.CDLL(ctypes.util.find_library('pam') or 'libpam.so.1'); "
                        + "    except: return False; "
                        + "    def conv_cb(n_msg, msg, resp, appdata): "
                        + "        libc = ctypes.CDLL(ctypes.util.find_library('c') or 'libc.so.6'); "
                        + "        size = ctypes.sizeof(PamResponse) * n_msg; ptr = libc.malloc(size); "
                        + "        res = (PamResponse * n_msg)(); "
                        + "        for i in range(n_msg): res[i].resp = ctypes.c_char_p(pwd.encode('utf-8')); res[i].resp_retcode = 0; "
                        + "        ctypes.memmove(ptr, res, size); resp[0] = ctypes.cast(ptr, ctypes.POINTER(PamResponse)); return PAM_SUCCESS; "
                        + "    cb = CONV_FUNC(conv_cb); conv = PamConv(cb, None); pamh = ctypes.c_void_p(); "
                        + "    for svc in [b'login', b'system-auth', b'sudo', b'passwd', b'common-auth']: "
                        + "        if libpam.pam_start(svc, user.encode('utf-8'), ctypes.byref(conv), ctypes.byref(pamh)) == PAM_SUCCESS: "
                        + "            res = libpam.pam_authenticate(pamh, 0); libpam.pam_end(pamh, res); "
                        + "            if res == PAM_SUCCESS: return True; "
                        + "    return False; "
                        + "user = os.getenv('USER'); pwd = sys.stdin.buffer.read().decode('utf-8', errors='ignore').rstrip('\\r\\n'); "
                        + "sys.exit(0 if auth(user, pwd) else 1);";

                    command = ["sh", "-c", "echo '" + b64Pass + "' | base64 -d | python3 -c \"" + pyScript + "\""];
                    running = true;
                }

                onExited: (exitCode, exitStatus) => {
                    if (exitCode === 0) {
                        lockScope.isError = false;
                        lockScope.isOpen = false;
                        passInput.text = "";
                    } else {
                        lockScope.isError = true;
                        passInput.text = "";
                        passInput.forceActiveFocus();
                    }
                }
            }
        }
    }
}
