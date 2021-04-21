#!/bin/bash

SCRIPT_VERSION="1.3"
SCRIPT_NAME="Template Gen"
HELP_MESSAGE="\n$SCRIPT_NAME $SCRIPT_VERSION, a Bash Template Generator\nUsage: template-gen [Options]... [Script Name]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n"
VERSION_MESSAGE="$SCRIPT_NAME version $SCRIPT_VERSION"

function writeFile() {
    echo "#!/bin/bash" > $1 && echo "" >> $1
    echo "SCRIPT_VERSION=\"1.0\"" >> $1
    echo "SCRIPT_NAME=\"$2\"" >> $1
    echo "HELP_MESSAGE=\"\n\$SCRIPT_NAME \$SCRIPT_VERSION, $3\nUsage: ${1%.sh} [Options]... [PlaceHolder]\n\nOptions:\n -V, --version\t\tDisplay script version.\n -h, --help\t\tShow this help message.\n\"" >> $1
    echo "VERSION_MESSAGE=\"\$SCRIPT_NAME version \$SCRIPT_VERSION\"" >> $1 && echo "" >> $1
    echo "while [[ \"\$1\" =~ ^- ]]; do" >> $1
    echo "    case \"\$1\" in" >> $1 && echo "" >> $1
    echo "        -h | --help) echo -e \$HELP_MESSAGE & exit ;;" >> $1 && echo "" >> $1
    echo "        -V | --version) echo -e \$VERSION_MESSAGE & exit ;;" >> $1 && echo "" >> $1
    echo "        -*) echo \"Option \$1 not recognized\" & exit ;;" >> $1 && echo "" >> $1
    echo "    esac" >> $1 && echo "" >> $1
    echo "    shift" >> $1
    echo "done" >> $1
}

function createFile() {
    script_name=$1
    file_name=${script_name,,} && file_name=${file_name// /-} && file_name="${file_name}.sh"
    read -p "Script description (empty for default): " script_description
    script_description=${script_description:="a Bash Script"}

    writeFile "$file_name" "$script_name" "$script_description"
}

while [[ "$1" =~ ^- ]]; do
    case "$1" in

        -h | --help) echo -e $HELP_MESSAGE & exit ;;

        -V | --version) echo -e $VERSION_MESSAGE & exit ;;

        -*) echo "Option $1 not recognized" & exit ;;

    esac

    shift
done

createFile "$*"