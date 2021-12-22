#!/bin/bash
# author: lonelyprogrammer
# Requirements: base base-devel linux-zen linux-zen-headers linux-firmware grub efibootmgr vim
# Assuming in all files on pre-install installation has all the requirements to
# run this script. There's no error handling in this script and only use for my
# own test case and post-install arch linux install. But you can use it if you want :>

# Variable used for all sorts of statement occuring while execution
TIMEZONE="/usr/share/zoneinfo/Asia/Manila"
LOCALTIME="/etc/localtime"
GRUB_TARGET="/boot/"
USERNAME="laynux"
HOSTNAME="laynux-pc"
USER="xelectro"

# Settings TIMEZONE symlinks
ln -sf $TIMEZONE $LOCALTIME

# Update rtc clock
hwclock --systohc

# Uncomment the US keyboard layout using stream editor to the locale file
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen

# Create a new file for system wide locale setting
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Create a HOSTNAME file for the system
echo $HOSTNAME > /etc/HOSTNAME

# Used to concatenate the existing hostfile, adding the HOSTNAME to the existing host file
echo -e "127.0.0.1\t $HOSTNAME\n::1\t $HOSTNAME\n127.0.0.1\t${HOSTNAME}.localdomain\t $HOSTNAME" >> /etc/hosts

# Install the bootloader assuming the EFI partition is mounted to $GRUB_TARGET
grub-install --target=x86_64-efi --efi-directory=$GRUB_TARGET --bootloader-id=ArchLinux

# Generating image for grub bootloader next boot
grub-mkconfig -o /boot/grub/grub.cfg

# Creating a normal user and add to the wheel group for sudo permissions
useradd -mG wheel $USER

# Password from for the $USER
passwd $USER

# Uncommenting the wheel group to give wheel group superuser permissions
sed -i 's/# wheel/wheel/' /etc/sudoers

# Install network manager utility, bluetooth. and audio. Last is neofetch ;>
pacman -S networkmanager bluez pulseaudio pulseaudio-bluetooth neofetch

# Used to enable them at boot
systemctl enable NetworkManager
systemctl enable bluetooth

# Flexing i use btw linux user uwu
neofetch
echo "All done! :>"
read -p "Press any key to exit." tmp
