#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] <archive> [target]
Extracts the contents of a compressed archive to a directory.

Options:
  -l, --list          List the contents of the archive.
  -h, --help          Show this help message and exit.

Arguments:
  <archive>           The path to the compressed archive file.
  [target]            Optional. The directory where the contents will be extracted. Defaults to the current directory or a directory named after the archive file if contents are not immediately inside a folder.

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

process_archive() {
  local action="$1"
  local archive="$2"
  local target_dir="$3"
  local archive_extension="${archive##*.}"
  local dependency list_flag extract_flag target_dir_flag

  if [[ -z "${archive_types[${archive##*.}]:-}" ]]; then
    echo "[ERROR] Unsupported archive type: $archive" >&2
    exit 1
  fi

  read -r dependency list_flag extract_flag target_dir_flag <<<"${archive_types[$archive_extension]}"

  if ! command -v "$dependency" &>/dev/null; then
    echo "[ERROR] $dependency is needed but not found." >&2
    exit 1
  fi

  if [[ ! -f "$archive" ]]; then
    echo "[ERROR] Not a valid archive: $archive" >&2
    exit 1
  fi

  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir" || {
      echo "[ERROR] Permission denied: $target_dir" >&2
      exit 1
    }
  fi

  case "$action" in
  list) "$dependency" "$list_flag" "$archive" ;;
  extract)
    # Create a temporary directory to extract the contents
    local temp_dir
    temp_dir=$(mktemp -d) || {
      echo "[ERROR] Could not create temporary directory" >&2
      exit 1
    }

    echo "[INFO] Extracting $archive to $target_dir..."

    if [[ -z "${target_dir_flag:-}" ]]; then
      if [[ "$dependency" == "unzip" ]]; then
        "$dependency" "$archive" "$extract_flag" "$temp_dir" >/dev/null
      else
        "$dependency" "$extract_flag" "$archive" "$temp_dir" >/dev/null
      fi
    else
      if [[ "$dependency" == "7z" ]]; then
        # 7z requires the output flag to be prepended to the target directory
        # eg. 7z x file.7z -o/tmp/archive (notice no space between -o and the directory)
        "$dependency" "$extract_flag" "$archive" "$target_dir_flag""$temp_dir" >/dev/null
      else
        "$dependency" "$extract_flag" "$archive" "$target_dir_flag" "$temp_dir" >/dev/null
      fi
    fi

    # Check exit status of the extraction command
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
      echo "[ERROR] Extraction failed with exit code $exit_code" >&2
      exit 1
    fi

    # Check if the contents are immediately inside a folder and move them accordingly
    if [ "$(find "$temp_dir" -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
      mkdir -p "$target_dir/$(basename "$archive" ."$archive_extension")"
      mv "$temp_dir"/* "$target_dir/$(basename "$archive" ."$archive_extension")"
    else
      mv "$temp_dir"/* "$target_dir"
    fi

    # Remove the temporary directory
    rmdir "$temp_dir"

    echo "[INFO] Extraction complete: $target_dir/$(basename "$archive" ."$archive_extension")"
    ;;
  esac
}

main() {
  local action="extract"
  local archive=""
  local target_dir=""

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -l | --list)
      action="list"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "[ERROR] Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *) break ;;
    esac
  done

  archive="$1"
  target_dir="${2:-$(pwd)}"

  process_archive "$action" "$archive" "$target_dir"
}

main "$@"
