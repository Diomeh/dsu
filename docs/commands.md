# Commands

## Overview

### File Management

- `backup` - Creates a timestamped backup of a file or directory
- `restore` - Restores a file or directory from a timestamped backup
- `cln` - Removes non-ASCII characters from file names
- `xtract` - Archive extraction utility

### System Utilities

- `hog` - Print disk usage of a directory

### Clipboard Operations

- `copy` - Copy STDOUT to clipboard
- `paste` - Paste clipboard to STDIN

### Built-in Commands

- `help` - Print help message or help for a specific subcommand
- `update` - Self update

## Command Details

### backup

Creates timestamped backups of files or directories.

**Usage:** `backup [OPTIONS] <SOURCE> [TARGET]`

- `options`: Same as [global options](./global-options.md)
- `source`: The path to the file, directory, or symlink to back up. _Required_
- `target` The directory where file backup will be stored. Defaults to the current directory. _Optional_

**Behavior:**

Creates a backup file with a timestamp in the name to avoid overwriting previous backups.
If the backup directory is not specified, the backup file will be created in the current directory.
If the backup directory does not exist, it will be created (assuming the correct permissions are set).
By default, the program will prompt for confirmation before overwriting existing backups unless the prompt mode is set to non-interactive.

**Naming Convention:**

Backup files will be named as follows, where timestamp is in the format `YYYY-MM-DD_hh-mm-ss`

    <target>/<filename>.<timestamp>.bak

Suppose `SOURCE` is `/etc/hosts` and `TARGET` is `/home/user/backups`:

    /etc/hosts → /home/user/backups/hosts.2024-07-04_12-00-00.bak

### restore

Restores files or directories from timestamped backups.

**Usage:** `restore [OPTIONS] <SOURCE> [TARGET]`

- `options`: Same as [global options](./global-options.md)
- `source`: The path to the file, directory, or symlink to restore. _Required_
- `target` Directory to which the backup will be restored . Defaults to the current directory. _Optional_

**Behavior:**

Restores the file or directory from a specified backup file.
If the target file or directory already exists, the user will be prompted for confirmation.
The optional argument `target` will be treated as the target directory where the backup file will be restored to.
By default, the program will prompt for confirmation before overwriting existing backups unless the prompt mode is set to non-interactive.

**Naming Convention:**

Program expects files to adhere to following name schema,
where timestamp is in the format `YYYY-MM-DD_hh-mm-ss`_(same as `backup`)_

    <target>/<filename>.<timestamp>.bak

Suppose `SOURCE` is `/home/user/backups/hosts.2024-07-04_12-00-00.bak` and `TARGET` is `/etc/hosts`:

    /home/user/backups/hosts.2024-07-04_12-00-00.bak → /etc/hosts

### cln

Cleans file names by removing or replacing non console-friendly characters.

**Usage:** `cln [OPTIONS] <FILES>...`

- `options`:
  - [global options](./global-options.md)
  - `-r`, `--recursive`: Recursively iterate over directories.
  - `-R`, `--recurse-depth`: Maximum number of subdirectories to recurse into.
  - `-k`, `--replace-with <char>` - Character to replace with. _(default: `_`)_
- `files`: List of files or directories to clean. _Required_

**Behavior:**

The program uses a regex pattern of the form `[^A-Za-z0-9_.-]` to determine
which characters in a filename are to be replaced with provided replacement character _(underscore by default)_.
If the result of cleaning a filename is that of either an empty string or a single replacement character,
a warning will be raised and the file will be skipped.

### hog

Displays the disk usage of files and directories within the specified directory,
sorted by size in descending order.

**Usage:** `hog [OPTIONS] [DIRECTORY]`

- `options`: [global options](./global-options.md)
- `directory`: The directory to analyze. _(optional, defaults to current directory)_

### xtract

Extracts the contents of a compressed archive to a directory

**Usage:** `xtract [OPTIONS] <ARCHIVE> [DESTINATION]`

- `options`:
  - [global options](./global-options.md)
  - `-l`, `--list`: List the contents of the archive.
- `archive`: Path to the compressed archive file.
- `target`: Directory where the contents will be extracted. _(optional, defaults to current directory)_

**Behavior:**

Program will try to extract archive to specified destination directory.
If archive content is not contained in a single root directory, program will instead create
a directory within target named after the archive filename and try to extract contents there.

**Supported archive types:**

- tarball:
  - `.tar`
  - `.tar.gz`
  - `.tgz`
  - `.tar.bz2`
  - `.tar.xz`
  - `.tar.7z`
- `.7z`
- `.zip`
- `.rar`

**Known problems:**

- Password-protected archives will fail extraction

### copy

Copies STDOUT to system clipboard.

**Usage:** `copy [OPTIONS]`

- `options`: [global options](./global-options.md)

### paste

Pastes clipboard content to STDIN.

**Usage:** `paste [OPTIONS]`

- `options`: [global options](./global-options.md)

### help

Show command usage information.

**Usage:** `help [COMMAND]`

- `command`: Any of the program commands except for itself.

### update

Check for version updates and trigger self update process.

**Usage:** `update`

## Exit codes

| Code | Meaning                     |
|------|-----------------------------|
| 0    | Success                     |
| 1    | General error               |
| 2    | Invalid usage/arguments     |
| 3    | Permission denied           |
| 4    | File/resource not found     |
| 5    | Network error               |
| 6    | Operation cancelled by user |
| 130  | Interrupted (Ctrl+C)        |

## Error Handling

### Error Message Format

```
error: <command>: <description>
  hint: <suggestion>
```

#### Examples

```
error: backup: permission denied accessing '/protected/file'
  hint: try running with elevated privileges or check file permissions

error: restore: backup file 'backup_20231201.tar.gz' not found
  hint: check the backup file path or list available backups

error: xtract: unsupported archive format '.rar'
  hint: supported formats are: zip, tar, tar.gz, tar.bz2, tar.xz
```
