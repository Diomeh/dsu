#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Pastes clipboard contents to stdin depending on the session type (Wayland or Xorg).

Options:
  -h, --help    Show this help message and exit.

Behavior:
- If running under Wayland, the script uses wl-paste to paste the clipboard contents.
- If running under Xorg, the script uses xclip to paste the clipboard contents.

Dependencies:
- wl-paste: Required for Wayland sessions.
- xclip: Required for Xorg sessions.

Examples:
  Paste the clipboard contents to stdin:
    $(basename "$0")

  Paste the clipboard contents to a file:
    $(basename "$0") > output.txt
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      usage
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
  # Check if wl-paste is installed
  if ! command -v wl-paste >/dev/null; then
    echo "[ERROR] wl-paste is not installed" >&2
    exit 1
  fi

  # Paste clipboard contents to stdin
  wl-paste
elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
  # Check if xclip is installed
  if ! command -v xclip >/dev/null; then
    echo "[ERROR] xclip is not installed" >&2
    exit 1
  fi

  # Paste clipboard contents to stdin
  xclip -o -sel clip
else
  echo "[ERROR] Unknown session type: $XDG_SESSION_TYPE" >&2
  exit 1
fi
