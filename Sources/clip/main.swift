import ArgumentParser
import ClipboardCore

@main
struct Clip: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clip",
        abstract: "A CLI tool for managing shared clipboard content.",
        subcommands: [Push.self, Get.self, List.self]
    )
}

struct Push: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Push content to the clipboard."
    )

    @Argument(help: "The content to push to the clipboard.")
    var content: String

    func run() {
        print("Pushing: \(content)")
    }
}

struct Get: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Get current clipboard content."
    )

    func run() {
        print("Getting clipboard content...")
    }
}

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List clipboard history."
    )

    func run() {
        print("Listing clipboard history...")
    }
}
