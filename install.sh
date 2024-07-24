#!/usr/bin/env bash
#
# Installer for DSU shell utilities
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

cli_src="./target/release/dsu"
bash_src="./dist"

install_dir=""

config_binaries=()
declare -A config=(
	["type"]=""
	["path"]=""
)

dry="n"
force="ask"
type="0"
user_path=""
sudo_command=""

usage() {
	local name=${0##*/}
	cat <<EOF
Usage: $name [OPTIONS]
Installs Diomeh's Script Utilities (dsu) on your system.

Options:
  -h, --help              Display this help message and exit
  -d, --dry               Dry run. Print the operations that would be performed without actually executing them.
  -f, --force <y/n/ask>   Interactive mode. If set to other than 'ask' -t is required. One of (ask by default):
                            - y: Assume "yes" as the answer to all prompts and run non-interactively.
                            - n: Assume "no" as the answer to all prompts and run non-interactively.
                            - ask: Prompt for confirmation before removing binaries and configuration files. This is the default behavior.
  -t, --type <type>       Installation type. If -f is set, this option is required. One of:
                            - rust: Install the Rust CLI binary
                            - bash: Install the standalone bash scripts
  -p, --path <path>       The path where the utilities will be installed. If -f is set, this option is required.
  -l, --log <level>       Log level. One of (2 by default):
                            - 0: Silent mode. No output
                            - 1: Quiet mode. Only errors
                            - 2: Log mode. Errors warnings and information. This is the default behavior.
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
			-t | --type)
				type="$2"

				if [[ ! $type =~ ^(rust|bash)$ ]]; then
					log $log_quiet "[ERROR] Invalid installation type: $type" >&2
					exit 1
				fi

				# 1 for rust, 2 for bash
				if [[ "$type" == "rust" ]]; then
					type=1
				else
					type=2
				fi

				shift 2
				;;
			-p | --path)
				user_path="$2"
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
			path=${path%/*}
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
	local use_sudo status
	local path="$1"

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

set_install_path() {
	local error=""

	# If path is provided, use it
	if [[ -n "$user_path" ]]; then
		if [[ $dry == "y" ]]; then
			log $log_normal "[dry] Would use provided path: $user_path"
		else
			log $log_verbose "[INFO] Using provided installation path: $user_path"
		fi
		install_dir="$user_path"
		config["path"]="$install_dir"
		return
	fi

	if [[ $force == "ask" ]]; then
		while true; do
			clear
			read -d'' -r -n1 -p 'Where do you want to install the utilities?
  1. Default multi user path (/usr/local/bin)
  2. Multi user path (/opt/dsu)
  3. Single user path ('"$HOME"'/bin)
  4. Custom path
  q. Abort and exit
'"$error"'Option: '
			echo ""

			case "$REPLY" in
				1)
					install_dir="/usr/local/bin"
					break
					;;
				2)
					install_dir="/opt/dsu"
					break
					;;
				3)
					install_dir="$HOME/bin"
					break
					;;
				4)
					read -r -p "Enter the custom path: " -e
					install_dir="$REPLY"
					break
					;;
				q)
					echo "Aborting..."
					exit 0
					;;
				*)
					error="Invalid choice: $REPLY. "
					;;
			esac
		done
	else
		install_dir="/usr/local/bin"
		log $log_verbose "[INFO] Using default installation path: $install_dir"
	fi

	if [[ -z "$install_dir" ]]; then
		log $log_quiet "[ERROR] installation path not set." >&2
		exit 1
	fi

	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would use installation path: $install_dir"
	fi

	config["path"]="$install_dir"
}

build_rust_cli() {
	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would build Rust CLI binary"
		return
	fi

	log $log_verbose "[INFO] Building Rust CLI binary..."
	log $log_verbose "[INFO] Checking for cargo..."

	# Cargo installed?
	if ! command -v cargo &>/dev/null; then
		log $log_normal "[WARN] Rust CLI binary not found and Cargo is not installed." >&2
		log $log_normal "[WARN] For information on how to install cargo, refer to https://doc.rust-lang.org/cargo/getting-started/installation.html" >&2
		log $log_normal "[WARN] Aborting..." >&2
		exit 1
	fi

	log $log_verbose "[INFO] Cargo found!"

	if [[ $force == "n" ]]; then
		log $log_normal "[WARN] Rust CLI binary not found. Aborting..." >&2
		exit 1
	elif [[ $force == "ask" ]]; then
		# Prompt for user confirmation
		read -p "Rust CLI binary not found. Do you want to build it now? [y/N] " -n 1 -r
		echo ""
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log $log_normal "[INFO] Aborting..."
			exit 0
		fi
	fi

	log $log_verbose "[INFO] Running cargo build..."

	# Attempt to build the binary. Write output to log file
	cargo build --release >"$log_file" 2>&1 || {
		log $log_quiet "[ERROR] Failed to build Rust CLI binary." >&2
		log $log_quiet "[INFO] Check the log file for more information: $log_file" >&2
		log $log_quiet "[INFO] For more information check log file: $log_file" >&2
		tail "$log_file" >&2
		exit 1
	}

	log $log_verbose "[INFO] Rust CLI binary built successfully!"
}

install_rust_cli() {
	config["type"]="rust"

	set_install_path
	log $log_normal "[INFO] Installing Rust CLI binary..."

	# Do we have the dsu binary?
	if [[ ! -e "$cli_src" ]]; then
		build_rust_cli
	fi

	set_sudo_command "$install_dir"
	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would create installation directory: $install_dir"
		log $log_normal "[dry] Would install binary to installation directory: $install_dir"
		return
	fi

	log $log_verbose "[INFO] Creating installation directory: $install_dir"

	$sudo_command mkdir -p "$install_dir" || {
		log $log_quiet "Could not create installation directory: $install_dir" >&2
		exit 1
	}

	log $log_quiet "[INFO] Installing binary to installation directory: $install_dir"

	$sudo_command install -m 755 "$cli_src" "$install_dir" || {
		echo "Failed to install binary to installation directory: $install_dir" >&2
		exit 1
	}

	config_binaries+=("${cli_src##*/}")
	log $log_normal "[INFO] Binary installed successfully to: $install_dir"
}

