# Shell scripts

## Overview
This project provides a set of shell scripts to handle various file operations including backup, extraction, cleaning, copying, and pasting. It also includes installation and uninstallation scripts to manage the setup of the environment.

## Getting started

### Installation

Make sure you have the following dependencies installed on your system:
- `xclip`
- `7z`
- `unzip`
- `unrar`

Make installer executable and run it, you'll need elevated permissions:

```sh
chmod +x install.sh
sudo ./install.sh
```

You can specify a custom installation directory by passing it as an argument to the installer, like so:

```sh
sudo ./install.sh -p ~/bin
```

The installer does the following:
- Creates a `./.install` file to keep track of the installation. The first line of this file contains the installation directory and the rest of the lines contain the names of the scripts that were installed.
- Reads the `./src` directory to know which scripts to install, for each file it:
    - Makes the scripts executable.
    - Creates a symbolic link of each script in the specified installation directory.
    - Adds the script name to the `./.install` file.

### Uninstallation

Make uninstaller executable and run it, you'll need elevated permissions:

```sh
chmod +x uninstall.sh
sudo ./uninstall.sh
```

You can also specify a location for where to read the `./.install` file:

```sh
sudo ./uninstall.sh -p ~/.install
```

The installer does the following:
- Searches for the `./.install` file in the specified location.
    - If the file is found, it:
        - For each script in the `./.install` file, it removes the symbolic link from the installation directory.
    - Else, it:
        - Defaults to `/usr/local/bin` as the installation directory.
        - Reads the `./src` directory to know which scripts to remove, for each file it:
            - Removes the symbolic link from the installation directory.
- Removes the `./.install` file.

## Usage

### Running globally

Once installed, you can run any of the scripts from anywhere in your system.
Refer to the help message of each script for usage instructions.

```sh
backup -h
```

### Running locally

You can also run the scripts locally by calling them from the `src` directory, just make sure to give them execution permissions:

```sh
chmod +x ./src/backup.sh
./src/backup.sh -h
```

## Contributing

If you would like to contribute to this project, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
