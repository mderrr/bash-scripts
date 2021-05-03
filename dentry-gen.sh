#!/bin/bash

SCRIPT_VERSION="2.0"
SCRIPT_NAME="Dentry Generator"

HELP_MESSAGE="\n%s %s, a .desktop File Generator\nUsage: dentry-gen [Options]... [Executable Path]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n\n"
VERSION_MESSAGE="%s version %s\n"
OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

FILE_NOT_FOUND_MESSAGE="Error: The specified executable file path could not be found."

LOCAL_SHARED_FOLDER_PATH="/home/$USER/.local/share"
ROOT_SHARED_FOLDER_PATH="/usr/share"
SHARED_FOLDER_PATH=""

DESKTOP_ENTRY_DESTINATION_FOLDER="applications"

APPLICATION_FOLDER_ALREADY_EXISTS_PROMPT="A folder for this file already exists, Override this directory? (y/N): "
ENTRY_CREATION_ABORTED_MESSAGE="Entry Creation Aborted.\n"
OVERRIDING_APPLICATION_FOLDER_MESSAGE="Overriding folder\n"

EXECUTABLE_PATH_NOT_FOUND_MESSAGE="The file '%s' was not found, aborting\n"

DESKTOP_ENTRY_GENERATED_SUCCESSFULLY_MESSAGE="The desktop entry was generated successfully\n"
ENTRY_UNINSTALL_ABORTED_MESSAGE="Aborting uninstall\n"

UNISTALL_DIRECTORY_NOT_FOUND_MESSAGE="The directory for %s could not be found, aborting unistall\n"
UNISTALL_DESKTOP_FILE_NOT_FOUND_MESSAGE="The desktop file for %s could not be found, aborting unistall\n"

CONFIRM_UNINSTALLATION_PROMPT="Are you sure you want to remove the %s desktop entry? (Y/n): "

INPUT_NOT_VALID_MESSAGE="%s is not a valid option, aborting\n"

VALID_DESKTOP_ENTRY_TYPES=("Application" "Link" "FSDevice" "MimeType" "Directory" "Service" "ServiceType")
VALID_DESKTOP_ENTRY_TERMINAL=("true" "false")

INVALID_DESKTOP_ENTRY_ARGUMENT_MESSAGE="The specified argument is not valid, valid types are: %s\nAborting entry creation\n"

DESKTOP_ENTRY_ARGUMENT_HEADER="[Desktop Entry Arguments]\n"
DESKTOP_ENTRY_TYPE_TITLE="Type="
DESKTOP_ENTRY_TERMINAL_TITLE="Terminal="
DESKTOP_ENTRY_COMMENT_TITLE="Comment="
DESKTOP_ENTRY_CATEGORIES_TITLE="Categories="
DESKTOP_ENTRY_GENERICNAME_TITLE="GenericName="

DESKTOP_ENTRY_TYPE_DEFAULT_VALUE="Application"
DESKTOP_ENTRY_TERMINAL_DEFAULT_VALUE="false"

USER_NAME="$(who)"
USER_NAME=${USER_NAME%% *}

VERBOSE_MODE_ENABLED=false

function setSharedFolder() {
	if [ "$EUID" == 0 ]; then
		SHARED_FOLDER_PATH="$ROOT_SHARED_FOLDER_PATH"
	else
		SHARED_FOLDER_PATH="$LOCAL_SHARED_FOLDER_PATH"
	fi
}

function checkArgumentValidity() {
	local argument=$1
	local valid_arguments_array=$2
	local argument_is_valid=false

	for valid_entry_type in ${valid_arguments_array[@]}; do
		if [[ $argument == $valid_entry_type ]]; then
			argument_is_valid=true
		fi
	done

	echo $argument_is_valid
}

