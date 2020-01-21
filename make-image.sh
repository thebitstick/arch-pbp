#!/bin/bash

set -eu

cleanup() {
	umount root || :
	kpartx -d arch.img || :
}

trap cleanup ERR

if [[ $UID -ne 0 ]]; then
	echo "This script must be run as root."
	exit
fi

tarball=ArchLinuxARM-aarch64-latest.tar.gz
url=http://os.archlinuxarm.org/os/$tarball

if [[ ! -f $tarball ]]; then
	wget $url
fi

if [[ ! -d atf ]]; then
	git clone https://github.com/ARM-software/arm-trusted-firmware.git atf
	git -C atf checkout 22d12c4148c373932a7a81e5d1c59a767e143ac2
fi
if [[ ! -d uboot ]]; then
	git clone https://git.eno.space/pbp-uboot.git uboot
fi

unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
if [[ $(uname -m) != aarch64 ]]; then
	export CROSS_COMPILE=aarch64-linux-gnu-
	export ARCH=arm64
fi

if [[ ! -f uboot/u-boot.itb ]]; then
	make -C atf -j$(nproc) PLAT=rk3399
	make -C uboot -j$(nproc) pinebook_pro-rk3399_defconfig
	make -C uboot -j8 BL31=../atf/build/rk3399/release/bl31/bl31.elf
fi

# Just in case
umount root || :
kpartx -d arch.img || :

rm -f arch.img
fallocate -l 2G arch.img

parted arch.img -- mktable msdos
parted arch.img -- mkpart primary ext4 16MiB -0M
parted arch.img -- set 1 boot on

loopdev=$(kpartx arch.img | cut -d" " -f1)
kpartx -a arch.img

mkdir -p root

mkfs.ext4 /dev/mapper/$loopdev
mount /dev/mapper/$loopdev root
bsdtar -xpvf $tarball -C root/

repostr=<<END
[pinebookpro]
SigLevel = Optional TrustAll
Server = https://simulated.earth/archlinux/pinebookpro/aarch64/
END

lineno=$(($(grep -Fn "[aur]" root/etc/pacman.conf | cut -d: -f1)+2))
cat <(head -n $lineno root/etc/pacman.conf) - \
	<(tail -n +$lineno root/etc/pacman.conf) << EOF > root/etc/pacman.conf.new
[pinebookpro]
SigLevel = Optional TrustAll
Server = https://simulated.earth/archlinux/pinebookpro/aarch64/
EOF

rm root/etc/pacman.conf
mv root/etc/pacman.conf{.new,}

arch-chroot root pacman-key --init
arch-chroot root pacman-key --populate archlinuxarm
arch-chroot root pacman -R linux-aarch64 --noconfirm
arch-chroot root pacman -Syu linux-pinebookpro pinebookpro-firmware \
	pinebookpro-post-install netctl wpa_supplicant dhcpcd dialog --noconfirm

rootuuid=$(blkid /dev/mapper/$loopdev | cut -d\" -f2)
mkdir root/boot/extlinux
cat << EOF > root/boot/extlinux/extlinux.conf
LABEL Arch Linux ARM
KERNEL /boot/Image
FDT /boot/dtbs/rockchip/rk3399-pinebook-pro.dtb
APPEND initrd=/boot/initramfs-linux.img console=tty1 rootwait root=UUID=${rootuuid} rw
EOF

cleanup

dd if=uboot/idbloader.img of=arch.img seek=64 conv=notrunc
dd if=uboot/u-boot.itb of=arch.img seek=16384 conv=notrunc
