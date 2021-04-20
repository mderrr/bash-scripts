#!/bin/bash

SCRIPT_VERSION="1.0"
HELP_MESSAGE="\nFont Installer $SCRIPT_VERSION, an archlinux automatic font installer utility\nUsage: font-installer [OPTIONS]... [Fonts Folder]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n -F, --format\t\tSpecify a file format for the font files.\n"
VERSION_MESSAGE="Font Installer version $SCRIPT_VERSION"
USER_NAME="$(whoami)"
FILE_FORMAT=".ttf"
FOLDER_PATH="/home/$USER_NAME/Fonts/"
FONT_INSTALLATION_PATH="/home/$USER_NAME/.local/share/fonts"

function installFonts() {
    folder="$FOLDER_PATH"
    file_format_folder=${FILE_FORMAT##*.}
    full_font_installation_path="$FONT_INSTALLATION_PATH/$file_format_folder"

    if [ ! -d "$full_font_installation_path" ]; then
        echo "The font installation folder was not found, creating one at '~/.local/share/fonts/$file_format_folder'..."
        mkdir "$FONT_INSTALLATION_PATH" && mkdir "$full_font_installation_path"
    fi

    for subfolder in $FOLDER_PATH*; do
        subfolder_name=${subfolder##*/} && subfolder_name=${subfolder_name// /""} && subfolder_name=${subfolder_name//_/""}
        subfolder_path="$full_font_installation_path/$subfolder_name"

        if [ ! -d "$subfolder_path" ]; then
            mkdir "$subfolder_path"
        fi

        for file in "$subfolder"/*$FILE_FORMAT; do
            cp "$file" "$subfolder_path"
        done
    done

    exit
}

if [ "$EUID" = 0 ]; then
    echo "Do not run this script as root!" & exit
fi

if [ -z "$1" ]; then
    echo "No directory specified with -d, defaulting to '~/Fonts'"
fi

while [ -n "$1" ]; do 
	case "$1" in

        -h | --help) echo -e $HELP_MESSAGE & exit ;;
        
        -V | --version) echo -e $VERSION_MESSAGE & exit ;;

        -F | --format) FILE_FORMAT=$2 && FOLDER_PATH=$3 ;;

        -d | --directory) FOLDER_PATH=$2 ;;

        -*) echo "Option $1 not recognized" ;;

	esac

	shift
done

if [ -d "$FOLDER_PATH" ]; then
    installFonts $FOLDER_PATH
else
    echo "The folder '$FOLDER_PATH' was not found, please check the name."
fi