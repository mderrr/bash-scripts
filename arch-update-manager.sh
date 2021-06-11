#!/bin/zsh

SCRIPT_NAME="Arch Update Manager"
SCRIPT_VERSION="2.2"
HELP_MESSAGE="\n%s %s, an Archlinux update manager\nUsage: arch-update-manager [Options]...\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n -Lu, --list-updates\t\tReturn a list of the updates\n -A, --aur\t\t\tGet the number of AUR updates\n -P, --pacman\t\t\tGet the number of pacman updates\n -T, --total\t\t\tGet the sum of all available updates\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

TAUR_SCRIPT="/home/$USER/.scripts/taur.sh"
PACMAN_UPDATES_SCRIPT="/home/$USER/.scripts/pacman-updates.sh"

CONFIG_FOLDER_PATH="/home/$USER/.config/Arch Update Manager/"
CONFIG_FILE_PATH="${CONFIG_FOLDER_PATH}aum.conf"

TAUR_NU_SCRIPT="$TAUR_SCRIPT -q -Synu"
PACMAN_UPDATES_NU_SCRIPT="$PACMAN_UPDATES_SCRIPT -Nu"

TAUR_LU_SCRIPT="$TAUR_SCRIPT -q -Sylu"
PACMAN_UPDATES_LU_SCRIPT="$PACMAN_UPDATES_SCRIPT -Lu"

LIST_UPDATES=false

function getNumberOfPacmanUpdates() {
	if [[ $LIST_UPDATES == true ]]; then
		local updates_list=( $($PACMAN_UPDATES_LU_SCRIPT) )
		echo ${updates_list[@]}
	else
		echo $($PACMAN_UPDATES_NU_SCRIPT)
	fi
}

function getNumberOfAurUpdates() {
	if [[ $LIST_UPDATES == true ]]; then
		local updates_list=( $($TAUR_LU_SCRIPT) )
		echo ${updates_list[@]}
	else
		echo $($TAUR_NU_SCRIPT)
	fi
}

function getTotalNumberOfUpdates() {
	local taur_updates=$(getNumberOfAurUpdates)
	local pacman_updates=$(getNumberOfPacmanUpdates)
	local total_updates=$(($taur_updates+$pacman_updates))

	echo $(($pacman_updates+$aur_updates))
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-Lu | --list-updates) LIST_UPDATES=true && shift && continue ;;

		-A | --aur) getNumberOfAurUpdates && exit ;;

		-P | --pacman) getNumberOfPacmanUpdates && exit ;;

		-T | --total) getTotalNumberOfUpdates && exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done