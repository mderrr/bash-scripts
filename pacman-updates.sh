#!/bin/bash

CONFIG_FOLDER_PATH="/home/$USER/.config/pacman-updates/"
CONFIG_FILE_NAME="pacman-updates.conf"
CONFIG_FILE_PATH="${CONFIG_FOLDER_PATH}${CONFIG_FILE_NAME}"

export HISTIGNORE='*sudo -S*'

function checkConfigFile() {
    if ! [[ -d "$CONFIG_FOLDER_PATH" ]]; then
        mkdir -p "$CONFIG_FOLDER_PATH"
    fi

    if ! [[ -e "$CONFIG_FILE_PATH" ]]; then
        printf "" > $CONFIG_FILE_PATH
    fi
}

function saveLastSyncronization() {
    local start_time=$1

    printf "# Last time the repos were syncronized\n" > $CONFIG_FILE_PATH
    printf "%s\n" "$start_time" >> $CONFIG_FILE_PATH
}

function calculateLastSyncronization() {
    local start_time=$(date +%s)
    local previous_execution=$(sed -n '2{p;q}' $CONFIG_FILE_PATH)
    local time_since_last_execution=$((start_time-previous_execution))

    if [[ -n $previous_execution && $time_since_last_execution < 600 ]]; then
        printf "The script was executed less than 10 minutes ago, skipping repo syncronization\n" >> /dev/tty
        echo false

    else
        saveLastSyncronization "$start_time"
        echo true
    fi
}

function syncronizeRepos() {
    passwd=$(/home/$USER/.scripts/pass.sh) &> /dev/null
    echo "$passwd" | sudo -S -k pacman -Sy &> /dev/null
}

function getNumberOfUpdates() {
    syncronizeRepos

    local number_of_updates=$(pacman -Qu | wc -l)

    echo $number_of_updates
}

function getUpdatesList() {
    syncronizeRepos

    local pacman_qu=( $(pacman -Qu) )
    local updates_list=()

    for ((i = 0 ; i < ${#pacman_qu[@]} ; i++)); do
        local item=${pacman_qu[$i]}
        local is_multiple_of_four=$(($i % 4 ))

        if [[ $is_multiple_of_four == 0 ]]; then
            updates_list+=($item) 
        fi
    done

    echo ${updates_list[@]}
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-Lu | --list-updates) getUpdatesList && exit ;;

		-Nu | --number-of-updates) getNumberOfUpdates && exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$file_path" & exit ;;

	esac

	shift
done

getNumberOfUpdates