#!/usr/bin/env bash
#
# Copy shell output to the clipboard.
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-08
#
# -*- mode: shell-script -*-

set -uo pipefail

version="2.2.10"
app=${0##*/}

# Logging

# Log levels
log_silent=0
log_error=1
log_warn=2
log_dry=3
log_info=4
log_verbose=5

# ANSI color codes
red="\033[0;31m"
green="\033[0;32m"
yellow="\033[1;33m"
blue="\033[0;34m"
no_color="\033[0m"

# Enable / disable colored output
use_color="y"

# Default log level
log=$log_info

# Log level strings
# Each level is associated with a color
declare -A log_levels=(
	[$log_silent]="SILENT $no_color"
	[$log_error]="ERROR $red"
	[$log_warn]="WARN $yellow"
	[$log_dry]="DRY $green"
	[$log_info]="INFO $blue"
	[$log_verbose]="VERBOSE $blue"
)

# Maximum log level
# Subtract so as to use the log_levels array as a 0-based index
max_log_level=${#log_levels[@]}
max_log_level=$((max_log_level - 1))

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

	-l, --log <level>
		Log level. One of (4 by default):
			- 0: Silent mode. No output
			- 1: Error mode. Only errors
			- 2: Warn mode. Errors and warnings
			- 3: Dry mode. Errors, warnings, and dry run information
			- 4: Info mode. Errors, warnings, and informational messages (default)
			- 5: Verbose mode. Detailed information about the operations being performed

	--no-color
		Disable ANSI colored output.
		Alternatively, you can set the NO_COLOR or NOCOLOR environment variables to disable colored output.

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
	log $log_info "Checking for updates..."
	log $log_info "Current version: $version"

	local local_version remote_version
	local_version="$version"
	remote_version="$(curl -s https://raw.githubusercontent.com/Diomeh/dsu/master/VERSION)"

	# strip leading and trailing whitespace
	remote_version="${remote_version//[[:space:]]/}"

	# split into version components
	IFS='.' read -r r_major r_minor r_patch <<<"$remote_version"
	IFS='.' read -r l_major l_minor l_patch <<<"$local_version"

	# Check if the remote version is greater than local version
	if ((r_major > l_major || r_minor > l_minor || r_patch > l_patch)); then
		log $log_info "A new version of $app ($remote_version) is available!"
		log $log_info "Refer to the repo README on how to update: https://github.com/Diomeh/dsu/blob/master/README.md"
	else
		log $log_info "You are running the latest version of $app."
	fi
}

log() {
	local level="$1"
	local message="$2"

	local level_str level_color
	read -r level_str level_color <<<"${log_levels[$level]:-}"

	# Assert log level is valid
	[[ -z "$level_str" ]] && {
		log $log_warn "Invalid log level: $level" >&2
		return
	}

	[[ $use_color == "n" ]] && {
		level_color=""
		no_color=""
	}

	# Assert message should be printed
	((log >= level)) && printf "%b[%s]%b %s\n" "$level_color" "$level_str" "$no_color" "$message"
}

disable_color() {
	# Disable color output if needed
	# Avoid unbound variable error
	local no_color_env=${NO_COLOR:-}
	local nocolor_env=${NOCOLOR:-}

	# Flag set to disable color, no need to check further
	[[ $use_color == "n" ]] && return

	# Check if env var NO_COLOR and NOCOLOR set
	[[ -z "$no_color_env" || -z "$nocolor_env" ]] && use_color="n"
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
			-l | --log)
				log="$2"

				if [[ ! $log =~ ^[${log_silent}-${max_log_level}]$ ]]; then
					log $log_error "Invalid log level: $log" >&2
					exit 1
				fi

				shift 2
				;;
			--no-color)
				use_color="n"
				shift
				;;
			*)
				log $log_error "Unknown option: $1" >&2
				usage
				exit 1
				;;
		esac
	done
}

run_wayland() {
	log $log_verbose "Running under Wayland"

	! command -v wl-copy >/dev/null && {
		log $log_error "wl-copy is not installed" >&2
		exit 1
	}

	# Use wl-copy to copy shell output to clipboard
	wl-copy
}

run_xorg() {
	log $log_verbose "Running under Xorg"

	! command -v xclip >/dev/null && {
		log $log_error "xclip is not installed" >&2
		exit 1
	}

	# Use xclip to copy shell output to clipboard
	xclip -selection clipboard
}

main() {
	parse_args "$@"
	disable_color

	# Run dependency based on session type
	if [[ "$XDG_SESSION_TYPE" = "wayland" ]]; then
		run_wayland
	elif [[ "$XDG_SESSION_TYPE" = "x11" ]]; then
		run_xorg
	else
		log $log_error "Unknown session type: $XDG_SESSION_TYPE" >&2
		exit 1
	fi
}
