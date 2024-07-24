#!/usr/bin/env bash
#
# Copy shell output to the clipboard.
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-07
#
# -*- mode: shell-script -*-

set -uo pipefail

version="v2.1.30"
app=${0##*/}

usage() {
	cat <<EOF
Usage: $app [options]

Copies shell output to the clipboard.

Options
-h, --help
	Show this help message and exit.

-v, --version
	Show the version of this script and exit.

-c, --check-version
	Checks the version of this script against the remote repo version and prints a message on how to update.

Behavior
	- If running under Wayland, the script uses wl-copy to copy the output to the clipboard.
	- If running under Xorg, the script uses xclip to copy the output to the clipboard.
	- If the session type is unknown, an error is displayed.

Dependencies
	- wl-copy: Required for Wayland sessions.
	- xclip: Required for Xorg sessions.

Examples
	Echo a message and copy it to the clipboard
		echo "Hello, world!" | $app

	Copy the output of a command to the clipboard
		ls | $app

	Read a file and copy its contents to the clipboard
		cat file.txt | $app
EOF
}

version() {
	echo "$app version $version"
}

check_version() {
	echo "[INFO] Current version: $version"
	echo "[INFO] Checking for updates..."

	local remote_version
	remote_version="$(curl -s https://raw.githubusercontent.com/Diomeh/dsu/master/version)"

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
				echo "[ERROR] Unknown option: $1" >&2
				usage
				exit 1
				;;
		esac
	done
}

parse_args "$@"

# Determine if user is running Wayland or Xorg
if [[ "$XDG_SESSION_TYPE" = "wayland" ]]; then
	# Check if wl-copy is installed
	if ! command -v wl-copy >/dev/null; then
		echo "[ERROR] wl-copy is not installed" >&2
		exit 1
	fi

	# Use wl-copy to copy shell output to clipboard
	wl-copy
elif [[ "$XDG_SESSION_TYPE" = "x11" ]]; then
	# Check if xclip is installed
	if ! command -v xclip >/dev/null; then
		echo "[ERROR] xclip is not installed" >&2
		exit 1
	fi

	# Use xclip to copy shell output to clipboard
	xclip -selection clipboard
else
	echo "[ERROR] Unknown session type: $XDG_SESSION_TYPE" >&2
	exit 1
fi
