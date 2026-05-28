import CoreGraphics
import Foundation

enum TestImages {
    static func solidCGImage(width: Int, height: Int, rgba: [UInt8] = [80, 160, 220, 255]) throws -> CGImage {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for index in stride(from: 0, to: bytes.count, by: 4) {
            bytes[index] = rgba[0]
            bytes[index + 1] = rgba[1]
            bytes[index + 2] = rgba[2]
            bytes[index + 3] = rgba[3]
        }

        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }
}
