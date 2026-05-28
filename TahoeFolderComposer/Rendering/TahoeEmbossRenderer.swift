import CoreGraphics
import Foundation

struct TahoeEmbossRenderer {
    func render(base: CGImage, symbol: CGImage, settings: RenderSettings) -> CGImage {
        let size = settings.canvasSize
        let glowRadius = 2
        var pixels = drawBase(base, size: size)
        let mask = SymbolImageLoader.alphaMask(from: symbol, canvasSize: size, targetRect: settings.symbolRect)
        let bounds = expandedEffectBounds(settings: settings, canvasSize: size, glowRadius: glowRadius)

        for y in bounds.minY..<bounds.maxY {
            for x in bounds.minX..<bounds.maxX {
                let index = (y * size + x) * 4
                let alpha = CGFloat(mask.value(x: x, y: y)) / 255.0
                let shadow = CGFloat(mask.value(x: x - Int(settings.shadowOffset.width), y: y - Int(settings.shadowOffset.height))) / 255.0
                let highlight = max(0, CGFloat(mask.value(x: x + 1, y: y + 1)) / 255.0 - alpha)
                let glow = max(0, neighborhoodMax(mask, x: x, y: y, radius: glowRadius) - alpha)

                if alpha > 0 {
                    let factor = 1.0 - settings.mainDarken * alpha
                    pixels[index] = UInt8(clamp(CGFloat(pixels[index]) * factor))
                    pixels[index + 1] = UInt8(clamp(CGFloat(pixels[index + 1]) * factor))
                    pixels[index + 2] = UInt8(clamp(CGFloat(pixels[index + 2]) * factor))
                }

                if shadow > 0 {
                    let factor = 1.0 - settings.shadowOpacity * shadow
                    pixels[index] = UInt8(clamp(CGFloat(pixels[index]) * factor))
                    pixels[index + 1] = UInt8(clamp(CGFloat(pixels[index + 1]) * factor))
                    pixels[index + 2] = UInt8(clamp(CGFloat(pixels[index + 2]) * factor))
                }

                if highlight > 0 {
                    blendScreen(&pixels, index: index, color: (189, 238, 255), amount: highlight * settings.highlightOpacity)
                }

                if glow > 0 {
                    blendScreen(&pixels, index: index, color: (169, 232, 255), amount: glow * settings.glowOpacity)
                }
            }
        }

        return makeImage(from: pixels, width: size, height: size)
    }

    private func drawBase(_ image: CGImage, size: Int) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: size * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        return pixels
    }

    private struct EffectBounds {
        let minX: Int
        let maxX: Int
        let minY: Int
        let maxY: Int
    }

    private func expandedEffectBounds(settings: RenderSettings, canvasSize: Int, glowRadius: Int) -> EffectBounds {
        let shadowX = abs(Int(settings.shadowOffset.width))
        let shadowY = abs(Int(settings.shadowOffset.height))
        let xPadding = max(glowRadius, 1, shadowX)
        let yPadding = max(glowRadius, 1, shadowY)
        let rect = settings.symbolRect

        return EffectBounds(
            minX: clamped(Int(floor(rect.minX)) - xPadding, to: canvasSize),
            maxX: clamped(Int(ceil(rect.maxX)) + xPadding, to: canvasSize),
            minY: clamped(Int(floor(rect.minY)) - yPadding, to: canvasSize),
            maxY: clamped(Int(ceil(rect.maxY)) + yPadding, to: canvasSize)
        )
    }

    private func clamped(_ value: Int, to canvasSize: Int) -> Int {
        min(canvasSize, max(0, value))
    }

    private func makeImage(from pixels: [UInt8], width: Int, height: Int) -> CGImage {
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
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
            shouldInterpolate: true,
            intent: .defaultIntent
        )!
    }

    private func neighborhoodMax(_ mask: AlphaMask, x: Int, y: Int, radius: Int) -> CGFloat {
        var maxValue: UInt8 = 0
        for yy in (y - radius)...(y + radius) {
            for xx in (x - radius)...(x + radius) {
                maxValue = max(maxValue, mask.value(x: xx, y: yy))
            }
        }
        return CGFloat(maxValue) / 255.0
    }

    private func blendScreen(_ pixels: inout [UInt8], index: Int, color: (CGFloat, CGFloat, CGFloat), amount: CGFloat) {
        pixels[index] = UInt8(clamp(screen(CGFloat(pixels[index]), color.0, amount: amount)))
        pixels[index + 1] = UInt8(clamp(screen(CGFloat(pixels[index + 1]), color.1, amount: amount)))
        pixels[index + 2] = UInt8(clamp(screen(CGFloat(pixels[index + 2]), color.2, amount: amount)))
    }

    private func screen(_ base: CGFloat, _ top: CGFloat, amount: CGFloat) -> CGFloat {
        let screened = 255.0 - ((255.0 - base) * (255.0 - top) / 255.0)
        return base + (screened - base) * amount
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(255, max(0, value))
    }
}
