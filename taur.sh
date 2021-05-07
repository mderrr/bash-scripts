#!/bin/bash

SCRIPT_VERSION="2.1"
SCRIPT_NAME="TAUR"

HELP_MESSAGE="\n%s %s, a Tool for the Arch User Repository\nUsage: taur [Options]... [AUR Link]\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n -I, --install\t\t\tInstall the specified package (Default Option)\n -u, --update\t\t\tFind updates for installed packages\n -Iu, --install-updates\t\tFind and Install updates for installed packages\n -Q, --query\t\t\tSearch installed packages\n\n"
VERSION_MESSAGE="%s version %s\n"
OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

REMOVING_DIR_MESSAGE="Cleaning up...\n"
REPOSITORY_DIRECTORY_NOT_FOUND_MESSAGE="Repository folder not found, creating one in '~/Repositories/'\n"
INSTALLING_PACKAGE_MESSAGE="Installing package: %s...\n"
SUCCESSFULLY_INSTALLED_MESSAGE="AUR package: %s was installed successfully\n"
INSTALLING_UPDATED_PACKAGES_MESSAGE="Installing updated packages...\n"
UPDATED_PACKAGE_NOT_FOUND_MESSAGE="Package: '%s' not found in out-dated packages list, skipping installation\n"
OUTDATED_PACKAGES_FOUND_MESSAGE="\nFound one or more packages that are out-dated, run 'taur -CI' to install all updates, or specify a list of packages to update\n"
ALL_PACKAGES_UPDATED_MESSAGE="\nAll packages are up-to-date with the Arch User Repository\n"
NO_MATCHING_PACKAGES_FOUND_MESSAGE="No matching packages found\n"
CONNECTION_NOT_FOUND_MESSAGE="Could not connect to the AUR, please try again\n"
INSTALLED_PACKAGES_MESSAGE="Installed packages:\n\n"
NO_LINK_PROVIDED_MESSAGE="No link provided, aborting installation\n"

CONFIG_FILE_PACKAGE_HEADER="[Package]\t\t\t\t\t\t[Version]\n"

