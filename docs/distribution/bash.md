# Bash scripts distribution

Bash scripts are available as-is to download in the [GitHub releases](https://github.com/Diomeh/dsu/releases) page
as a bundled tarfile.

## Cross-platform Support

No cross-platform support will be worked on beyond POSIX compliance. 

## Installation Methods

**Manually**

Download bundled tarfile from releases

    wget https://github.com/Diomeh/dsu/releases/download/2.2.12/dsu.tar.gz

Extract archive 

    tar -vxzf dsu.tar.gz

Make scripts executable

    chmod -R +x ./bin

**Through Git**

Clone the repo

    git clone https://github.com/Diomeh/dsu.git
    cd dsu/bash

Run installation script

    chmod +x install.sh
    ./install.sh

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
