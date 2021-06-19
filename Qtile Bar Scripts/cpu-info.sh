#!/bin/zsh

SCRIPT_NAME="CPU Info"
SCRIPT_VERSION="0.3"
HELP_MESSAGE="\n%s %s, a Qtile CPU information script\nUsage: cpu-info [Options]...\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

function colorAndCenter() {
	local color=$1
	local text=${*:2}

	printf "\e[1;${color}m%*s\e[m" $(( (${#text} + COLUMNS) / 2 )) "$text"
}

function color() {
	local color=$1
	local text=${*:2}

	printf "\e[${color}m%s\e[m" "$text"
}

function main() {
	local processor_name=$(cat /proc/cpuinfo | grep "model name" | cut -c14- | uniq)
	local processor_vendor=$(cat /proc/cpuinfo | grep "vendor" | cut -c13- | uniq)
	local cache_size=$(cat /proc/cpuinfo | grep "cache size" | cut -c14- | uniq)

	local number_of_cores=$(cat /proc/cpuinfo | grep "processor" | wc -l)

	local core_speeds=( $(cat /proc/cpuinfo | grep "cpu MHz" | cut -c12-) )

	local cpu_temperature=$(sensors | grep Tctl | cut -c16-19)

	printf "%s\n" "$(colorAndCenter 91 $SCRIPT_NAME)"

	printf "\n%s\n" "$(color "1;93" "[ Processor Info ]")"
	printf "%s %s\n" "$(color "33" " • Reference:")" "$processor_name" "$(color "33" " • Vendor:")" "$processor_vendor" "$(color "33" " • Cache:")" "$cache_size"

	printf "\n%s\n" "$(color "1;92" "[ Core Info ]")"
	printf "%s %s\n" "$(color "32" " • Cores:")" "$number_of_cores"

	printf "\n%s\n" "$(color "1;94" "[ Core Speed ]")"
	for ((i = 1 ; i < ${#core_speeds[@]} + 1 ; i++)); do
		local speed=${core_speeds[$i]}

		printf "%s %s MHz\n" "$(color "34" " • Core $i:")" "$speed"
	done

	printf "\n%s\n" "$(color "1;95" "[ CPU Info ]")"
	printf "%s %s°C\n" "$(color "35" " • Temperature:")" "$cpu_temperature"
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

main