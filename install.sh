#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

# Log levels
#LOG_SILENT=0
LOG_QUIET=1
LOG_NORMAL=2
LOG_VERBOSE=3
LOG=$LOG_NORMAL

CONFIG_PATH="$HOME/.config/dsu"
CONFIG_FILE="$CONFIG_PATH/dsu.conf"
DSU_LOG_FILE="$CONFIG_PATH/dsu.log"

CLI_SRC_PATH="./target/release/dsu"
BASH_SRC_DIR="./dist"

INSTALL_DIR=""

CONFIG_BINARIES=()
declare -A CONFIG=(
  ["type"]=""
  ["path"]=""
)

DRY="n"
FORCE="ask"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]
Install all the scripts in ./sh to the specified directory.

Options:
  -p, --path    Specify the installation path (default: /usr/local/bin)
  -h, --help    Show this help message and exit

Example:
  $(basename "$0") -p ~/bin
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
      if [ "$LOG" -ge $LOG_QUIET ]; then
        echo "$message"
      fi
      ;;
    2)
      if [ "$LOG" -ge $LOG_NORMAL ]; then
        echo "$message"
      fi
      ;;
    3)
      if [ "$LOG" -ge $LOG_VERBOSE ]; then
        echo "$message"
      fi
      ;;
    *)
      echo "[ERROR] Invalid log level: $level" >&2
      exit 1
      ;;
  esac
}

arg_parse() {
  # Expand combined short options (e.g., -qy to -q -y)
  expanded_args=()
  while [[ $# -gt 0 ]]; do
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
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage
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
        log $LOG_QUIET "[ERROR] Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  # Will only happen when on verbose mode
  log $LOG_VERBOSE "[INFO] Running verbose log level"

  if [ "$FORCE" == "y" ]; then
    log $LOG_VERBOSE "[INFO] Running non-interactive mode. Assuming 'yes' for all prompts."
  elif [ "$FORCE" == "n" ]; then
    log $LOG_VERBOSE "[INFO] Running non-interactive mode. Assuming 'no' for all prompts."
  else
    log $LOG_VERBOSE "[INFO] Running interactive mode. Will prompt for confirmation."
  fi

  if [ $DRY == "y" ]; then
    log $LOG_VERBOSE "[INFO] Running dry run mode. No changes will be made."
  fi
}

do_install() {
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
        CONFIG["type"]="rust"
        install_rust_cli
        break
        ;;
      2)
        CONFIG["type"]="bash"
        install_bash_scripts
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
}

path_needs_sudo() {
  local path="$1"

  while true; do
    # Safeguard, prevent infinite loop
    if [ -z "$path" ]; then
      echo "Error: provided path is not valid: $1" >&2
      exit 1
    fi
    if [ "$path" == "/" ]; then
      echo "y"
      break
    fi

    # if exists, check write permissions
    if [ -e "$path" ]; then
      if [ -w "$path" ]; then
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

set_install_path() {
  local error=""

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
        INSTALL_DIR="/usr/local/bin"
        break
        ;;
      2)
        INSTALL_DIR="/opt/dsu"
        break
        ;;
      3)
        INSTALL_DIR="$HOME/bin"
        break
        ;;
      4)
        read -r -p "Enter the custom path: " -e
        INSTALL_DIR="$REPLY"
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

  if [ -z "$INSTALL_DIR" ]; then
    echo "Error: installation path not set." >&2
    exit 1
  fi

  CONFIG["path"]="$INSTALL_DIR"
}

write_to_conf() {
  local key="$1"
  local value="${2:-}"

  if [ -z "$value" ]; then
    echo "$key" >>"$CONFIG_FILE"
  else
    echo "$key=$value" >>"$CONFIG_FILE"
  fi
}

init_config() {
  echo "Writing configuration file..."
  mkdir -p "$CONFIG_PATH"
  rm "$CONFIG_FILE"
  touch "$CONFIG_FILE"

  write_to_conf "# Configuration file for dsu"
  write_to_conf "# This file is used to store the installation path and other settings"
  write_to_conf "# Do not modify this file unless you know what you are doing"
  write_to_conf ""
  write_to_conf "type" "${CONFIG["type"]}"
  write_to_conf "path" "${CONFIG["path"]}"
  write_to_conf "binaries="
  for binary in "${CONFIG_BINARIES[@]}"; do
    write_to_conf "    $binary"
  done
}

build_rust_cli() {
  # Cargo installed?
  if ! command -v cargo &>/dev/null; then
    echo "Rust CLI binary not found and Cargo is not installed."
    echo "For information on how to install cargo, refer to https://doc.rust-lang.org/cargo/getting-started/installation.html"
    exit 1
  fi

  # Prompt for user confirmation
  read -p "Rust CLI binary not found. Do you want to build it now? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting..."
    exit 0
  fi

  # Attempt to build the binary
  # Write output to log file
  echo "Building CLI binary..."
  cargo build --release >"$DSU_LOG_FILE)" 2>&1 || {
    echo "Failed to build Rust CLI binary." >&2
    echo "Check the log file for more information: $DSU_LOG_FILE" >&2
    echo "Last 10 lines of log file:" >&2
    tail "$DSU_LOG_FILE" >&2
    exit 1
  }
}

