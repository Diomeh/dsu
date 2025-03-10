#!/usr/bin/env bash
#
# Package the scripts in the sh directory into a tarball.
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-07
#
# -*- mode: shell-script -*-

set -uo pipefail

usage() {
	local app=${0##*/}
	cat <<EOF
Usage: $app

Creates a tarball of the scripts in the sh directory and save it to the dist directory.

Example
	$app - Will create a tarball of the scripts in the sh directory.
EOF
}

make_tarball() {
	local version filepath filename tarball_name
	local version_file="./VERSION"
	local src_dir="./sh"
	local dist_dir="./dist"
	local bin_dir="$dist_dir/bin"

	if [[ ! -f "$version_file" ]]; then
		echo "Error: version file not found" >&2
		echo "Are you in the correct directory?" >&2
		exit 1
	fi

	version=$(<"$version_file")
	tarball_name="dsu-$version.tar.gz"

	# Check if source directory exists
	if [[ ! -d "$src_dir" ]]; then
		echo "Error: Source directory '$src_dir' not found" >&2
		echo "Are you in the correct directory?" >&2
		exit 1
	fi

	# Recreate dist directory
	rm -rf "$dist_dir"
	mkdir -p "$bin_dir"

	# Copy the scripts to the dist directory
	for file in "$src_dir"/*; do
		cp "$file" "$bin_dir"

		filepath="$bin_dir/${file##*/}"
		chmod +x "$filepath"

		# Remove extension from the file
		filename="${filepath%.*}"
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
	while (($# > 0)); do
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
