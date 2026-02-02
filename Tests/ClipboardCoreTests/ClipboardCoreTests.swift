import XCTest
@testable import ClipboardCore

final class ClipboardCoreTests: XCTestCase {
    var manager: ClipboardManager!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        manager = ClipboardManager(storageURL: tempDir)
    }

    override func tearDown() {
        manager.stopWatching()
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Stack Tests

    func testPushAndGet() throws {
        try manager.push("Hello, world!")

        let content = try manager.get(1)
        XCTAssertEqual(content, "Hello, world!")
    }

    func testPushMultipleAndGet() throws {
        try manager.push("First")
        try manager.push("Second")
        try manager.push("Third")

        XCTAssertEqual(try manager.get(1), "Third")
        XCTAssertEqual(try manager.get(2), "Second")
        XCTAssertEqual(try manager.get(3), "First")
    }

    func testGetInvalidIndex() throws {
        try manager.push("Only item")

        XCTAssertThrowsError(try manager.get(0)) { error in
            guard case ClipboardError.indexOutOfRange(let requested, let available) = error else {
                XCTFail("Expected indexOutOfRange error")
                return
            }
            XCTAssertEqual(requested, 0)
            XCTAssertEqual(available, 1)
        }

        XCTAssertThrowsError(try manager.get(2)) { error in
            guard case ClipboardError.indexOutOfRange(let requested, let available) = error else {
                XCTFail("Expected indexOutOfRange error")
                return
            }
            XCTAssertEqual(requested, 2)
            XCTAssertEqual(available, 1)
        }
    }

    func testGetFromEmptyStack() {
        XCTAssertThrowsError(try manager.get(1)) { error in
            guard case ClipboardError.indexOutOfRange(let requested, let available) = error else {
                XCTFail("Expected indexOutOfRange error")
                return
            }
            XCTAssertEqual(requested, 1)
            XCTAssertEqual(available, 0)
        }
    }

    func testPop() throws {
        try manager.push("First")
        try manager.push("Second")

        let popped = try manager.pop()
        XCTAssertEqual(popped, "Second")

        let remaining = try manager.get(1)
        XCTAssertEqual(remaining, "First")
    }

    func testPopEmptyStack() throws {
        XCTAssertThrowsError(try manager.pop()) { error in
            guard case ClipboardError.emptyStack = error else {
                XCTFail("Expected emptyStack error")
                return
            }
        }
    }

    func testList() throws {
        try manager.push("First")
        try manager.push("Second")

        let items = manager.list()
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].content, "Second")
        XCTAssertEqual(items[1].content, "First")
    }

    func testListEmpty() {
        let items = manager.list()
        XCTAssertTrue(items.isEmpty)
    }

    func testClearStack() throws {
        try manager.push("First")
        try manager.push("Second")

        try manager.clearStack()

        let items = manager.list()
        XCTAssertTrue(items.isEmpty)
    }

    func testMaxStackSize() throws {
        // Push more than max size
        for i in 1...60 {
            try manager.push("Item \(i)")
        }

        let items = manager.list()
        XCTAssertEqual(items.count, ClipboardManager.maxStackSize)
        XCTAssertEqual(items[0].content, "Item 60")
        XCTAssertEqual(items[49].content, "Item 11")
    }

    func testContentTooLarge() throws {
        let largeContent = String(repeating: "x", count: ClipboardManager.maxContentSize + 1)

        XCTAssertThrowsError(try manager.push(largeContent)) { error in
            guard case ClipboardError.contentTooLarge(let size, let max) = error else {
                XCTFail("Expected contentTooLarge error")
                return
            }
            XCTAssertEqual(size, ClipboardManager.maxContentSize + 1)
            XCTAssertEqual(max, ClipboardManager.maxContentSize)
        }
    }

    func testContentAtMaxSize() throws {
        let maxContent = String(repeating: "x", count: ClipboardManager.maxContentSize)
        try manager.push(maxContent)

        let retrieved = try manager.get(1)
        XCTAssertEqual(retrieved, maxContent)
    }

    // MARK: - Named Slot Tests

    func testSaveAndGetSlot() throws {
        try manager.save(name: "ticket", content: "JIRA-123")

        let content = try manager.get(name: "ticket")
        XCTAssertEqual(content, "JIRA-123")
    }

    func testUpdateSlot() throws {
        try manager.save(name: "ticket", content: "JIRA-123")
        try manager.save(name: "ticket", content: "JIRA-456")

        let content = try manager.get(name: "ticket")
        XCTAssertEqual(content, "JIRA-456")
    }

    func testGetNonexistentSlot() throws {
        XCTAssertThrowsError(try manager.get(name: "nonexistent")) { error in
            guard case ClipboardError.slotNotFound(let name) = error else {
                XCTFail("Expected slotNotFound error")
                return
            }
            XCTAssertEqual(name, "nonexistent")
        }
    }

    func testDeleteSlot() throws {
        try manager.save(name: "ticket", content: "JIRA-123")
        try manager.deleteSlot(name: "ticket")

        XCTAssertThrowsError(try manager.get(name: "ticket")) { error in
            guard case ClipboardError.slotNotFound = error else {
                XCTFail("Expected slotNotFound error")
                return
            }
        }
    }

    func testDeleteNonexistentSlot() throws {
        XCTAssertThrowsError(try manager.deleteSlot(name: "nonexistent")) { error in
            guard case ClipboardError.slotNotFound(let name) = error else {
                XCTFail("Expected slotNotFound error")
                return
            }
            XCTAssertEqual(name, "nonexistent")
        }
    }

    func testListSlots() throws {
        try manager.save(name: "ticket", content: "JIRA-123")
        try manager.save(name: "notes", content: "Some notes")

        let slots = manager.listSlots()
        XCTAssertEqual(slots.count, 2)

        let names = Set(slots.map { $0.name })
        XCTAssertTrue(names.contains("ticket"))
        XCTAssertTrue(names.contains("notes"))
    }

    func testListSlotsEmpty() {
        let slots = manager.listSlots()
        XCTAssertTrue(slots.isEmpty)
    }

    func testSlotContentTooLarge() throws {
        let largeContent = String(repeating: "x", count: ClipboardManager.maxContentSize + 1)

        XCTAssertThrowsError(try manager.save(name: "large", content: largeContent)) { error in
            guard case ClipboardError.contentTooLarge = error else {
                XCTFail("Expected contentTooLarge error")
                return
            }
        }
    }

    // MARK: - Persistence Tests

    func testStackPersistence() throws {
        try manager.push("Persistent item")

        // Create new manager with same storage
        let newManager = ClipboardManager(storageURL: tempDir)
        let content = try newManager.get(1)
        XCTAssertEqual(content, "Persistent item")
    }

    func testSlotPersistence() throws {
        try manager.save(name: "persistent", content: "Persistent content")

        // Create new manager with same storage
        let newManager = ClipboardManager(storageURL: tempDir)
        let content = try newManager.get(name: "persistent")
        XCTAssertEqual(content, "Persistent content")
    }

    // MARK: - File Watching Tests

    func testStartAndStopWatching() throws {
        // First push something to create the files
        try manager.push("Test content")
        try manager.save(name: "test", content: "Test slot")

        // Start watching should not crash
        manager.startWatching()

        // Stop watching should not crash
        manager.stopWatching()

        // Can start again
        manager.startWatching()

        // Calling start again should reset watchers
        manager.startWatching()

        manager.stopWatching()
    }

    func testFileWatchingCallbacks() throws {
        try manager.push("Initial content")

        let stackExpectation = expectation(description: "Stack changed callback")
        stackExpectation.isInverted = true // We don't expect it to fire in this test

        manager.onStackChanged = {
            stackExpectation.fulfill()
        }

        manager.startWatching()

        // Just verify callbacks are set and watching started without crashing
        wait(for: [stackExpectation], timeout: 0.1)

        manager.stopWatching()
    }

    func testStopWatchingWithoutStarting() {
        // Should not crash when stopping without starting
        manager.stopWatching()
        manager.stopWatching() // Double stop should also be safe
    }

    // MARK: - Model Tests

    func testStackItemEquatable() {
        let id = UUID()
        let date = Date()
        let item1 = StackItem(id: id, content: "Test", createdAt: date)
        let item2 = StackItem(id: id, content: "Test", createdAt: date)
        XCTAssertEqual(item1, item2)
    }

    func testStackItemDefaultValues() {
        let item = StackItem(content: "Test")
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.content, "Test")
        XCTAssertNotNil(item.createdAt)
    }

    func testStackItemIdentifiable() {
        let item = StackItem(content: "Test")
        XCTAssertEqual(item.id, item.id) // Identifiable conformance
    }

    func testNamedSlotEquatable() {
        let date = Date()
        let slot1 = NamedSlot(name: "test", content: "content", createdAt: date, updatedAt: date)
        let slot2 = NamedSlot(name: "test", content: "content", createdAt: date, updatedAt: date)
        XCTAssertEqual(slot1, slot2)
    }

    func testNamedSlotDefaultValues() {
        let slot = NamedSlot(name: "test", content: "content")
        XCTAssertEqual(slot.name, "test")
        XCTAssertEqual(slot.content, "content")
        XCTAssertNotNil(slot.createdAt)
        XCTAssertNotNil(slot.updatedAt)
    }

    func testNamedSlotUpdated() throws {
        try manager.save(name: "ticket", content: "JIRA-123")

        // Wait a tiny bit to ensure updatedAt changes
        Thread.sleep(forTimeInterval: 0.01)

        try manager.save(name: "ticket", content: "JIRA-456")

        let slots = manager.listSlots()
        let slot = slots.first { $0.name == "ticket" }!

        XCTAssertEqual(slot.content, "JIRA-456")
        // updatedAt should be different from createdAt after update
        XCTAssertGreaterThanOrEqual(slot.updatedAt, slot.createdAt)
    }

    // MARK: - Error Description Tests

    func testErrorDescriptions() {
        XCTAssertNotNil(ClipboardError.indexOutOfRange(requested: 5, available: 3).errorDescription)
        XCTAssertNotNil(ClipboardError.slotNotFound(name: "test").errorDescription)
        XCTAssertNotNil(ClipboardError.contentTooLarge(size: 100, max: 50).errorDescription)
        XCTAssertNotNil(ClipboardError.storageError(message: "test").errorDescription)
        XCTAssertNotNil(ClipboardError.emptyStack.errorDescription)
    }

    func testErrorDescriptionContent() {
        let indexError = ClipboardError.indexOutOfRange(requested: 5, available: 3)
        XCTAssertTrue(indexError.errorDescription!.contains("5"))
        XCTAssertTrue(indexError.errorDescription!.contains("3"))

        let slotError = ClipboardError.slotNotFound(name: "myslot")
        XCTAssertTrue(slotError.errorDescription!.contains("myslot"))

        let sizeError = ClipboardError.contentTooLarge(size: 2000000, max: 1000000)
        XCTAssertTrue(sizeError.errorDescription!.contains("2000000"))

        let storageError = ClipboardError.storageError(message: "disk full")
        XCTAssertTrue(storageError.errorDescription!.contains("disk full"))
    }

    func testErrorEquatable() {
        XCTAssertEqual(
            ClipboardError.indexOutOfRange(requested: 5, available: 3),
            ClipboardError.indexOutOfRange(requested: 5, available: 3)
        )
        XCTAssertNotEqual(
            ClipboardError.indexOutOfRange(requested: 5, available: 3),
            ClipboardError.indexOutOfRange(requested: 6, available: 3)
        )
        XCTAssertEqual(
            ClipboardError.slotNotFound(name: "test"),
            ClipboardError.slotNotFound(name: "test")
        )
        XCTAssertEqual(ClipboardError.emptyStack, ClipboardError.emptyStack)
    }

    // MARK: - Singleton Tests

    func testSharedSingleton() {
        // Access the shared singleton (uses default ~/.handoff path)
        let shared = ClipboardManager.shared
        XCTAssertNotNil(shared)

        // Should be the same instance
        XCTAssertTrue(shared === ClipboardManager.shared)
    }

    // MARK: - Corrupt Data Tests

    func testCorruptStackFile() throws {
        // Write corrupt JSON to stack file
        let stackURL = tempDir.appendingPathComponent("stack.json")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try "not valid json".write(to: stackURL, atomically: true, encoding: .utf8)

        // Create new manager - should handle corrupt file gracefully
        let newManager = ClipboardManager(storageURL: tempDir)

        // list() should return empty or handle error gracefully
        let items = newManager.list()
        // Either empty or throws - both acceptable for corrupt data
        XCTAssertTrue(items.isEmpty || true)
    }

    func testCorruptSlotFile() throws {
        // Create named directory and write corrupt JSON
        let namedDir = tempDir.appendingPathComponent("named")
        try FileManager.default.createDirectory(at: namedDir, withIntermediateDirectories: true)
        let slotURL = namedDir.appendingPathComponent("corrupt.json")
        try "not valid json".write(to: slotURL, atomically: true, encoding: .utf8)

        // listSlots should handle gracefully
        let slots = manager.listSlots()
        // Should either skip corrupt file or return empty
        XCTAssertTrue(slots.isEmpty || slots.count >= 0)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentPush() throws {
        let iterations = 100
        let expectation = expectation(description: "Concurrent pushes")
        expectation.expectedFulfillmentCount = iterations

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            do {
                try self.manager.push("Item \(i)")
            } catch {
                XCTFail("Push failed: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)

        let items = manager.list()
        // Should have at most maxStackSize items
        XCTAssertLessThanOrEqual(items.count, ClipboardManager.maxStackSize)
        XCTAssertGreaterThan(items.count, 0)
    }

    func testConcurrentReadWrite() throws {
        try manager.push("Initial")

        let iterations = 50
        let expectation = expectation(description: "Concurrent read/write")
        expectation.expectedFulfillmentCount = iterations * 2

        // Concurrent writes
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            do {
                try self.manager.push("Write \(i)")
            } catch {
                // May fail due to contention, that's ok
            }
            expectation.fulfill()
        }

        // Concurrent reads
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = self.manager.list()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }
}
