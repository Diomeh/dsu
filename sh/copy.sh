#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

VERSION="v2.1.26"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Copies shell output to the clipboard.

Options:
  -h, --help          Show this help message and exit.
  -v, --version       Show the version of this script and exit.

Behavior:
- If running under Wayland, the script uses wl-copy to copy the output to the clipboard.
- If running under Xorg, the script uses xclip to copy the output to the clipboard.

Dependencies:
- wl-copy: Required for Wayland sessions.
- xclip: Required for Xorg sessions.

Examples:
  Echo a message and copy it to the clipboard:
    echo "Hello, world!" | $(basename "$0")
EOF
}

version() {
  echo "$(basename "$0") version $VERSION"
}

parse_args() {
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
    *)
      echo "[ERROR] Unknown option: $1" >&2
      usage
      exit 1
      ;;
    esac
  done
}

parse_args "$@"

# Determine if user is running Wayland or Xorg
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  # Check if wl-copy is installed
  if ! command -v wl-copy >/dev/null; then
    echo "[ERROR] wl-copy is not installed" >&2
    exit 1
  fi

  # Use wl-copy to copy shell output to clipboard
  wl-copy
elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
  # Check if xclip is installed
  if ! command -v xclip >/dev/null; then
    echo "[ERROR] xclip is not installed" >&2
    exit 1
  fi

  # Use xclip to copy shell output to clipboard
  xclip -selection clipboard
else
  echo "[ERROR] Unknown session type: $XDG_SESSION_TYPE" >&2
  exit 1
fi