install_rust_cli() {
  local use_sudo
  local sudo_command=""

  clear
  set_install_path
  echo "Installing Rust CLI binary..."

  # Do we have the dsu binary?
  if [ ! -e "$CLI_SRC_PATH" ]; then
    build_rust_cli
  fi

  use_sudo="$(path_needs_sudo "$INSTALL_DIR")"

  # Do we have write permissions?
  if [ "$use_sudo" == "y" ]; then
    sudo_command="sudo"

    echo "Permission denied: $INSTALL_DIR" >&2

    # Elevate permissions? Prompt the user
    read -p "Do you want to elevate permissions to continue installation? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborting..."
      exit 0
    fi
  fi

  # Attempt to install
  $sudo_command mkdir -p "$INSTALL_DIR" || {
    echo "Could not create installation directory: $INSTALL_DIR" >&2
    exit 1
  }

  $sudo_command install -m 755 "$CLI_SRC_PATH" "$INSTALL_DIR" || {
    echo "Failed to install binary to installation directory: $INSTALL_DIR" >&2
    exit 1
  }

  CONFIG_BINARIES+=("$(basename "$CLI_SRC_PATH")")

  echo "Rust CLI binary installed successfully to: $INSTALL_DIR"
}

build_bash_scripts() {
  # Attempt to build the tarball
  # Write output to log file
  echo "Bash scripts tarball not found. Building..."

  ./build.sh >"$DSU_LOG_FILE" 2>&1 || {
    echo "Failed to build Bash scripts tarball." >&2
    echo "Check the log file for more information: $DSU_LOG_FILE" >&2
    echo "Last 10 lines of log file:" >&2
    tail "$DSU_LOG_FILE" >&2
    exit 1
  }
}

bash_tarball_to_tmp() {
  local tmp_dir
  tmp_dir=$(mktemp -d)

  # Extract the tarball to the temporary directory
  tar -xzf "$tarball" -C "$tmp_dir" || {
    echo "Failed to extract tarball to temporary directory: $tmp_dir" >&2
    exit 1
  }

  # Return the temporary directory
  # bin/ directory exists inside the tarball so we return that
  echo "$tmp_dir/bin"
}

install_bash_scripts() {
  local tarball tmp_dir use_sudo
  local sudo_command=""

  clear
  set_install_path
  echo "Installing standalone bash scripts..."

  # Do we have the tarball with the scripts?
  # Filename should be dsu-vx.y.z.tar.gz (semver schema)
  tarball="$BASH_SRC_DIR/dsu-$(cat VERSION).tar.gz"

  if [ ! -e "$tarball" ]; then
    build_bash_scripts
  fi

  tmp_dir=$(bash_tarball_to_tmp)
  use_sudo="$(path_needs_sudo "$INSTALL_DIR")"

  # Do we have write permissions?
  if [ "$use_sudo" == "y" ]; then
    sudo_command="sudo"

    echo "Permission denied: $INSTALL_DIR" >&2

    # Elevate permissions? Prompt the user
    read -p "Do you want to elevate permissions to continue installation? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborting..."
      exit 0
    fi
  fi

  # Attempt to install
  $sudo_command mkdir -p "$INSTALL_DIR" || {
    echo "Could not create installation directory: $INSTALL_DIR" >&2
    exit 1
  }

  # Attempt to install the files
  for file in "$tmp_dir"/*; do
    $sudo_command install -m 755 "$file" "$INSTALL_DIR" || {
      echo "Failed to install file to installation directory: $INSTALL_DIR" >&2
      exit 1
    }

    CONFIG_BINARIES+=("$(basename "$file")")
  done

  # Clean up the temporary directory
  rm -rf "$tmp_dir"

  echo "Bash scripts installed successfully to: $INSTALL_DIR"
}

remove_previous_install() {
  local type=""
  local path=""
  local binaries=()

  local use_sudo
  local sudo_command=""

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
      binaries+=("${line// /}")
    fi
  done <"$CONFIG_FILE"

  echo "Removing existing $type installation from $path..."

  use_sudo="$(path_needs_sudo "$path")"
  if [ "$use_sudo" == "y" ]; then
    sudo_command="sudo"

    echo "Permission denied: $path" >&2

    # Elevate permissions? Prompt the user
    read -p "Do you want to elevate permissions to continue installation? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborting..."
      exit 0
    fi
  fi

  for binary in "${binaries[@]}"; do
    $sudo_command rm -f "$path/$binary" || {
      echo "Failed to remove binary: $path/$binary" >&2
      exit 1
    }
  done

  rm "$CONFIG_FILE"
}

pre_install() {
  # Check for previous installation
  if [ ! -e "$CONFIG_FILE" ]; then
    return
  fi

  echo "Looks like dsu is already installed. Proceeding will remove the existing installation."
  read -p "Do you want to continue? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting..."
    exit 0
  fi

  remove_previous_install
}

post_install() {
  local reject_msg

  echo "Installation complete!"

  # shellcheck disable=SC2016
  reject_msg='Please make sure to add the installation path to your PATH environment variable.
For example, add the following line to your shell configuration file:
  export PATH="$PATH:'"$INSTALL_DIR"'"
'

  for path in $(echo "$PATH" | tr ':' '\n' | sort | uniq); do
    if [ "$path" == "$INSTALL_DIR" ]; then
      return
    fi
  done

  local shell_config_file

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

  if [ ! -w "$shell_config_file" ]; then
    echo "$reject_msg"
  else
    # Prompt the user to add the installation path to the PATH environment variable
    echo "Installation path not found in PATH environment variable."
    read -p "Do you want to add it now? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >>"$shell_config_file"
      echo "Installation path added to PATH environment variable."
    else
      echo "$reject_msg"
    fi
  fi

  echo "Do not forget to source your shell configuration file to apply the changes."
  echo "source $shell_config_file"
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
