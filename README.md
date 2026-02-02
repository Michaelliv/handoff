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

## Menu Bar App

The menu bar app provides quick visual access to your clipboard stack:

- **Auto-capture**: Automatically captures anything you copy with ⌘C
- **Click to copy**: Click any item to copy it back to system clipboard
- **Launch at Login**: Optional toggle to start with macOS
- **Live sync**: Auto-refreshes when CLI modifies storage

## CLI Usage

```bash
# Push content to stack
handoff push "Hello, world!"    # or: handoff p "..."

# Push from pipe
echo "piped content" | handoff push
cat file.txt | handoff p

# Get item by position (1 = newest)
handoff 1
handoff 2

# Pop (get and remove) newest item
handoff pop                      # or: handoff o

# List stack items
handoff list                     # or: handoff l, handoff ls

# Save #1 to named slot
handoff save ticket              # or: handoff s ticket

# Get named slot
handoff ticket

# Delete named slot
handoff delete ticket            # or: handoff d, handoff rm

# List all named slots
handoff slots                    # or: handoff sl

# Clear the stack
handoff clear                    # or: handoff c

# Show version
handoff version                  # or: handoff v

# Add instructions to ~/.claude/CLAUDE.md (for AI agents)
handoff onboard
handoff onboard --force          # update existing instructions

# Help
handoff help
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
