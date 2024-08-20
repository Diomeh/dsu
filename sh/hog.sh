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

version="v2.2.8"
app=${0##*/}

dir=""

usage() {
	cat <<EOF
Usage: $app <directory>

Displays the disk usage of files and directories within the specified directory,
sorted by size in descending order. If no directory is specified, the current
directory is used by default.

Options
-h, --help
	Show this help message and exit.

-v, --version
	Show the version of this script and exit.

-c, --check-version
	Checks the version of this script against the remote repo version and prints a message on how to update.

Arguments
	directory
		Required. The directory to analyze. If not specified, the current directory "." is used.

Example
	Analyzing the current directory
		$app

	Analyzing a specific directory
		$app /path/to/directory

Notes
	The script uses 'du' to calculate disk usage and 'sort' to sort the results.

	The '--one-file-system' option for 'du' ensures that only the file system
	containing the specified directory is analyzed, ignoring mounted file systems.
EOF
}

version() {
	echo "$app version $version"
}

check_version() {
	echo "[INFO] Current version: $version"
	echo "[INFO] Checking for updates..."

	local remote_version
	remote_version="$(curl -s https://raw.githubusercontent.com/Diomeh/dsu/master/VERSION)"

	# strip leading and trailing whitespace
	remote_version="${remote_version//[[:space:]]/}"

	# Check if the remote version is different from the local version
	if [[ "$remote_version" != "$version" ]]; then
		echo "[INFO] A new version of $app ($remote_version) is available!"
		echo "[INFO] Refer to the repo README on how to update: https://github.com/Diomeh/dsu/blob/master/README.md"
	else
		echo "[INFO] You are running the latest version of $app."
	fi
}

parse_args() {
	while (($# > 0)); do
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
				if [[ -z "$dir" ]] && [[ -d "$1" ]]; then
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

# Ensure existence and permissions
if [[ ! -d "$dir" ]]; then
	echo "[ERROR] Not a directory: '$dir'" >&2
	exit 1
fi

if [[ ! -r "$dir" ]]; then
	echo "[ERROR] Directory cannot be read: '$dir'" >&2
	exit 1
fi

# Calling du directly may fail with "No such file or directory"
# So instead we call du on every file in $dir
find "$dir" -maxdepth 1 -mindepth 1 -exec du -sh --one-file-system {} + | sort -rn | head
