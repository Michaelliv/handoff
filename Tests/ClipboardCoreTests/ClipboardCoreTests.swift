import XCTest
@testable import ClipboardCore

final class ClipboardCoreTests: XCTestCase {
    func testClipboardCoreInitializes() {
        let core = ClipboardCore()
        XCTAssertNotNil(core)
    }
}
