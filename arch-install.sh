#!/bin/bash

SCRIPT_NAME="Arch Install"
SCRIPT_VERSION="2.4"

HELP_MESSAGE="\n%s %s, an Archlinux Installer\nUsage: arch-install [Options]... [Place Holder]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n\n"
VERSION_MESSAGE="%s version %s\n"
OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

CHECKING_INTERNET_CONNECTION_MESSAGE="Checking internet connection..."
INTERNET_CONNECTION_OK_MESSAGE="\r\t\t\t\t\t\t[ OK ]\n"
INTERNET_CONNECTION_FAILED_MESSAGE="\r\t\t\t\t\t\t[ FAILED ]\n"
NO_INTERNET_CONNECTION_MESSAGE="No internet connection detected, installation aborted\n"

AVAILABLE_DISKS_FOR_INSTALLATION_MESSAGE="\nAvailable disk for installation:\n"

USERNAME_PROMPT_MESSAGE="Enter the username for the main user (empty for default): "
PASSWORD_PROMPT_MESSAGE="Enter the password for root and main user: "
PASSWORD_REENTER_PROMPT_MESSAGE="Re-enter the password: "
SELECT_DISK_PROMPT_MESSAGE="\nType in a disk to install Arch (type 'd' for details): "
SELECT_DISK_NO_DETAILS_PROMPT_MESSAGE="\nType in a disk to install Arch: "

PASSWORDS_NOT_EQUAL_MESSAGE="The passwords do not coincide, installation aborted\n"

DETAIL_CHAR="d"
NEWLINE="\n"

DEFAULT_USERNAME="santiago"

ITEM_TEMPLATE="%s\n"

FDISK_COMMANDS="g\nn\n\n\n+500M\nn\n\n\n+4G\nn\n\n\n\nt\n1\n1\nt\n2\n19\nw\n"

MANUAL_PARTITION=false

function checkConnection() {
	printf "$CHECKING_INTERNET_CONNECTION_MESSAGE" >> /dev/tty

	if $(ping -c 2 google.com >> /dev/null 2>&1); then
		printf "$INTERNET_CONNECTION_OK_MESSAGE" >> /dev/tty
		exit 0
	else
		printf "$INTERNET_CONNECTION_FAILED_MESSAGE" >> /dev/tty
		exit 1
	fi
}

function displayAvailableDisks() {
	local dev_contents=$(ls /dev/sd*)

	printf "$AVAILABLE_DISKS_FOR_INSTALLATION_MESSAGE"

	for item in ${dev_contents[*]}; do
		if [[ ! $item =~ [0-9] ]];then
			printf "$ITEM_TEMPLATE" "$item"
		fi
	done
}

function createDiskPartitions() {
	local selected_disk=$1
	printf "$FDISK_COMMANDS" | fdisk $selected_disk
}

function main() {
	if ! $(checkConnection); then
		printf "$NO_INTERNET_CONNECTION_MESSAGE" && exit
	fi

	local user_name=""
	read -p "$USERNAME_PROMPT_MESSAGE" user_name
	user_name=${user_name:-"$DEFAULT_USERNAME"}

	read -s -p "$PASSWORD_PROMPT_MESSAGE" password
	printf "$NEWLINE"
	read -s -p "$PASSWORD_REENTER_PROMPT_MESSAGE" password_reentered
	local password_string="${password}\n${password}"
	if ! [[ $password == $password_reentered ]]; then
		printf "$PASSWORDS_NOT_EQUAL_MESSAGE" & exit
	fi
	
	timedatectl set-ntp true

	if [[ $MANUAL_PARTITION == true ]]; then
		fdisk /dev/sdc
		# TODO
	else
		displayAvailableDisks

		printf "$SELECT_DISK_PROMPT_MESSAGE" && read -e selected_disk
		if [[ $selected_disk == "$DETAIL_CHAR" ]]; then
			fdisk -l && printf "$SELECT_DISK_NO_DETAILS_PROMPT_MESSAGE" && read -e selected_disk
		fi
	fi

	createDiskPartitions "$selected_disk"
	mkfs.fat -F32 ${selected_disk}1
	mkswap ${selected_disk}2
	swapon ${selected_disk}2
	mkfs.ext4 ${selected_disk}3
	mount ${selected_disk}3 /mnt
	pacstrap /mnt base base-devel linux linux-firmware
	genfstab -U /mnt >> /mnt/etc/fstab
	
	cat <<-EOT > /mnt/root/arch-chroot-install.sh
	ln -sf /usr/share/zoneinfo/AMERICA/BOGOTA /etc/localtime
	hwclock --systohc
	sed -i "177s/#//" /etc/locale.gen
	sed -i "178s/#//" /etc/locale.gen
	sed -i "191s/#//" /etc/locale.gen
	sed -i "192s/#//" /etc/locale.gen
	locale-gen
	printf "LANG=en_US.UTF-8" > /etc/locale.conf
	printf "KEYMAP=la-latin1" > /etc/vconsole.conf
	printf "arch-linux" > /etc/hostname
	printf "127.0.0.1\tlocalhost\n" >> /etc/hosts
	printf "::1\t\tlocalhost\n" >> /etc/hosts
	printf "127.0.1.1\tarch-linux.localdomain\tarch-linux" >> /etc/hosts
	printf "$password_string" | passwd
	useradd -m $user_name
	printf "$password_string" | passwd $user_name
	usermod -aG wheel,audio,video,optical,storage,uucp $user_name
	sed -i "82s/#//" /etc/sudoers
	pacman -S --noconfirm grub efibootmgr dosfstools os-prober mtools
	mkdir /boot/EFI
	mount ${selected_disk}1 /boot/EFI
	grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
	grub-mkconfig -o /boot/grub/grub.cfg
	pacman -S --noconfirm networkmanager
	systemctl enable NetworkManager
	pacman -S --noconfirm neovim git python-pip tk doas neofetch
	printf "permit $user_name as root" > /etc/doas.conf
	EOT

	chmod +x /mnt/root/arch-chroot-install.sh
	arch-chroot /mnt /root/arch-chroot-install.sh
	umount -R /mnt
	reboot
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-p | --manual-partition) MANUAL_PARTITION=true && shift && continue ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$file_path" & exit ;;

	esac

	shift
done

main