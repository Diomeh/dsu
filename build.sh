#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0")
Creates a tarball of the scripts in the sh directory and save it to the dist directory.

Example:
    $(basename "$0") - Will create a tarball of the scripts in the sh directory.
EOF
}

make_tarball() {
    local root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local src_dir="$root_dir/sh"
    local dist_dir="$root_dir/dist"
    local bin_dir="$dist_dir/bin"
    local version="$(cat "$root_dir/VERSION")"
    local tarball_name="shell-scripts-$version.tar.gz"

    # Check if source directory exists
    if [ ! -d "$src_dir" ]; then
        echo "Error: Source directory '$src_dir' not found" >&2
        exit 1
    fi

    # Recreate dist directory
    rm -rf "$dist_dir"
    mkdir -p "$bin_dir"

    # Copy the scripts to the dist directory
    for file in "$src_dir"/*; do
        cp "$file" "$bin_dir"

        local filepath="$bin_dir/$(basename "$file")"
        chmod +x "$filepath"

        # Remove extension from the file
        local filename="${filepath%.*}"
        mv "$filepath" "$filename"
    done

    # Create a tarball of bin directory
    tar -czf "$dist_dir/$tarball_name" -C "$dist_dir" bin

    # Remove bin directory
    rm -rf "$bin_dir"

    echo "Tarball created: $dist_dir/$tarball_name"
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
