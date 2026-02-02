# handoff

A macOS clipboard manager designed for sharing content between humans and AI agents.

## Components

- **ClipboardCore**: Shared Swift library for storage and logic
- **handoff**: CLI tool for pushing/getting clipboard content
- **Handoff.app**: macOS menu bar app for visual access

## Installation

### Homebrew

```bash
# Install CLI tool
brew install michaelliv/tap/handoff

# Install menu bar app
brew install --cask michaelliv/tap/handoff
```

### Build from Source

```bash
git clone https://github.com/michaelliv/handoff.git
cd handoff
swift build -c release
cp .build/release/handoff /usr/local/bin/
```

## CLI Usage

```bash
# Push content to stack
handoff push "Hello, world!"

# Push from pipe
echo "piped content" | handoff push
cat file.txt | handoff push

# Get item by position (1 = newest)
handoff 1
handoff 2

# Pop (get and remove) newest item
handoff pop

# List stack items
handoff list

# Save #1 to named slot
handoff save ticket

# Get named slot
handoff ticket

# Delete named slot
handoff delete ticket

# List all named slots
handoff slots

# Clear the stack
handoff clear

# Help
handoff --help
```

## Storage

Data is stored in `~/.handoff/`:
- `stack.json` - clipboard stack (max 50 items)
- `named/*.json` - named slots

## Related Issues

- [#1 Set up Swift package structure](../../issues/1)
- [#2 Implement ClipboardCore shared library](../../issues/2)
- [#3 Build CLI tool](../../issues/3)
- [#4 Build macOS menu bar app](../../issues/4)
- [#5 Set up Homebrew distribution](../../issues/5)

## License

MIT
