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
        "e") echo -e "${RED}[ERROR] ${message}${NC}" >&2 ;;
        "s") echo -e "${GREEN}[SUCCESS] ${message}${NC}" ;;
        "w") echo -e "${YELLOW}[WARNING] ${message}${NC}" >&2 ;;
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
            print "e" "Unknown option: $1"
            usage
            exit 1
            ;;
        esac
    done
}

test_backup() {
    local workdir="$TEST_DIR/backup"
    local binary="$SRC_DIR/backup.sh"
    local outfile="$TMP_DIR/backup.out"
    local r_file="r.txt.2024-06-06_17-47-45.backup"
    local b_file="b.txt"
    local result

    print "i" "backup: running tests"

    touch "$outfile"

    print "i" "backup: testing backup operation"

    # Perform -b operation, get script exit code and redirect output to a file
    "$binary" "-b" "./backup/$b_file" "./backup" >> "$outfile"
    local b_exit_code=$?

    # Check the exit code of the backup operation
    if [ "$b_exit_code" -ne 0 ]; then
        print "e" "backup: test failed during backup operation with exit code $b_exit_code"
        print "i" "backup: test output:"
        cat "$outfile"
        return 1
    fi

    # Verify if file with format b.txt.YYYY-MM-DD_HH-MM-SS.backup exists
    local file="$(find "$workdir" -name "b.txt.*.backup")"
    if [ -z "$file" ]; then
        print "e" "backup: backup operation failed to create target file"
        print "i" "backup: test output:"
        cat "$outfile"
        return 1
    else
        # Compare the backup file with the original file
        result=$(diff -qw "$file" "$workdir/$b_file" | wc -l)
        if [ "$result" -ne 0 ]; then
            print "e" "backup: backup file does not match original file"
            print "i" "backup: test output:"
            cat "$outfile"
            return 1
        else
            print "s" "backup: backup operation passed"
            rm "$file"
        fi
    fi

    print "i" "backup: testing restore operation"

    # Perform -r operation
    "$binary" "-r" "./backup/$r_file" "./backup" >> "$outfile"
    local r_exit_code=$?
    
    # Check the exit code of the restore operation
    if [ "$r_exit_code" -ne 0 ]; then
        print "e" "backup: test failed during restore operation with exit code $r_exit_code"
        print "i" "backup: test output:"
        cat "$outfile"
        return 1
    fi

    # Verify the restored file exists
    if [ ! -e "$workdir/r.txt" ]; then
        print "e" "backup: restore operation failed to create target file"
        print "i" "backup: test output:"
        cat "$outfile"
        return 1
    else
        # Compare the restored file with the original file
        result=$(diff -qw "$workdir/r.txt" "$workdir/$r_file" | wc -l)
        if [ "$result" -ne 0 ]; then
            print "e" "backup: restored file does not match original file"
            print "i" "backup: test output:"
            cat "$outfile"
            return 1
        else
            print "s" "backup: restore operation passed"
            rm "$workdir/r.txt"
        fi
    fi

    print "s" "backup: all tests passed"
}

test_cln() {
    print "w" "cln: test not implemented"
}

test_copy() {
    print "w" "copy: test not implemented"
}

test_hog() {
    local result

    print "i" "hog: running test"

    # Execute hog.sh and redirect output to a file
    "$SRC_DIR/hog.sh" "./hog" | egrep --invert-match expected > "$TMP_DIR/hog.out"

    # Compare output files and count differences
    result=$(diff -qw "$TMP_DIR/hog.out" "$TEST_DIR/hog/.expected" | wc -l)

    if [ "$result" -eq 0 ]; then
        print "s" "hog: test passed"
    else
        echo
        print "e" "hog: test failed"
        print "i" "Expected output:"
        cat "$TEST_DIR/hog/.expected"
        echo
        print "i" "Got:"
        cat "$TMP_DIR/hog.out"
    fi

    return $result
}

test_paste() {
    print "w" "paste: test not implemented"
}

test_xtract() {
    print "w" "xtract: test not implemented"
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
