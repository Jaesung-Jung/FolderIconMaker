import XCTest
@testable import TahoeFolderComposer

final class TahoeEmbossRendererTests: XCTestCase {
    func testRenderProducesCanvasSizedImage() throws {
        let base = try TestImages.solidCGImage(width: 1024, height: 1024, rgba: [105, 184, 228, 255])
        let symbol = try TestImages.solidCGImage(width: 32, height: 32, rgba: [0, 0, 0, 255])
        let result = TahoeEmbossRenderer().render(base: base, symbol: symbol, settings: .default)

        XCTAssertEqual(result.width, 1024)
        XCTAssertEqual(result.height, 1024)
    }
}
