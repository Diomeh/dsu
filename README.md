# Diomeh's Script Utilities

## Overview
A set of utilities to handle various file operations like
- file backup and restore
- archive extraction 
- file cleaning
- copying and pasting from and to the shell

## Getting started

Two distribution method are available, either: 

- standalone bash scripts
- rust CLI tool

### Standalone bash scripts

Please refer to the [wiki](https://github.com/Diomeh/dsu/wiki/Standalone-bash-scripts)
for information on building and running the standalone bash scripts;
Alternatively you can find a pre-built tarball in the [releases page](https://github.com/Diomeh/dsu/releases/latest).

### Rust CLI tool

A unix binary named as `dsu-X-Y-Z` can be found in the [releases page](https://github.com/Diomeh/dsu/releases/latest)
where `X-Y-Z` is the version number. Alternatively you can build it on your own.

## Usage

Ensure that the utility is executable by running the following command:
```bash
chmod +x dsu-X-Y-Z
```

Run the utility with the `--help` flag to see the available options and how to use them:
```bash
./dsu-X-Y-Z --help
```  

Each utility has its own set of options and arguments that you can see running the `--help` flag with the utility name:
```bash
./dsu-X-Y-Z <utility> --help
```

For a breakdown of all the utilities, their options and what do they do please refer to the [wiki](https://github.com/Diomeh/dsu/wiki)

### Installation

There are several different ways to install the utility on your system:
- copy|install the binary to a directory in your PATH
- create a symbolic link to the binary in a directory in your PATH
- install it globally to `/opt/dsu` and make that directory part of your PATH 

#### Installing to a directory in your PATH

To install the utility you can copy the binary to a directory in your PATH. Common directories are:
- Single user:
  - `~/.local/bin`
  - `~/bin`
- System-wide:
  - `/usr/local/bin`
  - `/usr/bin`
  - `/opt`

For single user:
```bash
install -Dm755 dsu-X-Y-Z ~/.local/bin/dsu
```
Or
```bash
mkdir -p ~/.local/bin
cp dsu-X-Y-Z ~/.local/bin/dsu
chmod +x ~/.local/bin/dsu
```

For system-wide:

**Note that you may need to run this command as root or with `sudo`.**
```bash
install -Dm755 dsu-X-Y-Z /usr/local/bin/dsu
```
Or
```bash
mkdir -p /usr/local/bin
cp dsu-X-Y-Z /usr/local/bin/dsu
chmod +x /usr/local/bin/dsu
```

#### Creating a symbolic link

You can also create a symbolic link to the binary in a directory in your PATH. 
This is useful if you want to keep the binary in a different directory than the one in your PATH.

For single user:
```bash
ln -s /path/to/dsu-X-Y-Z ~/.local/bin/dsu
```

For system-wide:

**Note that you may need to run this command as root or with `sudo`.**
```bash
ln -s /path/to/dsu-X-Y-Z /usr/local/bin/dsu
```

#### Installing to `/opt`

As a third option, you can install the utility globally to `/opt/dsu` and make that directory part of your PATH.

**Note that you'll need `sudo` or root permissions to do this.**

First, create the directory:
```bash
mkdir -p /opt/dsu
```

Then copy the binary to the directory:
```bash
cp dsu-X-Y-Z /opt/dsu/dsu
chmod +x /opt/dsu/dsu
```

Add the directory to your PATH by adding the following line to your shell configuration file (e.g. `~/.bashrc`, `~/.zshrc`, etc.):
```bash
# Add diomeh's script utilities to PATH
export PATH="$PATH:/opt/dsu"
```

Finally, source the shell configuration file to apply the changes:
```bash
source ~/.bashrc
```

This will ensure that the binary is always available at `/opt/dsu/dsu` no matter the version. 
If you want to update the binary, simply replace the symbolic link with a new one pointing to the new one.

### Uninstallation

To uninstall the utility, simply remove the binary from the directory where you installed it.
- If you installed it to a directory in your PATH, remove the binary from that directory.
- If you created a symbolic link, remove the symbolic link.
- If you installed it to `/opt`, remove the binary from `/opt/dsu`.
  - Also remove the directory from your PATH in your shell configuration file.

## Local development

To build the rust CLI tool, you will need to have the rust toolchain installed on your system.
Please refer to the [rust website](https://www.rust-lang.org/tools/install) for instructions on how to install the rust toolchain.

`bacon` is used as the build tool for this project. To install `bacon`, run the following command:
```bash
cargo install bacon
```

Afterwards you can build the project by running the following command:
```bash
bacon
```

This will build and watch for any changes in the source code and rebuild the project automatically.
For more information on how to use `bacon`, please refer to the [bacon documentation](https://dystroy.org/bacon/)
and the [bacon config file](./bacon.toml).

### Project structure

Each utility is defined as a module in the `src` directory. 
The main entry point for the CLI tool is in the `src/main.rs` file.

The module `src/cli.rs` contains the command line interface for `dsu` and defines 
all options and arguments for both the tool itself and all the utilities.

### Testing

As of now, testing has only been implemented for standalone bash scripts.
Refer to the [bash scripts wiki](https://github.com/Diomeh/dsu/wiki/Standalone-bash-scripts) 
for more information on how to run the tests.

### Deployment

To deploy the rust CLI tool, you can run the following command:
```bash
cargo build --release
```

This will build the project in release mode and create a binary optimized for release in the `target/release` directory.

## Contributing

If you would like to contribute to this project, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
