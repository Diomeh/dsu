#!/usr/bin/env bash
#
# Display the disk usage of files and directories within the specified directory.
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-07
#
# -*- mode: shell-script -*-

set -uo pipefail

VERSION="v2.1.30"
app=${0##*/}

usage() {
	cat <<EOF
Usage: $app <directory>

Displays the disk usage of files and directories within the specified directory,
sorted by size in descending order. If no directory is specified, the current
directory is used by default.

Options:
  -h, --help              Show this help message and exit.
  -v, --version           Show the version of this script and exit.
  -c, --check-version     Checks the version of this script against the remote repo version and prints a message on how to update.

Arguments:
  DIRECTORY           The directory to analyze. If not specified, the current directory (.) is used.

Example:
  $app                  # Analyze the current directory
  $app /path/to/dir     # Analyze the specified directory

Notes:
  - The script uses 'du' to calculate disk usage and 'sort' to sort the results.
  - The '--one-file-system' option for 'du' ensures that only the file system
    containing the specified directory is analyzed, ignoring mounted file systems.
EOF
}

version() {
	echo "$app version $VERSION"
}

check_version() {
	echo "[INFO] Current version: $VERSION"
	echo "[INFO] Checking for updates..."

	local remote_version
	remote_version="$(curl -s https://raw.githubusercontent.com/Diomeh/dsu/master/VERSION)"

	# strip leading and trailing whitespace
	remote_version="$(echo -e "${remote_version}" | tr -d '[:space:]')"

	# Check if the remote version is different from the local version
	if [ "$remote_version" != "$VERSION" ]; then
		echo "[INFO] A new version of $app ($remote_version) is available!"
		echo "[INFO] Refer to the repo README on how to update: https://github.com/Diomeh/dsu/blob/master/README.md"
	else
		echo "[INFO] You are running the latest version of $app."
	fi
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
			-h | --help)
				usage
				exit 0
				;;
			-v | --version)
				version
				exit 0
				;;
			-c | --check-version)
				check_version
				exit 0
				;;
			*)
				if [ -z "$dir" ] && [ -d "$1" ]; then
					dir="$1"
				else
					echo "[ERROR] Unknown option: $1" >&2
					usage
					exit 1
				fi
				shift
				;;
		esac
	done
}

parse_args "$@"

# Default to current directory if no directory is specified
dir="${dir:-.}"

du -s --one-file-system "$dir/*" "$dir/.[A-Za-z0-9]*" | sort -rn | head
