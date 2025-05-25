# Diomeh's Script Utilities

## Overview

A set of utilities to handle various file operations like

- file backup and restore
- archive extraction
- file cleaning
- copying and pasting from and to the shell

> [!NOTE]  
> This project is a **monorepo** containing two main codebases:
> - `./bash`: standalone Bash scripts
> - `./rust`: a Rust-based CLI tool

Each version of the utilities shares similar functionality but is built for different environments and usage preferences.

## Getting started

Two distribution methods are available:

- standalone Bash scripts
- Rust CLI tool

### Standalone bash scripts

Please refer to the [wiki](https://github.com/Diomeh/dsu/wiki/Standalone-bash-scripts)
for information on building and running the standalone Bash scripts.

Alternatively, you can find a pre-built tarball in the [releases page](https://github.com/Diomeh/dsu/releases/latest).

### Rust CLI tool

A Unix binary named as `dsu-X-Y-Z` can be found in the [releases page](https://github.com/Diomeh/dsu/releases/latest)
where `X-Y-Z` is the version number. Alternatively, you can build it on your own.

## Usage

Ensure that the utility is executable by running the following command:

```bash
chmod +x dsu-X-Y-Z
```

Run the utility with the `--help` flag to see the available options and how to use them:

```bash
./dsu-X-Y-Z --help
```  

Each utility has its own set of options and arguments that you can see by running the `--help` flag with the utility name:

```bash
./dsu-X-Y-Z <utility> --help
```

For a breakdown of all the utilities, their options, and what they do, please refer to the [wiki](https://github.com/Diomeh/dsu/wiki)

## Installation

There are several different ways to install the utility on your system:

- copy/install the binary to a directory in your PATH
- create a symbolic link to the binary in a directory in your PATH
- install it globally to `/opt/dsu` and make that directory part of your PATH

### Installing to a directory in your PATH

To install the utility, you can copy the binary to a directory in your PATH. Common directories include:

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

### Creating a symbolic link

You can also create a symbolic link to the binary in a directory in your PATH.

For single user:

```bash
ln -s /path/to/dsu-X-Y-Z ~/.local/bin/dsu
```

For system-wide:

**Note that you may need to run this command as root or with `sudo`.**

```bash
ln -s /path/to/dsu-X-Y-Z /usr/local/bin/dsu
```

### Installing to `/opt`

As a third option, you can install the utility globally to `/opt/dsu` and make that directory part of your PATH.

**Note that you'll need `sudo` or root permissions to do this.**

Create the directory:

```bash
mkdir -p /opt/dsu
```

Then copy the binary:

```bash
cp dsu-X-Y-Z /opt/dsu/dsu
chmod +x /opt/dsu/dsu
```

Update your PATH in your shell config (e.g. `~/.bashrc`, `~/.zshrc`):

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

To uninstall the utility:

- Remove the binary from your PATH if copied.
- Remove the symbolic link if one was created.
- Remove the binary from `/opt/dsu` and update your PATH if installed there.

## Local development

### Monorepo Structure

This project is structured as a monorepo:

```
.
├── bash/       # Standalone Bash scripts
└── rust/       # Rust-based CLI tool
```

### Rust CLI Tool

To build the Rust CLI tool, you need to have the Rust toolchain installed.  
Install it from the [Rust website](https://www.rust-lang.org/tools/install).

This repo uses [`bacon`](https://dystroy.org/bacon/) as the build tool:

```bash
cargo install bacon
```

Build and watch for changes:

```bash
bacon
```

Refer to [`rust/bacon.toml`](./rust/bacon.toml) for configuration.

### Project structure

Rust modules are in `rust/src/`.

- `main.rs`: entry point
- `cli.rs`: CLI definitions

This will build and watch for any changes in the source code and rebuild the project automatically.
For more information on how to use `bacon`, please refer to the [bacon documentation](https://dystroy.org/bacon/)
and the [bacon config file](rust/bacon.toml).

### Project structure

Rust modules are in `rust/src/`.

- `main.rs`: entry point
- `cli.rs`: CLI definitions


### Testing

Currently, only Bash scripts have dedicated tests.  
Refer to the [wiki](https://github.com/Diomeh/dsu/wiki/Standalone-bash-scripts) for details.

### Deployment

To build the release version of the Rust CLI:

```bash
cargo build --release
```

Binary will be in `target/release/`.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Contributing

If you would like to contribute to this project, please fork the repository and submit a pull request.

This project follows both the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#summary)
and [Semantic Versioning](https://semver.org/) specifications.

> [!NOTE]
> **Semantic Versioning (SemVer)** ensures that version numbers convey meaning about the underlying changes in a project.
> By leveraging Conventional Commits, this project enforces SemVer compliance automatically.
>
> * MAJOR (X.0.0) — Incremented when making breaking changes that are not backward-compatible.
> * MINOR (0.X.0) — Incremented when adding new features in a backward-compatible manner.
> * PATCH (0.0.X) — Incremented when making backward-compatible bug fixes.
>
> The `feat` and `fix` commit types directly map to `MINOR` and `PATCH` version increments, respectively.
> Any commit marked with `BREAKING CHANGE` will result in a `MAJOR` version bump.


The commit message should be structured as follows:

```plaintext
{type}[optional scope]: {description}

[optional body]

[optional footer(s)]
```

Where `type` is one of the following:

| Type              | Description                                                                                             | Example Commit Message                            |
|-------------------|---------------------------------------------------------------------------------------------------------|---------------------------------------------------|
| `fix`             | Patches a bug in your codebase (correlates with PATCH in Semantic Versioning)                           | `fix: correct typo in README`                     |
| `feat`            | Introduces a new feature to the codebase (correlates with MINOR in Semantic Versioning)                 | `feat: add new user login functionality`          |
| `BREAKING CHANGE` | Introduces a breaking API change (correlates with MAJOR in Semantic Versioning)                         | `feat!: drop support for Node 8`                  |
| `build`           | Changes that affect the build system or external dependencies                                           | `build: update dependency version`                |
| `chore`           | Other changes that don't modify src or test files                                                       | `chore: update package.json scripts`              |
| `ci`              | Changes to CI configuration files and scripts                                                           | `ci: add CircleCIconfig`                          |
| `docs`            | Documentation only changes                                                                              | `docs: update APIdocumentation`                   |
| `style`           | Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.) | `style: fix linting errors`                       |
| `refactor`        | Code change that neither fixes a bug nor adds a feature                                                 | `refactor: renamevariable for clarity`            |
| `perf`            | Code change that improves performance                                                                   | `perf: reduce size of image files`                |
| `test`            | Adding missing tests or correcting existing tests                                                       | `test: add unit tests for new feature`            |
| Custom Types      | Any other type defined by the project for its specific needs                                            | `security: address vulnerability in dependencies` |

For more information, refer to the [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/).
