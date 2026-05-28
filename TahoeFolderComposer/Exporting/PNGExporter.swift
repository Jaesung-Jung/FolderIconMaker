import AppKit
import CoreGraphics
import Foundation

enum PNGExporter {
    enum ExportError: Error {
        case encodingFailed
    }

    static func pngData(from image: CGImage) -> Data? {
        let rep = NSBitmapImageRep(cgImage: image)
        return rep.representation(using: .png, properties: [:])
    }

    static func write(_ image: CGImage, to url: URL) throws {
        guard let data = pngData(from: image) else {
            throw ExportError.encodingFailed
        }

        try data.write(to: url)
    }
}
