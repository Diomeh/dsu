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

VERSION="v2.1.30"
app=${0##*/}

# Log levels
#LOG_SILENT=0
LOG_QUIET=1
LOG_NORMAL=2
LOG_VERBOSE=3

# Args and options
SOURCE=""
TARGET=""
DRY="n"
FORCE="ask"
LOG=$LOG_NORMAL

usage() {
	cat <<EOF
Usage: $app [options] <source> [target]

Create a timestamped backup of a file or directory.

Arguments:
  [options]               Additional options to customize the behavior.
  <source>                The path to the file, directory, or symlink to back up.
  [target]                Optional. The directory where file backup will be stored. Defaults to the current directory.

Options:
  -h, --help              Display this help message and exit
  -v, --version           Display the version of this script and exit
  -d, --dry               Dry run. Print the operations that would be performed without actually executing them.
  -f, --force <y/n/ask>
                          Force mode. One of (ask by default):
                            - y: Automatic yes to prompts. Assume "yes" as the answer to all prompts and run non-interactively.
                            - n: Automatic no to prompts. Assume "no" as the answer to all prompts and run non-interactively.
                            - ask: Prompt for confirmation before overwriting existing backups. This is the default behavior.
  -l, --log <level>
                          Log level. One of (2 by default):
                            - 0: Silent mode. No output
                            - 1: Quiet mode. Only errors
                            - 2: Normal mode. Errors warnings and information. This is the default behavior.
                            - 3: Verbose mode. Detailed information about the operations being performed.
  -c, --check-version     Checks the version of this script against the remote repo version and prints a message on how to update.

Behavior:
  Creates a backup file with a timestamp in the name to avoid overwriting previous backups.
  If the backup directory is not specified, the backup file will be created in the current directory.
  If the backup directory does not exist, it will be created (assuming the correct permissions are set).
  By default, the script will prompt for confirmation before overwriting existing backups unless the force mode is set to 'y' or 'n'.

Naming Convention:
  Backup files will be named as follows:
    <target>/<filename>.<timestamp>.bak
  Where timestamp is in the format: YYYY-MM-DD_hh-mm-ss
  Example:
    /home/user/backups/hosts.2024-07-04_12-00-00.bak

Examples:
  Create a backup of /etc/hosts in the current directory:
    $app -b /etc/hosts

  Create a backup of /etc/hosts in /home/user/backups:
    $app -b /etc/hosts /home/user/backups

Note:
- Ensure you have the necessary permissions to read/write files and directories involved in the operations.
- For large directories, the backup and restore operations might take some time as all the file tree needs to be copied.
- Long arguments will take priority over short arguments, so if e.g. both --backup and -r are provided, the script will perform a backup.
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
	remote_version="${remote_version//[[:space:]]/}"

	# Check if the remote version is different from the local version
	if [[ "$remote_version" != "$VERSION" ]]; then
		echo "[INFO] A new version of $app ($remote_version) is available!"
		echo "[INFO] Refer to the repo README on how to update: https://github.com/Diomeh/dsu/blob/master/README.md"
	else
		echo "[INFO] You are running the latest version of $app."
	fi
}

log() {
	local level="$1"
	local message="$2"

	case "$level" in
		0)
			# Silent mode. No output
			;;
		1)
			if ((LOG >= LOG_QUIET)); then
				echo "$message"
			fi
			;;
		2)
			if ((LOG >= LOG_NORMAL)); then
				echo "$message"
			fi
			;;
		3)
			if ((LOG >= LOG_VERBOSE)); then
				echo "$message"
			fi
			;;
		*)
			log $LOG_QUIET "[ERROR] Invalid log level: $level" >&2
			exit 1
			;;
	esac
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
				DRY="y"
				shift
				;;
			-f | --force)
				FORCE="$2"

				if [[ ! $FORCE =~ ^(y|n|ask)$ ]]; then
					log $LOG_QUIET "[ERROR] Invalid force mode: $FORCE" >&2
					exit 1
				fi

				shift 2
				;;
			-l | --log)
				LOG="$2"

				if [[ ! $LOG =~ ^[0-3]$ ]]; then
					log $LOG_QUIET "[ERROR] Invalid log level: $LOG" >&2
					exit 1
				fi

				shift 2
				;;
			-*)
				log $LOG_QUIET "[ERROR] Unknown option: $1" >&2
				usage
				exit 1
				;;
			*)
				if [[ -z "$SOURCE" ]]; then
					SOURCE="$1"
				elif [[ -z "$TARGET" ]]; then
					TARGET="$1"
				else
					log $LOG_QUIET "[ERROR] Unknown argument: $1" >&2
					usage
					exit 1
				fi
				shift
				;;
		esac
	done

	# Default to current directory if backup directory not provided
	${TARGET:=.}

	# Will only happen when on verbose mode
	log $LOG_VERBOSE "[INFO] Running verbose log level"

	if [[ "$FORCE" == "y" ]]; then
		log $LOG_VERBOSE "[INFO] Running non-interactive mode. Assuming 'yes' for all prompts."
	elif [[ "$FORCE" == "n" ]]; then
		log $LOG_VERBOSE "[INFO] Running non-interactive mode. Assuming 'no' for all prompts."
	else
		log $LOG_VERBOSE "[INFO] Running interactive mode. Will prompt for confirmation."
	fi

	if [[ $DRY == "y" ]]; then
		log $LOG_VERBOSE "[INFO] Running dry run mode. No changes will be made."
	fi
}

