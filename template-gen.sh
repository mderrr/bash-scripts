#!/bin/bash

SCRIPT_VERSION="1.8"
SCRIPT_NAME="Template Gen"

HELP_MESSAGE="\n%s %s, a Bash Template Generator\nUsage: template-gen [Options]... [Script Name]\n\nOptions:\n -V, --version\t\t\tDisplay script version.\n -h, --help\t\t\tShow this help message.\n -q, --quiet\t\t\tNo prompts, use defaults.\n\n"
VERSION_MESSAGE="%s version %s\n"
OPTION_NOT_RECOGNIZED_MESSAGE="Option %s not recognized\n"

SCRIPT_DESCRIPTION_PROMPT_MESSAGE="Script description: "
SCRIPT_VERSION_PROMPT_MESSAGE="Script version: "
SCRIPT_USAGE_PROMPT_MESSAGE="Script usage placeholder action: "

DEFAULT_FILE_PATH="."
DEFAULT_SCRIPT_DESCRIPTION="a Bash Script"
DEFAULT_SCRIPT_VERSION="1.0"
DEFAULT_SCRIPT_USAGE_ACTION="Place Holder"

QUIET_MODE_ENABLED=false
VERBOSE_MODE_ENABLED=false

function writeFile() {
    local file_path=$1
    local file_name=${2%.sh}
    local script_name=$3
    local script_description=${4:-$DEFAULT_SCRIPT_DESCRIPTION}
    local script_version=${5:-$DEFAULT_SCRIPT_VERSION}
    local script_usage_action=${6:-$DEFAULT_SCRIPT_USAGE_ACTION}

    printf "#!/bin/bash\n\n" > $file_path
    printf "SCRIPT_NAME=\"$script_name\"\n" >> $file_path
    printf "SCRIPT_VERSION=\"$script_version\"\n" >> $file_path
    printf "HELP_MESSAGE=\"\\\n%%s %%s, $script_description\\\nUsage: $file_name [Options]... [$script_usage_action]\\\n\\\nOptions:\\\n -V, --version\\\t\\\t\\\tDisplay script version.\\\n -h, --help\\\t\\\t\\\tShow this help message.\\\n\\\n\"\n" >> $file_path
    printf "VERSION_MESSAGE=\"%%s version %%s\\\n\"\n\n" >> $file_path
    printf "OPTION_NOT_RECOGNIZED_MESSAGE=\"Option %%s not recognized\\\n\"\n\n" >> $file_path
    printf "while [[ \"\$1\" =~ ^- ]]; do\n" >> $file_path
    printf "\tcase \"\$1\" in\n\n" >> $file_path
    printf "\t\t-h | --help) printf \"\$HELP_MESSAGE\" \"\$SCRIPT_NAME\" \"\$SCRIPT_VERSION\" & exit ;;\n\n" >> $file_path
    printf "\t\t-V | --version) printf \"\$VERSION_MESSAGE\" \"\$SCRIPT_NAME\" \"\$SCRIPT_VERSION\" & exit ;;\n\n" >> $file_path
    printf "\t\t-*) printf \"\$OPTION_NOT_RECOGNIZED_MESSAGE\" \"\$file_path\" & exit ;;\n\n" >> $file_path
    printf "\tesac\n\n" >> $file_path
    printf "\tshift\n" >> $file_path
    printf "done" >> $file_path

    chmod +x "$file_path"
}

function createFile() {
    local custom_path=${1:-$DEFAULT_FILE_PATH}
    local script_name=$2
    local file_name=${script_name,,} && file_name=${file_name// /-} && file_name="${file_name}.sh"
    local file_path="$custom_path/$file_name"
    local script_description=""
    local script_version=""
    local script_usage_action=""

    if [[ ! $QUIET_MODE_ENABLED == true ]]; then
        printf "$SCRIPT_DESCRIPTION_PROMPT_MESSAGE"
        read script_description
    fi

    if [[ $VERBOSE_MODE_ENABLED == true ]]; then
        printf "$SCRIPT_VERSION_PROMPT_MESSAGE"
        read script_version

        printf "$SCRIPT_USAGE_PROMPT_MESSAGE"
        read script_usage_action
    fi

    writeFile "$file_path" "$file_name" "$script_name" "$script_description" "$script_version" "$script_usage_action"
}

while [[ "$1" =~ ^- ]]; do
    case "$1" in

        -h | --help) printf "$HELP_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;
        
        -V | --version) printf "$VERSION_MESSAGE" "$SCRIPT_NAME" "$SCRIPT_VERSION" & exit ;;

        -q | --quiet) QUIET_MODE_ENABLED=true && shift && continue ;;

        -v | --verbose) VERBOSE_MODE_ENABLED=true && shift && continue ;;

        -d | --directory) createFile "$2" "${*:3}" && exit ;;

        -*) printf "$OPTION_NOT_RECOGNIZED_MESSAGE" "$1" & exit ;;

    esac

    shift
done

createFile "" "$*"