#!/bin/zsh

TEMP_FILE_PATH="/home/$USER/.config/pac"

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

center() {
	local text=$*

	printf "%*s" $(( (${#text} + COLUMNS) / 2 )) "$text"
}

function manageUpdates() {
	pacman -Qu > "$TEMP_FILE_PATH"

	local number_of_updates=$(wc -l < $TEMP_FILE_PATH)

	local no_updates_message="nothing to do"

	local no_update_title="Pacman Updates Manager"
	local no_update_message="No Available Updates"

	local single_update_title="Pacman Updates Manager"
	local single_update_message="1 Update Available"

	local multiple_update_title="Pacman Update Manager"
	local multiple_update_message="$number_of_updates Updates Available"

	local prompt_title
	local prompt_message
	local message_color
	local install_color 

	if [[ $number_of_updates == 0 ]]; then
		prompt_title=$no_update_title
		prompt_message=$no_update_message 

	elif [[ $number_of_updates == 1 ]]; then
		prompt_title=$single_update_title
		prompt_message=$single_update_message
		message_color=33
		install_color=32

	else
		prompt_title=$multiple_update_title
		prompt_message=$multiple_update_message
		message_color=33
		install_color=32
	fi

	printf "\e[1;31m%s\e[m\n" "$(center $prompt_title)"
	printf "\e[1;${message_color}m%s\e[m\n\n" "$(center $prompt_message)"

	for ((i = 1 ; i < $number_of_updates + 1 ; i+=1)); do
		local package_name=$(cat $TEMP_FILE_PATH | awk '{i++}i=='"$i"' {print $1}')

		printf " • %s\n" "$package_name"
	done 

	rm $TEMP_FILE_PATH

	printf "\n \e[1;${install_color}minstall\e[m or \e[1;31mquit ❯\e[m "

	read choice

	case "$choice" in

		q | exit | quit | [nN][oO] | [nN]) exit ;;

		install | [sS] | [iI] | [yY][eE][sS] | [yY]) doas pacman --noconfirm -Syu ;;

	esac
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-Lu | --list-updates) getUpdatesList && exit ;;

		-Nu | --number-of-updates) getNumberOfUpdates && exit ;;

		-Mu | --manage-updates) manageUpdates && exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

getNumberOfUpdates