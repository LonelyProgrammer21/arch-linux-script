#!/bin/sh

MAINSTORAGE="/dev/sda"

pacman -S gdisk --noconfirm
sgdisk -o $MAINSTORAGE
sgdisk -n 1::+512MiB -t 1:EF00 -c 1:BOOT $MAINSTORAGE
sgdisk -n 2::+4GiB -t 2:8200 -c 2:SWAP $MAINSTORAGE
sgdisk -n 3::+32GiB -t 3:8300 -c 3:ROOT $MAINSTORAGE
sgdisk -n 4:: -t 4:8300 -c 4:HOME $MAINSTORAGE

mkfs.fat -F32 "${MAINSTORAGE}1"
mkswap "${MAINSTORAGE}2"
swapon "${MAINSTORAGE}2"
mkfs.ext4 "${MAINSTORAGE}3"
mkfs.ext4 "${MAINSTORAGE}4"

mount "${MAINSTORAGE}3" /mnt
mkdir -p /mnt/boot
mkdir -p /mnt/home

mount "${MAINSTORAGE}1" /mnt/boot
mount "${MAINSTORAGE}4" /mnt/home
pacstrap /mnt base base-devel linux-zen linux-zen-headers vim amd-ucode

gensftab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
echo "DONE :)"