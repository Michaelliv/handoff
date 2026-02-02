import SwiftUI
import ClipboardCore

@main
struct SharedClipboardApp: App {
    var body: some Scene {
        MenuBarExtra("SharedClipboard", systemImage: "doc.on.clipboard") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
