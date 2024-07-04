#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <directory>

Displays the disk usage of files and directories within the specified directory,
sorted by size in descending order. If no directory is specified, the current
directory is used by default.

Options:
  -h, --help          Show this help message and exit.

Arguments:
  DIRECTORY           The directory to analyze. If not specified, the current directory (.) is used.

Example:
  $(basename "$0")                  # Analyze the current directory
  $(basename "$0") /path/to/dir     # Analyze the specified directory

Notes:
  - The script uses 'du' to calculate disk usage and 'sort' to sort the results.
  - The '--one-file-system' option for 'du' ensures that only the file system
    containing the specified directory is analyzed, ignoring mounted file systems.
EOF
}

case $# in
0) dir='.' ;;
1) dir=$1 ;;
*)
  usage
  exit 0
  ;;
esac

du -s --one-file-system "$dir/*" "$dir/.[A-Za-z0-9]*" | sort -rn | head
