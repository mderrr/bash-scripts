#!/bin/zsh

SCRIPT_NAME="CPU Info"
SCRIPT_VERSION="0.2"
HELP_MESSAGE="\n%s %s, a cpu information script\nUsage: cpu-info [Options]... [Update Interval]\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

function getCpuUsage() {
	local test_time=0.9

	local total_starting_jiffies=$(cat /proc/stat | awk '/cpu/{i++}i==1 {print $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10 + $11}')
	local total_starting_work_jiffies=$(cat /proc/stat | awk '/cpu/{i++}i==1 {print $2 + $3 + $4}')

	sleep $test_time

	local total_ending_jiffies=$(cat /proc/stat | awk '/cpu/{i++}i==1 {print $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10 + $11}')
	local total_ending_work_jiffies=$(cat /proc/stat | awk '/cpu/{i++}i==1 {print $2 + $3 + $4}')

	local total_over_time=$(( total_ending_jiffies - total_starting_jiffies ))
	total_over_time="$total_over_time.0"

	local work_over_time=$(( total_ending_work_jiffies - total_starting_work_jiffies ))
	work_over_time="$work_over_time.0"

	local usage_over_time=$(( (work_over_time / total_over_time) * 100 ))
	usage_over_time=${usage_over_time:0:4}

	echo $usage_over_time
}

function main() {
	

	local number_of_cores=$(cat /proc/cpuinfo | grep "processor" | wc -l)
	local core_speeds=( $(cat /proc/cpuinfo | grep "cpu MHz" | cut -c12-) )
	local processor_name=$(cat /proc/cpuinfo | grep "model name" | cut -c14-30 | uniq)
	local processor_vendor=$(cat /proc/cpuinfo | grep "vendor" | cut -c13- | uniq)

	local cpu_temperature=$(sensors | grep Tctl | cut -c16-19)

	local average_core_speed=0
	for speed in ${core_speeds[@]}; do
		average_core_speed=$(( average_core_speed + speed ))
	done

	average_core_speed=$(( average_core_speed / number_of_cores )) 
	average_core_speed=${average_core_speed:0:8}
	#core_speeds=${core_speeds[*]}
	#core_speeds=${core_speeds//" "/,}





	printf "Vendor Name:\t\t%s\nProcessor Name:\t\t%s\n\nCores:\t\t\t%s Cores\nCore Speeds:\n\tAverage:\t%s MHz\n" "$processor_vendor" "$processor_name" "$number_of_cores" "$average_core_speed" 
	
	

	for ((i = 1 ; i < ${#core_speeds[@]} + 1 ; i++)); do
		local speed=${core_speeds[$i]}

		printf "\tCore %s:\t\t%s MHz\n" "$i" "$speed"
	done

	printf "\nCPU Temperature:\t%s °C\n" "$cpu_temperature"
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