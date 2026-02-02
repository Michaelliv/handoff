import ArgumentParser
import ClipboardCore
import Foundation

@main
struct Handoff: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "handoff",
        abstract: "Shared clipboard for humans and AI agents.",
        version: "1.0.0",
        subcommands: [
            Push.self,
            Pop.self,
            List.self,
            Save.self,
            Delete.self,
            Slots.self,
            Clear.self,
            Get.self,
            Onboard.self,
            Version.self,
        ],
        defaultSubcommand: Get.self
    )
}

// MARK: - Version Command

struct Version: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show version",
        aliases: ["v"]
    )

    func run() {
        print("1.0.0")
    }
}

// MARK: - Push Command

struct Push: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Add content to stack (or pipe to stdin)",
        aliases: ["p"]
    )

    @Flag(name: .long, help: "Read content from stdin")
    var stdin = false

    @Argument(help: "The content to push")
    var content: String?

    func run() throws {
        let manager = ClipboardManager.shared
        let text: String

        if stdin || content == nil {
            // Check if stdin has data
            if isatty(STDIN_FILENO) == 0 {
                // Read all stdin
                var allContent = ""
                while let line = readLine(strippingNewline: false) {
                    allContent += line
                }
                // Remove trailing newline if present
                if allContent.hasSuffix("\n") {
                    allContent.removeLast()
                }
                guard !allContent.isEmpty else {
                    throw ValidationError("No content provided")
                }
                text = allContent
            } else if let content = content {
                text = content
            } else {
                throw ValidationError("No content provided. Use: handoff push \"content\" or pipe content via stdin")
            }
        } else if let content = content {
            text = content
        } else {
            throw ValidationError("No content provided")
        }

        do {
            try manager.push(text)
        } catch ClipboardError.contentTooLarge(let size, _) {
            let sizeMB = String(format: "%.1f", Double(size) / 1_000_000)
            FileHandle.standardError.write("Error: Content exceeds 1MB limit (got \(sizeMB)MB)\n".data(using: .utf8)!)
            throw ExitCode(1)
        }
    }
}

// MARK: - Pop Command

struct Pop: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Get and remove newest item",
        aliases: ["o"]
    )

    func run() throws {
        let manager = ClipboardManager.shared

        do {
            let content = try manager.pop()
            print(content, terminator: "")
        } catch ClipboardError.emptyStack {
            FileHandle.standardError.write("Error: Stack is empty\n".data(using: .utf8)!)
            throw ExitCode(1)
        }
    }
}

// MARK: - List Command

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show all stack items",
        aliases: ["l", "ls"]
    )

    func run() {
        let manager = ClipboardManager.shared
        let items = manager.list()

        if items.isEmpty {
            print("Stack is empty")
            return
        }

        print("#   Age        Preview")
        for (index, item) in items.enumerated() {
            let num = String(index + 1).padding(toLength: 3, withPad: " ", startingAt: 0)
            let age = formatAge(item.createdAt).padding(toLength: 10, withPad: " ", startingAt: 0)
            let preview = formatPreview(item.content, maxLength: 40)
            print("\(num) \(age) \(preview)")
        }
    }
}

// MARK: - Save Command

struct Save: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Save #1 to named slot",
        aliases: ["s"]
    )

    @Argument(help: "Name for the slot (alphanumeric, dash, underscore)")
    var name: String

    func run() throws {
        let manager = ClipboardManager.shared

        // Validate name
        let validChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard name.unicodeScalars.allSatisfy({ validChars.contains($0) }) else {
            FileHandle.standardError.write("Error: Invalid name (use alphanumeric, dash, underscore)\n".data(using: .utf8)!)
            throw ExitCode(1)
        }

        let items = manager.list()
        guard let first = items.first else {
            FileHandle.standardError.write("Error: Stack is empty, nothing to save\n".data(using: .utf8)!)
            throw ExitCode(1)
        }

        try manager.save(name: name, content: first.content)
        print("Saved to '\(name)'")
    }
}

// MARK: - Delete Command

struct Delete: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Delete named slot",
        aliases: ["d", "rm"]
    )

    @Argument(help: "Name of the slot to delete")
    var name: String

    func run() throws {
        let manager = ClipboardManager.shared

        do {
            try manager.deleteSlot(name: name)
            print("Deleted '\(name)'")
        } catch ClipboardError.slotNotFound {
            FileHandle.standardError.write("Error: No slot named '\(name)'\n".data(using: .utf8)!)
            throw ExitCode(1)
        }
    }
}

// MARK: - Slots Command

struct Slots: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List named slots",
        aliases: ["sl"]
    )

    func run() {
        let manager = ClipboardManager.shared
        let slots = manager.listSlots()

        if slots.isEmpty {
            print("No named slots")
            return
        }

        print("Name        Age        Preview")
        for slot in slots {
            let name = slot.name.padding(toLength: 11, withPad: " ", startingAt: 0)
            let age = formatAge(slot.updatedAt).padding(toLength: 10, withPad: " ", startingAt: 0)
            let preview = formatPreview(slot.content, maxLength: 35)
            print("\(name) \(age) \(preview)")
        }
    }
}

// MARK: - Clear Command

struct Clear: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Clear the stack",
        aliases: ["c"]
    )

    func run() throws {
        let manager = ClipboardManager.shared
        let count = manager.list().count
        try manager.clearStack()
        print("Cleared stack (removed \(count) items)")
    }
}

