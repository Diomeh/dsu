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

    # Check filepath permissions
    if [ ! -w "$filepath" ]; then
        echo "Error: $filepath: Permission denied"
        return
    fi

    # Extract filename without directory path
    filename=$(basename "$filepath")

    # Replace spaces with underscore and strip non-alphanumeric characters
    newname=$(echo "$filename" | tr ' ' '_' | tr -s '_' | tr -cd '[:alnum:]_.-')

    # If newname is empty, skip
    if [ -z "$newname" ]; then
        echo "Error: $filename: new name is empty. Skipping..."
        return
    fi

    target="$(dirname "$filepath")/$newname"

    # If names are the same, skip
    if [ "$filename" == "$newname" ]; then
        return
    fi

    echo "Renaming: $filename -> $newname"

    # Check if target file already exists
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

    mv "$filepath" "$target"
}

# If no arguments are provided, use the current directory
if [ "$#" -eq 0 ]; then
    set -- .
fi

# If -h or --help flag is provided, print usage and exit
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_usage
    exit 0
fi

# Loop through arguments
for file in "$@"; do
    # If argument is a directory, loop through all files in the directory
    if [ -d "$file" ]; then
        for f in "$file"/*; do
            replace_special_chars "$f"
        done
        continue
    else 
        # If argument is a file, replace special characters in the file name
        replace_special_chars "$file"
    fi
done
