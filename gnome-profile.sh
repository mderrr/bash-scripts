#!/bin/bash

SCRIPT_VERSION="1.4"
SCRIPT_NAME="Gnome Profile"

HELP_MESSAGE="\n%s %s, an Archlinux Terminal Profile Utility\nUsage: gnome-profile [Options]... [Custom Path]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n -I, --import\t\tImport profile from file.\n -E, --export\t\tExport profile to file. (Default)\n\n"
VERSION_MESSAGE="%s version %s\n"
OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

PROFILE_EXPORTED_SUCCESSFULLY_MESSAGE="Profile exported successfully.\n"
PROFILE_IMPORTED_SUCCESSFULLY_MESSAGE="Profile imported successfully.\n"
CUSTOM_FOLDER_NOT_FOUND_MESSAGE="Folder '%s' not found, aborting profile %s.\n"

IMPORT="import"
EXPORT="export"

PROFILE_FILE_NAME="gnome-terminal-profiles.dconf"

function getFilePath() {
    local custom_path=${1:-"."}
    local profile_file_name=$PROFILE_FILE_NAME
    local profile_file_path="$custom_path/$profile_file_name"

    if [[ ! -d "$custom_path" ]]; then
        profile_file_path=""
    fi

    echo "$profile_file_path"
}

function exportProfile() {
    local profile_file_path=$1

    dconf dump /org/gnome/terminal/legacy/profiles:/ > "$profile_file_path"
    printf "$PROFILE_EXPORTED_SUCCESSFULLY_MESSAGE"
}

function importProfile() {
    local profile_file_path=$1

    dconf load /org/gnome/terminal/legacy/profiles:/ < "$profile_file_path"
    printf "$PROFILE_IMPORTED_SUCCESSFULLY_MESSAGE"
}

function setupProfile() {
    local action_name=$1
    local custom_path=$2
    local profile_file_path="$(getFilePath $custom_path)"

    if [[ -z $profile_file_path ]]; then
        printf "$CUSTOM_FOLDER_NOT_FOUND_MESSAGE" "$custom_path" "$action_name" & exit
    fi

    if [[ $action_name == $EXPORT ]]; then
        exportProfile "$profile_file_path"
    elif [[ $action_name == $IMPORT ]]; then
        importProfile "$profile_file_path"
    fi
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

        -h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;
        
        -V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

        -I | --import) setupProfile "$IMPORT" $2 && exit ;;

        -E | --export) setupProfile "$EXPORT" $2 && exit ;;

        -*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

setupProfile "$EXPORT" "$1"