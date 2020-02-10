import XCTest
@testable import Zip

final class ZipTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Zip().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
