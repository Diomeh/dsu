#!/usr/bin/env bash
#
# -*- mode: shell-script -*-

# Path vars
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/src"
TEST_DIR="$ROOT_DIR/tests"
TMP_DIR="$ROOT_DIR/tmp"

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print() {
    local color="$1"
    local message="$2"
    
    case "$color" in
        "e") echo -e "${RED}[ERROR] ${message}${NC}" ;;
        "s") echo -e "${GREEN}[SUCCESS] ${message}${NC}" ;;
        "w") echo -e "${YELLOW}[WARNING] ${message}${NC}" ;;
        "i") echo -e "${BLUE}[INFO] ${message}${NC}" ;;
        *) echo "$message" ;;
    esac
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run all the tests for the scripts in ./src.

Options:
  -h, --help    Show this help message and exit
EOF
}

arg_parse() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        *)
            print "e" "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        esac
    done
}

test_backup() {
    print "w" "backup: test not implemented\n"
}

test_cln() {
    print "w" "cln: test not implemented\n"
}

test_copy() {
    print "w" "copy: test not implemented\n"
}

test_hog() {
    local result

    print "i" "Running hog test"

    # Execute hog.sh and redirect output to a file
    "$SRC_DIR/hog.sh" "./hog" | egrep --invert-match expected > "$TMP_DIR/hog.out"

    # Compare output files and count differences
    result=$(diff -qw "$TMP_DIR/hog.out" "$TEST_DIR/hog/.expected" | wc -l)

    if [ "$result" -eq 0 ]; then
        print "s" "Hog: test passed"
    else
        echo
        print "e" "Hog: test failed"
        print "i" "Expected output:"
        cat "$TEST_DIR/hog/.expected"
        echo
        print "i" "Got:"
        cat "$TMP_DIR/hog.out"
    fi

    echo
    return $result
}

test_paste() {
    print "w" "paste: test not implemented\n"
}

test_xtract() {
    print "w" "xtract: test not implemented\n"
}

main() {
    arg_parse "$@"

    mkdir -p "$TMP_DIR"

    test_backup
    test_cln
    test_copy
    test_hog
    test_paste
    test_xtract

    rm -rf "$TMP_DIR"
}

main "$@"
