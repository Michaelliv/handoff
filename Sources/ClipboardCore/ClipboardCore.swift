/// ClipboardCore provides shared clipboard management functionality
/// used by both the CLI tool and the menu bar app.
///
/// ## Overview
///
/// The library provides a stack-based clipboard with named slots for persistent storage.
/// Data is stored in `~/.handoff/` as JSON files.
///
/// ## Usage
///
/// ```swift
/// let manager = ClipboardManager.shared
///
/// // Stack operations
/// try manager.push("Hello, world!")
/// let content = try manager.get(1)  // 1-based index
/// let popped = try manager.pop()
///
/// // Named slots
/// try manager.save(name: "ticket", content: "JIRA-123")
/// let ticket = try manager.get(name: "ticket")
/// ```
///
/// ## File Watching
///
/// For apps that need to react to external changes:
///
/// ```swift
/// manager.onStackChanged = { print("Stack changed!") }
/// manager.startWatching()
/// ```
