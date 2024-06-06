#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

usage() {
    cat << EOF
Usage: $0 [options] <file> [<output>]
Extracts the contents of a compressed file to a directory.

Options:
  -l, --list          List the contents of the file.
  -h, --help          Show this help message and exit.

If the output directory is not specified, the file is extracted to the current directory or to a directory named after the compressed file if contents are not immediately inside a folder.

Example:
  $(basename "$0") file.tar.gz
  $(basename "$0") file.tar.gz ~/Documents

Supported file types:
  .7z, .zip, .rar, .gz, .bz2, .xz, .tar, .tgz, .tar.gz, .tar.bz2, .tar.xz, .tar.7z
EOF
}

# file_types associative array
# This associative array maps file extensions to the commands and flags needed
# for listing and extracting the contents of the compressed files.
#
# Key: File extension (without leading dot)
# Value: A string containing four space-separated components:
#   1. Dependency command: The command required to handle the file type.
#   2. List flag: The flag used with the dependency command to list contents.
#   3. Extract flag: The flag used with the dependency command to extract contents.
#   4. Output flag (optional): The flag used to specify the output directory for extraction.
declare -A file_types=(
    ["7z"]="7z l x -o"
    ["zip"]="unzip -l -d -d"
    ["rar"]="unrar l x"
    ["gz"]="tar -tzf -xzf -C"
    ["tgz"]="tar -tzf -xzf -C"
    ["tar.gz"]="tar -tzf -xzf -C"
    ["bz2"]="tar -tjf -xjf -C"
    ["tar.bz2"]="tar -tjf -xjf -C"
    ["xz"]="tar -tJf -xJf -C"
    ["tar.xz"]="tar -tJf -xJf -C"
    ["tar"]="tar -tf -xf -C"
    ["tar.7z"]="7z l x -o"
)

process_file() {
    local action="$1"
    local file="$2"
    local output="$3"
    local file_extension="${file##*.}"
    local list_flag extract_flag output_flag

    if [[ -z "${file_types[${file##*.}]:-}" ]]; then
        echo "Error: Unsupported file type" >&2
        exit 1
    fi

    read -r dependency list_flag extract_flag output_flag <<< "${file_types[$file_extension]}"

    if ! command -v "$dependency" &> /dev/null; then
        echo "Error: $dependency is needed but not found." >&2
        exit 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "Error: $file is not a valid file" >&2
        exit 1
    fi

    if [[ ! -d "$output" ]]; then
        mkdir -p "$output" || { echo "Error: '$output': Permission denied" >&2; exit 1; }
    fi

    case "$action" in
        list) $dependency $list_flag "$file" ;;
        extract)
            if [[ -z "${output_flag:-}" ]]; then
                $dependency $extract_flag "$file"
            else
                # Create a temporary directory to extract the contents
                temp_dir=$(mktemp -d)
                $dependency $extract_flag "$file" $output_flag "$temp_dir"

                # Check if the contents are immediately inside a folder and move them accordingly
                if [ $(find "$temp_dir" -maxdepth 1 -type d | wc -l) -gt 1 ]; then
                    mkdir -p "$output/$(basename "$file" .$file_extension)"
                    mv "$temp_dir"/* "$output/$(basename "$file" ."$file_extension")"
                else
                    mv "$temp_dir"/* "$output"
                fi

                # Remove the temporary directory
                rmdir "$temp_dir"
            fi
            ;;
    esac
}

main() {
    local action="extract"
    local file=""
    local output=""

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -l|--list) action="list"; shift ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) echo "Error: Unknown option: $1" >&2; usage; exit 1 ;;
            *) break ;;
        esac
    done

    if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
        echo "Error: Incorrect number of arguments" >&2
        usage
        exit 1
    fi

    file="$1"
    output="${2:-.}"

    process_file "$action" "$file" "$output"
}

main "$@"
