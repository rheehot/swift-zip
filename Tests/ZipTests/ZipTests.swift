import XCTest
@testable import Zip

final class ZipTests: XCTestCase {
    func testGetItemFilePath() throws {
        let fileURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("jikji.epub+zip.epub")

        func test() {
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

    func testGetItemData() throws {
        let fileURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("jikji.epub+zip.epub")

        let data = try Data(contentsOf: fileURL)

        func test() {
            do {
                let zip = Zip(data: data)

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

    func testUnzipFilePath() throws {
        let fileURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("jikji.epub+zip.epub")

        let unzipDestinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)

        func test() {
            do {
                let zip = try Zip(contentsOf: fileURL)

                try zip.unzip(to: unzipDestinationURL)
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

        let subpaths = try FileManager.default.subpathsOfDirectory(atPath: unzipDestinationURL.path)
        XCTAssertEqual(subpaths.count, 104)

        try FileManager.default.removeItem(at: unzipDestinationURL)
    }

    func testUnzipData() throws {
        let fileURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("jikji.epub+zip.epub")

        let data = try Data(contentsOf: fileURL)

        let unzipDestinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)

        func test() {
            do {
                let zip = Zip(data: data)

                try zip.unzip(to: unzipDestinationURL)
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

        let subpaths = try FileManager.default.subpathsOfDirectory(atPath: unzipDestinationURL.path)
        XCTAssertEqual(subpaths.count, 104)

        try FileManager.default.removeItem(at: unzipDestinationURL)
    }

    static var allTests = [
        ("testGetItemFilePath", testGetItemFilePath),
    ]
}
