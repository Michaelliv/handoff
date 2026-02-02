# handoff

A macOS clipboard manager designed for sharing content between humans and AI agents.

## Installation

### Homebrew (recommended)

```bash
brew tap michaelliv/handoff https://github.com/Michaelliv/handoff
brew install handoff-cli               # CLI
brew install --cask handoff            # Menu bar app
```

### Manual

Download from [Releases](https://github.com/Michaelliv/handoff/releases).

### Build from Source

```bash
git clone https://github.com/Michaelliv/handoff.git
cd handoff
swift build -c release
cp .build/release/handoff /usr/local/bin/
```

> **Note:** The unsigned app requires right-click → Open on first launch to bypass Gatekeeper.

## Menu Bar App

- **Auto-capture**: Automatically captures ⌘C copies
- **Click to copy**: Click any item to copy back to clipboard
- **Launch at Login**: Optional toggle
- **Live sync**: Auto-refreshes when CLI modifies storage

## CLI Usage

```bash
# Push content
handoff push "Hello, world!"         # or: handoff p
echo "piped" | handoff push

# Get by position (1 = newest)
handoff 1

# Pop (get and remove)
handoff pop                          # or: handoff o

# List stack
handoff list                         # or: handoff l

# Named slots
handoff save myslot                  # save #1 to slot
handoff myslot                       # get slot
handoff delete myslot                # delete slot
handoff slots                        # list all slots

# Other
handoff clear                        # clear stack
handoff version                      # show version
handoff onboard                      # add AI agent instructions
handoff help
```

## Storage

Data stored in `~/.handoff/`:
- `stack.json` - clipboard stack (max 50 items)
- `named/*.json` - named slots

## License

MIT
