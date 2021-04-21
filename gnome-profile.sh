#!/bin/bash

SCRIPT_VERSION="1.2"
SCRIPT_NAME="Gnome Profile"
HELP_MESSAGE="\n$SCRIPT_NAME $SCRIPT_VERSION, an Archlinux Terminal Profile Utility\nUsage: gnome-profile [OPTIONS]... [Custom Path]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n -I, --import\t\tImport profile from file.\n -E, --export\t\tExport profile to file. (Default)\n"
VERSION_MESSAGE="$SCRIPT_NAME version $SCRIPT_VERSION"

function getFilePath() {
    profile_file="gnome-terminal-profiles.dconf"

    if [ ! -z "$1" ]; then
        profile_file="$1/$profile_file"
    fi

    echo "$profile_file"
}

function exportProfile() {
    profile_file="$(getFilePath $1)"
    dconf dump /org/gnome/terminal/legacy/profiles:/ > "$profile_file"

    echo "Profile exported successfully"
}

function importProfile() {
    profile_file="$(getFilePath $1)"
    dconf load /org/gnome/terminal/legacy/profiles:/ < "$profile_file"

    echo "Profile imported successfully"
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

        -h | --help) echo -e $HELP_MESSAGE & exit ;;
        
        -V | --version) echo -e $VERSION_MESSAGE & exit ;;

        -I | --import) importProfile $2 && exit ;;

        -E | --export) exportProfile $2 && exit ;;

        -*) echo "Option $1 not recognized" & exit ;;

	esac

	shift
done

exportProfile $1