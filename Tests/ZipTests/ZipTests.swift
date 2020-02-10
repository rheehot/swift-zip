import XCTest
@testable import Zip

final class ZipTests: XCTestCase {
    func testGetItem() throws {
        let fileURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("jikji.epub+zip.epub")

        let test = {
            do {
                let zip = try Zip(contentsOf: fileURL)

                let item = try zip.getItem(atPath: "META-INF/container.xml", caseSensitive: true)

                XCTAssertNotNil(item)
                XCTAssertEqual(item?.data.count, 259)
            } catch {
                XCTAssertThrowsError(error)
            }
        }

        if #available(OSX 10.15, *) {
            measure(metrics: [
                XCTCPUMetric(),
                XCTMemoryMetric(),
                XCTClockMetric()
            ], block: test)
        } else {
            measure(test)
        }
    }

    static var allTests = [
        ("testGetItem", testGetItem),
    ]
}
