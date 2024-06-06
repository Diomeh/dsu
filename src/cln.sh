#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail
IFS=$'\n\t'

print_usage() {
    cat << EOF
Usage: $(basename "$0") [directories]

Replace all special characters in filenames within the specified directories.
If no directories are provided, the script will operate in the current directory.

Options:
  -h, --help    Show this help message and exit.

Example:
  $(basename "$0")
  $(basename "$0") /path/to/directory
  $(basename "$0") /path/to/directory1 /path/to/directory2
EOF
}

replace_special_chars() {
    local filepath="$1"
    local filename
    local newname
    local target

    # Ensure given argument is a file or directory
    if [ -f "$filepath" ] || [ -d "$filepath" ]; then
        # Extract filename without directory path
        filename=$(basename "$filepath")

        # Replace spaces with underscore and strip non-alphanumeric characters
        newname=$(echo "$filename" | tr ' ' '_' | tr -s '_' | tr -cd '[:alnum:]_.-')

        target="$(dirname "$filepath")/$newname"

        # If the new filename differs from the old one, rename the file
        if [ "$newname" != "$filename" ]; then
            echo "Renaming: $filename -> $newname"

            # Check if exists
            if [ -e "$target" ]; then
                read -p "File already exists. Overwrite? [y/N] " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo "Skipping $filename"
                    return
                else 
                    rm -rf "$target" # Remove the existing file before renaming
                fi
            fi

            mv "$filepath" "$(dirname "$filepath")/$newname"
        fi
    fi
}

# If -h or --help flag is provided, print usage and exit
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_usage
    exit 0
fi

# Loop through arguments
for file in "$@"; do
    replace_special_chars "$file"
done
