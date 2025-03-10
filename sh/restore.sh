#!/usr/bin/env bash
#
# Restore back up of files or directories.
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-08
#
# -*- mode: shell-script -*-

set -uo pipefail

version="2.2.12"
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

# Args and options
source=""
target=""
dry="n"
force="ask"

usage() {
	cat <<EOF
Usage: $app [options] <source> [target]

Restore a file or directory from a timestamped backup.

Arguments:
	[options]
		Additional options to customize the behavior.

	<source>
		The path to the file, directory, or symlink to restore.

	[target]
		Optional. The directory where to put the restored backup. Defaults to the current directory.

Options:
	-h, --help
		Display this help message and exit.

	-v, --version
		Display the version of this script and exit.

	-d, --dry
		Dry run. Print the operations that would be performed without actually executing them.

	-f, --force <y/n/ask>
		Force mode. One of (ask by default):
			- y: Automatic yes to prompts. Assume "yes" as the answer to all prompts and run non-interactively.
			- n: Automatic no to prompts. Assume "no" as the answer to all prompts and run non-interactively.
			- ask: Prompt for confirmation before overwriting existing backups. This is the default behavior.

	-l, --log <level>
		Log level. One of (4 by default):
			- 0: Silent mode. No output
			- 1: Error mode. Only errors
			- 2: Warn mode. Errors and warnings
			- 3: Dry mode. Errors, warnings, and dry run information
			- 4: Info mode. Errors, warnings, and informational messages (default)
			- 5: Verbose mode. Detailed information about the operations being performed

	-c, --check-version
		Checks the version of this script against the remote repo version and prints a message on how to update.

	--no-color
		Disable ANSI colored output.
		Alternatively, you can set the NO_COLOR or NOCOLOR environment variables to disable colored output.

Behavior:
	Restores the file or directory from a specified backup file.
	If the target file or directory already exists, the user will be prompted for confirmation.
	The optional argument [target] will be treated as the target directory where the backup file will be restored.
	By default, the script will prompt for confirmation before overwriting existing backups unless the force mode is set to 'y' or 'n'.

Naming Convention:
	Backup files will be named as follows:
		<target>/<filename>.<timestamp>.bak
	Where timestamp is in the format: YYYY-MM-DD_hh-mm-ss
	Example:
		/home/user/backups/hosts.2024-07-04_12-00-00.bak

Examples:
	Restore the backup file to the current working directory:
		$app /home/user/backups/hosts.2024-07-04_12-00-00.bak

	Restore the backup file to a specified directory (e.g., ~/Documents):
		$app /home/user/backups/hosts.2024-07-04_12-00-00.bak ~/Documents

Note:
- Ensure you have the necessary permissions to read/write files and directories involved in the operations.
- For large directories, the backup and restore operations might take some time as all the file tree needs to be copied.
- Long arguments will take priority over short arguments, so if e.g. both --backup and -r are provided, the script will perform a backup.
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

arg_parse() {
	# Expand combined short options (e.g., -qy to -q -y)
	expanded_args=()
	while (($# > 0)); do
		# If the argument is -- or does not start with -, or is a long argument (--dry), add it as is
		if [[ $1 == -- || $1 != -* || ! $1 =~ ^-[^-].* ]]; then
			expanded_args+=("$1")
			shift
			continue
		fi

		# Iterate over all combined short options
		# and expand them into separate arguments
		# eg. -qy becomes -q -y
		for ((i = 1; i < ${#1}; i++)); do
			expanded_args+=("-${1:i:1}")
		done

		shift
	done

	# Reset positional parameters to expanded arguments
	set -- "${expanded_args[@]}"

	# Parse long arguments
	while (($# > 0)); do
		case "$1" in
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
			-d | --dry)
				dry="y"
				shift
				;;
			-f | --force)
				force="$2"

				if [[ ! $force =~ ^(y|n|ask)$ ]]; then
					log $log_error "Invalid force mode: $force" >&2
					exit 1
				fi

				shift 2
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
			-*)
				log $log_error "Unknown option: $1" >&2
				usage
				exit 1
				;;
			*)
				if [[ -z "$source" ]]; then
					source="$1"
				elif [[ -z "$target" ]]; then
					target="$1"
				else
					log $log_error "Unknown argument: $1" >&2
					usage
					exit 1
				fi
				shift
				;;
		esac
	done

	# Default to current directory if backup directory not provided
	target="${target:-.}"

	# Will only happen when on verbose mode
	log $log_verbose "Running verbose log level"

	if [[ "$force" == "y" ]]; then
		log $log_verbose "Running non-interactive mode. Assuming 'yes' for all prompts."
	elif [[ "$force" == "n" ]]; then
		log $log_verbose "Running non-interactive mode. Assuming 'no' for all prompts."
	else
		log $log_verbose "Running interactive mode. Will prompt for confirmation."
	fi

	if [[ $dry == "y" ]]; then
		log $log_verbose "Running dry run mode. No changes will be made."
	fi
}

prepare_source() {
	if [[ ! -e "$source" ]]; then
		log $log_error "Source not found: $source" >&2
		exit 1
	elif [[ ! -r "$source" ]]; then
		log $log_error "Permission denied: $source" >&2
		exit 1
	fi
}

prepare_target() {
	if [[ ! -e "$target" ]]; then
		if [[ $dry == "y" ]]; then
			log $log_dry "Would create backup directory: $target"
			return
		fi

		if [[ $force == "y" ]]; then
			log $log_verbose "Creating backup directory: $target"
			mkdir -p "$target" || {
				log $log_error "Could not create backup directory: $target" >&2
				exit 1
			}
		elif [[ $force == "n" ]]; then
			log $log_error "Backup directory does not exist, exiting: $target" >&2
			exit 1
		else
			read -p "[WARN] Backup directory does not exist. Create? [y/N] " -n 1 -r
			echo ""
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				log $log_info "Exiting..."
				exit 0
			else
				log $log_verbose "Creating backup directory: $target"
				mkdir -p "$target" || {
					log $log_error "Could not create backup directory: $target" >&2
					exit 1
				}
			fi
		fi
	elif [[ ! -d "$target" ]]; then
		log $log_error "Not a directory: $target" >&2
		exit 1
	elif [[ ! -w "$target" ]]; then
		log $log_error "Permission denied: $target" >&2
		exit 1
	fi
}

run() {
	local target_file
	local target_path="$target"

	# Check if the file name matches the backup pattern: file.2019-01-01_00-00-00.bak
	# .backup extension is also supported
	if [[ "${source##*/}" =~ ^(.*)\.[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\.(bak|backup)$ ]]; then
		# Extract the base filename without the backup extension
		target_file="${BASH_REMATCH[1]}"
	else
		log $log_error "Not a valid backup file: $source" >&2
		log $log_error "Backup file must match the pattern: file.YYYY-MM-DD_hh-mm-ss.bak"
		exit 1
	fi

	log $log_info "Restoring: '$source'"

	# Ask for confirmation if target_file exists
	if [[ -e "$target_path/$target_file" ]]; then
		if [[ $dry == "y" ]]; then
			log $log_dry "Would overwrite existing file: $target_path/$target_file"
		elif [[ "$force" == "y" ]]; then
			log $log_info "Overwriting existing file: $target_path/$target_file"
			rm -rf "${target_path:?}/$target_file"
		elif [[ "$force" == "n" ]]; then
			log $log_info "File exists, exiting: $target_path/$target_file"
			exit 0
		else
			log $log_warn "File or directory already exists: $target_file"
			read -p "Overwrite $target_file? [y/N] " -r response
			if [[ ! $response =~ ^[Yy]$ ]]; then
				exit 0
			fi
		fi
	fi

	if [[ $dry == "y" ]]; then
		log $log_dry "Would restore backup: $source -> $target_path/$target_file"
	else
		cp -r "$source" "$target_path/$target_file" || {
			log $log_error "Failed to restore backup" >&2
			exit 1
		}

		log $log_info "Backup restored: $source -> $target_path/$target_file"
	fi
}

main() {
	arg_parse "$@"
	disable_color

	prepare_source
	prepare_target

	run
}

main "$@"
