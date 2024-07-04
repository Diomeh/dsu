#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

# Usage function
usage() {
  cat <<EOF
Usage: $(basename "$0") <mode> <path/to/file/or/directory> [backup directory]

Backup and restore files, directories or symlinks.

Mode:
  -b, --backup     Create a timestamped backup of the file or directory
  -r, --restore    Restore the file or directory from a backup
  -h, --help       Display this help message

If the backup directory is not specified, the backup file will be generated in the current directory.
If the backup directory does not exist, it will be created (assuming correct permissions are set).

When performing a restore operation, the optional argument <backup directory> will be treated as the target directory
where the backup file will be restored. If the target file or directory already exists, the user will be prompted for confirmation.

The backup file or directory will be named as follows:
  <backup directory>/<filename>.<timestamp>.backup

Examples:
  $(basename "$0") -b /etc/hosts
  $(basename "$0") -b /etc/hosts /home/user/backups
  $(basename "$0") -r /home/user/backups/hosts.2018-01-01_00-00-00.backup
  $(basename "$0") -r ./file.txt.2024-01-01_00-00-00.backup ~/Documents
EOF
}

prepare_target() {
  local target="$1"
  if [ ! -d "$target" ]; then
    mkdir -p "$target" || {
      echo "[ERROR] Could not create backup directory: $target" >&2
      exit 1
    }
  fi
  if [ ! -w "$target" ]; then
    echo "[ERROR] Permission denied: $target" >&2
    exit 1
  fi
}

backup() {
  local source="$1"
  local target="$2"

  local filename
  local timestamp

  filename=$(basename "$source")
  timestamp=$(date +%Y-%m-%d_%H-%M-%S)

  local backup_path="$target/$filename.$timestamp.bak"

  if [ -e "$backup_path" ]; then
    echo "[WARN] Backup target already exists: $backup_path"
    # ask to overwrite the backup
    read -p "Overwrite backup? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 0
    fi
  fi

  # create the backup
  if [ -d "$source" ]; then
    cp -r "$source" "$backup_path"
  else
    cp "$source" "$backup_path"
  fi

  echo "Created backup: $backup_path"
}

restore() {
  local source="$1"
  local target_path="$2"
  local target_file

  # Check that the backup exists
  if [ ! -e "$source" ]; then
    echo "[ERROR] File not found: $source" >&2
    exit 1
  fi

  # Check if the file name matches the backup pattern: file.2019-01-01_00-00-00.bak
  if [[ "$(basename "$source")" =~ ^(.*)\.[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\.bak$ ]]; then
    # Extract the base filename without the backup extension
    target_file="${BASH_REMATCH[1]}"
  else
    echo "[ERROR] Not a valid backup file: $source" >&2
    exit 1
  fi

  # Check if source is readable
  if [ ! -r "$source" ]; then
    echo "[ERROR] Permission denied: $source" >&2
    exit 1
  fi

  # Ensure target_path exists
  if [ ! -e "$target_path" ]; then
    mkdir -p "$target_path" || {
      echo "[ERROR] Could not create directory: $target_path" >&2
      exit 1
    }
  elif [ ! -d "$target_path" ]; then
    echo "[ERROR] Not a directory: $target_path" >&2
    exit 1
  fi

  # Check if target_path is writable
  if [ ! -w "$target_path" ]; then
    echo "[ERROR] Permission denied: $target_path" >&2
    exit 1
  fi

  # Ask for confirmation if target_file exists
  if [ -e "$target_path/$target_file" ]; then
    echo "[WARN] File or directory already exists: $target_file"
    read -p "Overwrite? [y/N] " -r response
    if [[ ! $response =~ ^[Yy]$ ]]; then
      exit 0
    fi
  fi

  # Restore backup
  cp -r "$source" "$target_path/$target_file" || {
    echo "[ERROR] Failed to restore backup" >&2
    exit 1
  }

  echo "[INFO] Backup restored: $source -> $target_path/$target_file"
}

# Argument parsing
while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -b | --backup)
    mode="backup"
    ;;
  -r | --restore)
    mode="restore"
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "[ERROR] Unknown option: $1" >&2
    usage
    exit 1
    ;;
  *) break ;;
  esac
  shift
done

source="$1"
target="${2:-.}" # Default to current directory if backup directory not provided

# Check if source exists
if [ ! -e "$source" ]; then
  echo "[ERROR] No such file or directory: $source" >&2
  exit 1
fi

prepare_target "$target"

# Check permissions
if [ ! -r "$source" ]; then
  echo "[ERROR] Permission denied: $source" >&2
  exit 1
fi
if [ ! -w "$target" ]; then
  echo "[ERROR] Permission denied: $target" >&2
  exit 1
fi

# Perform backup or restore based on mode
if [ "$mode" == "backup" ]; then
  backup "$source" "$target"
elif [ "$mode" == "restore" ]; then
  restore "$source" "$target"
fi
