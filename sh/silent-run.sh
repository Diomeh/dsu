#!/bin/sh

usage() {
    echo "This script will run a command silently in the background."
    echo "It will not print any output to the terminal."
    echo ""
    echo "Usage: $0 [-h] [-c command]"
    echo "  -h  Display this help message."
    echo "  -c  Command to run silently."
    exit 0
}

while getopts ":hc:" opt; do
    case $opt in
        h)
            usage
            ;;
        c)
            command="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done
