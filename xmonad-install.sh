#!/bin/zsh

SCRIPT_NAME="XMonad Install"
SCRIPT_VERSION="3.4"
HELP_MESSAGE="\n%s %s, an xmonad wm installer\nUsage: xmonad-install [Options]... [Place Holder]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

KEYMAP="latam"

LIGHTDM_XSESSION_FILE_PATH="/etc/lightdm/Xsession"

USER_NAME="$(who)"
USER_NAME=${USER_NAME%% *}

DEFAULT_CONFIG_DIRECTORY="/home/$USER_NAME/.config/"
TEMP_CONFIG_DIRECTORY="${DEFAULT_CONFIG_DIRECTORY}tempConfig/"

CONFIG_FILES_REPOSITORY="https://github.com/shernandezz/arch-config-files"

PICOM_CONFIG="picom.conf"
PICOM_CONFIG_DESTINATION_PATH="${DEFAULT_CONFIG_DIRECTORY}picom/"

XRESOURCES_CONFIG=".Xresources"
XRESOURCES_CONFIG_DESTINATION_PATH="/home/$USER_NAME/"

XMONAD_CONFIG="xmonad.hs"
XMONAD_CONFIG_DESTINATION_PATH="/home/$USER_NAME/.xmonad/"

XMOBAR_CONFIG="xmobarrc"
XMOBAR_CONFIG_DESTINATION_PATH="${DEFAULT_CONFIG_DIRECTORY}xmobar/"

BASHRC_CONFIG=".bashrc"
BASHRC_CONFIG_DESTINATION_PATH="/home/$USER_NAME/"

FONTS_CONFIG="fonts"
FONTS_CONFIG_DESTINATION_PATH="/home/$USER_NAME/.local/share/fonts/ttf/"

function checkTempConfigDirectory() {
	if ! [[ -d "$TEMP_CONFIG_DIRECTORY" ]]; then
		mkdir -p "$TEMP_CONFIG_DIRECTORY"
		git clone "$CONFIG_FILES_REPOSITORY" "$TEMP_CONFIG_DIRECTORY"
	fi
}

function checkDestinationDirectory() {
	local directory=$1

	if ! [[ -d "$directory" ]]; then
		mkdir -p "$directory"
		chown -R "${USER_NAME}:${USER_NAME}" "$directory"
	fi
}

function checkScriptsDirectory() {
	if ! [[ -d "$SCRIPTS_DIRECTORY" ]]; then
		mkdir -p "$SCRIPTS_DIRECTORY"
	fi
}

function copyConfigFile() {
	local config_file=$1
	local config_file_destination=$2
	local config_file_destination_path="${config_file_destination}${config_file}"
	local config_file_path="${TEMP_CONFIG_DIRECTORY}${config_file}"

	checkDestinationDirectory "$config_file_destination"

	cp "$config_file_path" "$config_file_destination_path"
	chown -R "${USER_NAME}:${USER_NAME}" "$config_file_destination_path"
	chown -R "${USER_NAME}:${USER_NAME}" "$config_file_destination"
}

function installFonts() {
	local fonts_destination=$1
	local fonts_directory="${TEMP_CONFIG_DIRECTORY}fonts/"

	checkDestinationDirectory "$fonts_destination"

	for font in $fonts_directory*; do
		cp $font $fonts_destination
	done

	rm -d -r "$fonts_directory"
}

function getConfigs() {
	checkTempConfigDirectory

	shopt -s dotglob # to include . files

	for file in $TEMP_CONFIG_DIRECTORY*; do
		local file_name=${file##*/}
		echo "$file_name"

		case "$file_name" in
			$PICOM_CONFIG) copyConfigFile "$PICOM_CONFIG" "$PICOM_CONFIG_DESTINATION_PATH" ;;

			$XRESOURCES_CONFIG) copyConfigFile "$XRESOURCES_CONFIG" "$XRESOURCES_CONFIG_DESTINATION_PATH" ;;

			$XMONAD_CONFIG) copyConfigFile "$XMONAD_CONFIG" "$XMONAD_CONFIG_DESTINATION_PATH" ;;

			$XMOBAR_CONFIG) copyConfigFile "$XMOBAR_CONFIG" "$XMOBAR_CONFIG_DESTINATION_PATH" ;;

			$BASHRC_CONFIG) copyConfigFile "$BASHRC_CONFIG" "$BASHRC_CONFIG_DESTINATION_PATH" ;;

			$FONTS_CONFIG) installFonts "$FONTS_CONFIG_DESTINATION_PATH" ;;
			
			*) echo "othr" ;;
			
		esac
	done

	chown -R "${USER_NAME}:${USER_NAME}" "$DEFAULT_CONFIG_DIRECTORY"
}

function installXorg() {
	pacman -S --noconfirm xorg xorg-xinit
}

function installNvidia() {
	pacman -S --noconfirm nvidia nvidia-settings nvidia-utils
}

function installPrev() {
	pacman -S --noconfirm lightdm lightdm-gtk-greeter
	systemctl enable lightdm
}

function installXmonad() {
	pacman -S --noconfirm xmonad xmonad-contrib xmobar xterm rxvt-unicode alacritty
}

function installExtras() {
	pacman -S --noconfirm firefox dmenu deja-dup nitrogen qtkeychain gnome-keyring
}

function installPulseAudio() {
	pacman -S --noconfirm alsa-utils pulseaudio pulseaudio-alsa pavucontrol lxappearance
	pulseaudio --check
	su -c 'pulseaudio -D' $USER_NAME
}

function setKeymap() {
	sed -i "61s/$/\n# Settings generated by xmonad-install.sh\npacman -Sy # Sync repos\nsetxkbmap ${KEYMAP} # Set xkb map\nxrandr --output DVI-I-0 --mode 1920x1080 --rotate right --pos 0x0 --output HDMI-0 --preferred --pos 3000x400 --output DVI-D-0 --primary --mode 1920x1080 --pos 1080x400 # Set monitor layouts\n/" "$LIGHTDM_XSESSION_FILE_PATH"
}

function main() {
	local install_nvidia_drivers=${1:-true}

	if ! [[ "$EUID" == 0 ]]; then
		printf "Please run as root\n" & exit
	fi

	if [[ $install_nvidia_drivers == true ]]; then
		installNvidia
	fi

	installXorg
	installPrev
	installXmonad
	installExtras
	installPulseAudio
	setKeymap

	# xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search # Set nemo defañit
	# gsettings set org.cinnamon.desktop.default-applications.terminal exec <terminal-name> # to ala

	getConfigs

	reboot
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-k | --set-keys) setKeyMap && exit ;;		

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$file_path" & exit ;;

	esac

	shift
done

main
