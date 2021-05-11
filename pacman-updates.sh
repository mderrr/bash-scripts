#!/bin/bash
export HISTIGNORE='*sudo -S*'

passwd=$(/home/$USER/.scripts/pass.sh) &> /dev/null

echo "$passwd" | sudo -S -k pacman -Sy &> /dev/null

number_of_updates=$(pacman -Qu | wc -l)
echo $number_of_updates