import Foundation
import Testing

@testable import FolderIconMaker

private let icnsSignature: [UInt8] = [0x69, 0x63, 0x6E, 0x73]

@Suite
struct ICNSExporterTests {
  @Test
  func writeCreatesICNSFileWithSignature() throws {
    let image = try TestImages.solidCGImage(width: 1024, height: 1024)
    let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directoryURL) }

    let fileURL = directoryURL.appendingPathComponent("image.icns")
    try ICNSExporter.write(image, to: fileURL)

    let data = try Data(contentsOf: fileURL)
    #expect(Array(data.prefix(icnsSignature.count)) == icnsSignature)
  }
}
