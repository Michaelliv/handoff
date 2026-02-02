import SwiftUI
import ClipboardCore

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("SharedClipboard")
                .font(.headline)

            Divider()

            Text("Clipboard content will appear here")
                .foregroundStyle(.secondary)
                .font(.caption)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 250)
    }
}

#Preview {
    ContentView()
}
