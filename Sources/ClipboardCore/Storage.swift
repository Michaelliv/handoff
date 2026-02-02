import Foundation

/// Handles file system operations for clipboard storage
final class Storage {
    private let baseURL: URL
    private let stackURL: URL
    private let namedURL: URL
    private let fileManager = FileManager.default

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(baseURL: URL? = nil) {
        if let baseURL = baseURL {
            self.baseURL = baseURL
        } else {
            self.baseURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".handoff")
        }
        self.stackURL = self.baseURL.appendingPathComponent("stack.json")
        self.namedURL = self.baseURL.appendingPathComponent("named")
    }

    /// Ensures the storage directories exist
    func ensureDirectoriesExist() throws {
        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: namedURL, withIntermediateDirectories: true)
    }

    // MARK: - Stack Operations

    func readStack() throws -> [StackItem] {
        guard fileManager.fileExists(atPath: stackURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: stackURL)
            return try decoder.decode([StackItem].self, from: data)
        } catch {
            throw ClipboardError.storageError(message: "Failed to read stack: \(error.localizedDescription)")
        }
    }

    func writeStack(_ items: [StackItem]) throws {
        do {
            try ensureDirectoriesExist()
            let data = try encoder.encode(items)
            try data.write(to: stackURL, options: .atomic)
        } catch let error as ClipboardError {
            throw error
        } catch {
            throw ClipboardError.storageError(message: "Failed to write stack: \(error.localizedDescription)")
        }
    }

    // MARK: - Named Slot Operations

    private func slotURL(for name: String) -> URL {
        namedURL.appendingPathComponent("\(name).json")
    }

    func readSlot(name: String) throws -> NamedSlot? {
        let url = slotURL(for: name)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(NamedSlot.self, from: data)
        } catch {
            throw ClipboardError.storageError(message: "Failed to read slot '\(name)': \(error.localizedDescription)")
        }
    }

    func writeSlot(_ slot: NamedSlot) throws {
        do {
            try ensureDirectoriesExist()
            let data = try encoder.encode(slot)
            try data.write(to: slotURL(for: slot.name), options: .atomic)
        } catch let error as ClipboardError {
            throw error
        } catch {
            throw ClipboardError.storageError(message: "Failed to write slot '\(slot.name)': \(error.localizedDescription)")
        }
    }

    func deleteSlot(name: String) throws {
        let url = slotURL(for: name)
        guard fileManager.fileExists(atPath: url.path) else {
            throw ClipboardError.slotNotFound(name: name)
        }

        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw ClipboardError.storageError(message: "Failed to delete slot '\(name)': \(error.localizedDescription)")
        }
    }

    func listSlots() throws -> [NamedSlot] {
        guard fileManager.fileExists(atPath: namedURL.path) else {
            return []
        }

        do {
            let files = try fileManager.contentsOfDirectory(at: namedURL, includingPropertiesForKeys: nil)
            return try files
                .filter { $0.pathExtension == "json" }
                .compactMap { url -> NamedSlot? in
                    let data = try Data(contentsOf: url)
                    return try decoder.decode(NamedSlot.self, from: data)
                }
                .sorted { $0.updatedAt > $1.updatedAt }
        } catch let error as ClipboardError {
            throw error
        } catch {
            throw ClipboardError.storageError(message: "Failed to list slots: \(error.localizedDescription)")
        }
    }

    // MARK: - File Watching

    var stackFileURL: URL { stackURL }
    var namedDirectoryURL: URL { namedURL }
}
