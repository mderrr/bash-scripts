#!/bin/zsh

SCRIPT_VERSION="3.3"
SCRIPT_NAME="TAUR"

HELP_MESSAGE="\n%s %s, a Tool for the Arch User Repository\nUsage: taur [Options]... [AUR Link]\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n -q, --quiet\t\t\tEnable quiet mode\n -Nu, --number-of-updates\tDisplay the number of available updates\n -S, --sync-package\t\tInstall an AUR package\n -Su, --sync-updates\t\tInstall available updates\n -Sy, --sync-database\t\tSync with the AUR's database\n -Syu, --sync-and-update\tSync database then install available updates\n -Synu\t\t\t\tSync database then display number of updates\n -Q, --query\t\t\tDisplay installed packages\n -Qu, --query-updates\t\tDisplay packages with available updates\n\n"
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
SYNCING_AUR_PACKAGES_MESSAGE="Synchronizing AUR package databases...\n"
SYNCING_AUR_PACKAGES_DONE_MESSAGE="AUR package database is up to date\n"

CONFIG_FILE_PACKAGE_HEADER="[Package]\t\t\t\t\t\t[Version]\n"

CONFIG_DIR_PATH="/home/$USER/.config/taur/"

CONFIG_FILE_PATH="${CONFIG_DIR_PATH}taur.conf"

INSTALLED_PACKAGES_FILE_PATH="${CONFIG_DIR_PATH}installed-packages"
OUTDATED_PACKAGES_FILE_PATH="${CONFIG_DIR_PATH}outdated-packages"

NEWLINE="\n"

CONFIG_FILE_OUTDATED_PACKAGE_TEMPLATE=" %s [ OUTDATED ]\n"
CONFIG_FILE_UPTODATE_PACKAGE_TEMPLATE=" %s [ OK ]\n"
QUERY_RESULT_TEMPLATE="%s\n"

REPOSITORIES_DIRECTORY="/home/$USER/Repositories/"

HTTPS_FORMAT="https://"

QUIET_MODE_ENABLED=1

sedStartLine() { sed -n '/<div id="pkgdetails" class="box">/,$p'; }
sedEndLine() { sed -n '/<div id="detailslinks" class="listing">/q;p'; }

