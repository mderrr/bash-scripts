#!/bin/bash

SCRIPT_NAME="Custom Bar Script"
SCRIPT_VERSION="1.0"
HELP_MESSAGE="\n%s %s, a script for gnome custom bar extension\nUsage: custom-bar-script [Options]...\n\nOptions:\n -V, --version\t\t\tDisplay script version.\n -h, --help\t\t\tShow this help message.\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

function getUname() {
	local output=$(uname -r)
	echo $output
}

function getAverageCpuSpeed() {
	local cpu_speeds=( $* )
	local average_cpu_speed=0

	for speed in ${cpu_speeds[@]}; do
		average_cpu_speed=$(python -c "print($average_cpu_speed + $speed)")
	done

	average_cpu_speed=$(python -c "print(round($average_cpu_speed / ${#cpu_speeds[@]}, 3))")

	echo $average_cpu_speed
}

function processorInfo() {
	local vendor_name=( $(cat /proc/cpuinfo | grep "vendor" | uniq | cut -c13-) ) vendor_name=${vendor_name[*]}
	local model_name=( $(cat /proc/cpuinfo | grep "model name" | uniq | cut -c14-) ) && model_name=${model_name[*]}
	local number_of_cores=$(cat /proc/cpuinfo | grep "processor" | wc -l)
	local current_cpu_speeds=( $(cat /proc/cpuinfo | grep "cpu MHz" | cut -c12-) ) 
	local average_cpu_speed=$(getAverageCpuSpeed "${current_cpu_speeds[@]}")
	local cpu_temperature=$(sensors | grep Tctl | cut -c16-)

	local user_cpu_usage=$(top -n 1 | grep "%Cpu(s):" | cut -c29-31)
	local system_cpu_usage=$(top -n 1 | grep "%Cpu(s):" | cut -c70-72)
	local total_cpu_usage=$(python -c "print($user_cpu_usage.replace(",", ".") + $system_cpu_usage)")
	

	printf "vendor: %s\n" "$vendor_name"
	printf "model: %s\n"  "$model_name"
	printf "number of cores: %s\n" "$number_of_cores"
	printf "total current cpu speed: %s\n" "$total_current_cpu_speed"
	printf "individual current cpu speed: %s\n" "${current_cpu_speeds[@]}"
	printf "avg current cpu speed: %s\n" "$average_cpu_speed"
	printf "temp: %s\n" "$cpu_temperature"
	printf "user_cpu_usage: %s\n" "$user_cpu_usage"
	printf "system_cpu_usage: %s\n" "$system_cpu_usage"
	printf "total_cpu_usage: %s\n" "$total_cpu_usage"
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-U | --uname) getUname && exit ;;

		-p | --processor-info) processorInfo && exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$file_path" & exit ;;

	esac

	shift
done