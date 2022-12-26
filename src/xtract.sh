#!/bin/bash

usage() {
    echo "Usage: $0 <file> <output>"
    echo "Extracts the contents of a compressed file to a directory"
    echo "If the output directory is not specified, the file is extracted to the current directory"
    echo ""
    echo "Example:"
    echo "  $0 file.tar.gz"
    echo "  $0 file.tar.gz /home/user"
    echo ""
    echo "Supported file types:"
    echo "  .7z"
    echo "  .zip"
    echo "  .rar"
    echo "  .gz"
    echo "  .bz2"
    echo "  .xz"
    echo "  .tar"
    echo "  .tgz"
    echo "  .tar.gz"
    echo "  .tar.bz2"
    echo "  .tar.xz"
    echo "  .tar.7z"
    exit 1
}

# If arguments are less than 1 or greater than 2, print usage
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
fi

# If the arguments contain -h or --help, print usage
if [[ "$@" == *"-h"* ]]; then
    usage
fi

# If the first argument is a file, set the file variable
if [ -f "$1" ]; then
    file="$1"
else
    echo "Error: $1 is not a file"
    exit 1
fi

# If second argument is not specified, set the output variable to the current directory
if [ -z "$2" ]; then
    output="."
else 
    output="$2"
fi

# Create the output directory if it doesn't exist
if [ ! -d "$output" ]; then
    mkdir -p "$output"
fi

# Extract the file
case "$file" in
    *.7z)
        7z x "$file" -o"$output"
        ;;
    *.zip)
        unzip "$file" -d "$output"
        ;;
    *.rar)
        unrar x "$file" "$output"
        ;;
    *.gz)
        tar -xzf "$file" -C "$output"
        ;;
    *.bz2)
        tar -xjf "$file" -C "$output"
        ;;
    *.xz)
        tar -xJf "$file" -C "$output"
        ;;
    *.tar)
        tar -xf "$file" -C "$output"
        ;;
    *.tgz)
        tar -xzf "$file" -C "$output"
        ;;
    *.tar.gz)
        tar -xzf "$file" -C "$output"
        ;;
    *.tar.bz2)
        tar -xjf "$file" -C "$output"
        ;;
    *.tar.xz)
        tar -xJf "$file" -C "$output"
        ;;
    *.tar.7z)
        7z x "$file" -o"$output"
        ;;
    *)
        echo "$0 Error: $file is not a supported file type"
        echo ""
        usage
        exit 1
        ;;
esac
