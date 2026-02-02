import Foundation

/// Errors that can occur during clipboard operations
public enum ClipboardError: Error, LocalizedError, Equatable {
    case indexOutOfRange(requested: Int, available: Int)
    case slotNotFound(name: String)
    case contentTooLarge(size: Int, max: Int)
    case storageError(message: String)
    case emptyStack

    public var errorDescription: String? {
        switch self {
        case .indexOutOfRange(let requested, let available):
            return "Index \(requested) is out of range. Available items: \(available)"
        case .slotNotFound(let name):
            return "Slot '\(name)' not found"
        case .contentTooLarge(let size, let max):
            return "Content size \(size) bytes exceeds maximum of \(max) bytes"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .emptyStack:
            return "Stack is empty"
        }
    }
}
