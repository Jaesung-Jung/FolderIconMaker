import CoreGraphics
import XCTest

@testable import FolderIconMaker

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

  func testAlphaMaskInterpretsTargetRectYAsTopLeftCoordinate() throws {
    let image = try TestImages.solidCGImage(width: 2, height: 2, rgba: [0, 0, 0, 255])
    let mask = SymbolImageLoader.alphaMask(
      from: image,
      canvasSize: 6,
      targetRect: CGRect(x: 1, y: 0, width: 2, height: 2)
    )

    XCTAssertGreaterThan(mask.value(x: 1, y: 0), 0)
    XCTAssertEqual(mask.value(x: 1, y: 5), 0)
  }

  func testAlphaMaskLimitsSymbolHeightAndPreservesWidthRatio() throws {
    let image = try TestImages.solidCGImage(width: 4, height: 2, rgba: [0, 0, 0, 255])
    let mask = SymbolImageLoader.alphaMask(
      from: image,
      canvasSize: 8,
      targetRect: CGRect(x: 2, y: 3, width: 2, height: 2)
    )

    XCTAssertEqual(mask.nonZeroBounds(), CGRect(x: 1, y: 3, width: 4, height: 2))
  }

  func testDefaultSymbolRectMatchesManualDownloadsPlacement() {
    XCTAssertEqual(RenderSettings.default.symbolRect, CGRect(x: 312, y: 380, width: 400, height: 400))
  }
}

private extension AlphaMask {
  func nonZeroBounds() -> CGRect {
    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1

    for y in 0..<height {
      for x in 0..<width where value(x: x, y: y) > 0 {
        minX = min(minX, x)
        minY = min(minY, y)
        maxX = max(maxX, x)
        maxY = max(maxY, y)
      }
    }

    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
  }
}
