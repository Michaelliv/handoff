import SwiftUI
import ClipboardCore

@main
struct SharedClipboardApp: App {
    @StateObject private var viewModel = ClipboardViewModel()

    var body: some Scene {
        MenuBarExtra("Handoff", systemImage: "doc.on.clipboard") {
            // Stack items
            if viewModel.stackItems.isEmpty {
                Text("No recent items")
            } else {
                ForEach(Array(viewModel.stackItems.enumerated()), id: \.element.id) { index, item in
                    Button {
                        viewModel.copyToClipboard(item.content, itemId: item.id.uuidString)
                    } label: {
                        Text("#\(index + 1)  \(viewModel.formatStackPreview(item.content))")
                    }
                }
            }

            Divider()

            // Named slots
            if viewModel.namedSlots.isEmpty {
                Text("No saved slots")
            } else {
                ForEach(viewModel.namedSlots, id: \.name) { slot in
                    Button {
                        viewModel.copyToClipboard(slot.content, itemId: "slot:\(slot.name)")
                    } label: {
                        Text("\(viewModel.formatSlotName(slot.name))  \(viewModel.formatSlotPreview(slot.content))")
                    }
                }
            }

            Divider()

            Toggle("Launch at Login", isOn: $viewModel.launchAtLogin)

            Divider()

            Button("Quit") {
                viewModel.quit()
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
