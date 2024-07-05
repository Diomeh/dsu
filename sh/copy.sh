#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

VERSION="v2.1.30"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Copies shell output to the clipboard.

Options:
  -h, --help              Show this help message and exit.
  -v, --version           Show the version of this script and exit.
  -c, --check-version     Checks the version of this script against the remote repo version and prints a message on how to update.

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
