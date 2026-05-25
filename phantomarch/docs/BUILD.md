# PhantomArch — Instruções de Build

## Pré-requisitos

### Sistema Host
- **Arch Linux** (ou derivado: EndeavourOS, Manjaro, CachyOS)
- **20GB+** de espaço em disco livre
- **8GB+ RAM** recomendado
- Conexão com internet estável
- Execução como **root** (sudo)

### Pacotes necessários
```bash
sudo pacman -S archiso git squashfs-tools xorriso mtools dosfstools erofs-utils
```

---

## Método 1: Build Rápido (Recomendado)

```bash
# 1. Clone o repositório
git clone https://github.com/phantomarch/phantomarch.git
cd phantomarch/archiso

# 2. Execute o build
sudo ./build.sh

# 3. A ISO estará em out/
ls -lh out/*.iso
```

---

## Método 2: Build Completo (Pipeline Full)

```bash
# 1. Clone o repositório
git clone https://github.com/phantomarch/phantomarch.git
cd phantomarch

# 2. Execute o pipeline completo
sudo ./scripts/build-iso.sh
```

Este método:
- Instala todas as dependências automaticamente
- Configura o Chaotic-AUR
- Gera a lista unificada de pacotes
- Builda a ISO
- Verifica a integridade
- Gera SHA256

---

## Método 3: Build Manual (Passo a Passo)

### Passo 1: Preparar o ambiente
```bash
# Instalar archiso
sudo pacman -S archiso

# Configurar Chaotic-AUR no host
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Adicionar ao pacman.conf do host
echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
sudo pacman -Sy
```

### Passo 2: Gerar lista de pacotes
```bash
cd phantomarch/archiso

# Unificar todas as listas
cat packages/packages-*.txt | grep -v '^\s*#' | grep -v '^\s*$' | sort -u > packages.x86_64
```

### Passo 3: Verificar pacotes disponíveis
```bash
# Verificar quais pacotes existem nos repos
while IFS= read -r pkg; do
    if ! pacman -Ss "^${pkg}$" &>/dev/null; then
        echo "AVISO: $pkg não encontrado"
    fi
done < packages.x86_64
```

### Passo 4: Build
```bash
# Limpar build anterior
sudo rm -rf work/

# Executar mkarchiso
sudo mkarchiso -v -w work/ -o out/ .
```

### Passo 5: Testar
```bash
# Com QEMU
qemu-system-x86_64 \
    -m 4G \
    -enable-kvm \
    -cpu host \
    -smp 4 \
    -cdrom out/phantomarch-*.iso \
    -boot d \
    -vga virtio \
    -display gtk
```

---

## Build no Replit / Cloud

> **Nota:** Build de ISOs requer acesso root e muito espaço. Replit free tier não é ideal.

### Opção A: GitHub Actions
```yaml
# .github/workflows/build-iso.yml
name: Build PhantomArch ISO
on:
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: archlinux:latest
      options: --privileged
    steps:
      - uses: actions/checkout@v4
      - name: Build ISO
        run: |
          pacman -Syu --noconfirm
          pacman -S --noconfirm archiso git squashfs-tools xorriso mtools dosfstools
          cd archiso && ./build.sh
      - name: Upload ISO
        uses: actions/upload-artifact@v4
        with:
          name: phantomarch-iso
          path: archiso/out/*.iso
```

### Opção B: Docker (local)
```bash
docker run --rm --privileged \
    -v $(pwd):/build \
    archlinux:latest \
    bash -c "pacman -Syu --noconfirm && pacman -S --noconfirm archiso && cd /build/archiso && ./build.sh"
```

### Opção C: VM na cloud
1. Crie uma VM com Arch Linux (Hetzner, Vultr, DigitalOcean)
2. Clone o repo
3. Execute `sudo ./scripts/build-iso.sh`
4. Download da ISO via SCP

---

## Estrutura de Build

```
archiso/
├── airootfs/          # Overlay do sistema de arquivos
├── efiboot/           # Configuração EFI
├── grub/              # GRUB config para live
├── syslinux/          # Syslinux config (BIOS)
├── packages/          # Listas de pacotes por categoria
├── pacman.conf        # Configuração do pacman
├── profiledef.sh      # Definição do perfil Archiso
├── build.sh           # Script de build principal
├── packages.x86_64    # Lista unificada (gerada)
├── work/              # Diretório de trabalho (temporário)
└── out/               # ISO de saída
```

---

## Troubleshooting

### "Package not found"
- Verifique se o Chaotic-AUR está configurado
- Atualize os mirrors: `sudo pacman -Sy`
- Remova o pacote da lista ou substitua por alternativa

### Build muito lento
- Use mirrors mais rápidos: `sudo reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist`
- Aumente os downloads paralelos no pacman.conf

### Espaço insuficiente
- O build precisa de ~20GB
- Limpe builds anteriores: `sudo rm -rf work/`
- Use um volume maior se em cloud

### ISO não boota
- Verifique se o GRUB está configurado corretamente
- Teste com QEMU antes de gravar em USB
- Verifique EFI vs BIOS no seu hardware

---

## Gravar a ISO

### USB (Linux)
```bash
sudo dd bs=4M if=out/phantomarch-*.iso of=/dev/sdX status=progress oflag=sync
```

### USB (Windows)
- Use [Rufus](https://rufus.ie) ou [balenaEtcher](https://etcher.balena.io)
- Modo: DD Image (não ISO)

### Ventoy
```bash
# Copie a ISO para o USB do Ventoy
cp out/phantomarch-*.iso /mnt/ventoy/
```

---

## Customização

### Adicionar pacotes
Edite os arquivos em `packages/` e adicione o nome do pacote.

### Modificar configurações
Edite os arquivos em `airootfs/etc/` — eles serão copiados para o sistema.

### Trocar wallpaper
Substitua os arquivos em `airootfs/usr/share/phantom/wallpapers/`.

### Trocar kernel padrão
Edite `grub/grub.cfg` e `syslinux/syslinux.cfg` para apontar para outro kernel.
