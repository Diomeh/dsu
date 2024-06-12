#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]
Install all the scripts in ./src to the specified directory.

Options:
  -p, --path    Specify the installation path (default: /usr/local/bin)
  -h, --help    Show this help message and exit

Example:
  $(basename "$0") -p ~/bin
EOF
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

INSTALL_DIR="/usr/local/bin"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -p|--path)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Path to the custom scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src/sh"
INSTALL_FILE=""$SCRIPT_DIR/.install""

# Make sure the install directory exists
mkdir -p "$INSTALL_DIR"

# Write install path to .install file
echo "$INSTALL_DIR" > "$INSTALL_FILE"

echo "Installing scripts from $SRC_DIR to $INSTALL_DIR"

# Install each script in ./src, removing the .sh extension
for script in "$SRC_DIR"/*; do
    [ -f "$script" ] || continue # Skip if not a file

    # Make the script executable
    chmod +x "$script"

    # Get the script name without the extension
    script_name=$(basename "${script%.*}")

    echo "Installing: $INSTALL_DIR/$script_name"

    # Create a symlink to the script in the install directory
    ln -sf "$script" "$INSTALL_DIR/$script_name"

    # Append installed script to .install file
    echo "$script_name" >> "$INSTALL_FILE"
done
