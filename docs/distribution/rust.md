# Rust Binary Distribution

Cross-platform releases and their installation methods will be documented when available. 
This will be the last thing to be worked on.

## Target Platforms

In order of priority

- Linux (x86_64, aarch64)
- Windows (x86_64)
- macOS (x86_64, aarch64)

## Installation Methods

Possible installation methods

- GitHub Releases: Pre-built binaries available for download from the releases page for each platform.
- Cargo
- Package Managers:
  - Homebrew (macOS/Linux):
  - Chocolatey (Windows)
  - APT (Ubuntu/Debian)
  - YUM (RHEL/CentOS)
  - Nix


## Proposed Release Process

1. **Automated builds via GitHub Actions**
  - Triggered on version tags
  - Cross-compilation for all target platforms
  - Automated testing on each platform

2. **Binary packaging**
  - Compression and checksums generation
  - Digital signing for security
  - Platform-specific packaging formats

3. **Distribution**
  - GitHub Releases with automated changelog
  - Package manager updates
  - Documentation updates

## Build Requirements

[cross-rs](https://github.com/cross-rs/cross) is a tool that promises 
`“Zero setup” cross compilation and “cross testing” of Rust crates`.
We'll need to look at it to see if it serves our use case.

### Development Dependencies

- Rust 1.70+
- Cross-compilation toolchains for target platforms
- Platform-specific development tools

### Runtime Dependencies

- Minimal system dependencies
- Static linking where possible
- Platform-specific clipboard integration libraries

## Versioning Strategy

- Semantic Versioning (SemVer)
- Breaking changes only in major versions
- Feature additions in minor versions
- Bug fixes in patch versions
