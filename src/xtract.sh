#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

usage() {
    cat << EOF
Usage: $0 [options] <archive> [output directory]
Extracts the contents of a compressed archive to a directory.

Options:
  -l, --list          List the contents of the archive.
  -h, --help          Show this help message and exit.

If the output directory is not specified, the archive is extracted to the current directory or to a directory named after the compressed archive if contents are not immediately inside a folder.

Example:
  $(basename "$0") file.tar.gz                   - Extracts the contents of file.tar.gz to the current directory.
  $(basename "$0") file.tar.gz ~/Documents       - Extracts the contents of file.tar.gz to ~/Documents.
  $(basename "$0") -l file.tar.gz                - Lists the contents of file.tar.gz.

Supported archive types:
  - tarball: .tar, .tar.gz, .tgz, .tar.bz2, .tar.xz, .tar.7z
  - .7z
  - .zip
  - .rar
EOF
}

# archive_types associative array
# This associative array maps archive extensions to the commands and flags needed
# for listing and extracting the contents of the compressed archives.
#
# Key: archive extension (without leading dot)
# Value: A string containing four space-separated components:
#   1. Dependency command: The command required to handle the archive type.
#   2. List flag: The flag used with the dependency command to list contents.
#   3. Extract flag: The flag used with the dependency command to extract contents.
#   4. Output flag (optional): The flag used to specify the output directory for extraction.
declare -A archive_types=(
    ["tar"]="tar -tf -xf -C"
    ["tar.gz"]="tar -tzf -xzf -C"
    ["tgz"]="tar -tzf -xzf -C"
    ["tar.bz2"]="tar -tjf -xjf -C"
    ["tar.xz"]="tar -tJf -xJf -C"
    ["tar.7z"]="7z l x -o"
    ["7z"]="7z l x -o"
    ["zip"]="unzip -l -d"
    ["rar"]="unrar l x"
    # ["gz"]="gzip - -dc >"
    # ["bz2"]="bzip2 - -dc >"
    # ["xz"]="unxz -l -dc >"
)

process_archive() {
    local action="$1"
    local archive="$2"
    local target_dir="$3"
    local archive_extension="${archive##*.}"
    local list_flag extract_flag target_dir_flag

    if [[ -z "${archive_types[${archive##*.}]:-}" ]]; then
        echo "Error: Unsupported archive type: $archive" >&2
        exit 1
    fi

    read -r dependency list_flag extract_flag target_dir_flag <<< "${archive_types[$archive_extension]}"

    if ! command -v "$dependency" &> /dev/null; then
        echo "Error: $dependency is needed but not found." >&2
        exit 1
    fi

    if [[ ! -f "$archive" ]]; then
        echo "Error: $archive is not a valid archive" >&2
        exit 1
    fi

    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir" || { echo "Error: '$target_dir': Permission denied" >&2; exit 1; }
    fi

    case "$action" in
        list) $dependency $list_flag "$archive" ;;
        extract)
            # Create a temporary directory to extract the contents
            temp_dir=$(mktemp -d)

            if [[ -z "${target_dir_flag:-}" ]]; then
                # Assume target directory is passed with no flag
                $dependency $extract_flag "$archive" "$temp_dir"
            else
                $dependency $extract_flag "$archive" $target_dir_flag "$temp_dir"
            fi

            # Check exit status of the extraction command
            local exit_code=$?
            if [ "$exit_code" -ne 0 ]; then
                echo "Error: Extraction failed with exit code $exit_code" >&2
                exit 1
            fi

            # Check if the contents are immediately inside a folder and move them accordingly
            if [ $(find "$temp_dir" -maxdepth 1 -type d | wc -l) -gt 1 ]; then
                mkdir -p "$target_dir/$(basename "$archive" .$archive_extension)"
                mv "$temp_dir"/* "$target_dir/$(basename "$archive" ."$archive_extension")"
            else
                mv "$temp_dir"/* "$target_dir"
            fi

            # Remove the temporary directory
            rmdir "$temp_dir"
            ;;
    esac
}

main() {
    local action="extract"
    local archive=""
    local target_dir=""

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

    archive="$1"
    target_dir="${2:-$(pwd)}"

    process_archive "$action" "$archive" "$target_dir"
}

main "$@"