build_bash_scripts() {
	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would build Bash scripts tarball"
		return
	fi

	# Attempt to build the tarball
	# Write output to log file
	log $log_normal "[WARN] Bash scripts tarball not found. Building..."

	./build.sh >"$log_file" 2>&1 || {
		log $log_quiet "[ERROR] Failed to build Bash scripts tarball." >&2
		log $log_normal "[WARN] Check the log file for more information: $log_file" >&2
		log $log_normal "[WARN] Last 10 lines of log file:" >&2
		tail "$log_file" >&2
		exit 1
	}
}

bash_tarball_to_tmp() {
	local tmp_dir

	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would extract tarball to temporary directory"
		return
	fi

	tmp_dir=$(mktemp -d)

	# Extract the tarball to the temporary directory
	tar -xzf "$tarball" -C "$tmp_dir" || {
		log $log_quiet "[ERROR] Failed to extract tarball to temporary directory: $tmp_dir" >&2
		exit 1
	}

	# Return the temporary directory
	# bin/ directory exists inside the tarball so we return that
	echo "$tmp_dir/bin"
}

install_bash_scripts() {
	config["type"]="bash"

	local tarball tmp_dir use_sudo

	set_install_path

	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would install standalone bash scripts"
	else
		log $log_normal "[INFO] Installing standalone bash scripts..."
	fi

	# Do we have the tarball with the scripts?
	# Filename should be dsu-vx.y.z.tar.gz (semver schema)
	tarball="$bash_src/dsu-$(cat version).tar.gz"

	if [[ ! -e "$tarball" ]]; then
		build_bash_scripts
	fi

	tmp_dir=$(bash_tarball_to_tmp)

	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would extract tarball to temporary directory"
	else
		log $log_verbose "[INFO] Extracted tarball to temporary directory: $tmp_dir"
	fi

	set_sudo_command "$install_dir"
	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would create installation directory: $install_dir"
		log $log_normal "[dry] Would install bash scripts to installation directory: $install_dir"
		return
	fi

	log $log_verbose "[INFO] Creating installation directory: $install_dir"
	$sudo_command mkdir -p "$install_dir" || {
		log $log_quiet "[ERROR] Could not create installation directory: $install_dir" >&2
		exit 1
	}

	log $log_verbose "[INFO] Installing bash scripts to installation directory: $install_dir"
	for file in "$tmp_dir"/*; do
		log $log_verbose "[INFO] Installing file: ${file##*/}"
		$sudo_command install -m 755 "$file" "$install_dir" || {
			log $log_quiet "[ERROR] Failed to install file to installation directory: $install_dir" >&2
			exit 1
		}

		config_binaries+=("${file##*/}")
	done

	# Clean up the temporary directory
	log $log_verbose "[INFO] Cleaning up temporary directory: $tmp_dir"
	rm -rf "$tmp_dir"

	log $log_normal "[INFO] Bash scripts installed successfully to: $install_dir"
}

