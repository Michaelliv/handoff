import Foundation

/// Manages clipboard stack and named slots with persistent storage
public final class ClipboardManager: @unchecked Sendable {
    /// Shared singleton instance
    public static let shared = ClipboardManager()

    /// Maximum number of items in the stack
    public static let maxStackSize = 50

    /// Maximum content size in bytes (1 MB)
    public static let maxContentSize = 1_000_000

    private let storage: Storage
    private let lock = NSLock()

    // File watching
    private var stackSource: DispatchSourceFileSystemObject?
    private var namedSource: DispatchSourceFileSystemObject?
    private var stackFileDescriptor: Int32 = -1
    private var namedFileDescriptor: Int32 = -1

    /// Called when the stack changes externally
    public var onStackChanged: (() -> Void)?

    /// Called when named slots change externally
    public var onSlotsChanged: (() -> Void)?

    /// Creates a new ClipboardManager with optional custom storage location
    public init(storageURL: URL? = nil) {
        self.storage = Storage(baseURL: storageURL)
        try? storage.ensureDirectoriesExist()
    }

    // MARK: - Stack Operations

    /// Push content to the top of the stack
    /// - Parameter content: The content to push
    /// - Throws: `ClipboardError.contentTooLarge` if content exceeds 1 MB
    public func push(_ content: String) throws {
        let size = content.utf8.count
        guard size <= Self.maxContentSize else {
            throw ClipboardError.contentTooLarge(size: size, max: Self.maxContentSize)
        }

        lock.lock()
        defer { lock.unlock() }

        var stack = try storage.readStack()
        let item = StackItem(content: content)
        stack.insert(item, at: 0)

        // Trim to max size
        if stack.count > Self.maxStackSize {
            stack = Array(stack.prefix(Self.maxStackSize))
        }

        try storage.writeStack(stack)
    }

    /// Get content by 1-based index
    /// - Parameter index: The 1-based index (1 = newest item)
    /// - Returns: The content at the specified index
    /// - Throws: `ClipboardError.indexOutOfRange` if index is invalid
    public func get(_ index: Int) throws -> String {
        lock.lock()
        defer { lock.unlock() }

        let stack = try storage.readStack()
        let arrayIndex = index - 1

        guard arrayIndex >= 0 && arrayIndex < stack.count else {
            throw ClipboardError.indexOutOfRange(requested: index, available: stack.count)
        }

        return stack[arrayIndex].content
    }

    /// Pop and return the top item from the stack
    /// - Returns: The content of the top item
    /// - Throws: `ClipboardError.emptyStack` if stack is empty
    public func pop() throws -> String {
        lock.lock()
        defer { lock.unlock() }

        var stack = try storage.readStack()

        guard !stack.isEmpty else {
            throw ClipboardError.emptyStack
        }

        let item = stack.removeFirst()
        try storage.writeStack(stack)

        return item.content
    }

    /// List all items in the stack
    /// - Returns: Array of stack items, newest first
    public func list() -> [StackItem] {
        lock.lock()
        defer { lock.unlock() }

        return (try? storage.readStack()) ?? []
    }

    /// Clear all items from the stack
    public func clearStack() throws {
        lock.lock()
        defer { lock.unlock() }

        try storage.writeStack([])
    }

    // MARK: - Named Slot Operations

    /// Save content to a named slot
    /// - Parameters:
    ///   - name: The slot name
    ///   - content: The content to save
    /// - Throws: `ClipboardError.contentTooLarge` if content exceeds 1 MB
    public func save(name: String, content: String) throws {
        let size = content.utf8.count
        guard size <= Self.maxContentSize else {
            throw ClipboardError.contentTooLarge(size: size, max: Self.maxContentSize)
        }

        lock.lock()
        defer { lock.unlock() }

        let slot: NamedSlot
        if let existing = try storage.readSlot(name: name) {
            slot = existing.updated(with: content)
        } else {
            slot = NamedSlot(name: name, content: content)
        }

        try storage.writeSlot(slot)
    }

    /// Get content from a named slot
    /// - Parameter name: The slot name
    /// - Returns: The content of the slot
    /// - Throws: `ClipboardError.slotNotFound` if slot doesn't exist
    public func get(name: String) throws -> String {
        lock.lock()
        defer { lock.unlock() }

        guard let slot = try storage.readSlot(name: name) else {
            throw ClipboardError.slotNotFound(name: name)
        }

        return slot.content
    }

    /// Delete a named slot
    /// - Parameter name: The slot name to delete
    /// - Throws: `ClipboardError.slotNotFound` if slot doesn't exist
    public func deleteSlot(name: String) throws {
        lock.lock()
        defer { lock.unlock() }

        try storage.deleteSlot(name: name)
    }

    /// List all named slots
    /// - Returns: Array of named slots, sorted by most recently updated
    public func listSlots() -> [NamedSlot] {
        lock.lock()
        defer { lock.unlock() }

        return (try? storage.listSlots()) ?? []
    }

    // MARK: - File Watching

    /// Start watching for external file changes
    public func startWatching() {
        stopWatching()

        // Watch stack file
        let stackPath = storage.stackFileURL.path
        stackFileDescriptor = open(stackPath, O_EVTONLY)
        if stackFileDescriptor != -1 {
            stackSource = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: stackFileDescriptor,
                eventMask: [.write, .delete, .rename],
                queue: .main
            )
            stackSource?.setEventHandler { [weak self] in
                self?.onStackChanged?()
            }
            stackSource?.setCancelHandler { [weak self] in
                if let fd = self?.stackFileDescriptor, fd != -1 {
                    close(fd)
                }
                self?.stackFileDescriptor = -1
            }
            stackSource?.resume()
        }

        // Watch named directory
        let namedPath = storage.namedDirectoryURL.path
        namedFileDescriptor = open(namedPath, O_EVTONLY)
        if namedFileDescriptor != -1 {
            namedSource = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: namedFileDescriptor,
                eventMask: [.write, .delete, .rename],
                queue: .main
            )
            namedSource?.setEventHandler { [weak self] in
                self?.onSlotsChanged?()
            }
            namedSource?.setCancelHandler { [weak self] in
                if let fd = self?.namedFileDescriptor, fd != -1 {
                    close(fd)
                }
                self?.namedFileDescriptor = -1
            }
            namedSource?.resume()
        }
    }

    /// Stop watching for external file changes
    public func stopWatching() {
        stackSource?.cancel()
        stackSource = nil

        namedSource?.cancel()
        namedSource = nil
    }

    deinit {
        stopWatching()
    }
}
