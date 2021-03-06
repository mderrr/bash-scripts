#!/bin/zsh

SCRIPT_NAME="Export Configs"
SCRIPT_VERSION="1.7"
HELP_MESSAGE="\n%s %s, a Tool to get config files\nUsage: export-configs [Options]...\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

DEFAULT_CONFIG_DIRECTORY="/home/$USER/.config/"
TEMP_CONFIG_DIRECTORY="${DEFAULT_CONFIG_DIRECTORY}tempConfig/"

CONFIG_FILES_REPOSITORY="https://github.com/shernandezz/arch-config-files"

PICOM_CONFIG="picom.conf"
PICOM_CONFIG_DESTINATION_PATH="${DEFAULT_CONFIG_DIRECTORY}picom/"

XMONAD_CONFIG="xmonad.hs"
XMONAD_CONFIG_DESTINATION_PATH="/home/$USER/.xmonad/"

XMOBAR_CONFIG="xmobarrc"
XMOBAR_TV_CONFIG="xmobarrc-tv"
XMOBAR_PORTRAIT_CONFIG="xmobarrc-portrait"
XMOBAR_CONFIG_DESTINATION_PATH="${DEFAULT_CONFIG_DIRECTORY}xmobar/"

BASHRC_CONFIG=".bashrc"
BASHRC_CONFIG_DESTINATION_PATH="/home/$USER/"

UPDATING_CONFIGS_MESSAGE="Updating config files\t\t\t[ .... ]"
UPDATE_COMPLETE_MESSAGE="\r\t\t\t\t\t[ DONE ]\n"

function checkTempConfigDirectory() {
	if ! [[ -d "$TEMP_CONFIG_DIRECTORY" ]]; then
		mkdir -p "$TEMP_CONFIG_DIRECTORY"
		git clone --quiet "$CONFIG_FILES_REPOSITORY" "$TEMP_CONFIG_DIRECTORY" > /dev/null
	fi
}

function checkDestinationDirectory() {
	local directory=$1

	if ! [[ -d "$directory" ]]; then
		mkdir -p "$directory"
	fi
}

function copyConfigFile() {
	local config_file=$1
	local config_file_destination=$2
	local config_file_destination_path="${config_file_destination}${config_file}"
	local config_file_path="${TEMP_CONFIG_DIRECTORY}${config_file}"

	checkDestinationDirectory "$config_file_destination"

	cp "$config_file_path" "$config_file_destination_path"
}

function exportConfigs() {
	printf "$UPDATING_CONFIGS_MESSAGE"

	checkTempConfigDirectory

	for file in $TEMP_CONFIG_DIRECTORY*; do
		local file_name=${file##*/}

		case "$file_name" in
			$PICOM_CONFIG) copyConfigFile "$PICOM_CONFIG" "$PICOM_CONFIG_DESTINATION_PATH" ;;

			$XMONAD_CONFIG) copyConfigFile "$XMONAD_CONFIG" "$XMONAD_CONFIG_DESTINATION_PATH" ;;

			$XMOBAR_CONFIG | $XMOBAR_TV_CONFIG | $XMOBAR_PORTRAIT_CONFIG) copyConfigFile "$file_name" "$XMOBAR_CONFIG_DESTINATION_PATH" ;;

			$BASHRC_CONFIG) copyConfigFile "$BASHRC_CONFIG" "$BASHRC_CONFIG_DESTINATION_PATH" ;;
			
		esac
	done

	rm -d -r -f $TEMP_CONFIG_DIRECTORY
	printf "$UPDATE_COMPLETE_MESSAGE"
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

exportConfigs