prepare_source() {
	if [[ ! -e "$SOURCE" ]]; then
		log $LOG_QUIET "[ERROR] Source not found: $SOURCE" >&2
		exit 1
	elif [[ ! -r "$SOURCE" ]]; then
		log $LOG_QUIET "[ERROR] Permission denied: $SOURCE" >&2
		exit 1
	fi
}

prepare_target() {
	if [[ ! -e "$TARGET" ]]; then
		if [[ $DRY == "y" ]]; then
			log $LOG_NORMAL "[DRY] Would create backup directory: $TARGET"
			return
		fi

		if [[ $FORCE == "y" ]]; then
			log $LOG_VERBOSE "[INFO] Creating backup directory: $TARGET"
			mkdir -p "$TARGET" || {
				log $LOG_QUIET "[ERROR] Could not create backup directory: $TARGET" >&2
				exit 1
			}
		elif [[ $FORCE == "n" ]]; then
			log $LOG_QUIET "[ERROR] Backup directory does not exist, exiting: $TARGET" >&2
			exit 1
		else
			read -p "[WARN] Backup directory does not exist. Create? [y/N] " -n 1 -r
			echo ""
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				log $LOG_NORMAL "[INFO] Exiting..."
				exit 0
			else
				log $LOG_VERBOSE "[INFO] Creating backup directory: $TARGET"
				mkdir -p "$TARGET" || {
					log $LOG_QUIET "[ERROR] Could not create backup directory: $TARGET" >&2
					exit 1
				}
			fi
		fi
	elif [[ ! -d "$TARGET" ]]; then
		log $LOG_QUIET "[ERROR] Not a directory: $TARGET" >&2
		exit 1
	elif [[ ! -w "$TARGET" ]]; then
		log $LOG_QUIET "[ERROR] Permission denied: $TARGET" >&2
		exit 1
	fi
}

run() {
	local filename timestamp backup_path

	filename=${SOURCE##*/}
	timestamp=$(date +%Y-%m-%d_%H-%M-%S)
	backup_path="$TARGET/$filename.$timestamp.bak"

	log $LOG_VERBOSE "[INFO] Creating file backup: $SOURCE"
	log $LOG_VERBOSE "[INFO] To backup target: $backup_path"

	if [[ -e "$backup_path" ]]; then
		if [[ $DRY == "y" ]]; then
			log $LOG_NORMAL "[DRY] Would remove existing backup: $backup_path"
		elif [[ "$FORCE" == "y" ]]; then
			log $LOG_VERBOSE "[INFO] Removing existing backup: $backup_path"
			rm -rf "$backup_path"
		elif [[ "$FORCE" == "n" ]]; then
			log $LOG_NORMAL "[INFO] Backup target already exists: $backup_path. Exiting..."
			exit 0
		else
			log $LOG_NORMAL "[WARN] Backup target already exists: $backup_path"
			read -p "Overwrite backup? [y/N] " -n 1 -r
			echo ""
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				exit 0
			fi
		fi
	fi

	if [[ $DRY == "y" ]]; then
		log $LOG_NORMAL "[DRY] Would create backup: $backup_path"
	else
		# create the backup
		if [[ -d "$SOURCE" ]]; then
			cp -r "$SOURCE" "$backup_path"
		else
			cp "$SOURCE" "$backup_path"
		fi

		log $LOG_NORMAL "[INFO] Created backup: $backup_path"
	fi
}

main() {
	arg_parse "$@"
	prepare_source
	prepare_target
	run
}

main "$@"
