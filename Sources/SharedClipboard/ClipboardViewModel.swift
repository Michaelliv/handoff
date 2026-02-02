import SwiftUI
import ClipboardCore
import AppKit
import ServiceManagement

@MainActor
final class ClipboardViewModel: ObservableObject {
    @Published var stackItems: [StackItem] = []
    @Published var namedSlots: [NamedSlot] = []
    @Published var copiedItemId: String?
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    private let manager = ClipboardManager.shared
    private var feedbackTask: Task<Void, Never>?
    private var clipboardMonitorTask: Task<Void, Never>?
    private var lastChangeCount: Int = 0

    /// Maximum stack items to display
    static let maxDisplayedItems = 10

    /// Maximum characters for stack preview
    static let stackPreviewLength = 35

    /// Maximum characters for slot name
    static let slotNameLength = 10

    /// Maximum characters for slot preview
    static let slotPreviewLength = 25

    init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.lastChangeCount = NSPasteboard.general.changeCount
        refresh()
        setupFileWatching()
        startClipboardMonitoring()
    }

    func refresh() {
        stackItems = Array(manager.list().prefix(Self.maxDisplayedItems))
        namedSlots = manager.listSlots()
    }

    private func setupFileWatching() {
        manager.onStackChanged = { [weak self] in
            Task { @MainActor in
                self?.refresh()
            }
        }
        manager.onSlotsChanged = { [weak self] in
            Task { @MainActor in
                self?.refresh()
            }
        }
        manager.startWatching()
    }

    func copyToClipboard(_ content: String, itemId: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)

        // Show feedback
        feedbackTask?.cancel()
        copiedItemId = itemId
        feedbackTask = Task {
            try? await Task.sleep(for: .seconds(1))
            if !Task.isCancelled {
                copiedItemId = nil
            }
        }
    }

    func formatStackPreview(_ content: String) -> String {
        formatPreview(content, maxLength: Self.stackPreviewLength)
    }

    func formatSlotPreview(_ content: String) -> String {
        formatPreview(content, maxLength: Self.slotPreviewLength)
    }

    func formatSlotName(_ name: String) -> String {
        if name.count > Self.slotNameLength {
            return String(name.prefix(Self.slotNameLength - 1)) + "…"
        }
        return name
    }

    private func formatPreview(_ content: String, maxLength: Int) -> String {
        // Replace newlines with visible symbol
        let singleLine = content.replacingOccurrences(of: "\n", with: "␤")

        if singleLine.count > maxLength {
            return String(singleLine.prefix(maxLength - 1)) + "…"
        }
        return singleLine
    }

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently handle - user can retry
            }
        }
    }

    private func startClipboardMonitoring() {
        clipboardMonitorTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                await checkClipboard()
            }
        }
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty else { return }

        // Don't add duplicates of the most recent item
        if let topItem = stackItems.first, topItem.content == content {
            return
        }

        // Push to stack
        do {
            try manager.push(content)
            refresh()
        } catch {
            // Content too large or other error - ignore
        }
    }

    func quit() {
        clipboardMonitorTask?.cancel()
        manager.stopWatching()
        NSApplication.shared.terminate(nil)
    }
}
