#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

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
