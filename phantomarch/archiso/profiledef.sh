#!/usr/bin/env bash
# PhantomArch 1.0 Phantom — Archiso Profile Definition

iso_name="phantomarch"
iso_label="PHANTOMARCH_$(date +%Y%m)"
iso_publisher="PhantomArch Project <https://github.com/phantomarch>"
iso_application="PhantomArch Live/Install ISO"
iso_version="1.0"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux.mbr'
  'bios.syslinux.eltorito'
  'uefi-ia32.grub.esp'
  'uefi-x64.grub.esp'
  'uefi-ia32.grub.eltorito'
  'uefi-x64.grub.eltorito'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/bin/phantom-welcome"]="0:0:755"
  ["/usr/bin/phantom-optimizer"]="0:0:755"
  ["/usr/bin/phantom-gamemode-toggle"]="0:0:755"
)
