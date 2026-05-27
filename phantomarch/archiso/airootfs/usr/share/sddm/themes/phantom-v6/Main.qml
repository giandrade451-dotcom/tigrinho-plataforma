import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0a0a12"

    property string currentUser: userModel.lastUser
    property int currentIndex: userModel.lastIndex

    // Background gradient (no external image dependency)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a0a1a" }
            GradientStop { position: 0.4; color: "#12102a" }
            GradientStop { position: 0.7; color: "#0d1525" }
            GradientStop { position: 1.0; color: "#0a0a12" }
        }
    }

    // Subtle animated glow (lightweight)
    Rectangle {
        id: glowOrb
        width: 400
        height: 400
        radius: 200
        x: parent.width * 0.7
        y: parent.height * 0.3
        color: "transparent"
        opacity: 0.15

        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#bd93f9" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.2; duration: 3000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.1; duration: 3000; easing.type: Easing.InOutSine }
        }
    }

    // Second glow orb (cyan)
    Rectangle {
        width: 300
        height: 300
        radius: 150
        x: parent.width * 0.2
        y: parent.height * 0.6
        color: "transparent"
        opacity: 0.08

        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00fff7" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // Center login panel
    Rectangle {
        id: loginPanel
        anchors.centerIn: parent
        width: 420
        height: 520
        color: Qt.rgba(0.06, 0.06, 0.1, 0.85)
        radius: 24
        border.color: Qt.rgba(0.74, 0.58, 0.98, 0.2)
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 8
            radius: 32
            samples: 32
            color: Qt.rgba(0, 0, 0, 0.4)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 16

            // FexOS Logo
            Text {
                text: "⚡ FexOS"
                font.pixelSize: 32
                font.weight: Font.ExtraBold
                color: "#bd93f9"
                Layout.alignment: Qt.AlignHCenter
            }

            // Subtitle
            Text {
                text: "Ghost in the Machine"
                font.pixelSize: 12
                color: "#6b6d80"
                Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillHeight: true; Layout.maximumHeight: 20 }

            // Avatar circle
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 80
                height: 80
                radius: 40
                color: Qt.rgba(0.74, 0.58, 0.98, 0.2)
                border.color: Qt.rgba(0.74, 0.58, 0.98, 0.4)
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: currentUser ? currentUser.charAt(0).toUpperCase() : "U"
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: "#bd93f9"
                }
            }

            // Username
            Text {
                text: currentUser || "Usuário"
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillHeight: true; Layout.maximumHeight: 12 }

            // Password field
            TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                placeholderText: "Senha"
                echoMode: TextInput.Password
                font.pixelSize: 14
                color: "#e0e0e0"
                horizontalAlignment: TextInput.AlignHCenter

                background: Rectangle {
                    radius: 12
                    color: Qt.rgba(0.1, 0.1, 0.18, 0.8)
                    border.color: passwordField.activeFocus ?
                        "#bd93f9" : Qt.rgba(0.2, 0.2, 0.3, 0.8)
                    border.width: passwordField.activeFocus ? 2 : 1
                }

                Keys.onReturnPressed: doLogin()
                Keys.onEnterPressed: doLogin()
            }

            // Login button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 12

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#bd93f9" }
                    GradientStop { position: 1.0; color: "#00fff7" }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Entrar"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: "#0a0a12"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }

            // Error message
            Text {
                id: errorMsg
                text: ""
                color: "#ff5555"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
                visible: text !== ""
            }

            Item { Layout.fillHeight: true }

            // Power buttons row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                Text {
                    text: "⏻ Desligar"
                    font.pixelSize: 12
                    color: "#6b6d80"
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.powerOff()
                    }
                }

                Text {
                    text: "🔄 Reiniciar"
                    font.pixelSize: 12
                    color: "#6b6d80"
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.reboot()
                    }
                }
            }
        }
    }

    // Clock (top right)
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 32
        text: Qt.formatDateTime(new Date(), "HH:mm")
        font.pixelSize: 48
        font.weight: Font.Light
        color: "#ffffff"
        opacity: 0.8

        Timer {
            interval: 30000
            running: true
            repeat: true
            onTriggered: parent.text = Qt.formatDateTime(new Date(), "HH:mm")
        }
    }

    // Date (below clock)
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 88
        anchors.rightMargin: 32
        text: Qt.formatDateTime(new Date(), "dddd, d MMMM yyyy")
        font.pixelSize: 14
        color: "#8b8da3"
        opacity: 0.8
    }

    // Login function
    function doLogin() {
        if (passwordField.text === "") {
            errorMsg.text = "Digite sua senha"
            return
        }
        errorMsg.text = ""
        sddm.login(currentUser, passwordField.text, currentIndex)
    }

    // Focus password on load
    Component.onCompleted: {
        passwordField.forceActiveFocus()
    }

    // Handle login failure
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMsg.text = "Senha incorreta"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }
}