CONFIG_FILE_PATH="/home/$USER/.config/taur/taur.conf"
CONFIG_DIR_PATH=${CONFIG_FILE_PATH%/*}

NEWLINE="\n"

CONFIG_FILE_OUTDATED_PACKAGE_TEMPLATE=" %s [ OUTDATED ]\n"
CONFIG_FILE_UPTODATE_PACKAGE_TEMPLATE=" %s [ OK ]\n"
QUERY_RESULT_TEMPLATE="%s\n"

REPOSITORIES_DIRECTORY="/home/$USER/Repositories/"

sedStartLine() { sed -n '/<div id="pkgdetails" class="box">/,$p'; }
sedEndLine() { sed -n '/<div id="detailslinks" class="listing">/q;p'; }

function cloneAndMake() {
	local package_link=$1
	local repository_directory=$2

	git clone $package_link $repository_directory
	cd $repository_directory && makepkg -sirc
}

function removeDir() {
	local directory=$1
	printf "$REMOVING_DIR_MESSAGE"

	rm -r -f $directory
}

function checkRepoDir() {
	local repositories_directory=$1

	if [[ ! -d "$repositories_directory" ]]; then
		printf "$REPOSITORY_DIRECTORY_NOT_FOUND_MESSAGE" 
		mkdir $repositories_directory
	fi
}

function createConfigFile() {
	printf "$CONFIG_FILE_PACKAGE_HEADER" > $CONFIG_FILE_PATH
}

function checkConfigFile() {
	if [[ ! -d $CONFIG_DIR_PATH ]]; then
		mkdir $CONFIG_DIR_PATH
	fi

	if [[ ! -e $CONFIG_FILE_PATH ]]; then
		createConfigFile 
	fi
}

function calculateTabs() {
	local string_length=$1

	number_of_tabs=$(("(-($string_length+1) / 8) + 7"))

	echo "$number_of_tabs"
}

function getTabbedString() {
	local string="$1"
	local string_length=${#1}
	local number_of_tabs=$(calculateTabs $string_length)
	
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

function fetchCurrentVersion() {
	local package_name=$1
	local lastest_version=$(curl https://aur.archlinux.org/packages/$package_name/ --silent | sedStartLine | sedEndLine | tail -n+2)

    lastest_version=${lastest_version#*"<h2>Package Details: $package_name"}
    lastest_version=${lastest_version%"</h2>"}
    
    echo $lastest_version
}

function saveNewPackage() {
	local package_name=$1
	local current_version="$(fetchCurrentVersion $package_name)"
	
	deleteCoincidences "$package_name"
	tabbed_string=$(getTabbedString $package_name $current_version)

	printf "$tabbed_string\n" >> $CONFIG_FILE_PATH
}

function installPackage() {
	local package_link=$1
	local package_name=${package_link##*.org/} && package_name=${package_name%.git*}
	local git_directory=$REPOSITORIES_DIRECTORY$package_name

	if [[ -z "$package_link" ]]; then
		printf "$NO_LINK_PROVIDED_MESSAGE"
		exit
	fi

	printf "$INSTALLING_PACKAGE_MESSAGE" "$package_name" 

	checkConfigFile
	checkRepoDir "$REPOSITORIES_DIRECTORY"
	cloneAndMake "$package_link" "$git_directory"
	removeDir "$git_directory"

	saveNewPackage "$package_name"

	printf "$SUCCESSFULLY_INSTALLED_MESSAGE" "$package_name" 
}

function checkIfIsUpdated() {
	local package_name=$1
	local current_version=$2
	local lastest_version=$(fetchCurrentVersion $package_name)
	
	if [[ $current_version != $lastest_version ]]; then
		echo false
	else
		echo true
	fi
}

function installUpdates() {
	local outdated_package_list=$1
	local packages_to_update=${2:-"$outdated_package_list"} && packages_to_update=($packages_to_update)

	printf "$INSTALLING_UPDATED_PACKAGES_MESSAGE"

	for package in "${packages_to_update[@]}"; do
		if [[ "${outdated_package_list[@]}" =~ "${package}" ]]; then
			package=${package//[[:blank:]]/}
			local package_link="https://aur.archlinux.org/${package}.git"

			installPackage "$package_link"
		
		else
			printf "$UPDATED_PACKAGE_NOT_FOUND_MESSAGE" "$package" 
			exit
		fi
	done
}

function checkForConnection() {
	ping -c 1 -q google.com >&/dev/null
	
	echo $?
}

function checkUpdates() {
	local install_updates="${1:-false}"
	local packages_to_update="$2"
	local number_of_lines=$(wc -l $CONFIG_FILE_PATH) && number_of_lines=${number_of_lines%"$CONFIG_FILE_PATH"} && number_of_lines=$(("$number_of_lines + 1"))
	local isConnected=$(checkForConnection)
	local outdated_packages=()

	if [[ $isConnected -ne 0 ]]; then
		printf "$CONNECTION_NOT_FOUND_MESSAGE" & exit
	fi

	printf "$INSTALLED_PACKAGES_MESSAGE"

	for ((i = 2 ; i < $number_of_lines + 0 ; i++)); do
		local current_line=$(sed -n "$i p" $CONFIG_FILE_PATH)
		local version=($current_line) && version=${version[-1]}
		local package_name=${current_line%$version}

		if [[ $(checkIfIsUpdated "$package_name" "$version") == false ]]; then
			printf "$CONFIG_FILE_OUTDATED_PACKAGE_TEMPLATE" "$package_name"
			outdated_packages=("${outdated_packages[@]}" "$package_name")
		else
			printf "$CONFIG_FILE_UPTODATE_PACKAGE_TEMPLATE" "$package_name" > /dev/tty
		fi

	done

	if [[ "${outdated_packages[@]}" > 0 ]]; then
		if [[ "$install_updates" == true ]]; then
			installUpdates "$outdated_packages" "$packages_to_update"

		else
			printf "$OUTDATED_PACKAGES_FOUND_MESSAGE"
		fi

	else
		printf "$ALL_PACKAGES_UPDATED_MESSAGE"
	fi
}

function getNumberOfUpdates() {
	local install_updates="${1:-false}"
	local number_of_lines=$(wc -l $CONFIG_FILE_PATH) && number_of_lines=${number_of_lines%"$CONFIG_FILE_PATH"} && number_of_lines=$(("$number_of_lines + 1"))
	local isConnected=$(checkForConnection)
	local outdated_packages=()

	if [[ $isConnected -ne 0 ]]; then
		printf "$CONNECTION_NOT_FOUND_MESSAGE" & exit
	fi

	for ((i = 2 ; i < $number_of_lines + 0 ; i++)); do
		local current_line=$(sed -n "$i p" $CONFIG_FILE_PATH)
		local version=($current_line) && version=${version[-1]}
		local package_name=${current_line%$version}

		if [[ $(checkIfIsUpdated "$package_name" "$version") == false ]]; then
			outdated_packages=("${outdated_packages[@]}" "$package_name")
		fi

	done

	echo ${#outdated_packages[@]} 
}

function displayQueryResults() {
	local filter=${1,,}
	local number_of_lines=$(wc -l $CONFIG_FILE_PATH) && number_of_lines=${number_of_lines%"$CONFIG_FILE_PATH"} && number_of_lines=$(("$number_of_lines + 1"))
	local query_results=()

	for ((i = 2 ; i < $number_of_lines + 1 ; i++)); do
		local current_line=$(sed -n "$i p" $CONFIG_FILE_PATH)
		local version=($current_line) && version=${version[-1]}
		local package_name=${current_line%$version} && package_name=${package_name//[[:blank:]]/}
		local query_result="$package_name $version"

		if [[ -z $filter ]]; then
			query_results=("${query_results[@]}" "$query_result")
		
		else
			if [[ "$package_name" == *"$filter"* ]]; then
				query_results=("${query_results[@]}" "$query_result")
			fi
		fi	
		
	done

	if [[ -z "${query_results[@]}" ]]; then
		printf "$NO_MATCHING_PACKAGES_FOUND_MESSAGE"
	fi
	
	for result in "${query_results[@]}"; do
		printf "$QUERY_RESULT_TEMPLATE" "$result"
	done
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

        -h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;
        
        -V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-I | --install) installPackage $2 && exit ;;

		-u | --update) checkUpdates false && exit ;;

		-Nu | --number-of-updates) getNumberOfUpdates && exit ;;

		-Iu | --install-updates) checkUpdates true "${*:2}" && exit ;;

		-Q | --query) displayQueryResults $2 && exit ;;

        -*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

installPackage $1