// MARK: - Get Command (Default)

struct Get: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get stack item by position or named slot"
    )

    @Argument(help: "Position number (1 = newest) or slot name")
    var target: String

    func run() throws {
        let manager = ClipboardManager.shared

        // Check if target is a number
        if let index = Int(target) {
            do {
                let content = try manager.get(index)
                print(content, terminator: "")
            } catch ClipboardError.indexOutOfRange(let requested, let available) {
                FileHandle.standardError.write("Error: No item at position \(requested) (stack has \(available) items)\n".data(using: .utf8)!)
                throw ExitCode(1)
            }
        } else {
            // Treat as slot name
            do {
                let content = try manager.get(name: target)
                print(content, terminator: "")
            } catch ClipboardError.slotNotFound {
                FileHandle.standardError.write("Error: No slot named '\(target)'\n".data(using: .utf8)!)
                throw ExitCode(1)
            }
        }
    }
}

// MARK: - Onboard Command

struct Onboard: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Add handoff instructions to ~/.<dir>/CLAUDE.md or AGENTS.md"
    )

    @Flag(name: .long, help: "Replace existing handoff instructions")
    var force = false

    private static let markerStart = "<handoff>"
    private static let markerEnd = "</handoff>"

    private static let instructions = """
<handoff>
Shared clipboard for human/AI collaboration. Data in ~/.handoff/

  handoff push "text"   - add to stack
  handoff 1             - get item #1 (newest)
  handoff pop           - get & remove newest
  handoff list          - show stack
  handoff save <name>   - save #1 to slot
  handoff <name>        - get named slot

User sends you content: `handoff 1`
You send user content: `handoff push "..."` then tell them `handoff 1`

Run `handoff --help` for more.
</handoff>
"""

    func run() {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser.path

        // Search for existing ~/.<dir>/AGENT*.md or ~/.<dir>/CLAUDE*.md
        var targetFile: String? = nil

        if let contents = try? fileManager.contentsOfDirectory(atPath: homeDir) {
            for item in contents where item.hasPrefix(".") {
                let dotDir = (homeDir as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: dotDir, isDirectory: &isDir), isDir.boolValue else {
                    continue
                }

                if let files = try? fileManager.contentsOfDirectory(atPath: dotDir) {
                    for file in files {
                        if (file.hasPrefix("AGENT") || file.hasPrefix("CLAUDE")) && file.hasSuffix(".md") {
                            targetFile = (dotDir as NSString).appendingPathComponent(file)
                            break
                        }
                    }
                }
                if targetFile != nil { break }
            }
        }

        // Default to ~/.claude/CLAUDE.md if none found
        if targetFile == nil {
            let claudeDir = (homeDir as NSString).appendingPathComponent(".claude")
            if !fileManager.fileExists(atPath: claudeDir) {
                do {
                    try fileManager.createDirectory(atPath: claudeDir, withIntermediateDirectories: true)
                } catch {
                    FileHandle.standardError.write("Error: Failed to create ~/.claude directory\n".data(using: .utf8)!)
                    return
                }
            }
            targetFile = (claudeDir as NSString).appendingPathComponent("CLAUDE.md")
        }

        var existingContent = (try? String(contentsOfFile: targetFile!, encoding: .utf8)) ?? ""

        // Check if already onboarded
        let hasExisting = existingContent.contains(Self.markerStart)

        if hasExisting && !force {
            print("✓ Already onboarded")
            print("  \(targetFile!)")
            print("  Use --force to update instructions")
            return
        }

        // Remove old instructions if forcing update
        if hasExisting && force {
            if let startRange = existingContent.range(of: Self.markerStart),
               let endRange = existingContent.range(of: Self.markerEnd) {
                let fullRange = startRange.lowerBound..<endRange.upperBound
                existingContent.removeSubrange(fullRange)
                existingContent = existingContent.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let newContent: String
        if existingContent.isEmpty {
            newContent = Self.instructions + "\n"
        } else {
            newContent = existingContent + "\n\n" + Self.instructions + "\n"
        }

        do {
            try newContent.write(toFile: targetFile!, atomically: true, encoding: .utf8)
            let action = (hasExisting && force) ? "Updated" : "Added"
            print("✓ \(action) handoff instructions in \(targetFile!)")
        } catch {
            FileHandle.standardError.write("Error: Failed to write to \(targetFile!)\n".data(using: .utf8)!)
        }
    }
}

// MARK: - Helpers

func formatAge(_ date: Date) -> String {
    let seconds = Int(-date.timeIntervalSinceNow)

    if seconds < 60 {
        return "\(seconds)s ago"
    } else if seconds < 3600 {
        return "\(seconds / 60)m ago"
    } else if seconds < 86400 {
        return "\(seconds / 3600)h ago"
    } else {
        return "\(seconds / 86400)d ago"
    }
}

func formatPreview(_ content: String, maxLength: Int) -> String {
    // Replace newlines with ␤ symbol
    var preview = content.replacingOccurrences(of: "\n", with: "␤")
    preview = preview.replacingOccurrences(of: "\r", with: "")

    if preview.count > maxLength {
        preview = String(preview.prefix(maxLength - 3)) + "..."
    }

    return preview
}
