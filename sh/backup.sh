#!/usr/bin/env bash
#
# Perform a timestamped backup of a file or directory.
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-07
#
# -*- mode: shell-script -*-

set -uo pipefail

# App data
app=${0##*/}
version="v2.2.0"

# Log levels
log_silent=0
log_error=1
log_warn=2
log_dry=3
log_info=4
log_verbose=5
log=$log_info

# Args and options
source=""
target=""
dry="n"
force="ask"

usage() {
	cat <<EOF
Usage: $app [options] <source> [target]

Create a timestamped backup of a file or directory.

Arguments
	[options]
		Additional options to customize the behavior.

	<source>
		Required. The path to the file, directory, or symlink to back up.

	[target]
		Optional. The directory where file backup will be stored. Defaults to the current directory.

Options
	-h, --help
		Display this help message and exit

	-v, --version
		Display the version of this script and exit

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

Behavior
	Creates a backup file with a timestamp in the name to avoid overwriting previous backups.
	If the backup directory is not specified, the backup file will be created in the current directory.
	If the backup directory does not exist, it will be created (assuming the correct permissions are set).
	By default, the script will prompt for confirmation before overwriting existing backups unless the force mode is set to 'y' or 'n'.

Naming Convention
	Backup files will be named as follows:
	  <target>/<filename>.<timestamp>.bak

	Where timestamp is in the format YYYY-MM-DD_hh-mm-ss, like so
	  /home/user/backups/hosts.2024-07-04_12-00-00.bak

Examples
	Create a backup of /etc/hosts in the current directory:
	  $app /etc/hosts

	Create a backup of /etc/hosts in /home/user/backups:
	  $app /etc/hosts /home/user/backups

	Perform a silent backup without prompts:
		$app -l 0 -f y /etc/hosts /home/user/backups

Note
	- Ensure you have the necessary permissions to read/write files and directories involved in the operations.
	- For large directories, the backup and restore operations might take some time as all the file tree needs to be copied.
	- Long arguments will take priority over short arguments, so if e.g. both --backup and -r are provided, the script will perform a backup.
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

log() {
	local level="$1"
	local message="$2"
	local levels=("SILENT" "ERROR" "WARN" "DRY" "INFO" "VERBOSE")
	local log_level=(
		"$log_silent"
		"$log_error"
		"$log_warn"
		"$log_dry"
		"$log_info"
		"$log_verbose"
	)

	#	 Assert log level is valid
	((level >= 0 && level <= 4)) || {
		log $log_warn "Invalid log level: $level" >&2
		return
	}

	#	Assert message should be printed
	((log >= log_level[level])) && echo "[${levels[level]}] $message"
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

				if [[ ! $log =~ ^[0-3]$ ]]; then
					log $log_error "Invalid log level: $log" >&2
					exit 1
				fi

				shift 2
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
	${target:=.}

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
				$log_info "Exiting..."
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
	local filename timestamp backup_path

	filename=${source##*/}
	timestamp=$(date +%Y-%m-%d_%H-%M-%S)
	backup_path="$target/$filename.$timestamp.bak"

	log $log_verbose "Creating file backup: $source"
	log $log_verbose "To backup target: $backup_path"

	if [[ -e "$backup_path" ]]; then
		if [[ $dry == "y" ]]; then
			log $log_dry "Would remove existing backup: $backup_path"
		elif [[ "$force" == "y" ]]; then
			log $log_verbose "Removing existing backup: $backup_path"
			rm -rf "$backup_path"
		elif [[ "$force" == "n" ]]; then
			$log_info "Backup target already exists: $backup_path. Exiting..."
			exit 0
		else
			log $log_warn "Backup target already exists: $backup_path"
			read -p "Overwrite backup? [y/N] " -n 1 -r
			echo ""
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				exit 0
			fi
		fi
	fi

	if [[ $dry == "y" ]]; then
		log $log_dry "Would create backup: $backup_path"
	else
		# create the backup
		if [[ -d "$source" ]]; then
			cp -r "$source" "$backup_path"
		else
			cp "$source" "$backup_path"
		fi

		$log_info "Created backup: $backup_path"
	fi
}

main() {
	arg_parse "$@"
	prepare_source
	prepare_target
	run
}

main "$@"
