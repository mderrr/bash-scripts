#!/bin/bash

SCRIPT_VERSION="1.1"
SCRIPT_NAME="AUR Install"
HELP_MESSAGE="\n$SCRIPT_NAME $SCRIPT_VERSION, an AUR Install Helper\nUsage: aur-install [Options]... [AUR Link]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n"
VERSION_MESSAGE="$SCRIPT_NAME version $SCRIPT_VERSION"

function cloneAndMake() {
	git clone $1 $2
	cd $2 && makepkg -sirc
}

function removeDir() {
	echo "Cleaning up..."
	rm -r -f $1
}

function checkDir() {
	package=$1
	package_name=${package##*.org/} && package_name=${package_name%.git*}
	repo_dir="/home/$USER/Repositories/"
	git_dir=$repo_dir$package_name

	if [ ! -d "$git_dir" ]; then
		echo "Repository folder not found, creating one in '~/Repositories/'"
		mkdir $repo_dir
	fi

	cloneAndMake "$package" "$git_dir"
	removeDir "$git_dir"

	echo "AUR package installed successfully."
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

        -h | --help) echo -e $HELP_MESSAGE & exit ;;
        
        -V | --version) echo -e $VERSION_MESSAGE & exit ;;

        -*) echo "Option $1 not recognized" & exit ;;

	esac

	shift
done

checkDir $1