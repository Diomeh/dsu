# dotfiles

A collection of custom shell scripts for Linux

## Installation

The installation process consists of creating a symbolic link in `/usr/local/bin` to each script within the `src` directory, 
removing the `.sh` extension from the symbolic link. This allows the scripts to be run from anywhere on the system.

Before install, both file extension and shebang are checked to ensure the script uses the `sh` shell.

### Steps

1. Clone the repository
2. Grant execute permissions to `install.sh`

        chmod +x install.sh

3. Run `install.sh` as root

        sudo ./install.sh

## Uninstallation

Uninstallation is the reverse of installation, only removing the symbolic links from `/usr/local/bin`.

### Steps

1. Grant execute permissions to `uninstall.sh`

        chmod +x uninstall.sh

2. Run `uninstall.sh` as root

        sudo ./uninstall.sh
