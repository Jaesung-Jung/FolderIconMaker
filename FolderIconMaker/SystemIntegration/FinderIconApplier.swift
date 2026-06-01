import AppKit
import CoreGraphics
import Foundation

enum FinderIconApplier {
  static func apply(_ image: CGImage, to folderURL: URL) -> Bool {
    let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    return NSWorkspace.shared.setIcon(nsImage, forFile: folderURL.path, options: [])
  }
}
