#!/usr/bin/env bash
#
# Clean up filenames by replacing special characters with underscores.
#
# Author: David Urbina (davidurbina.dev@gmail.com)
# Date: 2022-02
# License: MIT
# Updated: 2024-07
#
# -*- mode: shell-script -*-

set -uo pipefail

IFS=$'\n\t'

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

# arguments and options
dry="n"
recurse="n"
recurse_depth=""
force="ask"

# Paths to process
paths=()

usage() {
	cat <<EOF
Usage: $app [directories...]

Replace all special characters in filenames within the specified directories.
If no directories are provided, the script will operate in the current directory.

Options
-h, --help
	Show this help message and exit.

-v, --version
	Display the version of this script and exit

-d, --dry
	Dry run. Print the operations that would be performed without actually executing them.

-c, --check-version
	Checks the version of this script against the remote repo version and prints a message on how to update.

-r, --recursive
	Recursively process all files in the specified directories.

-n, --recurse-depth <n>
	The maximum number of subdirectories to recurse into. Default is unlimited.

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

Behaviour
	The script replaces characters that are not alphanumeric or hyphens with underscores.
	Spaces, punctuation, and other special characters will be replaced.

	So, for a file named as "my file.txt", it will be renamed to "my_file.txt", notice the space.
	Another example, "léeme.md" will be renamed to "l_eme.md".
	If the result of renaming a file is that of either an empty string or "_", the file will be skipped.

Examples
	Replace special characters in filenames in the current directory.
		$app
		$app .
		$app $(pwd)

	Replace special characters in filenames within ~/Documents.
		$app ~/Documents

	Replace special characters in filenames within ./foo and /bar.
		$app ./foo /bar

	Replace special characters in filenames recursively within ~/Documents.
		$app -r ~/Documents

Special Character Replacement
	A regex pattern of the form "[^A-Za-z0-9_.-]" is used to match special characters.

Note
	- Ensure you have the necessary permissions to read/write files in the specified directories.
	- Filenames that only differ by special characters might result in name conflicts after replacement.
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

parse_args() {
	# Expand combined short options (e.g., -dr to -d -r)
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
			-d | --dry)
				dry="y"
				shift
				;;
			-r | --recursive)
				recurse="y"
				shift
				;;
			-n | --recurse-depth)
				recurse_depth="$2"

				# Validate depth is a positive integer
				if ! [[ "$recurse_depth" =~ ^[0-9]+$ ]]; then
					log $log_error "Invalid recursion depth: $recurse_depth" >&2
					exit 1
				fi

				shift 2
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
			-*)
				log $log_error "Unknown option: $1" >&2
				usage
				exit 1
				;;
			*)
				paths+=("$1")
				shift
				;;
		esac
	done

	# If no paths are provided, default to the current directory
	if ((${#paths[@]} == 0)); then
		paths+=(".")
	fi
}

replace_special_chars() {
	local filename new_name target
	local filepath="$1"

	# Extract filename without directory path
	filename=${filepath##*/}

	# Replace spaces with underscore
	new_name=${filename// /_}

	# Replace multiple underscores with a single underscore
	new_name=${new_name//__/_}

	# Remove leading and trailing underscores
	new_name=${new_name#_}
	new_name=${new_name%_}

	# Remove special characters
	new_name=${new_name//[^A-Za-z0-9_.-]/}

	# If new_name is empty, skip
	if [[ -z "$new_name" ]]; then
		log $log_warn "$filename: new name is empty. Skipping..." >&2
		return
	fi

	# If names are the same, skip
	if [[ "$filename" == "$new_name" ]]; then
		log $log_verbose "$filename: No special characters found. Skipping..."
		return
	fi

	target="${filepath%/*}/$new_name"

	if [[ "$dry" == "y" ]]; then
		log $log_dry "Would rename: $filename -> $new_name"
		if [[ -e "$target" ]]; then
			log $log_dry "Would need to overwrite: $target"
		fi
		return 0
	else
		log $log_info "Renaming: $filename -> $new_name"
	fi

	# Check if target file doesn't exists
	if ! [[ -e "$target" ]]; then
		mv "$filepath" "$target"
		return 0
	fi

	if [[ "$force" == "y" ]]; then
		log $log_verbose "Overwriting: $target"
		rm -rf "$target"
	elif [[ "$force" == "n" ]]; then
		log $log_info "File exists. Skipping...: $filename"
		return 0
	else
		read -p "File already exists. Overwrite? [y/N] " -n 1 -r
		echo ""
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log $log_info "Skipping $filename..."
			return 0
		else
			rm -rf "$target" # Remove the existing file before renaming
		fi
	fi

	mv "$filepath" "$target"
}

process_paths() {
	local depth=$1
	shift
	local paths=("$@")

	for path in "${paths[@]}"; do
		if [[ ! -e "$path" ]]; then
			log $log_error "$path: No such file or directory" >&2
			continue
		fi

		if [[ ! -r "$path" ]] || [[ ! -w "$path" ]]; then
			log $log_error "$path: Permission denied" >&2
			continue
		fi

		log $log_verbose "Processing directory: $path"
		if (( recurse_depth > 0 )); then
			log $log_verbose "Recurse depth: $depth of $recurse_depth"
		else
			log $log_verbose "Recurse depth: $depth"
		fi

		# Process single file
		if [[ -f "$path" ]]; then
			replace_special_chars "$path"
			continue
		fi

		# Process all files in the directory
		if [[ "$recurse" != "y" ]]; then
			for file in "$path"/*; do
				replace_special_chars "$file"
			done
			continue
		fi

		# Don't forget to process the directory itself
		replace_special_chars "$path"

		log $log_verbose "Recursing into: $path"

		# Recursively process directories
		if ((depth < recurse_depth)); then
			for file in "$path"/*; do
				if [[ -d "$file" ]]; then
					process_paths "$((depth + 1))" "$file"
				else
					replace_special_chars "$file"
				fi
			done
		fi
	done
}

main() {
	parse_args "$@"
	process_paths 0 "${paths[@]}"
}

main "$@"
