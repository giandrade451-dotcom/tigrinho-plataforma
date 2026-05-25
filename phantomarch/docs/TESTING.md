# PhantomArch — Checklist de Testes

## Antes de Gerar a ISO Final

### 1. Validação de Pacotes
- [ ] Todos os pacotes em `packages.x86_64` existem nos repositórios
- [ ] Sem conflitos entre pacotes (verificar com `pacman -Sp --print-format '%n'`)
- [ ] Pacotes AUR estão disponíveis no Chaotic-AUR
- [ ] Dependências de 32-bit (multilib) presentes

### 2. Build da ISO
- [ ] Build completa sem erros (`mkarchiso` retorna 0)
- [ ] ISO gerada com tamanho razoável (5-10GB esperado)
- [ ] SHA256 gerado para verificação

---

## Testes em VM (QEMU/VirtualBox)

### 3. Boot
- [ ] Boot UEFI funciona
- [ ] Boot BIOS/Legacy funciona
- [ ] Menu GRUB exibe corretamente
- [ ] Plymouth animation aparece
- [ ] Boot completa em < 30 segundos (sem erros)

### 4. Live Environment
- [ ] Desktop Hyprland carrega
- [ ] Waybar exibe informações corretas
- [ ] Wofi launcher funciona (SUPER+SPACE)
- [ ] Terminal (kitty) abre (SUPER+RETURN)
- [ ] Rede/Wi-Fi funciona (NetworkManager)
- [ ] Áudio funciona (PipeWire)
- [ ] Resolução de tela correta

### 5. Instalação (Calamares)
- [ ] Calamares inicia sem erros
- [ ] Tema Phantom carrega no instalador
- [ ] Particionamento funciona (EXT4, Btrfs, XFS)
- [ ] Instalação completa sem erros
- [ ] Bootloader instalado corretamente
- [ ] Primeiro boot após instalação OK

---

## Testes Pós-Instalação

### 6. Sistema Base
- [ ] Login funciona (SDDM)
- [ ] Hyprland inicia após login
- [ ] Todos os keybindings funcionam
- [ ] Clipboard funciona (wl-clipboard)
- [ ] Screenshot funciona (grim + slurp)
- [ ] File manager funciona (thunar)
- [ ] Browser funciona (firefox)

### 7. Performance Gaming
- [ ] `phantom-welcome` mostra checklist OK
- [ ] GameMode ativa/desativa (SUPER+G)
- [ ] Steam instala e abre
- [ ] Proton funciona (testar jogo simples)
- [ ] MangoHud overlay funciona
- [ ] Vulkan funciona (`vulkaninfo`)
- [ ] vm.max_map_count está alto
- [ ] FPS estável em benchmark

### 8. GPU (por hardware)

#### AMD
- [ ] amdgpu driver carregado
- [ ] Vulkan RADV funciona
- [ ] ROCm disponível
- [ ] VRR/FreeSync funciona

#### NVIDIA
- [ ] nvidia-dkms instalado
- [ ] nvidia-smi funciona
- [ ] Vulkan funciona
- [ ] CUDA disponível
- [ ] DRM modeset habilitado

### 9. Desenvolvimento
- [ ] VS Code/Codium abre
- [ ] Neovim funciona com plugins
- [ ] Git funciona
- [ ] Docker funciona (`docker run hello-world`)
- [ ] Rustup funciona (`rustc --version`)
- [ ] Python funciona (`python --version`)
- [ ] Node.js funciona (`node --version`)
- [ ] Godot abre

### 10. Áudio/Vídeo
- [ ] PipeWire rodando
- [ ] WirePlumber rodando
- [ ] Áudio de sistema funciona
- [ ] EasyEffects funciona
- [ ] Microfone funciona
- [ ] Bluetooth áudio funciona
- [ ] Codecs de vídeo (mpv reproduz h264/h265/av1)

### 11. Segurança
- [ ] Firewall ativo (`sudo ufw status`)
- [ ] AppArmor ativo (`aa-status`)
- [ ] Sem telemetria (verificar conexões: `ss -tuln`)
- [ ] Sem processos suspeitos

### 12. Estabilidade
- [ ] Sistema funciona 24h sem crash
- [ ] Suspend/Resume funciona
- [ ] Múltiplos reboots OK
- [ ] Não há memory leaks óbvios
- [ ] earlyoom funciona sob pressão de memória

---

## Testes de Stress

### 13. Gaming Stress
```bash
# Instalar e rodar unigine-heaven ou similar
# Verificar temperatura, FPS, estabilidade
mangohud glxgears  # Teste básico
```

### 14. I/O Stress
```bash
# Testar velocidade de disco
dd if=/dev/zero of=/tmp/test bs=1M count=1024 conv=fdatasync
fio --randrepeat=1 --ioengine=libaio --direct=1 --name=test \
    --filename=/tmp/fiotest --bs=4k --iodepth=64 --size=512M \
    --readwrite=randrw --rwmixread=75
```

### 15. RAM Stress
```bash
# Testar memória
stress-ng --vm 2 --vm-bytes 2G --timeout 60s
```

---

## Matriz de Hardware Testado

| Hardware | Status | Notas |
|----------|--------|-------|
| VM QEMU (UEFI) | | |
| VM QEMU (BIOS) | | |
| VirtualBox | | |
| AMD RX 6000+ | | |
| AMD RX 7000+ | | |
| NVIDIA RTX 3000+ | | |
| NVIDIA RTX 4000+ | | |
| Intel Arc | | |
| Laptop Intel+NVIDIA | | |
| Laptop AMD+AMD | | |

---

## Ferramentas de Teste Recomendadas

```bash
# Benchmark GPU
vkcube                    # Vulkan básico
glmark2                   # OpenGL benchmark
unigine-heaven           # Stress test GPU (AUR)

# Benchmark CPU
stress-ng --cpu $(nproc) --timeout 60s
sysbench cpu run

# Benchmark Disco
fio                      # I/O benchmark
hdparm -Tt /dev/nvme0n1  # Velocidade direta

# Network
iperf3                   # Bandwidth
ping -c 100 1.1.1.1     # Latência

# System
bootchart                # Tempo de boot
systemd-analyze blame    # Serviços lentos
```

---

## Critérios de Aprovação

A ISO é considerada **pronta para release** quando:

1. Todos os testes em VM passam (seções 3-12)
2. Pelo menos 1 teste em hardware real (AMD ou NVIDIA)
3. Tempo de boot < 15s (SSD) / < 30s (HDD)
4. Nenhum erro no journal durante uso normal
5. Gaming funcional com Proton
6. Todos os scripts Phantom funcionam
