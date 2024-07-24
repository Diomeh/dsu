#!/usr/bin/env bash
#
# Uninstaller for DSU shell utilities
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-07
#
# -*- mode: shell-script -*-

set -uo pipefail

# Log levels
#log_silent=0
log_quiet=1
log_normal=2
log_verbose=3
log=$log_normal

config_path="$HOME/.config/dsu"
config_file="$config_path/dsu.conf"
log_file="$config_path/dsu.log"

dry="n"
force="ask"

sudo_command=""

usage() {
	local name=${0##*/}
	cat <<EOF
Usage: $name [OPTIONS]

Removes the installed binaries and configuration files of the Diomeh's Script Utilities.

Options:
  -h, --help              Display this help message and exit
  -d, --dry               Dry run. Print the operations that would be performed without actually executing them.
  -f, --force <y/n/ask>   Force mode. One of (ask by default):
                            - y: Assume "yes" as the answer to all prompts and run non-interactively.
                            - n: Assume "no" as the answer to all prompts and run non-interactively.
                            - ask: Prompt for confirmation before removing binaries and configuration files. This is the default behavior.
  -l, --log <level>       Log level. One of (2 by default):
                            - 0: Silent mode. No output
                            - 1: Quiet mode. Only errors
                            - 2: Normal mode. Errors warnings and information. This is the default behavior.
                            - 3: Verbose mode. Detailed information about the operations being performed.
EOF
}

log() {
	local level="$1"
	local message="$2"

	case "$level" in
		0)
			# Silent mode. No output
			;;
		1)
			if ((log >= log_quiet)); then
				echo "$message"
			fi
			;;
		2)
			if ((log >= log_normal)); then
				echo "$message"
			fi
			;;
		3)
			if ((log >= log_verbose)); then
				echo "$message"
			fi
			;;
		*)
			log $log_quiet "[ERROR] Invalid log level: $level" >&2
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
			-d | --dry)
				dry="y"
				shift
				;;
			-f | --force)
				force="$2"

				if [[ ! $force =~ ^(y|n|ask)$ ]]; then
					log $log_quiet "[ERROR] Invalid force mode: $force" >&2
					exit 1
				fi

				shift 2
				;;
			-l | --log)
				log="$2"

				if [[ ! $log =~ ^[0-3]$ ]]; then
					log $log_quiet "[ERROR] Invalid log level: $log" >&2
					exit 1
				fi

				shift 2
				;;
			-*)
				log $log_quiet "[ERROR] Unknown option: $1" >&2
				usage
				exit 1
				;;
			*)
				log $log_quiet "[ERROR] Unknown argument: $1" >&2
				usage
				exit 1
				;;
		esac
	done

	# Will only happen when on verbose mode
	log $log_verbose "[INFO] Running verbose log level"

	if [[ "$force" == "y" ]]; then
		log $log_verbose "[INFO] Running non-interactive mode. Assuming 'yes' for all prompts."
	elif [[ "$force" == "n" ]]; then
		log $log_verbose "[INFO] Running non-interactive mode. Assuming 'no' for all prompts."
	else
		log $log_verbose "[INFO] Running interactive mode. Will prompt for confirmation."
	fi

	if [[ $dry == "y" ]]; then
		log $log_verbose "[INFO] Running dry run mode. No changes will be made."
	fi
}

path_needs_sudo() {
	local path="$1"

	while true; do
		# Safeguard, prevent infinite loop
		if [[ -z "$path" ]]; then
			log $log_quiet "[ERROR] Provided path is not valid: $1" >&2
			exit 1
		fi
		if [[ "$path" == "/" ]]; then
			echo "y"
			break
		fi

		# if exists, check write permissions
		if [[ -e "$path" ]]; then
			if [[ -w "$path" ]]; then
				echo "n"
				break
			else
				echo "y"
				break
			fi
		else
			# if doesn't exist, set path to parent directory and check again
			path=$(dirname "$path")
			continue
		fi
	done
}

prompt_for_sudo() {
	if [[ $force == "y" ]]; then
		log $log_verbose "[INFO] Elevating permissions to continue installation."
	elif [[ $force == "n" ]]; then
		log $log_normal "[INFO] Elevated (sudo) permissions needed to continue installation. Exiting..."
		exit 0
	else
		# Elevate permissions? Prompt the user
		read -p "Do you want to elevate permissions to continue installation? [y/N] " -n 1 -r
		echo ""
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log $log_normal "[INFO] Aborting..."
			exit 0
		fi
	fi

	# Elevate permissions
	sudo -v || {
		log $log_quiet "[ERROR] Failed to elevate permissions. Exiting..." >&2
		exit 1
	}
}

set_sudo_command() {
	local path="$1"
	local use_sudo
	local status

	use_sudo="$(path_needs_sudo "$path")"
	status=$?

	if ((status != 0)); then
		log $log_quiet "[ERROR] Could not determine if sudo is needed. Exiting..." >&2
		exit 1
	fi

	if [[ "$use_sudo" == "y" ]]; then
		if [[ $dry == "y" ]]; then
			log $log_normal "[dry] Would use sudo to remove binaries from $path"
		else
			sudo_command="sudo"
			prompt_for_sudo
		fi
	fi
}

main() {
	local binaries=()
	local type=""
	local path=""

	arg_parse "$@"

	if [[ ! -e "$config_file" ]]; then
		log $log_normal "[INFO] Nothing to uninstall. Configuration file not found: $config_file"
		exit 0
	fi

	# Read the config file
	while IFS= read -r line; do
		# Skip comments and empty lines
		[[ "$line" =~ ^#.* ]] && continue
		[[ -z "$line" ]] && continue

		# Read type and path
		if [[ "$line" =~ ^type= ]]; then
			type="${line#*=}"
		elif [[ "$line" =~ ^path= ]]; then
			path="${line#*=}"
		elif [[ "$line" =~ ^[[:space:]] ]]; then
			binaries+=("${line//[[:space:]]/}")
		fi
	done <"$config_file"

	if [[ -z "$type" ]] || [[ -z "$path" ]]; then
		log $log_quiet "[ERROR] Invalid configuration file: $config_file" >&2
		exit 1
	fi

	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would remove existing $type installation from $path"
	else
		log $log_normal "[INFO] Removing existing $type installation from $path..."
	fi

	set_sudo_command "$path"
	for binary in "${binaries[@]}"; do
		if [[ $dry == "y" ]]; then
			log $log_normal "[dry] Would remove binary: $path/$binary"
			continue
		fi

		log $log_verbose "[INFO] Removing binary: $path/$binary"
		$sudo_command rm -f "$path/$binary" || {
			log $log_quiet "[ERROR] Failed to remove binary: $path/$binary" >&2
			exit 1
		}
	done

	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would remove configuration file: $config_file"
		log $log_normal "[dry] Would remove log file: $log_file"
		log $log_normal "[dry] Would remove configuration directory: $config_path"
	else
		log $log_verbose "[INFO] Removing configuration file: $config_file"
		rm "$config_file" 2>/dev/null || true

		log $log_verbose "[INFO] Removing log file: $log_file"
		rm "$log_file" 2>/dev/null || true

		log $log_verbose "[INFO] Removing configuration directory: $config_path"
		rmdir "$config_path" 2>/dev/null || true

		log $log_normal "[INFO] Uninstallation completed successfully."
	fi
}

main "$@"
