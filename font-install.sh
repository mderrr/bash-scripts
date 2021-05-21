#!/bin/zsh

SCRIPT_VERSION="1.9"
SCRIPT_NAME="Font Install"

HELP_MESSAGE="\n%s %s, an Archlinux Automatic Font Installer \nUsage: font-installer [Options]... [Fonts Folder]\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n -F, --format\t\t\tSpecify a file format for the font files\n\n"
VERSION_MESSAGE="%s version %s\n"
OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

FONT_INSTALLATION_FOLDER_NOT_FOUND_MESSAGE="The font installation folder was not found, creating one at '~/.local/share/fonts/%s'...\n"
FONTS_INSTALLED_SUCCESSFULLY_MESSAGE="Fonts installed successfully\n"
DONT_RUN_AS_ROOT_MESSAGE="Do not run this script as root!\n"
NO_DIRECTORY_SPECIFIED_MESSAGE="No directory specified with -d, defaulting to '~/Fonts'\n"
NO_FILES_FOUND_IN_DIRECTORY_MESSAGE="No %s files found in %s, aborting installation\n"
SPECIFIED_FOLDER_NOT_FOUND_MESSAGE="The folder '%s' was not found, please check the name\n"

FILE_FORMAT=".ttf"

FOLDER_PATH="/home/$USER/Fonts"
FONT_INSTALLATION_PATH="/home/$USER/.local/share/fonts"

function installFonts() {
    local folder_path=${1:-"$FOLDER_PATH"}
    local file_format_folder_name=${FILE_FORMAT##*.}
    local full_font_installation_path="$FONT_INSTALLATION_PATH/$file_format_folder_name"

    if [ ! -d "$full_font_installation_path" ]; then
        printf "$FONT_INSTALLATION_FOLDER_NOT_FOUND_MESSAGE" "$file_format_folder_name" 
        mkdir -p "$full_font_installation_path"
    fi
    
    for subfolder in $folder_path*; do
        subfolder_name=${subfolder##*/} && subfolder_name=${subfolder_name// /""} && subfolder_name=${subfolder_name//_/""}
        subfolder_path="$full_font_installation_path/$subfolder_name"

        if [ ! -d "$subfolder_path" ]; then
            mkdir -p "$subfolder_path"
        fi

        for file in "$subfolder"/*$FILE_FORMAT; do
            if [[ "$file" =~ "*$FILE_FORMAT" ]]; then 
                printf "$NO_FILES_FOUND_IN_DIRECTORY_MESSAGE" "$FILE_FORMAT" "$folder_path" & exit
            fi 

            cp "$file" "$subfolder_path"
        done
    done

    printf "$FONTS_INSTALLED_SUCCESSFULLY_MESSAGE"
    exit
}

function checkCustomFolder() {
    local folder_path=${1:-"$FOLDER_PATH"} && folder_path="${folder_path}/"

    FILE_FORMAT=${2:-"$FILE_FORMAT"}

    if [[ "$folder_path" == "$FOLDER_PATH" ]]; then
        printf "$NO_DIRECTORY_SPECIFIED_MESSAGE"
    fi

    if [ -d "$folder_path" ]; then
        installFonts $folder_path
    else
        printf "$SPECIFIED_FOLDER_NOT_FOUND_MESSAGE" "$folder_path"
        exit
    fi
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

        -h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;
        
        -V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

        -F | --format) checkCustomFolder "$3" "$2" ;;

        -*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

if [ "$EUID" = 0 ]; then
    printf "$DONT_RUN_AS_ROOT_MESSAGE" & exit
fi

checkCustomFolder "$1"