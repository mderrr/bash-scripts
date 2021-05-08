#!/bin/bash

SCRIPT_NAME="Export Scripts"
SCRIPT_VERSION="1.0"
HELP_MESSAGE="\n%s %s, a Bash Script Exporter\nUsage: export-scripts [Options]... [Place Holder]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

SYNCING_REPOSITORY_MESSAGE="Syncing the scripts repository\t\t[ .... ]"
SYNC_COMPLETE_MESSAGE="\r\t\t\t\t\t[ DONE ]\n"

USER_NAME=$USER
SCRIPTS_DESTINATION_DIRECTORY="/home/$USER_NAME/.scripts/"

DEFAULT_REPOSITORIES_DIRECTORY="/home/$USER_NAME/Repositories/"
SCRIPTS_REPOSITORY="${DEFAULT_REPOSITORIES_DIRECTORY}bash-scripts/"

EXCLUDED_FILES_FROM_SCRIPTS=("README.md" "template-gen.sh" "arch-install.sh" "xmonad-install.sh")

function checkScriptsDirectory() {
	if ! [[ -d "$SCRIPTS_DESTINATION_DIRECTORY" ]]; then
		mkdir -p "$SCRIPTS_DESTINATION_DIRECTORY"
        chown -R "${USER_NAME}:${USER_NAME}" "$SCRIPTS_DESTINATION_DIRECTORY"
	fi
}

function exportScripts() {
	checkScriptsDirectory

    for script in $SCRIPTS_REPOSITORY*; do
        local script_name=${script##*/} 
		local scripts_destination_path="${SCRIPTS_DESTINATION_DIRECTORY}$script_name"
        
        if ! [[ ${EXCLUDED_FILES_FROM_SCRIPTS[*]} =~ $script_name ]]; then
            echo $script_name

			cp $script $scripts_destination_path
			chown -R "${USER_NAME}:${USER_NAME}" "$scripts_destination_path"
        fi
    done
}

function syncRepository() {
	printf "$SYNCING_REPOSITORY_MESSAGE"
	cd $SCRIPTS_REPOSITORY && git pull >> /dev/null
	printf "$SYNC_COMPLETE_MESSAGE"
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-S | --sync-repo) syncRepository && exit ;;

		-Su | --sync-update) syncRepository ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$file_path" & exit ;;

	esac

	shift
done

exportScripts