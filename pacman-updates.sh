#!/bin/zsh

export HISTIGNORE='*sudo -S*'

function syncronizeRepos() {
    passwd=$(/home/$USER/.scripts/pass.sh) #&> /dev/null
    echo "$passwd" | sudo -S -k pacman -Sy &> /dev/null
}

function getNumberOfUpdates() {
    syncronizeRepos

    local number_of_updates=$(pacman -Qu | wc -l)

    echo $number_of_updates
}

function getUpdatesList() {
    syncronizeRepos

    pacman -Qu | awk '{print $1}'
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-Lu | --list-updates) getUpdatesList && exit ;;

		-Nu | --number-of-updates) getNumberOfUpdates && exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

getNumberOfUpdates