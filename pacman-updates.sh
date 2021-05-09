#!/bin/bash

number_of_updates=$(pacman -Qu | wc -l)

echo $number_of_updates