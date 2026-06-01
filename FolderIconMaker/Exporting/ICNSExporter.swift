import CoreGraphics
import Foundation

enum ICNSExporter {
  private static let iconSetEntries = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
  ]

  static func write(_ image: CGImage, to url: URL) throws {
    let iconSetURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
      .appendingPathExtension("iconset")
    try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: iconSetURL) }

    for (fileName, pixelSize) in iconSetEntries {
      guard let data = pngData(from: image, pixelSize: pixelSize) else {
        throw exportError()
      }

      try data.write(to: iconSetURL.appendingPathComponent(fileName))
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconSetURL.path, "-o", url.path]
    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
      throw exportError()
    }
  }

  private static func pngData(from image: CGImage, pixelSize: Int) -> Data? {
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
      | CGImageAlphaInfo.premultipliedLast.rawValue
    guard
      let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: pixelSize * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo)
    else { return nil }

    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

    guard let resizedImage = context.makeImage() else { return nil }
    return PNGExporter.pngData(from: resizedImage)
  }

  private static func exportError() -> NSError {
    NSError(domain: "ICNSExporter", code: 1)
  }
}
