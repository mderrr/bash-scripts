#!/bin/bash

SCRIPT_VERSION="1.3"
SCRIPT_NAME="Tool for AUR"
HELP_MESSAGE="\n$SCRIPT_NAME $SCRIPT_VERSION, an AUR Install Helper\nUsage: taur [Options]... [AUR Link]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n"
VERSION_MESSAGE="$SCRIPT_NAME version $SCRIPT_VERSION"
CONFIG_FILE_PATH="/home/$USER/.config/taur/taur.conf"
CONFIG_DIR_PATH=${CONFIG_FILE_PATH%/*}

function cloneAndMake() {
	local package_link=$1
	local repository_dir=$2
	echo "$package_link and $repository_dir"
	git clone $package_link $repository_dir
	
	cd $repository_dir && makepkg -sirc
}

function removeDir() {
	echo "Cleaning up..."
	rm -r -f $1
}

function checkRepoDir() {
	local repo_dir=$1

	if [ ! -d "$repo_dir" ]; then
		echo "Repository folder not found, creating one in '~/Repositories/'"
		mkdir $repo_dir
	fi
}

function installPackage() {
	local package_link=$1
	local package_name=${package_link##*.org/} && package_name=${package_name%.git*}
	local repo_dir="/home/$USER/Repositories/"
	local git_dir=$repo_dir$package_name

	
	checkConfigFile
	checkRepoDir "$repo_dir"
	#	cloneAndMake "$package_link" "$git_dir"
	#removeDir "$git_dir"


	saveNewPackage "$package_name"

	echo "AUR package installed successfully."
}

function fetchCurrentVersion() {
	local package_name=$1

    sedStartLine() { sed -n '/<div id="pkgdetails" class="box">/,$p'; }
    sedEndLine() { sed -n '/<div id="detailslinks" class="listing">/q;p'; }

    local lastest_version=$(curl https://aur.archlinux.org/packages/$package_name/ --silent | sedStartLine | sedEndLine | tail -n+2)
    lastest_version=${lastest_version#*"<h2>Package Details: $package_name"}
    lastest_version=${lastest_version%"</h2>"}
    
    echo $lastest_version
}

function calculateTabs() {
	number_of_tabs=$(("(-($1+1) / 8) + 7"))
	echo "$number_of_tabs"
}

function getTabbedString() {
	string_length=${#1}
	number_of_tabs=$(calculateTabs $string_length)
	string="$1"

	for ((i = 0 ; i < $number_of_tabs ; i++)); do
		string="${string}\t"
	done
	string="${string}$2"
	echo "$string"
}

function deleteCoincidences() {
	local package_name=$1
	local package_found=$(grep -Fxq "$package_name" $CONFIG_FILE_PATH)

	if [[ package_found ]]; then
		sed -i -e "s/^$package_name.*$//g" $CONFIG_FILE_PATH && sed -i "/^$/d" $CONFIG_FILE_PATH
	fi
}

function saveNewPackage() {
	local package_name=$1
	local current_version="$(fetchCurrentVersion $package_name)"
	
	deleteCoincidences "$package_name"
	tabbed_string=$(getTabbedString $package_name $current_version)

	echo -e "$tabbed_string" >> $CONFIG_FILE_PATH
}

function createConfigFile() {
	echo -e "[Package]\t\t\t\t\t\t[Version]" > $CONFIG_FILE_PATH
}

function checkConfigFile() {
	if [[ ! -d $CONFIG_DIR_PATH ]]; then
		mkdir $CONFIG_DIR_PATH
	fi

	if [[ ! -e $CONFIG_FILE_PATH ]]; then
		createConfigFile 
	fi
}

function checkIfIsUpdated() {
	local package_name=$1
	local current_version=$2
	local lastest_version=$(fetchCurrentVersion $package_name)
	local outdated_packages=()
	
	if [[ $current_version != $lastest_version ]]; then
		echo "$package_name [ OUTDATED ]" > /dev/tty
		echo false
	else
		echo "$package_name [ OK ]" > /dev/tty
		echo true
	fi

	
}

function checkUpdates() {
	local install_updates="${1:-false}"
	local number_of_lines=$(wc -l $CONFIG_FILE_PATH) && number_of_lines=${number_of_lines%"$CONFIG_FILE_PATH"} && number_of_lines=$(("$number_of_lines + 1"))
	local outdated_packages=()

	for ((i = 2 ; i < $number_of_lines ; i++)); do
		local current_line=$(sed -n "$i p" $CONFIG_FILE_PATH)
		local version=($current_line) && version=${version[-1]}
		local package_name=${current_line%$version}

		if [[ $(checkIfIsUpdated "$package_name" "$version") == false ]]; then
			#echo "$package_name [ OUTDATED ]"
			outdated_packages=("${outdated_packages[@]}" "$package_name") 
		fi

	done

	if [[ "$install_updates" == true ]]; then
		echo "aaaa"
		echo "${outdated_packages[@]}"

		for package in "${outdated_packages[@]}"; do
			package=${package//[[:blank:]]/}
			local package_link="https://aur.archlinux.org/${package}.git"

			installPackage "$package_link"
		done
	fi

	
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

        -h | --help) echo -e $HELP_MESSAGE & exit ;;
        
        -V | --version) echo -e $VERSION_MESSAGE & exit ;;

		-C | --check-updates) checkUpdates true && exit ;;

        -*) echo "Option $1 not recognized" & exit ;;

	esac

	shift
done

installPackage $1
#checkConfigFile