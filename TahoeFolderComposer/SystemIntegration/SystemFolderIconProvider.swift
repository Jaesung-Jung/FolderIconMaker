import AppKit
import CoreGraphics
import Foundation

struct SystemFolderIconProvider {
  func emptyFolderIcon(canvasSize: Int) -> CGImage {
    let folderURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("TahoeFolderComposerEmptyFolder", isDirectory: true)
    try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
    NSWorkspace.shared.noteFileSystemChanged(folderURL.path)

    let image = NSWorkspace.shared.icon(forFile: folderURL.path)
    image.size = NSSize(width: canvasSize, height: canvasSize)
    return draw(image, canvasSize: canvasSize)
  }

  private func draw(_ image: NSImage, canvasSize: Int) -> CGImage {
    let size = NSSize(width: canvasSize, height: canvasSize)
    let rep = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: canvasSize,
      pixelsHigh: canvasSize,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: canvasSize * 4,
      bitsPerPixel: 32
    )!
    rep.size = size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()
    image.draw(
      in: NSRect(origin: .zero, size: size),
      from: .zero,
      operation: .sourceOver,
      fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()

    return rep.cgImage!
  }
}
