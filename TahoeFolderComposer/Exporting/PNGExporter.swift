import AppKit
import CoreGraphics
import Foundation

enum PNGExporter {
    static func pngData(from image: CGImage) -> Data? {
        let rep = NSBitmapImageRep(cgImage: image)
        return rep.representation(using: .png, properties: [:])
    }

    static func write(_ image: CGImage, to url: URL) throws {
        try pngData(from: image)?.write(to: url)
    }
}
