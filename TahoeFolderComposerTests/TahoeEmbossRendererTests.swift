import CoreGraphics
import Foundation
import XCTest

@testable import TahoeFolderComposer

final class TahoeEmbossRendererTests: XCTestCase {
  private let pngSignature = [UInt8](arrayLiteral: 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)

  func testRenderProducesCanvasSizedImage() throws {
    let base = try TestImages.solidCGImage(width: 1024, height: 1024, rgba: [105, 184, 228, 255])
    let symbol = try TestImages.solidCGImage(width: 32, height: 32, rgba: [0, 0, 0, 255])
    let result = TahoeEmbossRenderer().render(base: base, symbol: symbol, settings: .default)

    XCTAssertEqual(result.width, 1024)
    XCTAssertEqual(result.height, 1024)
  }

  func testRenderChangesMaskedPixelAndLeavesFarPixelUnchanged() throws {
    let baseColor = Pixel(red: 105, green: 184, blue: 228, alpha: 255)
    let base = try TestImages.solidCGImage(width: 8, height: 8, rgba: baseColor.rgba)
    let symbol = try TestImages.solidCGImage(width: 2, height: 2, rgba: [0, 0, 0, 255])
    let settings = RenderSettings(
      canvasSize: 8,
      symbolRect: CGRect(x: 3, y: 3, width: 2, height: 2),
      mainDarken: 0.16,
      shadowOpacity: 0.30,
      shadowOffset: CGSize(width: 1, height: 1),
      highlightOpacity: 0.24,
      glowOpacity: 0.16
    )

    let result = TahoeEmbossRenderer().render(base: base, symbol: symbol, settings: settings)

    XCTAssertNotEqual(try pixel(in: result, x: 3, y: 3), baseColor)
    XCTAssertEqual(try pixel(in: result, x: 0, y: 0), baseColor)
  }

  func testRenderedImageCanBeEncodedAsPNG() throws {
    let base = try TestImages.solidCGImage(width: 8, height: 8, rgba: [105, 184, 228, 255])
    let symbol = try TestImages.solidCGImage(width: 2, height: 2, rgba: [0, 0, 0, 255])
    let settings = RenderSettings(
      canvasSize: 8,
      symbolRect: CGRect(x: 3, y: 3, width: 2, height: 2),
      mainDarken: 0.16,
      shadowOpacity: 0.30,
      shadowOffset: CGSize(width: 1, height: 1),
      highlightOpacity: 0.24,
      glowOpacity: 0.16
    )
    let result = TahoeEmbossRenderer().render(base: base, symbol: symbol, settings: settings)
    let pngData = try XCTUnwrap(PNGExporter.pngData(from: result))

    XCTAssertEqual(Array(pngData.prefix(pngSignature.count)), pngSignature)
  }

  func testDefaultRenderCompletesInPreviewBudget() throws {
    let base = try TestImages.solidCGImage(width: 1024, height: 1024, rgba: [105, 184, 228, 255])
    let symbol = try TestImages.solidCGImage(width: 32, height: 32, rgba: [0, 0, 0, 255])
    let start = Date()

    _ = TahoeEmbossRenderer().render(base: base, symbol: symbol, settings: .default)

    XCTAssertLessThan(Date().timeIntervalSince(start), 3.0)
  }

  private struct Pixel: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    var rgba: [UInt8] {
      [red, green, blue, alpha]
    }
  }

  private func pixel(in image: CGImage, x: Int, y: Int) throws -> Pixel {
    var bytes = [UInt8](repeating: 0, count: 4)
    try bytes.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
      let validContext = try XCTUnwrap(context)
      validContext.draw(
        image, in: CGRect(x: -x, y: y - image.height + 1, width: image.width, height: image.height))
    }
    return Pixel(red: bytes[0], green: bytes[1], blue: bytes[2], alpha: bytes[3])
  }
}
