#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail
IFS=$'\n\t'

VERSION="v2.1.30"

# Dry run flag
DRY="n"

usage() {
  cat <<EOF
Usage: $(basename "$0") [directories...]

Replace all special characters in filenames within the specified directories.
If no directories are provided, the script will operate in the current directory.

Options:
  -h, --help              Show this help message and exit.
  -v, --version           Display the version of this script and exit
  -d, --dry               Dry run. Print the operations that would be performed without actually executing them.
  -c, --check-version     Checks the version of this script against the remote repo version and prints a message on how to update.

Examples:
  Replace special characters in filenames in the current directory.
    $(basename "$0")

  Replace special characters in filenames within ~/Documents.
    $(basename "$0") ~/Documents

  Replace special characters in filenames within ./foo and /bar.
    $(basename "$0") ./foo /bar

Special Character Replacement:
- The script replaces characters that are not alphanumeric or hyphens with underscores.
- Spaces, punctuation, and other special characters will be replaced.

Note:
- Ensure you have the necessary permissions to read/write files in the specified directories.
- Filenames that only differ by special characters might result in name conflicts after replacement.
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

parse_args() {
  # Expand combined short options (e.g., -dr to -d -r)
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

  while [[ $# -gt 0 ]]; do
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
        DRY="y"
        shift
        ;;
      *)
        echo "[ERROR] Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

replace_special_chars() {
  local filepath="$1"
  local filename
  local newname
  local target

  # Check filepath permissions
  if [ ! -w "$filepath" ]; then
    echo "[ERROR] $filepath: Permission denied" >&2
    return
  fi

  # Extract filename without directory path
  filename=$(basename "$filepath")

  # Replace spaces with underscore and strip non-alphanumeric characters
  newname=$(echo "$filename" | tr ' ' '_' | tr -s '_' | tr -cd '[:alnum:]_.-')

  # If newname is empty, skip
  if [ -z "$newname" ]; then
    echo "[WARN] $filename: new name is empty. Skipping..." >&2
    return
  fi

  target="$(dirname "$filepath")/$newname"

  # If names are the same, skip
  if [ "$filename" == "$newname" ]; then
    return
  fi

  if [ "$DRY" == "y" ]; then
    echo "[DRY] Would rename: $filename -> $newname"
  else
    echo "[INFO] Renaming: $filename -> $newname"
  fi

  # Check if target file already exists
  if [ -e "$target" ]; then
    if [ "$DRY" == "y" ]; then
      echo "[DRY] Would prompt for overwriting: $target"
      return 0
    fi

    read -p "File already exists. Overwrite? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "[INFO] Skipping $filename"
      return
    else
      rm -rf "$target" # Remove the existing file before renaming
    fi
  fi

  mv "$filepath" "$target"
}

parse_args "$@"

# Loop through arguments
for file in "$@"; do
  # If argument is a directory, loop through all files in the directory
  if [ -d "$file" ]; then
    for f in "$file"/*; do
      replace_special_chars "$f"
    done
    continue
  else
    # If argument is a file, replace special characters in the file name
    replace_special_chars "$file"
  fi
done
