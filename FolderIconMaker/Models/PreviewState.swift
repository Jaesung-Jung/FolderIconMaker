import CoreGraphics

struct PreviewState {
  var baseImage: CGImage?
  var renderedImage: CGImage?
  var isRendering = false

  var visibleImage: CGImage? {
    renderedImage ?? baseImage
  }

  var exportImage: CGImage? {
    renderedImage
  }

  mutating func showBase(_ image: CGImage?) {
    baseImage = image
    renderedImage = nil
    isRendering = false
  }

  mutating func beginRendering(baseImage image: CGImage) {
    baseImage = image
    renderedImage = nil
    isRendering = true
  }

  mutating func showRendered(_ image: CGImage) {
    renderedImage = image
    isRendering = false
  }
}
