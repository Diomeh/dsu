#!/bin/bash

# Install all the scripts in ./src to /usr/local/bin

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
    echo "Creating install directory $INSTALL_DIR"
    mkdir -p $INSTALL_DIR
fi

echo "Installing scripts from $SRC_DIR to $INSTALL_DIR"

# Install each script in ./src, removing the .sh extension
for script in $SRC_DIR/*; do
    # Make the script executable
    chmod +x $script

    # Get the script name without the extension
    script_name=$(basename $script)
    script_name=${script_name%.*}

    echo "Installing: $INSTALL_DIR/$script_name"

    # Create a symlink to the script in the install directory and make it executable
    ln -sf $script $INSTALL_DIR/$script_name
    chmod +x $INSTALL_DIR/$script_name
done