function cloneAndMake() {
	local package_link=$1
	local repository_directory=$2

	git clone $package_link $repository_directory
	cd $repository_directory && makepkg -sirc --noconfirm
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

function createInstalledPackagesFile() {
	printf "" > $INSTALLED_PACKAGES_FILE_PATH
}

function createOutdatedPackagesFile() {
	printf "" > $OUTDATED_PACKAGES_FILE_PATH
}

function checkConfigFile() {
	if [[ ! -d $CONFIG_DIR_PATH ]]; then
		mkdir $CONFIG_DIR_PATH
	fi

	if [[ ! -e $INSTALLED_PACKAGES_FILE_PATH ]]; then
		createInstalledPackagesFile 
	fi

	if [[ ! -e $OUTDATED_PACKAGES_FILE_PATH ]]; then
		createOutdatedPackagesFile 
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
	local package_found=$(grep -Fxq "$package_name" $INSTALLED_PACKAGES_FILE_PATH)

	if [[ package_found ]]; then
		sed -i -e "s/^$package_name.*$//g" $INSTALLED_PACKAGES_FILE_PATH && sed -i "/^$/d" $INSTALLED_PACKAGES_FILE_PATH
	fi
}

function fetchCurrentVersion() {
	local package_name=$1
	local package_pkgver=$(curl -s "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${package_name}" | awk '/pkgver=/') && package_pkgver=${package_pkgver##*=}
	local package_pkgrel=$(curl -s "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${package_name}" | awk '/pkgrel=/') && package_pkgrel=${package_pkgrel##*=}
	local lastest_version="${package_pkgver}-${package_pkgrel}"

    echo $lastest_version
}

function saveNewPackage() {
	local package_name=$1
	local current_version="$(fetchCurrentVersion $package_name)"
	
	deleteCoincidences "$package_name"

	printf "${package_name} ${current_version}\n" >> $INSTALLED_PACKAGES_FILE_PATH
}

function markUpdated() {
	local package_name=$1
	local package_found=$(grep -Fxq "$package_name" $OUTDATED_PACKAGES_FILE_PATH)

	if [[ package_found ]]; then
		sed -i -e "s/^$package_name.*$//g" $OUTDATED_PACKAGES_FILE_PATH && sed -i "/^$/d" $OUTDATED_PACKAGES_FILE_PATH
	fi
}

function formatInputArgument() {
	local input_argument=$1

	if ! [[ $input_argument =~ "$HTTPS_FORMAT" ]]; then
		input_argument="https://aur.archlinux.org/${input_argument}.git"
	fi

	echo $input_argument
}

function installPackage() {
	if [[ -z "$1" ]]; then
		printf "$NO_LINK_PROVIDED_MESSAGE" & exit
	else
		local package_link=$(formatInputArgument "$1")
	fi

	local package_name=${package_link##*.org/} && package_name=${package_name%.git*}
	local git_directory=$REPOSITORIES_DIRECTORY$package_name

	

	printf "$INSTALLING_PACKAGE_MESSAGE" "$package_name" 

	checkConfigFile
	checkRepoDir "$REPOSITORIES_DIRECTORY"
	cloneAndMake "$package_link" "$git_directory"
	removeDir "$git_directory"

	saveNewPackage "$package_name"
	markUpdated "$package_name"

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

function syncAurPackages() {
	if [[ $(checkForConnection) -ne 0 ]]; then
		printf "$CONNECTION_NOT_FOUND_MESSAGE" & exit
	fi

	local number_of_lines=$(wc -l < $INSTALLED_PACKAGES_FILE_PATH) 

	if [[ $QUIET_MODE_ENABLED != 0 ]]; then
		printf "$SYNCING_AUR_PACKAGES_MESSAGE"
	fi

	for ((i = 1 ; i < $number_of_lines + 1 ; i++)); do
		local package_name=$(cat "$INSTALLED_PACKAGES_FILE_PATH" | awk '{i++}i=='"$i"' {print $1}')
		local package_version=$(cat "$INSTALLED_PACKAGES_FILE_PATH" | awk '{i++}i=='"$i"' {print $2}')
		local latest_version=$(fetchCurrentVersion "$package_name")

		if [[ $package_version != $latest_version ]]; then
			printf "%s\n" "$package_name" > "$OUTDATED_PACKAGES_FILE_PATH"
		fi
	done

	if [[ $QUIET_MODE_ENABLED != 0 ]]; then
		printf "$SYNCING_AUR_PACKAGES_DONE_MESSAGE"
	fi
}

function getAvailableUpdates() {
	local return_list="${1:-false}"
	local list_of_outdated_packages=()

	while read line; do
		list_of_outdated_packages+=("$line")
	done < $OUTDATED_PACKAGES_FILE_PATH

	if [[ $return_list == true ]]; then
		if [[ ${#list_of_outdated_packages[@]} < 1 ]]; then
			printf "" && exit
		fi

		printf "%s\n" "${list_of_outdated_packages[@]}"
	else
		echo ${#list_of_outdated_packages[@]}
	fi
}

function syncDatabasesAndUpdate() {
	syncAurPackages

	local number_of_available_updates=$(getAvailableUpdates)

	if [[ $number_of_available_updates > 0 ]]; then

		for ((i = 1 ; i < $number_of_available_updates + 1 ; i++)); do
			local current_line=$(sed "${i}q;d" $OUTDATED_PACKAGES_FILE_PATH)
			local version=($current_line) && version=${version[-1]}
			local package_name=${current_line% $version}

			installPackage "$package_name"
		done
	fi
}

function displayQueryResults() {
	local filter=${1:l}
	local number_of_lines=$(wc -l < $INSTALLED_PACKAGES_FILE_PATH)
	local query_results=()

	for ((i = 1 ; i < $number_of_lines + 1 ; i++)); do
		local current_line=$(sed "${i}q;d" $INSTALLED_PACKAGES_FILE_PATH)

		if [[ -z $filter ]]; then
			query_results=("${query_results[@]}" "$current_line")
		
		else
			if [[ "$query_result" == *"$filter"* ]]; then
				query_results=("${query_results[@]}" "$current_line")
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

function installAvailableUpdates() {
	local number_of_updates=$(wc -l < $OUTDATED_PACKAGES_FILE_PATH)

	if [[ number_of_updates == 0 ]]; then
		printf "There are no available updates to install. Did you sync the database?\n"
		exit 0
	fi

	for ((i = 1 ; i < $number_of_updates + 1 ; i++)); do
		local package_name=$(cat "$OUTDATED_PACKAGES_FILE_PATH" | awk '{i++}i=='"$i"' {print $1}')

		installPackage "$package_name"
	done
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

        -h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;
        
        -V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-q | --quiet) QUIET_MODE_ENABLED=0 && shift && continue ;;

		-Nu | --number-of-updates) getAvailableUpdates false && exit ;;

		-S | --sync-package) installPackage $2 && exit ;;

		-Su | --sync-updates) installAvailableUpdates && exit ;;

		-Sy | --sync-database) syncAurPackages && exit ;;

		-Syu | --sync-and-update) syncDatabasesAndUpdate && exit ;;

		-Synu) QUIET_MODE_ENABLED=0 && syncAurPackages && getAvailableUpdates false && exit ;;

		-Q | --query) displayQueryResults $2 && exit ;;

		-Qu | --query-updates) getAvailableUpdates true && exit ;;

        -*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

installPackage $1