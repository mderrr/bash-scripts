#!/bin/zsh

SCRIPT_NAME="MEM Info"
SCRIPT_VERSION="0.2"
HELP_MESSAGE="\n%s %s, a Memory information script\nUsage: mem-info [Options]...\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

function main() {
	local memory_size=$(free -h --si | awk '/Mem:/ {print $2}')
	local memory_used=$(free -h --si | awk '/Mem:/ {print $3}')
	local memory_used_unit=${memory_used[-1]}
	local memory_free=$(free -h --si | awk '/Mem:/ {print $4}')
	local memory_shared=$(free -h --si | awk '/Mem:/ {print $5}')
	local memory_buffer=$(free -h --si | awk '/Mem:/ {print $6}')
	local memory_available=$(free -h --si | awk '/Mem:/ {print $7}')

	printf "Memory Info\n\n"

	printf "Total Size:\t%sB\nBeing Used:\t%sB\nFree:\t\t%sB\nShared Size:\t%sB\nBuffer Size:\t%sB\nAvailable:\t%sB\n" "$memory_size" "$memory_used" "$memory_free" "$memory_shared" "$memory_buffer" "$memory_available" 
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