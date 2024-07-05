#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

VERSION="v2.1.28"

# Log levels
#LOG_SILENT=0
LOG_QUIET=1
LOG_NORMAL=2
LOG_VERBOSE=3

# Args and options
SOURCE=""
TARGET=""
LIST="n"
DRY="n"
FORCE="ask"
LOG=$LOG_NORMAL

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
Usage: $(basename "$0") [options] <archive> [target]
Extracts the contents of a compressed archive to a directory.

Arguments:
  <archive>               The path to the compressed archive file.
  [target]                Optional. The directory where the contents will be extracted. Defaults to the current directory
                          or a directory named after the archive file if contents are not immediately inside a folder.

Options:
  -l, --list              List the contents of the archive.
  -h, --help              Show this help message and exit.
  -v, --version           Show the version of this script and exit.
  -d, --dry               Dry run. Print the operations that would be performed without actually executing them.
  -f, --force <y/n/ask>
                          Force mode. One of (ask by default):
                            - y: Automatic yes to prompts. Assume "yes" as the answer to all prompts and run non-interactively.
                            - n: Automatic no to prompts. Assume "no" as the answer to all prompts and run non-interactively.
                            - ask: Prompt for confirmation before overwriting existing backups. This is the default behavior.
  -L, --log <level>
                          Log level. One of (2 by default):
                            - 0: Silent mode. No output
                            - 1: Quiet mode. Only errors
                            - 2: Normal mode. Errors warnings and information. This is the default behavior.
                            - 3: Verbose mode. Detailed information about the operations being performed.
  -c, --check-version     Checks the version of this script against the remote repo version and prints a message on how to update.

Behavior:
- If the target directory is not specified, the archive is extracted to the current directory.
- If the archive contents are not inside a folder, a directory named after the archive will be created for extraction.

Examples:
  Extract the contents of file.tar.gz to the current directory:
    $(basename "$0") file.tar.gz

  Extract the contents of file.tar.gz to ~/Documents:
    $(basename "$0") file.tar.gz ~/Documents

  List the contents of file.tar.gz:
    $(basename "$0") -l file.tar.gz

Supported archive types (Archive types not listed here are not supported):
  - tarball: .tar, .tar.gz, .tgz, .tar.bz2, .tar.xz, .tar.7z
  - .7z
  - .zip
  - .rar

Pending supported archive types:
  - .gz
  - .bz2
  - .xz

Dependencies:
  - tar: Required for tarball archives.
  - 7z: Required for 7z archives.
  - unzip: Required for zip archives.
  - unrar: Required for rar archives.

Notes:
- Ensure you have the necessary dependencies installed to handle the archive types (e.g., tar, unzip, 7z, unrar).
- Extraction may require sufficient disk space and write permissions in the target directory.
EOF
}

version() {
  echo "$(basename "$0") version $VERSION"
}

check_version() {
  echo "[INFO] Current version: $VERSION"
  echo "[INFO] Checking for updates..."

  local remote_version
  remote_version="$(curl -s https://raw.githubusercontent.com/Diomeh/dsu/master/VERSION)"

  # strip leading and trailing whitespace
  remote_version="$(echo -e "${remote_version}" | tr -d '[:space:]')"

  # Check if the remote version is different from the local version
  if [ "$remote_version" != "$VERSION" ]; then
    echo "[INFO] A new version of $(basename "$0") ($remote_version) is available!"
    echo "[INFO] Refer to the repo README on how to update: https://github.com/Diomeh/dsu/blob/master/README.md"
  else
    echo "[INFO] You are running the latest version of $(basename "$0")."
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
    -L | --log)
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
      if [ -z "$SOURCE" ]; then
        SOURCE="$1"
      elif [ -z "$TARGET" ]; then
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
  TARGET="${TARGET:-$(pwd)}"

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

