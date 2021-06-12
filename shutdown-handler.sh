#!/bin/zsh

SCRIPT_NAME="Shutdown Handler"
SCRIPT_VERSION="0.4"
HELP_MESSAGE="\n%s %s, a Script to manage shutdowns\nUsage: shutdown-handler [Options]...\n\nOptions:\n -V, --version\t\t\tDisplay script version\n -h, --help\t\t\tShow this help message\n -s, --shutdown\t\t\tInitiate the shutdown process (default option)\n\n"
VERSION_MESSAGE="%s version %s\n"

OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

POWER_WAITING_ICON_PATH="/home/santiago/.config/dunst/icons/power-waiting.png"
POWER_ICON_PATH="/home/santiago/.config/dunst/icons/power.png"

NOTIFICATION_PERIOD=1000
NOTIFICATION_TIMEOUT=30

function handle_countdown_done() {
	shutdown now
}

function handle_clicked() {
	dunstify -i $POWER_ICON_PATH -t 3000 -a "Shutdown" "Shutdown Canceled" 
}

function handle_dismiss() {
	local time_left=$1
	time_left=$((time_left-1))  # -1 to round down the time left

	sleep $time_left
	handle_countdown_done
}

function main() {
	for ((i = $NOTIFICATION_TIMEOUT ; i >= 0 ; i--)); do
		if [[ $i == 0 ]]; then
			handle_countdown_done && break
		fi

		action=$(dunstify -i $POWER_WAITING_ICON_PATH -t $NOTIFICATION_PERIOD -u critical -a "Shutdown" -A "0,cancel" "Shutdown in ${i}s" "click to cancel")

		case "$action" in

			0) handle_clicked && exit ;; # Notification clicked

			1) continue ;;               # Notification timed out

			2) handle_dismiss $i && exit ;; # Notification dismissed

		esac
	done
}

while [[ "$1" =~ ^- ]]; do
	case "$1" in

		-h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

		-s | --shutdown) main && exit ;;

		-*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

	esac

	shift
done

main