remove_previous_install() {
	local binaries=()
	local type=""
	local path=""

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

pre_install() {
	# Check for previous installation
	if [[ ! -e "$config_file" ]]; then
		log $log_normal "[INFO] Nothing to uninstall. Configuration file not found: $config_file"
		return
	fi

	if [[ $force == "y" ]]; then
		log $log_normal "[INFO] Previous installation found. Removing..."
		remove_previous_install
	elif [[ $force == "n" ]]; then
		log $log_quiet "Previous installation found. Exiting..."
		exit 0
	else
		echo "Looks like dsu is already installed. Proceeding will remove the existing installation."
		read -p "Do you want to continue? [y/N] " -n 1 -r
		echo ""
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			echo "Aborting..."
			exit 0
		fi

		remove_previous_install
	fi
}

do_install() {
	# Skip the prompt if either force mode is set or install type is provided
	if [[ $force != "ask" ]] || [[ $type != 0 ]]; then
		case "$type" in
			1) install_rust_cli ;;
			2) install_bash_scripts ;;
			*) log $log_quiet "[ERROR] Invalid installation type: $type." >&2 ;;
		esac
		return
	fi

	local error=""
	while true; do
		clear
		read -d'' -r -n1 -p 'Welcome to the dsu'\''s installer!

Currently, there are two implementations of the utilities:
.- Rust CLI: A command-line interface written in Rust that bundles all the utilities in one place.
.- Bash individual scripts: Each script is a standalone utility that can be used independently.

Both implementations are kept up-to-date and have the same features. The choice is yours!

Please select the installation method:
  1. Rust CLI
  2. Bash individual scripts
  q. Abort and exit
'"$error"'Option: '
		echo ""

		case "$REPLY" in
			1)
				install_rust_cli
				break
				;;
			2)
				install_bash_scripts
				break
				;;
			q) echo "Aborting..." exit 0 ;;
			*) error="Invalid choice: $REPLY. " ;;
		esac
	done
}

write_to_conf() {
	local key="$1"
	local value="${2:-}"

	if [[ -z "$value" ]]; then
		echo "$key" >>"$config_file"
	else
		echo "$key=$value" >>"$config_file"
	fi
}

init_config() {
	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would write configuration file"
		log $log_normal "[dry] Would create configuration directory: $config_path"
		return
	fi

	log $log_normal "[INFO] Writing configuration file..."
	log $log_verbose "[INFO] Creating configuration directory: $config_path"

	mkdir -p "$config_path"
	rm "$config_file" 2>/dev/null || true
	touch "$config_file"

	write_to_conf "# Configuration file for dsu"
	write_to_conf "# This file is used to store the installation path and other settings"
	write_to_conf "# Do not modify this file unless you know what you are doing"
	write_to_conf ""
	write_to_conf "type" "${config["type"]}"
	write_to_conf "path" "${config["path"]}"
	write_to_conf "binaries="
	for binary in "${config_binaries[@]}"; do
		write_to_conf "    $binary"
	done
}

post_install() {
	local reject_msg
	local shell_config_file

	if [[ $dry == "y" ]]; then
		log $log_normal "[dry] Would check if installation path is in PATH environment variable"
		return
	fi

	log $log_normal "[INFO] Installation complete!"

	# shellcheck disable=SC2016
	reject_msg='[INFO] Please make sure to add the installation path to your PATH environment variable.
[INFO] For example, add the following line to your shell configuration file:
  export PATH="$PATH:'"$install_dir"'"'

	log $log_verbose "[INFO] Checking if installation path is in PATH environment variable..."
	for path in $(echo "$PATH" | tr ':' '\n' | sort | uniq); do
		if [[ "$path" == "$install_dir" ]]; then
			return
		fi
	done

	log $log_verbose "[INFO] Installation path not found in PATH environment variable."
	case "$SHELL" in
		*/bash)
			shell_config_file="$HOME/.bashrc"
			;;
		*/zsh)
			shell_config_file="$HOME/.zshrc"
			;;
		*)
			shell_config_file=""
			;;
	esac

	if [[ ! -w "$shell_config_file" ]]; then
		echo "$reject_msg"
	else
		if [[ $force == "y" ]]; then
			echo "export PATH=\"\$PATH:$install_dir\"" >>"$shell_config_file"
			log $log_normal "[INFO] Installation path added to PATH environment variable."
		elif [[ $force == "n" ]]; then
			echo "$reject_msg"
		else
			# Prompt the user to add the installation path to the PATH environment variable
			read -p "Do you want to add it now? [y/N] " -n 1 -r
			echo ""
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				echo "export PATH=\"\$PATH:$install_dir\"" >>"$shell_config_file"
				log $log_normal "[INFO] Installation path added to PATH environment variable."
			else
				echo "$reject_msg"
			fi
		fi
	fi

	log $log_normal "[INFO] Do not forget to source your shell configuration file to apply the changes."
	echo "    source $shell_config_file"
}

main() {
	arg_parse "$@"

	pre_install

	# These functions can call exit on failure
	# So, we don't need to check for errors here
	# PD: Is this a good practice?
	do_install
	init_config
	post_install
}

main "$@"
