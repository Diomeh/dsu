#!/usr/bin/env bash
#
# Uninstaller for DSU shell utilities
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-08
#
# -*- mode: shell-script -*-

set -uo pipefail

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
	-h, --help
		Display this help message and exit
	-d, --dry
		Dry run. Print the operations that would be performed without actually executing them.
	-f, --force <y/n/ask>
		Force mode. One of (ask by default):
			- y: Assume "yes" as the answer to all prompts and run non-interactively.
			- n: Assume "no" as the answer to all prompts and run non-interactively.
			- ask: Prompt for confirmation before removing binaries and configuration files. This is the default behavior.

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
EOF
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
				log $log_error "Unknown argument: $1" >&2
				usage
				exit 1
				;;
		esac
	done

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

path_needs_sudo() {
	local path="$1"

	while true; do
		# Safeguard, prevent infinite loop
		if [[ -z "$path" ]]; then
			log $log_error "Provided path is not valid: $1" >&2
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
		log $log_verbose "Elevating permissions to continue installation."
	elif [[ $force == "n" ]]; then
		log $log_info "Elevated (sudo) permissions needed to continue installation. Exiting..."
		exit 0
	else
		# Elevate permissions? Prompt the user
		read -p "Do you want to elevate permissions to continue installation? [y/N] " -n 1 -r
		echo ""
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log $log_info "Aborting..."
			exit 0
		fi
	fi

	# Elevate permissions
	sudo -v || {
		log $log_error "Failed to elevate permissions. Exiting..." >&2
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
		log $log_error "Could not determine if sudo is needed. Exiting..." >&2
		exit 1
	fi

	if [[ "$use_sudo" == "y" ]]; then
		if [[ $dry == "y" ]]; then
			log $log_dry "Would use sudo to remove binaries from $path"
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
	disable_color

	if [[ ! -e "$config_file" ]]; then
		log $log_info "Nothing to uninstall. Configuration file not found: $config_file"
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
		log $log_error "Invalid configuration file: $config_file" >&2
		exit 1
	fi

	if [[ $dry == "y" ]]; then
		log $log_dry "Would remove existing $type installation from $path"
	else
		log $log_info "Removing existing $type installation from $path..."
	fi

	set_sudo_command "$path"
	for binary in "${binaries[@]}"; do
		if [[ $dry == "y" ]]; then
			log $log_dry "Would remove binary: $path/$binary"
			continue
		fi

		log $log_verbose "Removing binary: $path/$binary"
		$sudo_command rm -f "$path/$binary" || {
			log $log_error "Failed to remove binary: $path/$binary" >&2
			exit 1
		}
	done

	if [[ $dry == "y" ]]; then
		log $log_dry "Would remove configuration file: $config_file"
		log $log_dry "Would remove log file: $log_file"
		log $log_dry "Would remove configuration directory: $config_path"
	else
		log $log_verbose "Removing configuration file: $config_file"
		rm "$config_file" 2>/dev/null || true

		log $log_verbose "Removing log file: $log_file"
		rm "$log_file" 2>/dev/null || true

		log $log_verbose "Removing configuration directory: $config_path"
		rmdir "$config_path" 2>/dev/null || true

		log $log_info "Uninstallation completed successfully."
	fi
}

main "$@"
