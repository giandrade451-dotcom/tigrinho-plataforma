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

    // Background with blur
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        visible: false
    }

    FastBlur {
        anchors.fill: backgroundImage
        source: backgroundImage
        radius: 48
    }

    // Dark overlay
    Rectangle {
        anchors.fill: parent
        color: "#0a0a12"
        opacity: 0.55
    }

    // Subtle animated gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.04, 0.04, 0.07, 0.3) }
            GradientStop { position: 0.5; color: Qt.rgba(0.04, 0.04, 0.07, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0.04, 0.04, 0.07, 0.6) }
        }
    }

    // Clock top-left
    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 40

        Text {
            text: Qt.formatTime(new Date(), "HH:mm")
            font.pixelSize: 64
            font.weight: Font.Light
            font.family: "Inter"
            color: "#ffffff"
            opacity: 0.9
        }
        Text {
            text: Qt.formatDate(new Date(), "dddd, d 'de' MMMM")
            font.pixelSize: 18
            font.family: "Inter"
            color: "#8b8da3"
        }
    }

    // Main login container
    Rectangle {
        id: loginContainer
        anchors.centerIn: parent
        width: 380
        height: 480
        color: Qt.rgba(0.06, 0.06, 0.1, 0.85)
        radius: 24
        border.color: Qt.rgba(0.74, 0.58, 0.98, 0.3)
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 8
            radius: 32
            samples: 65
            color: Qt.rgba(0.0, 0.0, 0.0, 0.5)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            width: parent.width - 60

            // Avatar
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 96
                height: 96
                radius: 48
                color: Qt.rgba(0.74, 0.58, 0.98, 0.2)
                border.color: "#bd93f9"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "👤"
                    font.pixelSize: 42
                }
            }

            // Username
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.currentUser || "FexOS"
                font.pixelSize: 22
                font.weight: Font.DemiBold
                font.family: "Inter"
                color: "#ffffff"
            }

            // Subtitle
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Bem-vindo de volta"
                font.pixelSize: 13
                font.family: "Inter"
                color: "#8b8da3"
            }

            Item { height: 8 }

            // Password field
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.06)
                border.color: passwordField.activeFocus ? "#bd93f9" : Qt.rgba(1, 1, 1, 0.1)
                border.width: 1

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    anchors.margins: 4
                    placeholderText: "Senha"
                    echoMode: TextInput.Password
                    font.pixelSize: 14
                    font.family: "Inter"
                    color: "#ffffff"
                    background: Item {}

                    placeholderTextColor: "#6b6d80"

                    Keys.onReturnPressed: sddm.login(root.currentUser, passwordField.text, sessionModel.lastIndex)
                    Keys.onEnterPressed: sddm.login(root.currentUser, passwordField.text, sessionModel.lastIndex)
                }
            }

            // Login button
            Rectangle {
                Layout.fillWidth: true
                height: 48
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
                    font.weight: Font.DemiBold
                    font.family: "Inter"
                    color: "#0a0a12"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.login(root.currentUser, passwordField.text, sessionModel.lastIndex)
                }
            }

            // Error message
            Text {
                id: errorMessage
                Layout.alignment: Qt.AlignHCenter
                text: ""
                font.pixelSize: 12
                font.family: "Inter"
                color: "#ff5555"
                visible: text !== ""
            }

            // PIN option
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Usar PIN"
                font.pixelSize: 12
                font.family: "Inter"
                color: "#bd93f9"
                opacity: 0.7

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    // Bottom bar
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 30
        spacing: 32

        // Power button
        Rectangle {
            width: 40; height: 40; radius: 20
            color: Qt.rgba(1, 1, 1, 0.08)
            Text {
                anchors.centerIn: parent
                text: "⏻"
                font.pixelSize: 18
                color: "#ff5555"
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.powerOff()
            }
        }

        // Restart button
        Rectangle {
            width: 40; height: 40; radius: 20
            color: Qt.rgba(1, 1, 1, 0.08)
            Text {
                anchors.centerIn: parent
                text: "⟳"
                font.pixelSize: 18
                color: "#f1fa8c"
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.reboot()
            }
        }

        // Session selector
        Rectangle {
            width: 40; height: 40; radius: 20
            color: Qt.rgba(1, 1, 1, 0.08)
            Text {
                anchors.centerIn: parent
                text: "⚙"
                font.pixelSize: 16
                color: "#8b8da3"
            }
        }

        // Accessibility
        Rectangle {
            width: 40; height: 40; radius: 20
            color: Qt.rgba(1, 1, 1, 0.08)
            Text {
                anchors.centerIn: parent
                text: "♿"
                font.pixelSize: 16
                color: "#8b8da3"
            }
        }
    }

    // FexOS branding bottom right
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 20
        text: "FexOS 5.0 Phantom"
        font.pixelSize: 11
        font.family: "Inter"
        color: "#6b6d80"
    }

    // Error handler
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = "Senha incorreta"
            passwordField.text = ""
            passwordField.focus = true
        }
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}
