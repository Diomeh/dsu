# Global Options

All commands support the following global options:

| Short | Long                | Description                                          | Default |
|-------|---------------------|------------------------------------------------------|---------|
| `-h`  | `--help`            | Display help information and exit                    | -       |
| `-V`  | `--version`         | Display version information and exit                 | -       |
| `-v`  | `--verbose <level>` | Set verbosity level                                  | info    |
| `-q`  | `--quiet`           | Suppress output (same as `--verbose off`)            | -       |
| `-c`  | `--color <option>`  | Set colored output                                   | auto    |
|       | `--no-color`        | Disable color output (same as `--color off`)         |         |
| `-d`  | `--dry-run`         | Preview actions without executing                    | -       |
| `-p`  | `--prompt <option>` | Prompt behavior mode                                 | ask     |
| `-y`  | `--yes`             | Answer "yes" to all prompts (same as `--prompt yes`) |         |
| `-n`  | `--no`              | Answer "no" to all prompts (same as `--prompt no`)   |         |

## Behaviors

### Verbosity Levels

Level can be set using either the integer or string value

| Level | Name    | Description                                                           |
|-------|---------|-----------------------------------------------------------------------|
| `0`   | `off`   | Disable output                                                        |
| `1`   | `error` | Output only errors                                                    |
| `2`   | `warn`  | Output only errors and warnings                                       |
| `3`   | `info`  | Output errors, warnings, informational and dry run messages (default) |
| `4`   | `debug` | Output detailed execution information                                 |

### Color Output

Can be one of:

- `auto`: Use colors if terminal supports it (default)
- `on`: Force colors even if not detected
- `off`: Disable all colors

### Prompt behavior

Can be one of:

- `ask`: Prompt for confirmation before operations (default)
- `yes`: Automatically answer "yes" to all prompts and run non-interactively
- `no`: Automatically answer "no" to all prompts and run non-interactively

### Conflict Resolution

Some flags are aliases or control the same behavior.
When both an alias and its canonical flag are provided, **the canonical flag takes precedence**.
The precedence rules are:

| Behavior       | Flags and aliases           | Canonical flag |
|----------------|-----------------------------|----------------|
| Output control | `--verbose`, `--quiet`      | `--verbose`    |
| Prompt control | `--prompt`, `--yes`, `--no` | `--prompt`     |
| Color control  | `--color`, `--no-color`     | `--color`      |

Similarly as above, long form flags will take precedence over short form flags.
i.e. `--color` will override `-c`.
