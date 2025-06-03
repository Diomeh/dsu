# Bash Implementation Notes

## Project Structure

```
./
├── src/                    # Command implementations         
│   ├── ...
│   └── <command>.sh        
├── tests/            
│   ├── ...
│   ├── <command>/          # Command specific test files
│   └── run.sh              # Test runner
├── install.sh              # Bash installer
└── uninstall.sh            # Bash uninstaller
```

## Architecture Patterns

### Functional Pattern

Each command is a self-contained POSIX-compliant bash script implemented through a functional pattern.

### CLI 

All command adhere to both the [global options](../global-options.md) and [commands](../commands.md) specification.
