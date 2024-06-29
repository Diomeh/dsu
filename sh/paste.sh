#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

# Check if xclip is installed
if ! command -v xclip > /dev/null; then
    echo "xclip is not installed"
    exit 1
fi

# Paste clipboard contents to stdin
xclip -o -sel clip
