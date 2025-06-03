# Rust Implementation Notes

## Dependencies

- `clap` - Command line argument parsing with derive macros
- `serde` - Serialization framework
- `tokio` - Async runtime
- `anyhow` - Error handling
- `tracing` - Structured logging
- `config` - Configuration management
- `clipboard` - System clipboard integration
- `walkdir` - Directory traversal
- `flate2` - Compression support

## Project Structure

```
src/
├── main.rs             # Entry point
├── cli.rs              # CLI definition
├── config/
│   ├── mod.rs          # Configuration handling
│   └── default.rs      # Default configuration
├── utils/
│   ├── mod.rs          # Utility modules
│   ├── output.rs       # Output formatting
│   ├── logging.rs      # Logging setup
│   └── error.rs        # Error types and handling
└── commands/
    ├── mod.rs          # Command module exports
    ├── ...        
    └── <command>.rs    # Command implementation
```

## Architecture Patterns

### Command Pattern

Each command is implemented as a separate module with:

- Command-specific argument parsing
- Business logic implementation
- Error handling and user feedback

### Global Options Integration

All commands inherit and respect global options through a shared context structure.

### Error Handling Strategy

- Use `anyhow` for error propagation
- Structured error messages with hints
- Graceful degradation where possible

### Logging and Verbosity

- Structured logging with `tracing`
- Configurable log levels based on verbosity flags
- Machine-readable output options for automation

## Testing Strategy

- Unit tests for individual functions
- Integration tests for command workflows
- Cross-platform compatibility testing
- Performance benchmarks for file operations
