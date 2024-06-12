#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

set -euo pipefail

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]
Uninstall scripts listed in the specified .install file or search for src/* in the install directory.

Options:
  -p, --path    Specify the path to the .install file (default: ./<script directory>/.install)
  -h, --help    Show this help message and exit

Example:
    $(basename "$0") -p ~/.install
EOF
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: Please run as root" >&2
        exit 1
    fi
}

parse_arguments() {
    local install_file="$1/.install"
    local src_dir="$1/src/sh"
    local install_dir="/usr/local/bin"
    
    while [[ "$#" -gt 1 ]]; do
        case "$2" in
            -p|--path)
                install_file="$3"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Error: Unknown option: $2" >&2
                usage
                exit 1
                ;;
        esac
    done

    echo "$install_file:$src_dir:$install_dir"
}

uninstall_scripts_from_install_file() {
    local install_file="$1"
    local install_dir
    install_dir=$(head -n 1 "$install_file")

    if [ ! -d "$install_dir" ]; then
        echo "Error: Install directory $install_dir does not exist" >&2
        exit 1
    fi

    echo "Uninstalling scripts from $install_dir listed in $install_file"

    tail -n +2 "$install_file" | while read -r script_name; do
        if [ -f "$install_dir/$script_name" ]; then
            echo "Uninstalling $install_dir/$script_name"
            rm "$install_dir/$script_name"
        else
            echo "Error: $install_dir/$script_name does not exist" >&2
        fi
    done

    rm "$install_file"
}

search_and_uninstall_scripts() {
    local src_dir="$1"
    local install_dir="$2"
    local install_file="$3"

    local response
    read -p "$install_file not found. Search for scripts from $src_dir in $install_dir? [y/N] " -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Exiting"
        exit 0
    fi

    for script in "$src_dir"/*; do
        [ -f "$script" ] || continue

        local script_name
        script_name=$(basename "${script%.*}")

        if [ -f "$install_dir/$script_name" ]; then
            echo "Uninstalling $install_dir/$script_name"
            rm "$install_dir/$script_name"
        else
            echo "Error: $install_dir/$script_name does not exist" >&2
        fi
    done
}

main() {
    check_root

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    IFS=":" read -r install_file src_dir install_dir <<< "$(parse_arguments "$script_dir" "$@")"

    if [ -f "$install_file" ]; then
        uninstall_scripts_from_install_file "$install_file"
    else
        search_and_uninstall_scripts "$src_dir" "$install_dir" "$install_file"
    fi
}

main "$@"
