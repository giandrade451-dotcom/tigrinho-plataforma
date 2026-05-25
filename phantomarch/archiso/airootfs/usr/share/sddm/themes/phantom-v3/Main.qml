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

    // Background with blur
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
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
        opacity: 0.6
    }

    // Clock
    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: 60
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Text {
            text: Qt.formatTime(new Date(), "HH:mm")
            font.pixelSize: 72
            font.weight: Font.Light
            color: "#f8f8f2"
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
            font.pixelSize: 16
            color: "#8b8da3"
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // Login Box
    Rectangle {
        anchors.centerIn: parent
        width: 380
        height: 320
        radius: 20
        color: Qt.rgba(0.04, 0.04, 0.07, 0.85)
        border.color: Qt.rgba(0.74, 0.58, 0.98, 0.4)
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            width: parent.width - 60

            // Logo
            Text {
                text: "⚡ PhantomArch"
                font.pixelSize: 22
                font.weight: Font.Bold
                color: "#bd93f9"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Ghost in the Machine"
                font.pixelSize: 11
                color: "#6272a4"
                Layout.alignment: Qt.AlignHCenter
            }

            // Username
            TextField {
                id: userField
                Layout.fillWidth: true
                placeholderText: "Usuário"
                font.pixelSize: 14
                color: "#f8f8f2"
                background: Rectangle {
                    radius: 10
                    color: "#1a1a2e"
                    border.color: userField.focus ? "#bd93f9" : "#3d3d5c"
                    border.width: 1
                }
                padding: 12
            }

            // Password
            TextField {
                id: passField
                Layout.fillWidth: true
                placeholderText: "Senha"
                echoMode: TextInput.Password
                font.pixelSize: 14
                color: "#f8f8f2"
                background: Rectangle {
                    radius: 10
                    color: "#1a1a2e"
                    border.color: passField.focus ? "#bd93f9" : "#3d3d5c"
                    border.width: 1
                }
                padding: 12
                Keys.onReturnPressed: sddm.login(userField.text, passField.text, sessionModel.lastIndex)
            }

            // Login button
            Button {
                Layout.fillWidth: true
                text: "Entrar"
                font.pixelSize: 14
                font.weight: Font.Bold
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "#0a0a12"
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle {
                    radius: 10
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#bd93f9" }
                        GradientStop { position: 1.0; color: "#00fff7" }
                    }
                }
                onClicked: sddm.login(userField.text, passField.text, sessionModel.lastIndex)
            }
        }
    }

    // Session selector (bottom)
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        ComboBox {
            id: sessionBox
            model: sessionModel
            textRole: "name"
            width: 180
            currentIndex: sessionModel.lastIndex
        }

        // Power buttons
        Button {
            text: "⏻"
            font.pixelSize: 20
            onClicked: sddm.powerOff()
            background: Rectangle { color: "transparent" }
            contentItem: Text { text: parent.text; color: "#ff5555"; font: parent.font }
        }
        Button {
            text: "🔄"
            font.pixelSize: 20
            onClicked: sddm.reboot()
            background: Rectangle { color: "transparent" }
            contentItem: Text { text: parent.text; color: "#ffb86c"; font: parent.font }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: { /* Clock updates automatically via binding */ }
    }
}
