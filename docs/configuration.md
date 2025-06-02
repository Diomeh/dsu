# Configuration

Configuration feature is planned but not yet implemented or being worked on.
Below is a proposal of how the feature should work, but it is prone to change.

## Config File Locations

- Linux/macOS: `~/.config/dsu/config.toml`
- Windows: `%APPDATA%\dsu\config.toml`
- Custom: `dsu --config path/to/config.toml <command>`

## Config File Format (TOML)

Config file will be grouped in `toml` sections, one for `global` options
and one for each command available to the CLI

## Configuration Options

### Global Settings

- `verbose` - Default verbosity level
- `color` - Color output preference
- `prompt` - Default prompt behaviour

### Command-Specific Settings

Each command can have its own default configuration section that overrides the global defaults for that specific command.

### Environment Variables

- `DSU_CONFIG` - Custom config file path
- `DSU_NO_COLOR` - Disable colored output
- `DSU_VERBOSE` - Default verbosity level
- `DSU_LOG_LEVEL` - Logging level (error, warn, info, debug, trace)
