import CoreGraphics
import XCTest

@testable import FolderIconMaker

final class PreviewStateTests: XCTestCase {
  func testVisibleImageFallsBackToBaseBeforeSymbolRender() throws {
    let base = try TestImages.solidCGImage(width: 8, height: 8, rgba: [105, 184, 228, 255])
    var state = PreviewState()

    state.showBase(base)

    XCTAssertTrue(state.visibleImage === base)
    XCTAssertNil(state.exportImage)
  }

  func testVisibleImagePrefersRenderedImageAfterSymbolRender() throws {
    let base = try TestImages.solidCGImage(width: 8, height: 8, rgba: [105, 184, 228, 255])
    let rendered = try TestImages.solidCGImage(width: 8, height: 8, rgba: [95, 174, 218, 255])
    var state = PreviewState()

    state.showBase(base)
    state.beginRendering(baseImage: base)
    state.showRendered(rendered)

    XCTAssertTrue(state.visibleImage === rendered)
    XCTAssertTrue(state.exportImage === rendered)
    XCTAssertFalse(state.isRendering)
  }
}
