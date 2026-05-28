import CoreGraphics
import XCTest
@testable import TahoeFolderComposer

final class SymbolImageLoaderTests: XCTestCase {
    func testAlphaMaskFitsImageIntoTargetRect() throws {
        let image = try TestImages.solidCGImage(width: 2, height: 2, rgba: [0, 0, 0, 255])
        let mask = SymbolImageLoader.alphaMask(
            from: image,
            canvasSize: 6,
            targetRect: CGRect(x: 2, y: 2, width: 2, height: 2)
        )

        XCTAssertEqual(mask.width, 6)
        XCTAssertEqual(mask.height, 6)
        XCTAssertEqual(mask.value(x: 0, y: 0), 0)
        XCTAssertGreaterThan(mask.value(x: 2, y: 2), 0)
    }
}