check_source() {
  if [ -z "$SOURCE" ]; then
    log $LOG_QUIET "[ERROR] No archive provided" >&2
    exit 1
  elif [ ! -r "$SOURCE" ]; then
    log $LOG_QUIET "[ERROR] Permission denied: $SOURCE" >&2
    exit 1
  elif [[ ! -f $SOURCE || -z ${archive_types[${SOURCE##*.}]:-} ]]; then
    log $LOG_QUIET "[ERROR] Not a valid archive: $SOURCE" >&2
    exit 1
  fi
}

check_target() {
  if [ ! -e "$TARGET" ]; then
    if [[ $DRY == "y" ]]; then
      log $LOG_NORMAL "[DRY] Would create directory: $TARGET"
      return
    fi

    if [[ $FORCE == "y" ]]; then
      log $LOG_VERBOSE "[INFO] Creating directory: $TARGET"
      mkdir -p "$TARGET" || {
        log $LOG_QUIET "[ERROR] Could not create directory: $TARGET" >&2
        exit 1
      }
    elif [[ $FORCE == "n" ]]; then
      log $LOG_QUIET "[ERROR] Directory does not exist, exiting: $TARGET" >&2
      exit 1
    else
      read -p "[WARN] Directory does not exist. Create? [y/N] " -n 1 -r
      echo ""
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log $LOG_NORMAL "[INFO] Exiting..."
        exit 0
      else
        log $LOG_VERBOSE "[INFO] Creating directory: $TARGET"
        mkdir -p "$TARGET" || {
          log $LOG_QUIET "[ERROR] Could not create directory: $TARGET" >&2
          exit 1
        }
      fi
    fi
  elif [ ! -d "$TARGET" ]; then
    log $LOG_QUIET "[ERROR] Not a directory: $TARGET" >&2
    exit 1
  elif [ ! -w "$TARGET" ]; then
    log $LOG_QUIET "[ERROR] Permission denied: $TARGET" >&2
    exit 1
  fi
}

extract_archive() {
  local dependency="$1"
  local extract_flag="$2"
  local target_dir_flag="$3"
  local target_dir="$TARGET"

  if [[ $DRY == "y" ]]; then
    if [ "$LOG" == $LOG_VERBOSE ]; then
      log $LOG_VERBOSE "[DRY] Would create temporary directory"
      log $LOG_VERBOSE "[DRY] Would extract $SOURCE to temporary directory"
      log $LOG_VERBOSE "[DRY] Would move contents from temporary directory to target directory: $target_dir"
      log $LOG_VERBOSE "[DRY] Would remove temporary directory"
    else
      log $LOG_NORMAL "[DRY] Would extract $SOURCE to $target_dir..."
    fi

    return 0
  fi

  log $LOG_VERBOSE "[INFO] Creating temporary directory"

  # Create a temporary directory to extract the contents
  local temp_dir
  temp_dir=$(mktemp -d) || {
    log $LOG_QUIET "[ERROR] Could not create temporary directory" >&2
    exit 1
  }

  log $LOG_NORMAL "[INFO] Extracting $SOURCE to $target_dir..."

  if [[ -z ${target_dir_flag:-} ]]; then
    if [[ $dependency == "unzip" ]]; then
      "$dependency" "$SOURCE" "$extract_flag" "$temp_dir" >/dev/null
    else
      "$dependency" "$extract_flag" "$SOURCE" "$temp_dir" >/dev/null
    fi
  else
    if [[ $dependency == "7z" ]]; then
      # 7z requires the output flag to be prepended to the target directory
      # eg. 7z x file.7z -o/tmp/archive (notice no space between -o and the directory)
      "$dependency" "$extract_flag" "$SOURCE" "$target_dir_flag""$temp_dir" >/dev/null
    else
      "$dependency" "$extract_flag" "$SOURCE" "$target_dir_flag" "$temp_dir" >/dev/null
    fi
  fi

  # Check exit status of the extraction command
  local exit_code=$?
  if [ "$exit_code" -ne 0 ]; then
    log $LOG_QUIET "[ERROR] Extraction failed with exit code $exit_code" >&2
    exit 1
  fi

  log $LOG_VERBOSE "[INFO] Checking contents of the extracted directory: $temp_dir"

  # Check if the contents are immediately inside a folder and move them accordingly
  local target
  target="$target_dir/$(basename "$SOURCE" ."$archive_extension")"

  if [ "$(find "$temp_dir" -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
    log $LOG_VERBOSE "[INFO] Using archive name as target directory: $target"
    log $LOG_VERBOSE "[INFO] Moving contents to target directory"

    mkdir -p "$target"
    mv "$temp_dir"/* "$target"
  else
    log $LOG_VERBOSE "[INFO] Moving contents to target directory: $target_dir"
    mv "$temp_dir"/* "$target_dir"
  fi

  # Remove the temporary directory
  log $LOG_VERBOSE "[INFO] Removing temporary directory"
  rmdir "$temp_dir"

  log $LOG_NORMAL "[INFO] Extraction complete: $target"
}

run() {
  local archive_extension="${SOURCE##*.}"
  local dependency list_flag extract_flag target_dir_flag

  read -r dependency list_flag extract_flag target_dir_flag <<<"${archive_types[$archive_extension]}"

  if ! command -v "$dependency" &>/dev/null; then
    log $LOG_QUIET "[ERROR] $dependency is needed but not found." >&2
    exit 1
  fi

  if [[ $DRY == "y" ]]; then
    if [ $LIST == "Y" ]; then
      log $LOG_NORMAL "[DRY] Would list contents of $SOURCE"
    else
      log $LOG_NORMAL "[DRY] Would extract contents of $SOURCE"
    fi
  else
    if [ $LIST == "Y" ]; then
      log $LOG_NORMAL "[INFO] Listing contents of $SOURCE"
      "$dependency" "$list_flag" "$SOURCE"
    else
      log $LOG_NORMAL "[INFO] Initiating extraction process."
      extract_archive "$dependency" "$extract_flag" "$target_dir_flag"
    fi
  fi

}

main() {
  arg_parse "$@"

  log $LOG_VERBOSE "[INFO] Checking source directory"
  check_source

  log $LOG_VERBOSE "[INFO] Checking target directory"
  check_target

  run
}

main "$@"
