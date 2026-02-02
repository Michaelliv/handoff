import Foundation

/// An item in the clipboard stack
public struct StackItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let content: String
    public let createdAt: Date

    public init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}

/// A named storage slot for persistent content
public struct NamedSlot: Codable, Equatable, Sendable {
    public let name: String
    public let content: String
    public let createdAt: Date
    public let updatedAt: Date

    public init(name: String, content: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.name = name
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Creates an updated copy with new content
    func updated(with content: String) -> NamedSlot {
        NamedSlot(name: name, content: content, createdAt: createdAt, updatedAt: Date())
    }
}
