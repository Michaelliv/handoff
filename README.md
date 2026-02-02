# shared-clipboard

A macOS clipboard manager designed for sharing content between humans and AI agents.

## Components

- **ClipboardCore**: Shared Swift library for storage and logic
- **clip**: CLI tool for pushing/getting clipboard content
- **SharedClipboard**: macOS menu bar app for visual access

## Installation

### Homebrew

```bash
# Install CLI tool
brew install michaelliv/tap/clip

# Install menu bar app
brew install --cask michaelliv/tap/shared-clipboard
```

### Build from Source

```bash
git clone https://github.com/michaelliv/shared-clipboard.git
cd shared-clipboard
swift build -c release
```

## CLI Usage

```bash
# Push content to clipboard
clip push "Hello, world!"

# Get current clipboard content
clip get

# List clipboard history
clip list
```

## Related Issues

- [#1 Set up Swift package structure](../../issues/1)
- [#2 Implement ClipboardCore shared library](../../issues/2)
- [#3 Build CLI tool](../../issues/3)
- [#4 Build macOS menu bar app](../../issues/4)
- [#5 Set up Homebrew distribution](../../issues/5)

## License

MIT
