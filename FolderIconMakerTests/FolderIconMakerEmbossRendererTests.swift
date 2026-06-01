import CoreGraphics
import CoreImage
import Darwin
import Foundation
import XCTest

@testable import FolderIconMaker

final class FolderIconMakerEmbossRendererTests: XCTestCase {
  private let pngSignature = [UInt8](arrayLiteral: 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)

  func testRenderProducesCanvasSizedImage() throws {
    let base = try TestImages.solidCGImage(width: 1024, height: 1024, rgba: [105, 184, 228, 255])
    let symbol = try TestImages.solidCGImage(width: 32, height: 32, rgba: [0, 0, 0, 255])
    let result = FolderIconMakerEmbossRenderer().render(base: base, symbol: symbol, settings: .default)

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

    let result = FolderIconMakerEmbossRenderer().render(base: base, symbol: symbol, settings: settings)

    XCTAssertNotEqual(try pixel(in: result, x: 3, y: 3), baseColor)
    XCTAssertEqual(try pixel(in: result, x: 0, y: 0), baseColor)
  }

  func testRenderMatchesIconServicesEmbossEffect() throws {
    let base = try TestImages.solidCGImage(width: 1024, height: 1024, rgba: [105, 184, 228, 255])
    let symbol = try TestImages.solidCGImage(width: 32, height: 32, rgba: [0, 0, 0, 255])
    let settings = RenderSettings.default
    let result = FolderIconMakerEmbossRenderer().render(base: base, symbol: symbol, settings: settings)
    let expected = try iconServicesEmbossedImage(base: base, symbol: symbol, settings: settings)

    XCTAssertLessThan(try meanAbsoluteRGBDifference(result, expected), 0.5)
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
    let result = FolderIconMakerEmbossRenderer().render(base: base, symbol: symbol, settings: settings)
    let pngData = try XCTUnwrap(PNGExporter.pngData(from: result))

    XCTAssertEqual(Array(pngData.prefix(pngSignature.count)), pngSignature)
  }

  func testDefaultRenderCompletesInPreviewBudget() throws {
    let base = try TestImages.solidCGImage(width: 1024, height: 1024, rgba: [105, 184, 228, 255])
    let symbol = try TestImages.solidCGImage(width: 32, height: 32, rgba: [0, 0, 0, 255])
    let start = Date()

    _ = FolderIconMakerEmbossRenderer().render(base: base, symbol: symbol, settings: .default)

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

  private func iconServicesEmbossedImage(
    base: CGImage,
    symbol: CGImage,
    settings: RenderSettings
  ) throws -> CGImage {
    dlopen("/System/Library/PrivateFrameworks/IconServices.framework/IconServices", RTLD_NOW)
    let effectClass = try XCTUnwrap(NSClassFromString("ISEmbossedEffect") as? NSObject.Type)
    let effect = effectClass.init()
    let selector = NSSelectorFromString("filterWithBackgroundImage:inputImage:")
    let filter = try XCTUnwrap(
      effect.perform(
        selector,
        with: CIImage(cgImage: base),
        with: CIImage(cgImage: symbolInputImage(from: symbol, settings: settings))
      )?.takeUnretainedValue()
    )
    let outputImage = try XCTUnwrap(filter.value(forKey: "outputImage") as? CIImage)
    let context = CIContext(options: nil)
    return try XCTUnwrap(
      context.createCGImage(
        outputImage,
        from: CGRect(x: 0, y: 0, width: settings.canvasSize, height: settings.canvasSize)
      )
    )
  }

  private func symbolInputImage(from symbol: CGImage, settings: RenderSettings) -> CGImage {
    let mask = SymbolImageLoader.alphaMask(
      from: symbol,
      canvasSize: settings.canvasSize,
      targetRect: settings.symbolRect
    )
    var pixels = [UInt8](repeating: 0, count: settings.canvasSize * settings.canvasSize * 4)
    for y in 0..<settings.canvasSize {
      for x in 0..<settings.canvasSize {
        let index = (y * settings.canvasSize + x) * 4
        pixels[index + 3] = mask.value(x: x, y: y)
      }
    }

    let provider = CGDataProvider(data: Data(pixels) as CFData)!
    return CGImage(
      width: settings.canvasSize,
      height: settings.canvasSize,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: settings.canvasSize * 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent
    )!
  }

  private func meanAbsoluteRGBDifference(_ lhs: CGImage, _ rhs: CGImage) throws -> Double {
    let lhsPixels = try pixels(in: lhs)
    let rhsPixels = try pixels(in: rhs)
    var total = 0

    for index in stride(from: 0, to: lhsPixels.count, by: 4) {
      total += abs(Int(lhsPixels[index]) - Int(rhsPixels[index]))
      total += abs(Int(lhsPixels[index + 1]) - Int(rhsPixels[index + 1]))
      total += abs(Int(lhsPixels[index + 2]) - Int(rhsPixels[index + 2]))
    }

    return Double(total) / Double(lhs.width * lhs.height * 3)
  }

  private func pixels(in image: CGImage) throws -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
    try pixels.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: image.width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
      let validContext = try XCTUnwrap(context)
      validContext.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
    return pixels
  }
}
