import AppKit
import CoreGraphics
import Foundation

enum SymbolImageLoader {
    static func loadCGImage(from url: URL) -> CGImage? {
        guard let image = NSImage(contentsOf: url) else { return nil }
        var rect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    static func alphaMask(from image: CGImage, canvasSize: Int, targetRect: CGRect) -> AlphaMask {
        var rgba = [UInt8](repeating: 0, count: canvasSize * canvasSize * 4)
        let context = CGContext(
            data: &rgba,
            width: canvasSize,
            height: canvasSize,
            bitsPerComponent: 8,
            bytesPerRow: canvasSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        context.clear(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        context.interpolationQuality = .high
        let rect = aspectFitRect(for: image, in: targetRect)
        let drawingRect = CGRect(
            x: rect.minX,
            y: CGFloat(canvasSize) - rect.maxY,
            width: rect.width,
            height: rect.height
        )
        context.draw(image, in: drawingRect)

        var alpha = [UInt8](repeating: 0, count: canvasSize * canvasSize)
        for pixel in 0..<(canvasSize * canvasSize) {
            alpha[pixel] = rgba[pixel * 4 + 3]
        }
        return AlphaMask(width: canvasSize, height: canvasSize, values: alpha)
    }

    private static func aspectFitRect(for image: CGImage, in rect: CGRect) -> CGRect {
        let imageRatio = CGFloat(image.width) / CGFloat(image.height)
        let rectRatio = rect.width / rect.height

        if imageRatio > rectRatio {
            let height = rect.width / imageRatio
            return CGRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width, height: height)
        } else {
            let width = rect.height * imageRatio
            return CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: rect.height)
        }
    }
}
