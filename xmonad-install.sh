#!/bin/bash

SCRIPT_NAME="XMonad Install"
SCRIPT_VERSION="1.7"
HELP_MESSAGE="\n%s %s, an xmonad wm installer\nUsage: xmonad-install [Options]... [Place Holder]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

KEYMAP="latam"

LIGHTDM_XSESSION_FILE_PATH="/etc/lightdm/Xsession"

function installXorg() {
	pacman -S --noconfirm xorg xorg-xinit
}

function installNvidia() {
	pacman -S nvidia nvidia-settings nvidia-utils
}

function installPrev() {
	pacman -S --noconfirm lightdm lightdm-gtk-greeter
	systemctl enable lightdm
}

function installXmonad() {
	pacman -S --noconfirm xmonad xmonad-contrib xmobar xterm rxvt-unicode
}

function installExtras() {
	pacman -S --noconfirm firefox dmenu deja-dup nitrogen
}

function installPulseAudio() {
	pacman -S --noconfirm pulseaudio pavucontrol
	pulseaudio --check
	pulseaudio -D
}

function setKeymap() {
	printf "\n# Set xkb map - generated by xmonad-install.sh\n" >> "$LIGHTDM_XSESSION_FILE_PATH"
	printf "setxkbmap $KEYMAP" >> "$LIGHTDM_XSESSION_FILE_PATH"
}

function main() {
	local install_nvidia_drivers=${1:-true}

	installXorg
	if [[ $install_nvidia_drivers == true ]]; then
		installNvidia
	fi
	installPrev
	installXmonad
	installExtras
	installPulseAudio
	setKeymap
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$file_path" & exit ;;

	esac

	shift
done

main