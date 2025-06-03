# Diomeh's Script Utilities

**Table of Contents**
- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)
- [Contributing](#contributing)

## Overview

Set of utilities to handle various file and console operations

> [!NOTE]  
> This project is a **monorepo** containing two main codebases:
> - `./bash`: standalone Bash scripts
> - `./rust`: a Rust-based CLI tool

Each distribution of the utilities shares the same CLI specifications
but is built for different environments and usage preferences.

## Installation

Two distribution methods are available to install:

- [Standalone Bash scripts](./docs/distribution/bash.md)
- [Rust CLI tool](./docs/distribution/rust.md)

## Usage

All available commands have an extensive usage message accesible through a `--help` flag.
Form more details on each command see the [command specification](./docs/commands.md)

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
