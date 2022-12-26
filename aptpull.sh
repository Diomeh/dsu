#! /bin/bash

# check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# if arglist contains -i, install updates
if [[ "$@" == *"-i"* ]]; then
    apt update
    apt list --upgradable
    apt upgrade
    exit 0
fi

# if arglist contains -y, assume yes to all prompts. implies -i
if [[ "$@" == *"-y"* ]]; then
    apt update
    apt list --upgradable
    apt upgrade -y
    exit 0
fi

# if arglist contains -l, only list updates
if [[ "$@" == *"-l"* ]]; then
    apt update
    apt list --upgradable
    apt-get upgrade -s | grep "upgraded"
    exit 0
fi

if [[ "$@" == *"-h"* || "$@" == *"--help"* || "$#" -gt 0 ]]; then
    echo "Usage: aptpull [-i] [-y] [-h] [-l]"
    echo "           -i: install updates"
    echo "           -y: assume yes to all prompts, implies -i"
    echo "           -l: only list updates"
    echo "  --help   -h : show this help message"
    exit 0
fi

apt update
apt list --upgradable

# check if updates are available
if ! apt-get upgrade -s | grep "upgraded"; then
    echo "No updates available"
    exit 0
fi

read -p "Do you want to upgrade? [y/N] " response
if [ "$response" = "y" ]; then
    apt upgrade -y
fi
