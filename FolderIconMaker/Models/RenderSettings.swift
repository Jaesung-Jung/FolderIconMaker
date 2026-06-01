import CoreGraphics

struct RenderSettings: Equatable {
  var canvasSize: Int
  var symbolRect: CGRect
  var mainDarken: CGFloat
  var shadowOpacity: CGFloat
  var shadowOffset: CGSize
  var highlightOpacity: CGFloat
  var glowOpacity: CGFloat

  static let `default` = RenderSettings(
    canvasSize: 1024,
    symbolRect: CGRect(x: 312, y: 380, width: 400, height: 400),
    mainDarken: 0.16,
    shadowOpacity: 0.30,
    shadowOffset: CGSize(width: 2, height: 3),
    highlightOpacity: 0.24,
    glowOpacity: 0.16
  )
}
