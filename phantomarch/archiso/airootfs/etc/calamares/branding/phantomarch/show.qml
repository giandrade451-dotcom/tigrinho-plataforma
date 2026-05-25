import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a12"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "👻 PhantomArch 1.0"
                    font.pixelSize: 36
                    font.bold: true
                    color: "#bd93f9"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Ghost in the Machine"
                    font.pixelSize: 18
                    color: "#00fff7"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Instalando seu sistema otimizado para gaming..."
                    font.pixelSize: 14
                    color: "#f8f8f2"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a12"

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    text: "🎮 Gaming Performance"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#bd93f9"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    width: 500
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "• Steam + Proton-GE para jogos Windows\n• GameMode + Gamescope para performance máxima\n• MangoHud para monitoramento em tempo real\n• DXVK + VKD3D para compatibilidade Vulkan"
                    font.pixelSize: 14
                    color: "#f8f8f2"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a12"

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    text: "💻 Ambiente de Desenvolvimento"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#bd93f9"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    width: 500
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "• VS Code, Neovim, Zed — editores modernos\n• Godot, Unity, Unreal — game engines\n• Docker, Podman, Kubernetes — containers\n• Rust, Python, C++, Go, Node.js — linguagens"
                    font.pixelSize: 14
                    color: "#f8f8f2"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a12"

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    text: "🔒 Privacidade Total"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#bd93f9"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    width: 500
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "• Zero telemetria, zero tracking\n• Sem contas obrigatórias\n• Firewall habilitado por padrão\n• AppArmor para segurança de aplicações\n• 100% funcional offline"
                    font.pixelSize: 14
                    color: "#f8f8f2"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a12"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "⚡ Quase pronto!"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#00fff7"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    width: 500
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "Após a instalação:\n\n1. Execute 'phantom-welcome' para checklist\n2. Use SUPER+G para ativar GameMode\n3. Execute 'phantom-optimizer' para tuning\n\nMáxima Performance. Liberdade Total."
                    font.pixelSize: 14
                    color: "#f8f8f2"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
