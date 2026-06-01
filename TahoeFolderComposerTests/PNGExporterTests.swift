import Foundation
import XCTest

@testable import TahoeFolderComposer

private let pngSignature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]

final class PNGExporterTests: XCTestCase {
  func testPNGDataHasPNGSignature() throws {
    let image = try TestImages.solidCGImage(width: 2, height: 2)
    let data = try XCTUnwrap(PNGExporter.pngData(from: image))
    XCTAssertEqual(Array(data.prefix(8)), pngSignature)
  }

  func testWriteWritesPNGBytesToURL() throws {
    let image = try TestImages.solidCGImage(width: 2, height: 2)
    let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directoryURL) }

    let fileURL = directoryURL.appendingPathComponent("image.png")
    try PNGExporter.write(image, to: fileURL)

    let data = try Data(contentsOf: fileURL)
    XCTAssertEqual(Array(data.prefix(8)), pngSignature)
  }
}
