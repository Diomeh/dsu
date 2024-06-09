#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") 
Creates a tarball of the scripts in the src directory and save it to the build directory.

Example:
    $(basename "$0") - Will create a tarball of the scripts in the src directory.
EOF
}

make_tarball() {
    local root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local src_dir="$root_dir/src"
    local build_dir="$root_dir/build"
    local version="$(cat "$root_dir/VERSION")"
    local tarball_name="scripts-$version.tar.gz"

    # Check if source directory exists
    if [ ! -d "$src_dir" ]; then
        echo "Error: Source directory '$src_dir' not found" >&2
        exit 1
    fi

    # Recreate build directory
    rm -rf "$build_dir"
    mkdir -p "$build_dir"

    local scripts=()

    # Copy the scripts to the build directory
    for file in "$src_dir"/*; do
        cp "$file" "$build_dir"
        
        local filepath="$build_dir/$(basename "$file")"
        chmod +x "$filepath"

        # Remove extension from the file
        local filename="${filepath%.*}"
        mv "$filepath" "$filename"

        scripts+=("$(basename "$filename")")
    done

    # Create a tarball of the scripts
    tar -czf "$build_dir/$tarball_name" -C "$build_dir" "${scripts[@]}"

    # Remove the copied scripts
    find "$build_dir" -type f -not -name "$tarball_name" -delete

    echo "Tarball created: $build_dir/$tarball_name"
}

main() {
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            usage
            exit 1
            ;;
        esac
    done

    make_tarball
}

main "$@"
