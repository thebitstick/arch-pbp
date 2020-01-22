# Pinebook Pro Arch image script

This is a simple script that will generate a minimal bootable Arch Linux ARM image for the Pinebook Pro. It is set up as a single ext4 partition and only has the minimum packages needed to boot the Pinebook Pro and connect to Wi-Fi. The image could either be used as-is, or written to an SD card to use to set up an Arch system yourself on the eMMC.

See the releases page for a prebuilt image.

>**Note**: I have not tried writing this image to eMMC as I would not be able to recover it if something went wrong. Do that at your own risk and be sure you can fix it if something goes wrong.

The default usernames are as they are by default in Arch Linux ARM: There's a default unprivileged user named `alarm` with the password `alarm`, and the default root password is `root`.

The Pinebook Pro-specific packages are taken from [Brian Salcedo](https://github.com/salcedo)'s repository [here](https://simulated.earth/archlinux/pinebookpro/aarch64/). The PKGBUILDs used can be found [here](https://github.com/salcedo/pinebookpro-PKGBUILDs).

If you're using this image to set up Arch yourself, you will also need to build and install u-boot for your setup, instructions on how to do that are [here](https://eno.space/blog//2020/01/pbp-uboot).


## Dependencies
This script has only been tested on an Arch x86\_64 system.

```
base-devel bc dtc multipath-tools e2fsprogs parted arch-install-scripts arm-none-eabi-gcc
```

No extra dependencies should be needed on aarch64, but for other architectures you'll also need `aarch64-linux-gnu-gcc` and some way to run aarch64 binaries, such as `qemu-user-static-bin` + `binfmt-qemu-static` from AUR.
