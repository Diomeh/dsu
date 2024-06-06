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

When performing a restore operation, the optional argument <backup directory> is ignored.

The backup file or directory will be named as follows:
  <backup directory>/<filename>.<timestamp>.backup

Examples:
  $(basename "$0") -b /etc/hosts
  $(basename "$0") -b /etc/hosts /home/user/backups
  $(basename "$0") -r /home/user/backups/hosts.2018-01-01_00-00-00.backup
EOF
}

backup() {
    local target="$1"
    local backup_dir="$2"

    filename=$(basename "$target")
    timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    backup_path="$backup_dir/$filename.$timestamp.backup"

    if [ -e "$backup_path" ]; then
        echo "backup: '$backup_path': Backup target already exists"
        # ask to overwrite the backup
        read -p "Overwrite backup? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # create the backup
    if [ -d "$target" ]; then
        cp -r "$target" "$backup_path"
    else
        cp "$target" "$backup_path"
    fi

    echo "Created backup: $backup_path"
}

restore() {
    local target="$1"
    local backup_dir="$2"

    # check that the backup exists
    if [ ! -e "$target" ]; then
        echo "Error: '$target': File not found" >&2
        exit 1
    fi

    # if file is named like "file.20190101_000000.backup", then target is a backup
    if [[ "$target" =~ ^(.*)\.[0-9]{8}_[0-9]{6}\.backup$ ]]; then
        target="${BASH_REMATCH[1]}"
    else
        echo "Error: '$target': No such backup" >&2
        exit 1
    fi

    # if target exists, then ask for confirmation
    if [ -e "$target" ]; then
        read -p "$target: File or directory already exists. Overwrite? [y/N] " -r response
        if [ "$response" != "y" ]; then
            exit 1
        fi
    fi

    # print message and restore
    if [ -d "$1" ]; then
        echo "Restoring directory: $target"
        cp -r "$1" "$target"
    else
        echo "Restoring file: $target"
        cp "$1" "$target"
    fi

    echo "Restored backup: $1 -> $target"
}

# Argument parsing
if [[ $# -lt 2 || $# -gt 3 ]]; then
    usage
    exit 1
fi

while getopts ":b:r:h" opt; do
    case $opt in
        b | --backup)
            mode="backup"
            ;;
        r | --restore)
            mode="restore"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

target="$1"
backup_dir="${2:-.}"  # Default to current directory if backup directory not provided

# Check if target exists
if [ ! -e "$target" ]; then
    echo "Error: '$target': No such file or directory" >&2
    exit 1
fi

# Prepare backup directory
prepare_backup_dir() {
    local backup_dir="$1"
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir" || { echo "Error: '$backup_dir': Could not create backup directory" >&2; exit 1; }
    fi
}
prepare_backup_dir "$backup_dir"

# Check permissions
if [ ! -r "$target" ]; then
    echo "Error: '$target': Permission denied" >&2
    exit 1
fi
if [ ! -w "$backup_dir" ]; then
    echo "Error: '$backup_dir': Permission denied" >&2
    exit 1
fi

# Perform backup or restore based on mode
if [ "$mode" == "backup" ]; then
    backup "$target" "$backup_dir"
elif [ "$mode" == "restore" ]; then
    restore "$target" "$backup_dir"
fi
