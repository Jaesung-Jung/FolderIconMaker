import XCTest
@testable import TahoeFolderComposer

final class PNGExporterTests: XCTestCase {
    func testPNGDataHasPNGSignature() throws {
        let image = try TestImages.solidCGImage(width: 2, height: 2)
        let data = try XCTUnwrap(PNGExporter.pngData(from: image))
        XCTAssertEqual(Array(data.prefix(8)), [137, 80, 78, 71, 13, 10, 26, 10])
    }
}
