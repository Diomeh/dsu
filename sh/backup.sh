#!/bin/bash

# This script is used to backup files and directories.

usage() {
    echo "Usage: backup <mode> <path/to/file/or/directory> [backup directory]"
    echo "Backup and restore files, directories or symlinks."
    echo ""
    echo "Mode:"
    echo "  -b, --backup     Create a timestamped backup of the file or directory"
    echo "  -r, --restore    Restore the file or directory from a backup"
    echo "  -h, --help       Display this help message"
    echo ""
    echo "If the backup directory is not specified, the backup file will be generated in the current directory."
    echo "If the backup directory does not exist, it will be created (assuming correct permissions are set)."
    echo ""
    echo "When performing a restore operation, the optional argument <backup directory> is ignored."
    echo ""
    echo "The backup file or directory will be named as follows:"
    echo "  <backup directory>/<filename>.<timestamp>.backup"
    echo ""
    echo "Examples:"
    echo "  backup -b /etc/hosts"
    echo "  backup -b /etc/hosts /home/user/backups"
    echo "  backup -r /home/user/backups/hosts.2018-01-01_00-00-00.backup"
}

prepare_backup_dir() {
    local backup_dir="$1"

    # check that the backup directory exists
    if [ ! -d "$backup_dir" ]; then
        # try to create the backup directory
        mkdir -p "$1"
        if [ $? -ne 0 ]; then
            echo "backup: '$backup_dir': Could not create backup directory"
            exit 1
        fi
    fi
}

# if first argument is either -b or --backup, then there must be 2 or 3 arguments
if [ "$1" == "-b" ] || [ "$1" == "--backup" ]; then
    if [ $# -lt 2 ] || [ $# -gt 3 ]; then
        usage
        exit 1
    fi
fi

# if first argument is either -r or --restore, then there must be 2 arguments
if [ "$1" == "-r" ] || [ "$1" == "--restore" ]; then
    if [ $# -ne 2 ]; then
        usage
        exit 1
    fi
fi

# if first argument is either -h or --help, print usage and exit
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
    exit 1
fi

mode="$1"
target="$2"
backup_dir="."

# check target exists
if [ ! -e "$target" ]; then
    echo "backup: '$target': No such file or directory"
    exit 1
fi

# if the backup directory is not specified, use the current directory
if [ $# -eq 3 ]; then
    backup_dir="$3"
    prepare_backup_dir "$backup_dir"
fi

# check permission on target
if [ ! -r "$target" ]; then
    echo "backup: '$target': Permission denied"
    exit 1
fi

# check premissions on backup directory
if [ ! -w "$backup_dir" ]; then
    echo "backup: '$backup_dir': Permission denied"
    exit 1
fi

# if the mode is backup, create a backup
if [ "$mode" == "-b" ] || [ "$mode" == "--backup" ]; then
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
    exit 0
fi

# if the mode is restore, restore the backup
if [ "$mode" == "-r" ] || [ "$mode" == "--restore" ]; then
    # check that the backup exists
    if [ ! -e "$target" ]; then
        echo "backup: '$target': No such backup"
        exit 1
    fi

    # if file is named like "file.20190101_000000.backup", then target is a backup
    if [[ "$target" =~ ^(.*)\.[0-9]{8}_[0-9]{6}\.backup$ ]]; then
        target="${BASH_REMATCH[1]}"
    else
        echo "backup: '$target': No such backup"
        exit 1
    fi

    # if target exists, then ask for confirmation
    if [ -e "$target" ]; then
        read -p "$target: File or directory already exists. Overwrite? [y/N] " response
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
    exit 0
fi
