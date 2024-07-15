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
LOG_FILE="$CONFIG_PATH/dsu.log"

DRY="n"
FORCE="ask"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Removes the installed binaries and configuration files of the Diomeh's Script Utilities.

Options:
  -h, --help              Display this help message and exit
  -d, --dry               Dry run. Print the operations that would be performed without actually executing them.
  -f, --force <y/n/ask>   Force mode. One of (ask by default):
                            - y: Automatic yes to prompts. Assume "yes" as the answer to all prompts and run non-interactively.
                            - n: Automatic no to prompts. Assume "no" as the answer to all prompts and run non-interactively.
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

main() {
  arg_parse "$@"

  if [ ! -e "$CONFIG_FILE" ]; then
    echo "Nothing to uninstall. Configuration file not found: $CONFIG_FILE"
    exit 0
  fi

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
  rm "$LOG_FILE"
  rmdir "$CONFIG_PATH"
}

main "$@"
