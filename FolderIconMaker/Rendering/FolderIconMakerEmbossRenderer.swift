import CoreGraphics
import CoreImage
import Darwin
import Foundation

struct FolderIconMakerEmbossRenderer {
  func render(base: CGImage, symbol: CGImage, settings: RenderSettings) -> CGImage {
    let baseImage = drawBase(base, size: settings.canvasSize)
    let symbolInput = drawSymbolInput(symbol, settings: settings)
    return IconServicesEmbossEffect().render(
      background: baseImage,
      input: symbolInput,
      canvasSize: settings.canvasSize
    )
  }

  private func drawBase(_ image: CGImage, size: Int) -> CGImage {
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

    return makeImage(from: pixels, width: size, height: size)
  }

  private func drawSymbolInput(_ symbol: CGImage, settings: RenderSettings) -> CGImage {
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

    return makeImage(from: pixels, width: settings.canvasSize, height: settings.canvasSize)
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
}

private struct IconServicesEmbossEffect {
  private static let context = CIContext(options: nil)

  func render(background: CGImage, input: CGImage, canvasSize: Int) -> CGImage {
    dlopen("/System/Library/PrivateFrameworks/IconServices.framework/IconServices", RTLD_NOW)

    let effectClass = NSClassFromString("ISEmbossedEffect") as! NSObject.Type
    let effect = effectClass.init()
    let filter = effect.perform(
      NSSelectorFromString("filterWithBackgroundImage:inputImage:"),
      with: CIImage(cgImage: background),
      with: CIImage(cgImage: input)
    )!.takeUnretainedValue()
    let outputImage = filter.value(forKey: "outputImage") as! CIImage

    return Self.context.createCGImage(
      outputImage,
      from: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
    )!
  }
}
