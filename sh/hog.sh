#!/usr/bin/env bash
#
# Display the disk usage of files and directories within the specified directory.
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
	log $log_info "Checking for updates..."
	log $log_info "Current version: $version"

	local local_version remote_version
	local_version="$version"
	remote_version="$(curl -sS https://raw.githubusercontent.com/Diomeh/dsu/master/VERSION)"

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

	# Flag set to disable color, no need to check further
	[[ $use_color == "n" ]] && return

	# Check if env var NO_COLOR and NOCOLOR set
	[[ -z "$NO_COLOR" || -z "$NOCOLOR" ]] && use_color="n"
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
				if [[ -z "$dir" ]] && [[ -d "$1" ]]; then
					dir="$1"
				else
					log $log_error "Unknown option: $1" >&2
					usage
					exit 1
				fi
				shift
				;;
		esac
	done

}

prepare_dir() {
	# Default to current directory if no directory is specified
	dir="${dir:-.}"

	[[ ! -r "$dir" ]] && {
		log $log_error "Permission denied: '$dir'" >&2
		exit 1
	}

	[[ ! -d "$dir" ]] && {
		log $log_error "Not a directory: '$dir'" >&2
		exit 1
	}
}

main() {
	parse_args "$@"
	disable_color
	prepare_dir

	# Calling du directly may fail with "No such file or directory"
	# So instead we call du on every file in $dir
	find "$dir" -maxdepth 1 -mindepth 1 -exec du -sh --one-file-system {} + | sort -rn | head
}
