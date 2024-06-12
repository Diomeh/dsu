#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

case $# in
0) dir='.' ;;
1) dir=$1 ;;
*)
  echo "usage: hog <dir>"
  exit 1
  ;;
esac

du -s --one-file-system $dir/* $dir/.[A-Za-z0-9]* | sort -rn | head
