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
  local name=${0##*/}
    cat << EOF
Usage: $name [OPTIONS]

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
      if [[ "$LOG" -ge $LOG_QUIET ]]; then
        echo "$message"
      fi
      ;;
    2)
      if [[ "$LOG" -ge $LOG_NORMAL ]]; then
        echo "$message"
      fi
      ;;
    3)
      if [[ "$LOG" -ge $LOG_VERBOSE ]]; then
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

path_needs_sudo() {
  local path="$1"

  while true; do
    # Safeguard, prevent infinite loop
    if [[ -z "$path" ]]; then
      log $LOG_QUIET "[ERROR] Provided path is not valid: $1" >&2
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
  if [[ $FORCE == "y" ]]; then
    log $LOG_VERBOSE "[INFO] Elevating permissions to continue installation."
  elif [[ $FORCE == "n" ]]; then
    log $LOG_NORMAL "[INFO] Elevated (sudo) permissions needed to continue installation. Exiting..."
    exit 0
  else
    # Elevate permissions? Prompt the user
    read -p "Do you want to elevate permissions to continue installation? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log $LOG_NORMAL "[INFO] Aborting..."
      exit 0
    fi
  fi

  # Elevate permissions
  sudo -v || {
    log $LOG_QUIET "[ERROR] Failed to elevate permissions. Exiting..." >&2
    exit 1
  }
}

get_sudo_command() {
  local path="$1"
  local use_sudo
  local sudo_command=""
  local status

  use_sudo="$(path_needs_sudo "$path")"
  status=$?

  if ((status != 0)); then
    log $LOG_QUIET "[ERROR] Could not determine if sudo is needed. Exiting..." >&2
    exit 1
  fi

  if [[ "$use_sudo" == "y" ]]; then
    sudo_command="sudo"
    prompt_for_sudo
  fi

  echo "$sudo_command"
}

main() {
  local binaries=()
  local type=""
  local path=""
  local sudo_command=""

  arg_parse "$@"

  if [[ ! -e "$CONFIG_FILE" ]]; then
    log $LOG_NORMAL "[INFO] Nothing to uninstall. Configuration file not found: $CONFIG_FILE"
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
  done <"$CONFIG_FILE"

  if [[ -z "$type" ]] || [[ -z "$path" ]]; then
    log $LOG_QUIET "[ERROR] Invalid configuration file: $CONFIG_FILE" >&2
    exit 1
  fi

  log $LOG_NORMAL "[INFO] Removing existing $type installation from $path..."

  sudo_command="$(get_sudo_command "$path" | tail -n 1)"
  for binary in "${binaries[@]}"; do
    log $LOG_VERBOSE "[INFO] Removing binary: $path/$binary"
    $sudo_command rm -f "$path/$binary" || {
      log $LOG_QUIET "[ERROR] Failed to remove binary: $path/$binary" >&2
      exit 1
    }
  done

  log $LOG_VERBOSE "[INFO] Removing configuration file: $CONFIG_FILE"
  rm "$CONFIG_FILE"

  log $LOG_VERBOSE "[INFO] Removing log file: $LOG_FILE"
  rm "$LOG_FILE"

  log $LOG_VERBOSE "[INFO] Removing configuration directory: $CONFIG_PATH"
  rmdir "$CONFIG_PATH"

  log $LOG_NORMAL "[INFO] Uninstallation completed successfully."
}

main "$@"
