#!/bin/bash
# author: lonelyprogrammer
# Requirements: base base-devel linux-zen linux-zen-headers linux-firmware grub efibootmgr vim
# Assuming in all files on pre-install installation has all the requirements to
# run this script. There's no error handling in this script and only use for my
# own test case and post-install arch linux install. But you can use it if you want :>

# Variable used for all sorts of statement occuring while execution
TIMEZONE="/usr/share/zoneinfo/Asia/Manila"
LOCALTIME="/etc/LOCALTIME"
GRUB_TARGET="/boot/"
HOSTNAME=""
USER=""

if [[ ! -e "/usr/lib/grub" ]]; then
	pacman -S --noconfirm grub efibootmgr os-prober 

if [[ -e "/dev/mapper/crypthome" ]]; then
	PARENTDEV=$(dmsetup deps -o devname /dev/mapper/crypthome | grep -o "(.*)$" | sed -e 's/(//g' -e 's/)//g')
	HOMEUID=$(blkid -s UUID -o value /dev/$PARENTDEV)

	echo -e "crypthome\t UUID=$HOMEUID\t none\n luks,timeout=150" >> /etc/crypttab
fi
# Settings TIMEZONE symlinks
ln -sf $TIMEZONE $LOCALTIME

# Update rtc clock
hwclock --systohc

# Uncomment the US keyboard layout using stream editor to the locale file
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen

# Create a new file for system wide locale setting
echo LANG=en_US.UTF-8 > /etc/locale.conf

while [[ -z $HOSTNAME ]]; do

	read -p "Enter hostname for your pc:" HOSTNAME

	if [[ $HOSTNAME ~= "^*[!\@\#\$%\^&\*\(\)-+_':\\\.]*$" ]]; then
		HOSTNAME = ""
	fi
done

echo "Creating hostname..."
# Create a HOSTNAME file for the system
echo $HOSTNAME > /etc/HOSTNAME

# Used to concatenate the existing hostfile, adding the hostname to the existing host file
echo -e "127.0.0.1\t $hostname\n
	::1\t $hostname\n127.0.0.1\t${hostname}.localdomain\t $hostname"
	>> /etc/hosts

echo "Installing grub bootloader now..."
# Install the bootloader assuming the EFI partition is mounted to $GRUB_TARGET
grub-install --target=x86_64-efi --efi-directory=$GRUB_TARGET --bootloader-id=ArchLinux

# Generating image for grub bootloader next boot
grub-mkconfig -o /boot/grub/grub.cfg

mkinitcpio -P

while [[ -z $USER ]]; do
	read -p "Enter your username:" USER

	if [[ $USER ~= "^*[!\@\#\$%\^&\*\(\)-+_':\\\.]*^" ]]; then
		USER = ""
		echo -e "Username should not contain any special characters...\nTry Again.\n"
	fi
done

# Uncommenting the wheel group to give wheel group superuser permissions
sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers

echo "Creating username..."
# Creating a normal user and add to the wheel group for sudo permissions
useradd -mG wheel $USER

echo "Enter password for $USER"
# Password from for the $USER
passwd $USER

echo "Enter password for root account:"
passwd

# Install network manager utility, bluetooth. and audio. Last is neofetch ;>
pacman -S networkmanager bluez pulseaudio pulseaudio-bluetooth neofetch

# Used to enable them at boot
systemctl enable NetworkManager
systemctl enable bluetooth

# Flexing i use btw linux user uwu
neofetch
echo "All done! :>"
read -p "Press enter to exit." TMP
exit
