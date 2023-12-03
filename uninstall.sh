#!/bin/bash

# Uninstall all the scripts in /usr/local/bin
# This script is meant to be run as root, but it will prompt for a password

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Path to the custom scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
INSTALL_DIR="/usr/local/bin"

# Make sure the install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Install directory $INSTALL_DIR does not exist"
    exit
fi

echo "Uninstalling scripts from $INSTALL_DIR"

# Uninstall each script in ./sh, removing the .sh extension
for script in $SRC_DIR/*; do
    script_name=$(basename $script)
    script_name=${script_name%.*}

    echo "Uninstalling $INSTALL_DIR/$script_name"

    # Remove the script if it already exists
    if [ -f "$INSTALL_DIR/$script_name" ]; then
        rm $INSTALL_DIR/$script_name
    fi
done
