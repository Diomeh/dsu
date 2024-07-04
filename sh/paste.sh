#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

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
