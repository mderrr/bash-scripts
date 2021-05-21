#!/bin/zsh

export HISTIGNORE='*sudo -S*'

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