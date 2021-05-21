#!/bin/zsh

SCRIPT_NAME="Custom Bar Script"
SCRIPT_VERSION="1.1"
HELP_MESSAGE="\n%s %s, a script for gnome custom bar extension\nUsage: custom-bar-script [Options]...\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n -a, --all\t\t\treturn all bar information\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

function getCpuAndNetworkUsage() {
	local network_interface="eno1"

	local test_time=0.9

	local starting_received_bytes=$(cat /sys/class/net/$network_interface/statistics/rx_bytes)
	local starting_transmitted_bytes=$(cat /sys/class/net/$network_interface/statistics/tx_bytes)

	local total_starting_jiffies=$(cat /proc/stat | awk '/cpu/{i++}i==1 {print $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10 + $11}')
	local total_starting_work_jiffies=$(cat /proc/stat | awk '/cpu/{i++}i==1 {print $2 + $3 + $4}')

	sleep $test_time

	local ending_received_bytes=$(cat /sys/class/net/$network_interface/statistics/rx_bytes)
	local ending_transmitted_bytes=$(cat /sys/class/net/$network_interface/statistics/tx_bytes)

	local total_ending_jiffies=$(cat /proc/stat | awk '/cpu/{i++}i==1 {print $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10 + $11}')
	local total_ending_work_jiffies=$(cat /proc/stat | awk '/cpu/{i++}i==1 {print $2 + $3 + $4}')


	local total_received_bytes=$(( (ending_received_bytes - starting_received_bytes) / 1000 ))
	local total_transmitted_bytes=$(( (ending_transmitted_bytes - starting_transmitted_bytes) / 1000 ))

	local total_over_time=$(( total_ending_jiffies - total_starting_jiffies ))
	total_over_time="$total_over_time.0"
	local work_over_time=$(( total_ending_work_jiffies - total_starting_work_jiffies ))
	work_over_time="$work_over_time.0"

	local usage_over_time=$(( (work_over_time / total_over_time) * 100 ))
	usage_over_time=${usage_over_time:0:4}

	local result=( "$usage_over_time" "$total_received_bytes,$total_transmitted_bytes" )
	echo $result[@]
}

function getAllInfo() {
	local uname=$(uname -a | awk '{printf "%s,%s,%s,%s,%s %s %s\n", $3, $14, $2, $13, $8, $9, $10}')

	local cpu_and_network_usage=( $(getCpuAndNetworkUsage) )

	local cpu_temperature=$(sensors | grep Tctl | cut -c16-19)
	local cpu_usage_percentage=${cpu_and_network_usage[1]}
	local number_of_cores=$(cat /proc/cpuinfo | grep "processor" | wc -l)
	local core_speeds=( $(cat /proc/cpuinfo | grep "cpu MHz" | cut -c12-) )
	local processor_name=$(cat /proc/cpuinfo | grep "model name" | cut -c14-30 | uniq)
	local processor_vendor=$(cat /proc/cpuinfo | grep "vendor" | cut -c13- | uniq)

	local average_core_speed=0
	for speed in ${core_speeds[@]}; do
		average_core_speed=$(( average_core_speed + speed ))
	done

	average_core_speed=$(( average_core_speed / number_of_cores )) 
	average_core_speed=${average_core_speed:0:8}
	core_speeds=${core_speeds[*]}
	core_speeds=${core_speeds//" "/,}

	local memory_size=$(free -h --si | awk '/Mem:/ {print $2}')
	memory_size=${memory_size:0:-1}
	memory_size=${memory_size//,/.}
	local memory_used=$(free -h --si | awk '/Mem:/ {print $3}')
	memory_used=${memory_used:0:-1} 
	memory_used=${memory_used//,/.}
	local memory_free=$(free -h --si | awk '/Mem:/ {print $4}')
	memory_free=${memory_free:0:-1}
	memory_free=${memory_free//,/.}
	local memory_shared=$(free -h --si | awk '/Mem:/ {print $5}')
	memory_shared=${memory_shared:0:-1}
	memory_shared=${memory_shared//,/.}
	local memory_buffer=$(free -h --si | awk '/Mem:/ {print $6}')
	memory_buffer=${memory_buffer:0:-1}
	memory_buffer=${memory_buffer//,/.}
	local memory_available=$(free -h --si | awk '/Mem:/ {print $7}')
	memory_available=${memory_available:0:-1}
	memory_available=${memory_available//,/.}

	local memory_percentage_used=$(( (memory_used / memory_size) * 100 ))
	memory_percentage_used=${memory_percentage_used:0:4} 

	local net=${cpu_and_network_usage[2]}
	local network_device_label=$(cat /sys/class/net/eno1/device/label)
	local network_device_mac_address=$(cat /sys/class/net/eno1/address)

	local date=$(date +%I\:%M\ %p)
	local week_day=$(date +%A)
	local day_number=$(date +%d)
	local month=$(date +%B)
	local year=$(date +%Y)
	local full_time=$(date +%r)
	local time_zone=$(date +%Z)


	echo "$uname;$cpu_usage_percentage,$cpu_temperature,$processor_name,$processor_vendor,$number_of_cores,$average_core_speed,$core_speeds;$memory_percentage_used,$memory_size,$memory_used,$memory_free,$memory_shared,$memory_buffer,$memory_available;$net,$network_device_label,$network_device_mac_address;$date,$week_day,$day_number,$month,$year,$full_time,$time_zone;"
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-a | --all) getAllInfo && exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done