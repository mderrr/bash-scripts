#!/bin/bash

SCRIPT_VERSION="1.0"

HELP_MESSAGE="\nDentry Generator $SCRIPT_VERSION, a .desktop file generator\nUsage: dentry-gen [OPTIONS]... [EXECUTABLE PATH]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message."
VERSION_MESSAGE="Dentry Generator version $SCRIPT_VERSION"
FILE_NOT_FOUND_MESSAGE="Error: The specified executable file path could not be found."




user_name="$(who)"
user_name=${user_name%% *}


if [ "$EUID" != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

function uninstallEntry () {
	entry_name=$*
	echo "Entry name is: $entry_name"
	entry_directory_name=${entry_name,,}
	entry_directory_name=${entry_directory_name// /-}
	echo $(rm -d -r "/usr/share/$entry_directory_name")	
	echo $(rm "/home/$user_name/.local/share/applications/$entry_name.desktop")

	exit

}


while [ -n "$1" ]; do # while loop starts

	case "$1" in

	-h) echo -e $HELP_MESSAGE ;; # Message for -a option

	-V) echo -e $VERSION_MESSAGE ;; # Message for -a option

	-u) 
		echo "befoer $@"
		echo ${*:2}
		uninstallEntry ${*:2}

		shift
		;;

	--help) echo -e $HELP_MESSAGE ;;

	--version) echo -e $VERSION_MESSAGE ;; # Message for -a option

	-*) echo "Option $1 not recognized" ;;

	*) FILE_PATH=$1 ;

	esac

	shift

done

if [ -f "$FILE_PATH" ]; then
	full_executable_name=${FILE_PATH##*/}
	executable_name=${full_executable_name%.*}

	user_name="$(who)"
	user_name=${user_name%% *}
	
	entry_name="$executable_name.desktop"
	entry_path="/home/$user_name/.local/share/applications/$entry_name"

	path_name=${executable_name,,}
	path_name=${path_name// /-}

	full_path="/usr/share/$path_name"
else
	echo $FILE_NOT_FOUND_MESSAGE
fi

if [ -d "$full_path" ]; then
	while true
	do
		echo -n "The directory '$path_name' is already present in /usr/share/, Do you want to replace this directory? (y/N): "
		read choice
			case $choice in
				[Yy]*) echo "Replacing directory..." && break ;;

				[Nn]*|"") echo "File already exists, terminating script." && exit ;;

				*) echo "Option not recognized" ;;
			esac
	done

	echo -n $(rm -d -r "$full_path")
fi

echo -n $(mkdir -p "$full_path")

echo -n $(cp "$FILE_PATH" "$full_path")
echo -n $(chmod +x "$full_path/$full_executable_name")

echo "Creating .desktop file..."

echo "[Desktop Entry]" > "$entry_path"
echo "Encoding=UTF-8" >> "$entry_path"
echo "Version=1.0" >> "$entry_path"
echo "Type=Application" >> "$entry_path"
echo "Terminal=false" >> "$entry_path"
echo "Name=$executable_name" >> "$entry_path"
echo "Path=$full_path" >> "$entry_path"
echo "Exec=\"$full_path/$full_executable_name\"" >> "$entry_path"
echo "Icon=\"$full_path/$executable_name.png\"" >> "$entry_path"
echo "Categories=Application" >> "$entry_path"
echo "GenericName=Interesting Point Geocoder" >> "$entry_path"
echo "Comment=Interesting Point Geocoder is a tool to create CSV files of geolocational data" >> "$entry_path"