function writeEntryFile() {
	local executable_file=$1
	local executable_name=${executable_file%.*}

	local formated_executable_name=${executable_name,,} && formated_executable_name=${formated_executable_name// /-}
	local entry_file_name="$formated_executable_name.desktop"

	local applications_folder_path=$2
	local shared_folder_path=$3

	local icon_file_path=$4
	local icon_file_name=${icon_file_path##*/}

	local entry_path="$shared_folder_path/$DESKTOP_ENTRY_DESTINATION_FOLDER/$entry_file_name"
	local executable_path="$applications_folder_path/$executable_file"

	if [[ $VERBOSE_MODE_ENABLED == true ]]; then
		printf "$DESKTOP_ENTRY_ARGUMENT_HEADER"

		printf $DESKTOP_ENTRY_TYPE_TITLE && read entry_type && entry_type=${entry_type:-"$DESKTOP_ENTRY_TYPE_DEFAULT_VALUE"}
		if [[ $(checkArgumentValidity "$entry_type" "${VALID_DESKTOP_ENTRY_TYPES[*]}") == false ]]; then
			printf "$INVALID_DESKTOP_ENTRY_ARGUMENT_MESSAGE" "${VALID_DESKTOP_ENTRY_TYPES[*]}" & exit
		fi
		
		printf $DESKTOP_ENTRY_TERMINAL_TITLE && read entry_terminal && entry_terminal=${entry_terminal:-"$DESKTOP_ENTRY_TERMINAL_DEFAULT_VALUE"}
		if [[ $(checkArgumentValidity "$entry_terminal" "${VALID_DESKTOP_ENTRY_TERMINAL[*]}") == false ]]; then
			printf "$INVALID_DESKTOP_ENTRY_ARGUMENT_MESSAGE" "${VALID_DESKTOP_ENTRY_TERMINAL[*]}" & exit
		fi

		printf $DESKTOP_ENTRY_COMMENT_TITLE && read entry_comment
		printf $DESKTOP_ENTRY_CATEGORIES_TITLE && read entry_categories
		printf $DESKTOP_ENTRY_GENERICNAME_TITLE && read entry_genericname
	fi

	entry_type=${entry_type:-"$DESKTOP_ENTRY_TYPE_DEFAULT_VALUE"}
	entry_terminal=${entry_terminal:-"$DESKTOP_ENTRY_TERMINAL_DEFAULT_VALUE"}

	printf "[Desktop Entry]\n" > "$entry_path"
	printf "Type=$entry_type\n" >> "$entry_path"
	printf "Terminal=$entry_terminal\n" >> "$entry_path"
	printf "Name=$executable_name\n" >> "$entry_path"
	printf "Path=$applications_folder_path\n" >> "$entry_path"
	printf "Exec=\"$executable_path\"\n" >> "$entry_path"

	if [[ -n $entry_comment ]]; then
		printf "Comment=$entry_comment\n" >> "$entry_path"
	fi

	if [[ -n $entry_categories ]]; then
		printf "Categories=$entry_categories\n" >> "$entry_path"
	fi
	
	if [[ -n $entry_genericname ]]; then
		printf "GenericName=$entry_genericname\n" >> "$entry_path"
	fi
	
	if [[ -n $icon_file_path ]]; then
		printf "Icon=$applications_folder_path/$icon_file_name\n" >> "$entry_path"
	fi
}

function checkApplicationsFolder() {
	local applications_folder_path=$1

	if [[ -d $applications_folder_path ]]; then
		printf "$APPLICATION_FOLDER_ALREADY_EXISTS_PROMPT" && read input
		case "$input" in

			[yY][eE][sS]|[yY]) printf "$OVERRIDING_APPLICATION_FOLDER_MESSAGE" && rm -d -r "$applications_folder_path" && mkdir -p "$applications_folder_path" ;;

			[nN][oO]|[nN]) printf "$ENTRY_CREATION_ABORTED_MESSAGE" && exit ;;

			*) printf "$INPUT_NOT_VALID_MESSAGE" "$input" && exit ;;

		esac

	else
		mkdir -p "$applications_folder_path"
	fi
}

function copyFileToApplicationsFolder() {
	local file_path=$1
	local file_name=${file_path##*/}
	local destination_folder=$2
	local copied_file_path="$destination_folder/$file_name"
	local is_executable=$3

	cp "$file_path" "$copied_file_path"

	if [[ $is_executable == true ]]; then
		chmod +x "$copied_file_path"
	fi
}

function removeEntry() {
	local desktop_entry_file_path=$1
	local desktop_entry_directory_path=$2

	rm -d -r "$desktop_entry_directory_path"
	rm "$desktop_entry_file_path"
}

function uninstallEntry() {
	local entry_name=$*
	local shared_folder_path=$SHARED_FOLDER_PATH
	local entry_directory_name=${entry_name,,} && entry_directory_name=${entry_directory_name// /-}
	local desktop_entry_directory_path="$shared_folder_path/$entry_directory_name"
	local desktop_entry_file_path="$shared_folder_path/$DESKTOP_ENTRY_DESTINATION_FOLDER/$entry_directory_name.desktop"

	if [[ ! -d $desktop_entry_directory_path ]]; then
		printf "$UNISTALL_DIRECTORY_NOT_FOUND_MESSAGE" "$entry_name" & exit
	fi

	if [[ ! -e $desktop_entry_file_path ]]; then
		printf "$UNISTALL_DESKTOP_FILE_NOT_FOUND_MESSAGE" "$entry_name" & exit
	fi
	
	printf "$CONFIRM_UNINSTALLATION_PROMPT" "$entry_name" && read input
	case "$input" in

		[yY][eE][sS]|[yY]|"") removeEntry "$desktop_entry_file_path" "$desktop_entry_directory_path" ;;

		[nN][oO]|[nN]) printf "$ENTRY_UNINSTALL_ABORTED_MESSAGE" && exit ;;

		*) printf "$INPUT_NOT_VALID_MESSAGE" "$input" && exit ;;

	esac
}

function generateEntry() {
	local executable_path=$1
	local executable_file=${executable_path##*/}
	local executable_name=${executable_file%.*}
	local formated_executable_name=${executable_name,,} && formated_executable_name=${formated_executable_name// /-}
	local icon_file_path=$2
	local shared_folder_path=$SHARED_FOLDER_PATH
	local applications_folder_path="$shared_folder_path/$formated_executable_name"

	if [[ ! -e $executable_path ]]; then
		printf "$EXECUTABLE_PATH_NOT_FOUND_MESSAGE" "$executable_path" & exit
	fi

	checkApplicationsFolder "$applications_folder_path"
	
	if [[ ! -z $icon_file_path ]]; then
		copyFileToApplicationsFolder "$icon_file_path" "$applications_folder_path" false
	fi

	copyFileToApplicationsFolder "$executable_path" "$applications_folder_path" true
	writeEntryFile "$executable_file" "$applications_folder_path" "$shared_folder_path" "$icon_file_path"

	printf "$DESKTOP_ENTRY_GENERATED_SUCCESSFULLY_MESSAGE"
}

setSharedFolder

while [[ "$1" =~ ^- ]]; do
	case "$1" in

        -h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;
        
        -V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

        -v | --verbose) VERBOSE_MODE_ENABLED=true && shift && continue ;;

		-I | --icon) generateEntry "$3" "$2" && exit ;;

		-u) uninstallEntry ${*:2} && exit ;;

        -*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

generateEntry "$1"