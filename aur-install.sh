#!/bin/bash

_package=$1
package_name=${_package##*.org/}
package_name=${package_name%.git*}

AUR_DIR="/home/$USER/Repositories/AUR/"
GIT_DIR=$AUR_DIR$package_name

function cloneAndMake() {
	git clone $_package $GIT_DIR
	cd $GIT_DIR && makepkg -sirc
}

function removeDir() {
	echo "Cleaning up..."
	rm -r -f $GIT_DIR
}

if [ ! -d "$AUR_DIR" ]; then
	echo "AUR folder not found, creating one in ~/Repositories/AUR"
	mkdir $AUR_DIR
fi

cloneAndMake
removeDir
echo "Done."