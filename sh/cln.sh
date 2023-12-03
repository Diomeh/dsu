#!/bin/bash

# Replace all special characters in current directory filenames with underscore
# Usage: clrsp.sh [directories]

replace_special_chars() {
    # ensure given argument is a file or directory
    if [ -f "$1" ] || [ -d "$1" ]; then
        # replace spaces with underscore and strip non alphanumeric characters
        local newname=$(echo "$1" | tr ' ' '_' | tr -s '_' '_' | tr -cd '[:alnum:]_.-')

        if [ "$newname" != "$1" ]; then
            echo "$1 -> $newname"
            mv "$1" "$newname"
        fi
    fi
}

# if no arguments given, use current directory
if [ $# -eq 0 ]; then
    set -- *
fi

# loop through arguments
for file in "$@"; do
    replace_special_chars "$file"
done
