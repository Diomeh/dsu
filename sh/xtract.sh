#!/usr/bin/env bash
#
# Extract the contents of a compressed archive to a directory.
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

# Logging

# Log levels
log_silent=0
log_error=1
log_warn=2
log_dry=3
log_info=4
log_verbose=5

# Default log level
log=$log_info

# Log level strings
declare -A log_levels=(
	[$log_silent]="SILENT"
	[$log_error]="ERROR"
	[$log_warn]="WARN"
	[$log_dry]="DRY"
	[$log_info]="INFO"
	[$log_verbose]="VERBOSE"
)

# Maximum log level
# Subtract so as to use the log_levels array as a 0-based index
max_log_level=${#log_levels[@]}
max_log_level=$((max_log_level - 1))

# Args and options
source=""
target=""
LIST="n"
dry="n"
force="ask"

# archive_types associative array
# This associative array maps archive extensions to the commands and flags needed
# for listing and extracting the contents of the compressed archives.
#
# Key: archive extension (without leading dot)
# Value: A string containing four space-separated components:
#   1. Dependency command: The command required to handle the archive type.
#   2. List flag: The flag used with the dependency command to list contents.
#   3. Extract flag: The flag used with the dependency command to extract contents.
#   4. Output flag (optional): The flag used to specify the output directory for extraction.
declare -A archive_types=(
	["tar"]="tar -tf -xf -C"
	["tar.gz"]="tar -tzf -xzf -C"
	["tgz"]="tar -tzf -xzf -C"
	["tar.bz2"]="tar -tjf -xjf -C"
	["tar.xz"]="tar -tJf -xJf -C"
	["tar.7z"]="7z l x -o"
	["7z"]="7z l x -o"
	["zip"]="unzip -l -d"
	["rar"]="unrar l x"
	# ["gz"]="gzip - -dc >"
	# ["bz2"]="bzip2 - -dc >"
	# ["xz"]="unxz -l -dc >"
)

usage() {
	cat <<EOF
Usage: $app [options] <archive> [target]

Extracts the contents of a compressed archive to a directory.

Arguments
	<archive>
		The path to the compressed archive file.

	[target]
		Optional. The directory where the contents will be extracted. Defaults to the current directory
		or a directory named after the archive file if contents are not immediately inside a folder.

Options
	-l, --list
		List the contents of the archive.

	-h, --help
		Show this help message and exit.

	-v, --version
		Show the version of this script and exit.

	-d, --dry
		Dry run. Print the operations that would be performed without actually executing them.

	-f, --force <y/n/ask>
		Force mode. One of (ask by default):
			- y: Automatic yes to prompts. Assume "yes" as the answer to all prompts and run non-interactively.
			- n: Automatic no to prompts. Assume "no" as the answer to all prompts and run non-interactively.
			- ask: Prompt for confirmation before overwriting existing backups. This is the default behavior.

	-L, --log <level>
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
	- If the target directory is not specified, the archive is extracted to the current directory.
	- If the archive contents are not inside a folder, a directory named after the archive will be created for extraction.

Examples
	Extract the contents of file.tar.gz to the current directory:
		$app file.tar.gz

	Extract the contents of file.tar.gz to ~/Documents:
		$app file.tar.gz ~/Documents

	List the contents of file.tar.gz:
		$app -l file.tar.gz

Supported archive types
	- tarball: .tar, .tar.gz, .tgz, .tar.bz2, .tar.xz, .tar.7z
	- .7z
	- .zip
	- .rar

Pending supported archive types
	- .gz
	- .bz2
	- .xz

Dependencies
	- tar: Required for tarball archives.
	- 7z: Required for 7z archives.
	- unzip: Required for zip archives.
	- unrar: Required for rar archives.

Notes
	- Ensure you have the necessary dependencies installed to handle the archive types (e.g., tar, unzip, 7z, unrar).
	- Extraction may require sufficient disk space and write permissions in the target directory.
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

log() {
	local level="$1"
	local message="$2"
	local level_str="${log_levels[$level]:-}"

	# Assert log level is valid
	[[ -z "$level_str" ]] && {
		log $log_warn "Invalid log level: $level" >&2
		return
	}

	# Assert message should be printed
	((log >= level)) && echo "[$level_str] $message"
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
			-l | --list)
				LIST="y"
				shift
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
			-L | --log)
				log="$2"

				if [[ ! $log =~ ^[${log_silent}-${max_log_level}]$ ]]; then
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

check_source() {
	if [[ -z "$source" ]]; then
		log $log_error "No archive provided" >&2
		exit 1
	elif [[ ! -r "$source" ]]; then
		log $log_error "Permission denied: $source" >&2
		exit 1
	elif [[ ! -f $source || -z ${archive_types[${source##*.}]:-} ]]; then
		log $log_error "Not a valid archive: $source" >&2
		exit 1
	fi
}

check_target() {
	if [[ ! -e "$target" ]]; then
		if [[ $dry == "y" ]]; then
			log $log_dry "Would create directory: $target"
			return
		fi

		if [[ $force == "y" ]]; then
			log $log_verbose "Creating directory: $target"
			mkdir -p "$target" || {
				log $log_error "Could not create directory: $target" >&2
				exit 1
			}
		elif [[ $force == "n" ]]; then
			log $log_error "Directory does not exist, exiting: $target" >&2
			exit 1
		else
			read -p "[WARN] Directory does not exist. Create? [y/N] " -n 1 -r
			echo ""
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				log $log_info "Exiting..."
				exit 0
			else
				log $log_verbose "Creating directory: $target"
				mkdir -p "$target" || {
					log $log_error "Could not create directory: $target" >&2
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

extract_archive() {
	local name
	local dependency="$1"
	local extract_flag="$2"
	local target_dir_flag="$3"
	local target_dir="$target"

	if [[ $dry == "y" ]]; then
		if [[ "$log" == "$log_verbose" ]]; then
			log $log_verbose "[dry] Would create temporary directory"
			log $log_verbose "[dry] Would extract $source to temporary directory"
			log $log_verbose "[dry] Would move contents from temporary directory to target directory: $target_dir"
			log $log_verbose "[dry] Would remove temporary directory"
		else
			log $log_dry "Would extract $source to $target_dir..."
		fi

		return 0
	fi

	log $log_verbose "Creating temporary directory"

	# Create a temporary directory to extract the contents
	local temp_dir
	temp_dir=$(mktemp -d) || {
		log $log_error "Could not create temporary directory" >&2
		exit 1
	}

	log $log_info "Extracting $source to $target_dir..."

	if [[ -z ${target_dir_flag:-} ]]; then
		if [[ $dependency == "unzip" ]]; then
			"$dependency" "$source" "$extract_flag" "$temp_dir" >/dev/null
		else
			"$dependency" "$extract_flag" "$source" "$temp_dir" >/dev/null
		fi
	else
		if [[ $dependency == "7z" ]]; then
			# 7z requires the output flag to be prepended to the target directory
			# eg. 7z x file.7z -o/tmp/archive (notice no space between -o and the directory)
			"$dependency" "$extract_flag" "$source" "$target_dir_flag""$temp_dir" >/dev/null
		else
			"$dependency" "$extract_flag" "$source" "$target_dir_flag" "$temp_dir" >/dev/null
		fi
	fi

	# Check exit status of the extraction command
	local exit_code=$?
	if ((exit_code != 0)); then
		log $log_error "Extraction failed with exit code $exit_code" >&2
		exit 1
	fi

	log $log_verbose "Checking contents of the extracted directory: $temp_dir"

	# Check if the contents are immediately inside a folder and move them accordingly
	# Get basename
	name=${source##*/}

	# Remove extension
	name=${name%.archive_extension}
	target="$target_dir/$name"

	if (("$(find "$temp_dir" -maxdepth 1 -type d | wc -l)" > 1)); then
		log $log_verbose "Using archive name as target directory: $target"
		log $log_verbose "Moving contents to target directory"

		mkdir -p "$target"
		mv "$temp_dir"/* "$target"
	else
		log $log_verbose "Moving contents to target directory: $target_dir"
		mv "$temp_dir"/* "$target_dir"
	fi

	# Remove the temporary directory
	log $log_verbose "Removing temporary directory"
	rmdir "$temp_dir"

	log $log_info "Extraction complete: $target"
}

run() {
	local dependency list_flag extract_flag target_dir_flag
	local archive_extension="${source##*.}"

	read -r dependency list_flag extract_flag target_dir_flag <<<"${archive_types[$archive_extension]}"

	if ! command -v "$dependency" &>/dev/null; then
		log $log_error "$dependency is needed but not found." >&2
		exit 1
	fi

	if [[ $dry == "y" ]]; then
		if [[ $LIST == "Y" ]]; then
			log $log_dry "Would list contents of $source"
		else
			log $log_dry "Would extract contents of $source"
		fi
	else
		if [[ $LIST == "Y" ]]; then
			log $log_info "Listing contents of $source"
			"$dependency" "$list_flag" "$source"
		else
			log $log_info "Initiating extraction process."
			extract_archive "$dependency" "$extract_flag" "$target_dir_flag"
		fi
	fi
}

main() {
	arg_parse "$@"

	log $log_verbose "Checking source directory"
	check_source

	log $log_verbose "Checking target directory"
	check_target

	run
}

main "$@"
