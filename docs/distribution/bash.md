# Bash scripts distribution

Bash scripts are available as-is to download in the [GitHub releases](https://github.com/Diomeh/dsu/releases) page
as a bundled tarfile.

## Cross-platform Support

No cross-platform support will be worked on beyond POSIX compliance. 

## Installation Methods

**Manually**

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

## Release Process

1. Automated builds via GitHub Actions, triggered on version tags
2. Packaging as compressed tarfile

## Requirements

## Dev Dependencies

None

## Runtime Dependencies

- `backup`: none
- `cln`: none
- `copy`: 
  - `wl-copy`: Required for Wayland sessions.
  - `xclip`: Required for Xorg sessions.
- `hog`: du
- `paste`:
  - `wl-copy`: Required for Wayland sessions.
  - `xclip`: Required for Xorg sessions.
- `restore`: none
- `xtract`:
  - `tar`
  - `7z`
  - `unzip`
  - `unrar`

## Versioning Strategy

- Semantic Versioning (SemVer)
- Breaking changes only in major versions
- Feature additions in minor versions
- Bug fixes in patch versions
