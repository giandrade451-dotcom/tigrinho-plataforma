import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height

    property string currentUser: userModel.lastUser
    property int currentIndex: userModel.lastIndex
    property bool loginFailed: false

    // Deep background
    Rectangle {
        anchors.fill: parent
        color: "#08080f"
    }

    // Ambient gradient orbs
    Item {
        anchors.fill: parent

        Rectangle {
            id: orb1
            width: root.width * 0.6
            height: root.width * 0.6
            radius: width / 2
            x: root.width * 0.6
            y: -root.height * 0.1
            visible: false
            color: "#1a0a3d"
        }

        Rectangle {
            id: orb2
            width: root.width * 0.4
            height: root.width * 0.4
            radius: width / 2
            x: -root.width * 0.1
            y: root.height * 0.5
            visible: false
            color: "#0a1a2d"
        }

        // Apply blur to orbs for ambient light
        FastBlur {
            anchors.fill: parent
            source: ShaderEffectSource {
                sourceItem: Item {
                    width: root.width
                    height: root.height
                    Rectangle {
                        width: root.width * 0.6
                        height: root.width * 0.6
                        radius: width / 2
                        x: root.width * 0.6
                        y: -root.height * 0.1
                        color: "#1a0a3d"
                        opacity: 0.4
                    }
                    Rectangle {
                        width: root.width * 0.4
                        height: root.width * 0.4
                        radius: width / 2
                        x: -root.width * 0.1
                        y: root.height * 0.5
                        color: "#0a1a2d"
                        opacity: 0.3
                    }
                }
            }
            radius: 128
        }
    }

    // Clock and date (top-left)
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 48
        spacing: 4

        Text {
            id: timeLabel
            font.pixelSize: 72
            font.weight: Font.Thin
            font.family: "Inter"
            color: "#ffffff"
            opacity: 0.95

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: parent.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }

        Text {
            id: dateLabel
            font.pixelSize: 16
            font.weight: Font.Normal
            font.family: "Inter"
            color: "#9090a8"

            Timer {
                interval: 60000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: parent.text = Qt.formatDateTime(new Date(), "dddd, d 'de' MMMM 'de' yyyy")
            }
        }
    }

    // Center login card
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        width: 380
        height: 480
        radius: 20
        color: Qt.rgba(0.08, 0.08, 0.12, 0.75)
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1

        // Card blur backdrop
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 16
            radius: 48
            samples: 48
            color: Qt.rgba(0, 0, 0, 0.5)
        }

        Column {
            anchors.fill: parent
            anchors.margins: 36
            spacing: 0

            // Top spacer
            Item { width: 1; height: 24 }

            // Avatar
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96
                height: 96
                radius: 48
                color: "#1e1e32"
                border.color: "#3d3d5c"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: currentUser ? currentUser.charAt(0).toUpperCase() : "U"
                    font.pixelSize: 36
                    font.weight: Font.Medium
                    font.family: "Inter"
                    color: "#a78bfa"
                }
            }

            Item { width: 1; height: 16 }

            // Username
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: currentUser || "Usuário"
                font.pixelSize: 20
                font.weight: Font.DemiBold
                font.family: "Inter"
                color: "#f0f0f5"
            }

            Item { width: 1; height: 4 }

            // Account type
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Conta local"
                font.pixelSize: 12
                font.family: "Inter"
                color: "#6b6b80"
            }

            Item { width: 1; height: 32 }

            // Password input
            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: passwordField.activeFocus ? "#1a1a2e" : "#14141f"
                border.color: passwordField.activeFocus ? "#7c5cbf" : "#2a2a3e"
                border.width: passwordField.activeFocus ? 2 : 1

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    anchors.margins: 2
                    verticalAlignment: TextInput.AlignVCenter
                    leftPadding: 14
                    rightPadding: 14
                    placeholderText: "Senha"
                    echoMode: TextInput.Password
                    font.pixelSize: 14
                    font.family: "Inter"
                    color: "#e8e8f0"
                    selectionColor: "#7c5cbf"
                    placeholderTextColor: "#4a4a60"
                    background: Item {}

                    Keys.onReturnPressed: doLogin()
                    Keys.onEnterPressed: doLogin()
                }
            }

            Item { width: 1; height: 12 }

            // Error message
            Text {
                id: errorLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: loginFailed ? "Senha incorreta. Tente novamente." : ""
                font.pixelSize: 12
                font.family: "Inter"
                color: "#ef4444"
                opacity: loginFailed ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            Item { width: 1; height: 16 }

            // Login button
            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: loginBtnMouse.pressed ? "#5b3d9e" : (loginBtnMouse.containsMouse ? "#7c5cbf" : "#6d4db3")

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Entrar"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.family: "Inter"
                    color: "#ffffff"
                }

                MouseArea {
                    id: loginBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }

            Item { width: 1; height: 24 }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: "#1e1e2e"
            }

            Item { width: 1; height: 20 }

            // Bottom actions
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 32

                // Shutdown
                Column {
                    spacing: 4
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 36
                        height: 36
                        radius: 18
                        color: shutdownMouse.containsMouse ? "#1e1e2e" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\u23FB"
                            font.pixelSize: 16
                            color: "#8080a0"
                        }

                        MouseArea {
                            id: shutdownMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sddm.powerOff()
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Desligar"
                        font.pixelSize: 10
                        font.family: "Inter"
                        color: "#6b6b80"
                    }
                }

                // Restart
                Column {
                    spacing: 4
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 36
                        height: 36
                        radius: 18
                        color: restartMouse.containsMouse ? "#1e1e2e" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\u21BB"
                            font.pixelSize: 16
                            color: "#8080a0"
                        }

                        MouseArea {
                            id: restartMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sddm.reboot()
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Reiniciar"
                        font.pixelSize: 10
                        font.family: "Inter"
                        color: "#6b6b80"
                    }
                }

                // Sleep
                Column {
                    spacing: 4
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 36
                        height: 36
                        radius: 18
                        color: sleepMouse.containsMouse ? "#1e1e2e" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\u263D"
                            font.pixelSize: 16
                            color: "#8080a0"
                        }

                        MouseArea {
                            id: sleepMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sddm.suspend()
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Suspender"
                        font.pixelSize: 10
                        font.family: "Inter"
                        color: "#6b6b80"
                    }
                }
            }
        }
    }

    // Session selector (bottom-left)
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 8

        Text {
            text: "Sessão:"
            font.pixelSize: 12
            font.family: "Inter"
            color: "#6b6b80"
            anchors.verticalCenter: parent.verticalCenter
        }

        ComboBox {
            id: sessionSelector
            width: 160
            height: 32
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex

            background: Rectangle {
                radius: 6
                color: "#14141f"
                border.color: "#2a2a3e"
                border.width: 1
            }

            contentItem: Text {
                leftPadding: 10
                text: sessionSelector.displayText
                font.pixelSize: 12
                font.family: "Inter"
                color: "#c0c0d0"
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // FexOS branding (bottom-right)
    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32
        text: "FexOS 6.0"
        font.pixelSize: 11
        font.family: "Inter"
        color: "#3d3d50"
    }

    // Login logic
    function doLogin() {
        loginFailed = false
        if (passwordField.text === "") {
            loginFailed = true
            return
        }
        sddm.login(currentUser, passwordField.text, sessionSelector.currentIndex)
    }

    // Focus on load
    Component.onCompleted: {
        passwordField.forceActiveFocus()
    }

    // Login failure handler
    Connections {
        target: sddm
        function onLoginFailed() {
            loginFailed = true
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }
}
